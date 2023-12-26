
# Example how to run the code generation benchmark with "optimal" parameters
#
# It will evaluate arbitrary number of models and prompts, and save the results in sub-folders of where the definition file was stored.
# It saves: `evaluation__PROMPTABC__1SHOT__TIMESTAMP.json` and `conversation__PROMPTABC__1SHOT__TIMESTAMP.json`

# ## Imports
using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools

# ## Run for a single test case
device = "Apple-MacBook-Pro-M1" # "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model"

# OpenAI models can be easily run in async
model_options = ["gpt-3.5-turbo", "gpt-3.5-turbo-1106", "gpt-4-1106-preview", "mistral-tiny", "mistral-small", "mistral-medium"]
# When benchmarking local models, comment out the Threads.@spawn to run the generation sequentially
# model_options = ["llama2", "openhermes2.5-mistral", "starling-lm:latest", "yi:34b-chat", "codellama:13b-instruct", "codellama:13b-python", "magicoder", "stablelm-zephyr", "orca2:13b", "phind-codellama:34b-v2"]

# Optional: include optimized parameters
optimized_api_kwargs = Dict("mistral-medium" => (temperature=0.9, top_p=0.3),
    "mistral-small" => (temperature=0.9, top_p=0.3),
    "mistral-tiny" => (temperature=0.9, top_p=0.3),
    "gpt-4-1106-preview" => (temperature=0.1, top_p=0.9),
    "gpt-3.5-turbo-1106" => (temperature=0.9, top_p=0.1),
    "gpt-3.5-turbo" => (temperature=0.5, top_p=0.5))
# Useful tip -- APIs can get stuck, so use timeouts
http_kwargs = (; readtimeout=300)

prompt_options = ["JuliaExpertCoTTask", "JuliaExpertAsk", "InJulia", "AsIs", "JuliaRecapTask", "JuliaRecapCoTTask"]
# needed if you use non-OpenAI models, provide a key for each model you use
schema_lookup = Dict{String,Any}(["llama2", "openhermes2.5-mistral", "starling-lm:latest", "yi:34b-chat", "codellama:13b-instruct", "codellama:13b-python", "magicoder", "stablelm-zephyr", "orca2:13b", "phind-codellama:34b-v2"] .=> Ref(PT.OllamaManagedSchema()))
merge!(schema_lookup, Dict(["mistral-tiny", "mistral-small", "mistral-medium"] .=> Ref(PT.MistralOpenAISchema())))

all_options = Iterators.product(prompt_options, model_options) |> collect |> vec

# for reference: aitemplates("Julia")

# ## High-level Interface

# Use run_benchmark:
#
# evals = run_benchmark(; fn_definitions=find_definitions("code_generation/"), models=model_options, prompt_labels=prompt_options,
#     api_kwargs=NamedTuple(), model_suffix="", experiment="hyperparams__mistral-medium__grid_search1", save_dir="temp", auto_save=true, verbose=true, device,
#     num_samples=1, schema_lookup);

# ## Run for all model/prompt combinations -- Low-level
# if you want to run a single test case: 
# fn_definitions = [joinpath("code_generation", "utility_functions", "event_scheduler", "definition.toml")]
fn_definitions = find_definitions("code_generation/")

@time for fn_definition in fn_definitions
    @info "Running for $fn_definition at $(now())"
    definition = load_definition(fn_definition)["code_generation"]
    evals = let all_options = all_options
        evals = []
        for option in all_options
            # task = Threads.@spawn begin # disabled as it causes issue with stdout redirection
            try
                eval_ = begin
                    ## Setup
                    (prompt_label, model) = option
                    # Lookup schema, default to OpenAI
                    schema = get(schema_lookup, model, PT.OpenAISchema())
                    api_kwargs = get(optimized_api_kwargs, model, NamedTuple())
                    ## Pick response generator based on the prompt_label
                    conversation = if prompt_label == "JuliaExpertAsk"
                        aigenerate(schema, :JuliaExpertAsk; ask=definition["prompt"], model, api_kwargs, http_kwargs, return_all=true)
                    elseif prompt_label == "JuliaExpertCoTTask"
                        aigenerate(schema, :JuliaExpertCoTTask; task=definition["prompt"], data=first(definition["examples"]), model, api_kwargs, http_kwargs, return_all=true)
                    elseif prompt_label == "JuliaRecapCoTTask"
                        aigenerate(schema, :JuliaRecapCoTTask; task=definition["prompt"], data=first(definition["examples"]), model, api_kwargs, return_all=true)
                    elseif prompt_label == "JuliaRecapTask"
                        aigenerate(schema, :JuliaRecapTask; task=definition["prompt"], instructions="None.", model, api_kwargs, http_kwargs, return_all=true)
                    elseif prompt_label == "InJulia"
                        aigenerate(schema, "In Julia, $(definition["prompt"])"; model, api_kwargs, http_kwargs, return_all=true)
                    elseif prompt_label == "AsIs"
                        aigenerate(schema, definition["prompt"]; model, api_kwargs, http_kwargs, return_all=true)
                    else
                        @warn "Unknown prompt_label: $prompt_label. Add the options to the if-elseif-else block."
                        nothing
                    end
                    ## Evaluate 1SHOT, including saving the files (and randint to prevent overrides)
                    ## suffix the model name with --optim if we use optimized parameters
                    evaluate_1shot(; conversation, parameters=api_kwargs, fn_definition, definition, model=model * "--optim", prompt_label, device, schema, timestamp, prompt_strategy="1SHOT", verbose=false)
                end
                push!(evals, eval_)
            catch e
                @error "Failed for $option with error: $e"
            end
        end
        evals
    end
end