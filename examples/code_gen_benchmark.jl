# # Example Code Gen Benchmark
using TOML
using PromptingTools
const PT = PromptingTools
using Dates
using JSON3
using Random

# # Run for a single test case
definition = load_definition(fn_definition)["code_generation"]
model_options = ["gpt-3.5-turbo"]
prompt_options = ["JuliaExpertAsk", "JuliaExpertCoTTask", "InJulia"]
schema_lookup = Dict("gpt-3.5-turbo" => PT.OpenAISchema)
all_options = Iterators.product(model_options, prompt_options)

# for reference: aitemplates("Julia")

tasks = []
for option in all_options
    task = Threads.@spawn begin
        ## Setup
        (model, prompt_label) = option
        # This loop picks only
        schema = schema_lookup[model]
        ## Pick response generator based on the prompt_label
        conversation = if prompt_label == "JuliaExpertAsk"
            aigenerate(schema, :JuliaExpertAsk; ask=definition["prompt"]; model)
        elseif prompt_label == "JuliaExpertCoTTask"
            aigenerate(schema, :JuliaExpertCoTTask; task=definition["prompt"], data=definition["examples"] |> first; model)
        elseif prompt_label == "InJulia"
            aigenerate(schema, "In Julia, $(definition["prompt"])"; model)
        else
            nothing
        end
        ## Evaluate 1SHOT, including saving the files (and randint to prevent overrides)
        timestamp = "$(timestamp_now())__$(random(100:999))"
        evaluate_1shot(; conversation, fn_definition, definition, model, prompt_label, timestamp, prompt_strategy="1SHOT", verbose=false)
    end
    push!(tasks, task)
end