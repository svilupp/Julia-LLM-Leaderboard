
# # Run the Benchmark
#
# It will evaluate arbitrary number of models and prompts, and save the results in sub-folders of where the definition file was stored.
# It saves: `evaluation__PROMPTABC__1SHOT__TIMESTAMP.json` and `conversation__PROMPTABC__1SHOT__TIMESTAMP.json`

# ## Imports
using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools

# ## Run for a single test case
device = "Apple-MacBook-Pro-M1" # "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model"

# Select models to run
#
# Paid Models:
model_options = [
    "gpt-3.5-turbo",
    "gpt-3.5-turbo-1106",
    "gpt-4-1106-preview",
    "mistral-tiny",
    "mistral-small",
    "mistral-medium",
]

# Or OSS models:
model_options = ["llama2", "openhermes2.5-mistral", "starling-lm:latest", "yi:34b-chat",
    "codellama:13b-instruct", "magicoder", "stablelm-zephyr",
    "orca2:13b", "phind-codellama:34b-v2",
    "deepseek-coder:33b-instruct-q4_K_M", "solar:10.7b-instruct-v1-q4_K_M",
    "mistral:7b-instruct-q4_K_M", "openchat:7b-v3.5-1210-q4_K_M", "phi:2.7b-chat-v2-q6_K",
    "mistral:7b-instruct-v0.2-q6_K", "dolphin-phi:2.7b-v2.6-q6_K",
    "nous-hermes2:34b-yi-q4_K_M"]

## Rerun: 3x 2 models all cases, then 1x all before Q&A for nous-hermes
## Then 3x for paid APIs
model_options = ["dolphin-phi:2.7b-v2.6-q6_K",
    "nous-hermes2:34b-yi-q4_K_M"]

# Select prompt templates to run (for reference check: `aitemplates("Julia")`)
prompt_options = [
    "JuliaExpertCoTTask",
    "JuliaExpertAsk",
    "InJulia",
    ## "AsIs", # no need to prove that it's worse
    "JuliaRecapTask",
    "JuliaRecapCoTTask",
]

# Define the schema for unknown models, eg, needed if you use non-OpenAI models, provide a key for each model you use
schema_lookup = Dict{String, Any}(["llama2", "openhermes2.5-mistral", "starling-lm:latest",
    "yi:34b-chat", "codellama:13b-instruct", "magicoder",
    "stablelm-zephyr", "orca2:13b", "phind-codellama:34b-v2",
    "deepseek-coder:33b-instruct-q4_K_M", "solar:10.7b-instruct-v1-q4_K_M",
    "openchat:7b-v3.5-1210-q4_K_M", "phi:2.7b-chat-v2-q6_K",
    "mistral:7b-instruct-v0.2-q6_K", "dolphin-phi:2.7b-v2.6-q6_K",
    "nous-hermes2:34b-yi-q4_K_M", "magicoder:7b-s-cl-q6_K",
    "mistral:7b-instruct-v0.2-q4_0", "mistral:7b-instruct-v0.2-q4_K_M"] .=> Ref(PT.OllamaSchema()))

# ## Run Benchmark - High-level Interface
fn_definitions = find_definitions("code_generation/")

# or if you want only one test case:
# fn_definitions = [joinpath("code_generation", "utility_functions", "event_scheduler", "definition.toml")]
models = ["mistral:7b-instruct-v0.2-q4_0", "mistral:7b-instruct-v0.2-q4_K_M"]
evals = run_benchmark(; fn_definitions, models,# = model_options,
    prompt_labels = prompt_options,
    experiment = "", auto_save = true, verbose = true, device,
    num_samples = 5, schema_lookup, http_kwargs = (; readtimeout = 150),
    api_kwargs = (; options = (; num_gpu = 99)));
# Note: On Mac M1 with Ollama, you want to set api_kwargs=(; options=(; num_gpu=99)) for Ollama to have normal performance

# Voila! You can now find the results in the `temp/` folder or in the vector `evals`!

# ## Low-level interface
#
# This is the low-level interface where you can experiment with prompts and various parameters.
# `run_benchmark` effectively wraps the below for-loop for you.

all_options = Iterators.product(prompt_options, model_options) |> collect |> vec

# if you want to run multiple, add one more loop with: fn_definitions = find_definitions("code_generation")
fn_definition = joinpath("code_generation",
    "utility_functions",
    "event_scheduler",
    "definition.toml")
# fn_definition = joinpath("code_generation", "data_analysis", "weather_data_analyzer", "definition.toml")

definition = load_definition(fn_definition)["code_generation"]
evals = let
    evals = []
    for option in all_options
        # Feel free to use multithread with `Threads.@spawn` if you want to run multiple models in parallel, but make sure to use lock for `push!`!
        # However, you must set `capture_stdout=false` in evaluate_1shot
        for i in 1:num_samples
            try
                ## Setup
                (prompt_label, model) = option
                # Lookup schema, default to OpenAI
                schema = get(schema_lookup, model, PT.OpenAISchema())
                ## Pick response generator based on the prompt_label
                conversation = if prompt_label == "JuliaExpertAsk"
                    aigenerate(schema,
                        :JuliaExpertAsk;
                        ask = definition["prompt"],
                        model,
                        return_all = true)
                elseif prompt_label == "JuliaExpertCoTTask"
                    aigenerate(schema,
                        :JuliaExpertCoTTask;
                        task = definition["prompt"],
                        data = first(definition["examples"]),
                        model,
                        return_all = true)
                elseif prompt_label == "JuliaRecapCoTTask"
                    aigenerate(schema,
                        :JuliaRecapCoTTask;
                        task = definition["prompt"],
                        data = first(definition["examples"]),
                        model,
                        return_all = true)
                elseif prompt_label == "JuliaRecapTask"
                    aigenerate(schema,
                        :JuliaRecapTask;
                        task = definition["prompt"],
                        instructions = "None.",
                        model,
                        return_all = true)
                elseif prompt_label == "InJulia"
                    aigenerate(schema,
                        "In Julia, $(definition["prompt"])";
                        model,
                        return_all = true)
                elseif prompt_label == "AsIs"
                    aigenerate(schema, definition["prompt"]; model, return_all = true)
                else
                    @warn "Unknown prompt_label: $prompt_label. Add the options to the if-elseif-else block."
                    nothing
                end
                ## Evaluate 1SHOT, including saving the files (and randint to prevent overrides)
                eval_ = evaluate_1shot(;
                    conversation,
                    fn_definition,
                    definition,
                    model,
                    prompt_label,
                    device,
                    schema,
                    prompt_strategy = "1SHOT",
                    verbose = false,
                    ## important to set to false if you run in multi-threaded mode
                    capture_stdout = false)
                push!(evals, eval_)
            catch e
                @error "Failed for $option with error: $e"
            end
        end
    end
    evals
end