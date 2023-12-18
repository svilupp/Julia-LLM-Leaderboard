"""
    run_benchmark(; fn_definitions::Vector{<:AbstractString}=find_definitons(joinpath(@__DIR__, "..", "code_generation")),
    models::Vector{String}=["gpt-3.5-turbo-1106"], model_suffix::String="", prompt_labels::Vector{<:AbstractString}=["JuliaExpertCoTTask", "JuliaExpertAsk", "InJulia", "AsIs", "JuliaRecapTask", "JuliaRecapCoTTask"],
    api_kwargs::NamedTuple=NamedTuple(),
    experiment::AbstractString="", save_dir::AbstractString="", auto_save::Bool=true, verbose::Bool=true, device::AbstractString="-",
    num_samples::Int=1, schema_lookup::AbstractDict{String,<:Any}=Dict{String,<:Any}())

Runs the code generation benchmark with specified models and prompts for the specified number of samples.

It will generate the response, evaluate it and, optionally, also save it.

Note: This benchmark is not parallelized, because locally hosted models would be overwhelmed. 
However, you can take this code and apply `Threads.@spawn` to it. The evaluation itself should be thread-safe.

# Keyword Arguments
- `fn_definitions`: a vector of paths to definitions of test cases to run (`definition.toml`). If not specified, it will run all definition files in the `code_generation` folder.
- `models`: a vector of models to run. If not specified, it will run only `gpt-3.5-turbo-1106`.
- `model_suffix`: a string to append to the model name in the evaluation data, eg, "--optim" if you provide some tuned API kwargs.
- `prompt_labels`: a vector of prompt labels to run. If not specified, it will run all available.
- `num_samples`: an integer to specify the number of samples to generate for each model/prompt combination. If not specified, it will generate 1 sample.
- `api_kwargs`: a named tuple of API kwargs to pass to the `aigenerate` function. If not specified, it will use the default values. Example: `(; temperature=0.5, top_p=0.5)`
- `schema_lookup`: a dictionary of schemas to use for each model. If not specified, it will use the default schemas in the registry. Example: `Dict("mistral-tiny" => PT.MistralOpenAISchema())`

- `experiment`: a string to save in the evaluation data. Useful for future analysis.
- `device`: specify the device the benchmark is running on, eg, "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model".
- `save_dir`: a string of path where to save the evaluation data. If not specified, it will save in the same folder as the definition file. Useful for small experiments not to pollute the main benchmark.

- `auto_save`: a boolean whether to automatically save the evaluation data. If not specified, it will save the data. Otherwise, it only returns the vector of `evals`
- `verbose`: a boolean to print progress. If not specified, it will print progress.

# Return
- Vector of `evals`, ie, a dictionary of evaluation data for each model/prompt combination and each sample.

# Example
```julia
fn_definitions = find_definitions("code_generation/") # all test cases

evals = run_benchmark(; fn_definitions, models=["gpt-3.5-turbo-1106"], prompt_labels=["JuliaExpertAsk"],
    experiment="my-first-run", save_dir="temp", auto_save=true, verbose=true, device="Apple-MacBook-Pro-M1",
    num_samples=1);

# not using `schema_lookup` as it's not needed for OpenAI models
```

Or if you want only one test case use:
`fn_definitions = [joinpath("code_generation", "utility_functions", "event_scheduler", "definition.toml")]`
"""
function run_benchmark(; fn_definitions::Vector{<:AbstractString}=find_definitons(joinpath(@__DIR__, "..", "code_generation")),
    models::Vector{String}=["gpt-3.5-turbo-1106"], model_suffix::String="", prompt_labels::Vector{<:AbstractString}=["JuliaExpertCoTTask", "JuliaExpertAsk", "InJulia", "AsIs", "JuliaRecapTask", "JuliaRecapCoTTask"],
    api_kwargs::NamedTuple=NamedTuple(),
    experiment::AbstractString="", save_dir::AbstractString="", auto_save::Bool=true, verbose::Bool=true, device::AbstractString="-",
    num_samples::Int=1, schema_lookup::AbstractDict{String,<:Any}=Dict{String,<:Any}())

    @assert num_samples > 0 "num_samples must be positive"
    unknown_definitions = filter(!isfile, fn_definitions)
    @assert isempty(unknown_definitions) "Unknown definition files: $(join(unknown_definitions, ", ")). Please fix the paths."

    available_prompts = ["JuliaExpertCoTTask", "JuliaExpertAsk", "InJulia", "AsIs", "JuliaRecapTask", "JuliaRecapCoTTask"]
    unknown_prompts = setdiff(prompt_labels, available_prompts)
    @assert isempty(unknown_prompts) "Unknown prompt labels: $(join(unknown_prompts, ", "))"

    # Check if all models are in the registry, if not, they must be in the schema_lookup
    unknown_models = setdiff(models, vcat(keys(PT.MODEL_REGISTRY.registry)..., keys(PT.MODEL_REGISTRY.aliases)...))
    unknown_models = setdiff(unknown_models, keys(schema_lookup))
    @assert isempty(unknown_models) "Unknown models: $(join(unknown_models, ", ")). Provide the necessary schema via the `schema_lookup` keyword."

    # Create the save_dir if it doesn't exist
    isdir(save_dir) || mkdir(save_dir, parents=true)

    # Prepare a list of combinations to run
    all_options = Iterators.product(prompt_labels, models) |> collect |> vec
    num_runs = length(all_options) * num_samples

    verbose && @info ">> Starting a benchmark with $(num_runs) runs"

    evals = []
    total_time = @elapsed for fn_definition in fn_definitions
        verbose && @info ">> Running for $fn_definition at $(now())"

        definition = load_definition(fn_definition)["code_generation"]
        for option in all_options
            for i in 1:num_samples
                ## Setup
                (prompt_label, model) = option
                # Lookup schema if not in registry
                schema = if !haskey(PT.MODEL_REGISTRY, model)
                    schema_lookup[model]
                else
                    # grab schema from registry
                    PT.MODEL_REGISTRY[model].schema
                end
                try
                    eval_ = begin
                        ## Pick response generator based on the prompt_label
                        conversation = if prompt_label == "JuliaExpertAsk"
                            aigenerate(schema, :JuliaExpertAsk; ask=definition["prompt"], model, api_kwargs, return_all=true, verbose)
                        elseif prompt_label == "JuliaExpertCoTTask"
                            aigenerate(schema, :JuliaExpertCoTTask; task=definition["prompt"], data=first(definition["examples"]), model, api_kwargs, return_all=true, verbose)
                        elseif prompt_label == "JuliaRecapCoTTask"
                            aigenerate(schema, :JuliaRecapCoTTask; task=definition["prompt"], data=first(definition["examples"]), model, api_kwargs, return_all=true, verbose)
                        elseif prompt_label == "JuliaRecapTask"
                            aigenerate(schema, :JuliaRecapTask; task=definition["prompt"], instructions="None.", model, api_kwargs, return_all=true, verbose)
                        elseif prompt_label == "InJulia"
                            aigenerate(schema, "In Julia, $(definition["prompt"])"; model, api_kwargs, return_all=true, verbose)
                        elseif prompt_label == "AsIs"
                            aigenerate(schema, definition["prompt"]; model, api_kwargs, return_all=true, verbose)
                        else
                            @warn "Unknown prompt_label: $prompt_label. Add the options to the if-elseif-else block."
                            nothing
                        end
                        ## Evaluate 1SHOT, including saving the files (and randint to prevent overrides)
                        evaluate_1shot(; conversation, parameters=api_kwargs, fn_definition, definition,
                            model=model * model_suffix, prompt_label, device, schema, prompt_strategy="1SHOT", verbose=false,
                            save_dir, auto_save, experiment)
                    end
                    push!(evals, eval_)
                catch e
                    @error "ERROR: Failed for $option with error: $e"
                end
            end
        end
    end



    ## Summary
    verbose && @info ">> Benchmark with $(num_runs) finished in $(round(total_time, digits=0))s"

    return evals

end