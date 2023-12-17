# # Example how to scan optimal hyperparamters (/run experiments)
using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools
using JuliaLLMLeaderboard
using CairoMakie, AlgebraOfGraphics, DataFramesMeta
using MarkdownTables
using Statistics: mean, median

# ## Run for a single test case
device = "Apple-MacBook-Pro-M1" # "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model"

# Models:
model_options = ["gpt-4-1106-preview", "gpt-3.5-turbo", "gpt-3.5-turbo-1106", "gpt-4-1106-preview", "mistral-tiny", "mistral-small", "mistral-medium"]


prompt_options = ["JuliaExpertAsk"]
# needed if you use non-OpenAI models, provide a key for each model you use
schema_lookup = Dict{String,Any}(["llama2", "openhermes2.5-mistral", "starling-lm:latest", "yi:34b-chat", "codellama:13b-instruct", "codellama:13b-python", "magicoder", "stablelm-zephyr", "orca2:13b", "phind-codellama:34b-v2"] .=> Ref(PT.OllamaManagedSchema()))
merge!(schema_lookup, Dict(["mistral-tiny", "mistral-small", "mistral-medium"] .=> Ref(PT.MistralOpenAISchema())))


# **Simple staged approach:**
# - Stage 1 - grid search
#   - pick the hardest test case: `extract_julia_code` and the default template `JuliaExpertAsk`
#   - run grid search for `temperature` and `top_p` for each model (36 hyperparameters)
# - Stage 2 - increase sample size for the most promising hyperparameters
#   - pick the top ~5-10 highest scoring hyperparameters
#   - run evaluation for all test cases (14 problems) and the default template `JuliaExpertAsk`
# - Stage 3 - run the full benchmark
#   - run the full benchmark for the best hyperparameters for each model

# **Note:**
# - variable `save_dir` allows us to save the experiments separately from the core benchmark
# - the variable `experiment` is a label that will be saved in the evaluation results. Good for future analysis

## Full grid search (ie, all possible combinations)
temperature_options = [0.1:0.2:1.0..., 1.0]
top_p_options = [0.1:0.2:1.0..., 1.0]
all_options = Iterators.product(prompt_options, model_options, temperature_options, top_p_options) |> collect |> vec

## Targeted search over specific combinations
temp_top_p_options = [(0.1, 0.5), (0.5, 0.5)]
all_options = Iterators.product(prompt_options, model_options, temp_top_p_options) |> opts -> [(o[begin:end-1]..., o[end]...) for o in opts] |> vec

# ## Run for all model/prompt combinations
# if you want to run multiple, add one more loop with: fn_definitions = find_definitions("code_generation")
# fn_definition = joinpath("code_generation", "utility_functions", "extract_julia_code", "definition.toml")
# fn_definition = joinpath("code_generation", "data_analysis", "weather_data_analyzer", "definition.toml")

fn_definitions = find_definitions("code_generation")
@time for fn_definition in fn_definitions
    definition = load_definition(fn_definition)["code_generation"]
    save_dir = joinpath("experiment", "hyperparams-search-paid-apis", definition["name"])

    evals = let all_options = all_options
        evals = []
        for option in all_options
            # task = Threads.@spawn begin # disabled as it causes issue with stdout redirection
            try
                ## Setup
                (prompt_label, model, temperature, top_p) = option
                # Lookup schema, default to OpenAI
                schema = get(schema_lookup, model, PT.OpenAISchema())
                ## Pick response generator based on the prompt_label
                conversation = if prompt_label == "JuliaExpertAsk"
                    aigenerate(schema, :JuliaExpertAsk; ask=definition["prompt"], model, api_kwargs=(; top_p, temperature), return_all=true)
                elseif prompt_label == "JuliaExpertCoTTask"
                    aigenerate(schema, :JuliaExpertCoTTask; task=definition["prompt"], data=first(definition["examples"]), model, api_kwargs=(; top_p, temperature), return_all=true)
                elseif prompt_label == "JuliaRecapCoTTask"
                    aigenerate(schema, :JuliaRecapCoTTask; task=definition["prompt"], data=first(definition["examples"]), model, api_kwargs=(; top_p, temperature), return_all=true)
                elseif prompt_label == "JuliaRecapTask"
                    aigenerate(schema, :JuliaRecapTask; task=definition["prompt"], instructions="None.", model, api_kwargs=(; top_p, temperature), return_all=true)
                elseif prompt_label == "InJulia"
                    aigenerate(schema, "In Julia, $(definition["prompt"])"; model, api_kwargs=(; top_p, temperature), return_all=true)
                elseif prompt_label == "AsIs"
                    aigenerate(schema, definition["prompt"]; model, api_kwargs=(; top_p, temperature), return_all=true)
                else
                    @warn "Unknown prompt_label: $prompt_label. Add the options to the if-elseif-else block."
                    nothing
                end
                ## Evaluate 1SHOT, including saving the files (and randint to prevent overrides)
                experiment = "hyperparams__$(model)__grid_search2"
                eval_ = evaluate_1shot(; parameters=(; top_p, temperature), experiment, conversation, fn_definition, definition, model, prompt_label, device, schema, save_dir, prompt_strategy="1SHOT", verbose=false)
                push!(evals, eval_)
            catch e
                @error "Failed for $option with error: $e"
            end
        end
        evals
    end
end

# # Analysis

df = load_evals(joinpath("experiments", "hyperparams-search-paid-apis"); max_history=0)
# Unpack parameters column if present (and homogenous)
transform!(df, :parameters => AsTable)

# Overall summary by test case
@chain df begin
    @by [:model, :name] begin
        :score = mean(:score)
        :count_zeros = count(==(0), :score)
        :cnt = $nrow
    end
    @orderby -:cnt
end

# Summary by model
@by df :model :score = mean(:score) :cnt = $nrow

# Check model hyperparameters
@chain df begin
    @rsubset :model == "mistral-medium"
    @by [:temperature, :top_p] begin
        :score = mean(:score)
        :count_zeros = count(==(0), :score)
        :cnt = $nrow
    end
    @orderby -:score
end

# Display a heatmap
fig = let dfx = df, model = "mistral-medium"
    dfx = @chain dfx begin
        @rsubset :model == model
        @orderby :temperature :top_p
        unstack(:temperature, :top_p, :score; fill=0.0, combine=mean)
    end

    temp_labels = dfx.temperature .|> string
    top_p_labels = names(dfx, Not(:temperature))
    data = Matrix(dfx[:, names(dfx, Not(:temperature))])

    fig = Figure()
    ax = Axis(fig[1, 1], title="$(titlecase(model)) API Parameter Search",
        ylabel="Temperature", xlabel="Top-p",
        yticks=(1:length(temp_labels), temp_labels),
        xticks=(1:length(top_p_labels), top_p_labels),
    )
    hm = heatmap!(ax, data')
    Colorbar(fig[1, 2], hm)
    for i in 1:size(data, 1)
        for j in 1:size(data, 2)
            value = data[i, j]
            text!(ax, j, i; text=string(round(value, digits=2)), align=(:center, :center), color=:black)
        end
    end
    fig
end
save("assets/experiment-hyperparams-mistral-medium.png", fig)