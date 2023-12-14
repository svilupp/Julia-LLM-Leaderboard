
# # Example how to run the code generation benchmark
#
# It will evaluate arbitrary number of models and prompts, and save the results in sub-folders of where the definition file was stored.
# It saves: `evaluation__PROMPTABC__1SHOT__TIMESTAMP.json` and `conversation__PROMPTABC__1SHOT__TIMESTAMP.json`

# ## Imports
using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools

# ## Run for a single test case
device = "Apple-MacBook-Pro-M1" # "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model"

# Paid Models:
model_options = ["gpt-3.5-turbo", "gpt-3.5-turbo-1106", "gpt-4-1106-preview", "mistral-tiny", "mistral-small", "mistral-medium"]

# Or OSS models:
model_options = ["llama2", "openhermes2.5-mistral", "starling-lm:latest", "yi:34b-chat", "codellama:13b-instruct", "codellama:13b-python", "magicoder", "stablelm-zephyr", "orca2:13b", "phind-codellama:34b-v2"]

prompt_options = ["JuliaExpertCoTTask", "JuliaExpertAsk", "InJulia", "AsIs", "JuliaRecapTask", "JuliaRecapCoTTask"]
# needed if you use non-OpenAI models, provide a key for each model you use
schema_lookup = Dict{String,Any}(["llama2", "openhermes2.5-mistral", "starling-lm:latest", "yi:34b-chat", "codellama:13b-instruct", "codellama:13b-python", "magicoder", "stablelm-zephyr", "orca2:13b", "phind-codellama:34b-v2"] .=> Ref(PT.OllamaManagedSchema()))
merge!(schema_lookup, Dict(["mistral-tiny", "mistral-small", "mistral-medium"] .=> Ref(MistralOpenAISchema())))

all_options = Iterators.product(prompt_options, model_options) |> collect |> vec

# for reference: aitemplates("Julia")

# ## Run for all model/prompt combinations
# if you want to run multiple, add one more loop with: fn_definitions = find_definitions("code_generation")
fn_definition = joinpath("code_generation", "utility_functions", "event_scheduler", "definition.toml")
# fn_definition = joinpath("code_generation", "data_analysis", "weather_data_analyzer", "definition.toml")

definition = load_definition(fn_definition)["code_generation"]
evals = let all_options = all_options
    evals = []
    for option in all_options
        # task = Threads.@spawn begin # disabled as it causes issue with stdout redirection
        try
            ## Setup
            (prompt_label, model) = option
            # Lookup schema, default to OpenAI
            schema = get(schema_lookup, model, PT.OpenAISchema())
            ## Pick response generator based on the prompt_label
            conversation = if prompt_label == "JuliaExpertAsk"
                aigenerate(schema, :JuliaExpertAsk; ask=definition["prompt"], model, return_all=true)
            elseif prompt_label == "JuliaExpertCoTTask"
                aigenerate(schema, :JuliaExpertCoTTask; task=definition["prompt"], data=first(definition["examples"]), model, return_all=true)
            elseif prompt_label == "JuliaRecapCoTTask"
                aigenerate(schema, :JuliaRecapCoTTask; task=definition["prompt"], data=first(definition["examples"]), model, return_all=true)
            elseif prompt_label == "JuliaRecapTask"
                aigenerate(schema, :JuliaRecapTask; task=definition["prompt"], instructions="None.", model, return_all=true)
            elseif prompt_label == "InJulia"
                aigenerate(schema, "In Julia, $(definition["prompt"])"; model, return_all=true)
            elseif prompt_label == "AsIs"
                aigenerate(schema, definition["prompt"]; model, return_all=true)
            else
                @warn "Unknown prompt_label: $prompt_label. Add the options to the if-elseif-else block."
                nothing
            end
            ## Evaluate 1SHOT, including saving the files (and randint to prevent overrides)
            eval_ = evaluate_1shot(; conversation, fn_definition, definition, model, prompt_label, device, schema, prompt_strategy="1SHOT", verbose=false)
            push!(evals, eval_)
        catch e
            @error "Failed for $option with error: $e"
        end
    end
    evals
end