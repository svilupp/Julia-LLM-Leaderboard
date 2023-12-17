### UNDER CONSTRUCTION
"""
    run_benchmark(; models=[],prompt_labels=[])

Runs the code generation benchmark with specified models and prompts.

# Keyword Arguments
"""
function run_benchmark(; fn_definitions=String[], models=String[], model_suffix::String="", prompt_labels=String[], api_kwargs::NamedTuple=NamedTuple(),
    experiment::AbstractString="", save_dir::AbstractString="", auto_save::Bool=true, verbose::Bool=true, device::String="-", num_samples::Int=1, schema_lookup::AbstractDict=Dict())

    @assert num_samples > 0 "num_samples must be positive"
    available_prompts = ["JuliaExpertCoTTask", "JuliaExpertAsk", "InJulia", "AsIs", "JuliaRecapTask", "JuliaRecapCoTTask"]
    unknown_prompts = setdiff(prompt_labels, available_prompts)
    @assert isempty(unknown_prompts) "Unknown prompt labels: $(join(unknown_prompts, ", "))"
    available_models = ["gpt-3.5-turbo", "gpt-3.5-turbo-1106", "gpt-4-1106-preview", "mistral-tiny", "mistral-small", "mistral-medium"]

    # device = "Apple-MacBook-Pro-M1" # "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model"

    # OpenAI models can be easily run in async
    # model_options = ["gpt-3.5-turbo", "gpt-3.5-turbo-1106", "gpt-4-1106-preview", "mistral-tiny", "mistral-small", "mistral-medium"]
    # When benchmarking local models, comment out the Threads.@spawn to run the generation sequentially
    # model_options = ["llama2", "openhermes2.5-mistral", "starling-lm:latest", "yi:34b-chat", "codellama:13b-instruct", "codellama:13b-python", "magicoder", "stablelm-zephyr", "orca2:13b", "phind-codellama:34b-v2"]

    # Optional: include optimized parameters
    # optimized_api_kwargs = Dict("mistral-medium" => (temperature=0.9, top_p=0.3),
    #     "mistral-small" => (temperature=0.9, top_p=0.3),
    #     "mistral-tiny" => (temperature=0.9, top_p=0.3),
    #     "gpt-4-1106-preview" => (temperature=0.1, top_p=0.9),
    #     "gpt-3.5-turbo-1106" => (temperature=0.9, top_p=0.1),
    #     "gpt-3.5-turbo" => (temperature=0.5, top_p=0.5))

    prompt_options = ["JuliaExpertCoTTask", "JuliaExpertAsk", "InJulia", "AsIs", "JuliaRecapTask", "JuliaRecapCoTTask"]
    # needed if you use non-OpenAI models, provide a key for each model you use
    # schema_lookup = Dict{String,Any}(["llama2", "openhermes2.5-mistral", "starling-lm:latest", "yi:34b-chat", "codellama:13b-instruct", "codellama:13b-python", "magicoder", "stablelm-zephyr", "orca2:13b", "phind-codellama:34b-v2"] .=> Ref(PT.OllamaManagedSchema()))
    # merge!(schema_lookup, Dict(["mistral-tiny", "mistral-small", "mistral-medium"] .=> Ref(PT.MistralOpenAISchema())))

    all_options = Iterators.product(prompt_options, model_options) |> collect |> vec

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