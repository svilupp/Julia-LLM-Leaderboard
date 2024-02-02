# # Yi model quantization benchmark in Chinese
#
# Evaluate effect of different quantizations on Yi models

# ## Imports
using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools

## Add JuliaExpertAsk in Chinese to PT
template, metadata_msgs = PT.load_template(joinpath(@__DIR__, "JuliaExpertAskZH.json"))
PT.TEMPLATE_STORE[:JuliaExpertAskZH] = template

# ## Run for a single test case
device = "NVIDIA-RTX-4090-4x" # "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model"
# export CUDA_VISIBLE_DEVICES=0

# Select models to run
model_options = [
    # "yi:34b-chat-fp16",
    # "yi:34b-chat-q8_0",
    # "yi:34b-chat-q6_K",
    # "yi:34b-chat-q5_K_M",
    # "yi:34b-chat-q5_K_S",
    "yi:34b-chat-q5_0",
    "yi:34b-chat-q4_K_M",
    "yi:34b-chat-q4_0",
    "yi:34b-chat-q3_K_L",
    "yi:34b-chat-q3_K_S",
    "yi:34b-chat-q2_K",
]

# Select prompt templates to run (for reference check: `aitemplates("Julia")`)
prompt_options = [
    "JuliaExpertAskZH",
]

# Define the schema for unknown models, eg, needed if you use non-OpenAI models, provide a key for each model you use
schema_lookup = Dict{String, Any}(model_options .=> Ref(PT.OllamaSchema()))

# ## Run Benchmark - High-level Interface
fn_definitions = find_definitions("yi-quantization-effects-zh")

# or if you want only one test case:
# fn_definitions = [
# joinpath("code_generation", "utility_functions", "clean_column", "definition.toml"),
# ]
evals = run_benchmark(; fn_definitions,
    models = model_options,
    prompt_labels = prompt_options,
    experiment = "yi-quantization-effects-zh-default",
    auto_save = true, verbose = true,
    device,
    save_dir = "yi-quantization-effects-zh",
    num_samples = 10, schema_lookup, http_kwargs = (; readtimeout = 200),
    api_kwargs = (; options = (; num_gpu = 99)));

@assert false "Stop here"

# # Fill missing
using DataFramesMeta
using Statistics
df_all = allcombinations(DataFrame,
    "model" => model_options,
    "prompt_label" => prompt_options,
    "fn_definitions" => fn_definitions)
@rtransform!(df_all, :name=split(:fn_definitions, "/")[end - 1])

## Load data
df = load_evals("yi-quantization-effects-zh"; max_history = 0)

# Overall summary by test case
df_missing = @chain df begin
    @rsubset :experiment == "yi-quantization-effects-zh-default"
    # @rsubset :model=="yi:34b-chat-q3_K_L" :prompt_label=="JuliaExpertCoTTask"
    @by [:model, :prompt_label, :name] begin
        :score = mean(:score)
        :count_zeros = count(==(0), :score)
        :count = $nrow
    end
    leftjoin(df_all, _, on = [:model, :prompt_label, :name], validate = (true, true))
    @rtransform :count_missing = 10 - coalesce(:count, 0)
    @rsubset :count_missing > 0
    @orderby -:count_missing
end
@by df_missing :name :count_missing=sum(:count_missing)

## fill missing benchmarks
for row in eachrow(df_missing)
    @info "Running $(row.model) / $(row.prompt_label) / $(row.name) for $(row.count_missing) samples"
    evals = run_benchmark(; fn_definitions = [row.fn_definitions],
        models = [row.model],
        prompt_labels = [row.prompt_label],
        experiment = "yi-quantization-effects-zh-default",
        auto_save = true, verbose = true,
        device,
        save_dir = "yi-quantization-effects-zh",
        num_samples = row.count_missing, schema_lookup,
        http_kwargs = (; readtimeout = 60),
        api_kwargs = (; options = (; num_gpu = 99)))
end
# # Analysis

@chain df begin
    # @rsubset :model=="yi:34b-chat-q3_K_L" :prompt_label=="JuliaExpertCoTTask"
    # @rsubset :experiment == "yi-quantization-effects-default"
    @by [:model] begin
        :score = mean(:score)
        :count_zero = count(==(0), :score)
        :count_full = count(==(100), :score)
        :count = $nrow
    end
    @orderby -:score
end
output = @chain df begin
    # @rsubset :experiment == "yi-quantization-effects-default"
    @by [:model, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :model :AverageScore=mean(:score) |> x -> round(x, digits = 1)
    unstack(:model, :prompt_label, :score; fill = 0.0)
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :model)
    @orderby -:AverageScore
end
output = @chain df begin
    # @rsubset :experiment == "yi-quantization-effects-default"
    @by [:name, :model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :name :AverageScore=mean(:score) |> x -> round(x, digits = 1)
    unstack(:name, :model, :score; fill = 0.0)
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :name)
    @orderby -:AverageScore
end