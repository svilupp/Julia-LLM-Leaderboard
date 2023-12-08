
# Example how to run the code generation benchmark
#
# It will evaluate arbitrary number of models and prompts, and save the results in sub-folders of where the definition file was stored.
# It saves: `evaluation__PROMPTABC__1SHOT__TIMESTAMP.json` and `conversation__PROMPTABC__1SHOT__TIMESTAMP.json`

# ## Imports
using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools

# ## Run for a single test case
device = "Apple-MacBook-Pro-M1" # "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model"
fn_definition = joinpath("code_generation", "utility_functions", "wrap_string", "definition.toml")

definition = load_definition(fn_definition)["code_generation"]
# OpenAI models can be easily run in async
model_options = ["gpt-3.5-turbo", "gpt-3.5-turbo-1106", "gpt-4-1106-preview"]
# When benchmarking local models, comment out the Threads.@spawn to run the generation sequentially
# model_options = ["llama2", "openhermes2.5-mistral", "starling-lm:latest", "yi:34b-chat", "codellama:13b-instruct", "codellama:13b-python"]

prompt_options = ["JuliaExpertCoTTask", "JuliaExpertAsk", "InJulia", "AsIs"]
# needed if you use non-OpenAI models, provide a key for each model you use
schema_lookup = Dict(["llama2", "openhermes2.5-mistral", "starling-lm:latest", "yi:34b-chat", "codellama:13b-instruct", "codellama:13b-python"] .=> Ref(PT.OllamaManagedSchema()))
all_options = Iterators.product(model_options, prompt_options) |> collect |> vec

# for reference: aitemplates("Julia")

# ## Run for all model/prompt combinations
tasks = let all_options = all_options
    tasks = []
    for option in all_options
        task = Threads.@spawn begin
            ## Setup
            (model, prompt_label) = option
            # Lookup schema, default to OpenAI
            schema = get(schema_lookup, model, PT.OpenAISchema())
            ## Pick response generator based on the prompt_label
            conversation = if prompt_label == "JuliaExpertAsk"
                aigenerate(schema, :JuliaExpertAsk; ask=definition["prompt"], model, return_all=true)
            elseif prompt_label == "JuliaExpertCoTTask"
                aigenerate(schema, :JuliaExpertCoTTask; task=definition["prompt"], data=first(definition["examples"]), model, return_all=true)
            elseif prompt_label == "InJulia"
                aigenerate(schema, "In Julia, $(definition["prompt"])"; model, return_all=true)
            elseif prompt_label == "AsIs"
                aigenerate(schema, definition["prompt"]; model, return_all=true)
            else
                @warn "Unknown prompt_label: $prompt_label. Add the options to the if-elseif-else block."
                nothing
            end
            ## Evaluate 1SHOT, including saving the files (and randint to prevent overrides)
            evaluate_1shot(; conversation, fn_definition, definition, model, prompt_label, device, prompt_strategy="1SHOT", verbose=false)
        end
        push!(tasks, task)
    end
    tasks
end

# ## Debugging -- wait for all tasks to finish
@assert all(istaskdone, tasks) "Not all tasks finished!"

# Often, there can be failures (wrong model name etc.)
# Check which test cases failed
failed_mask = istaskfailed.(tasks)
(sum(failed_mask) > 0) && @info "$(sum(failed_mask)) out of $(length(tasks)) failed";

# Inspect which inputs need to be re-run (simply override the `all_options` variable in the let block and re-run the code block above)
all_options[failed_mask]

# Inspect which tasks failed / error messages
tasks[failed_mask] |> first |> fetch