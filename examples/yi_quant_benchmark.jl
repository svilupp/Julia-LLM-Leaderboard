# # Yi model quantization benchmark
#
# Evaluate effect of different quantizations on Yi models

# ## Imports
using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools

# ## Run for a single test case
device = "NVIDIA-RTX-4090-4x" # "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model"

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
model_options = [
    "yi:34b-chat-fp16",
    "yi:34b-chat-q8_0",
    "yi:34b-chat-q6_K",
    "yi:34b-chat-q5_K_M",
    "yi:34b-chat-q5_K_S",
    "yi:34b-chat-q5_0",
    # "yi:34b-chat-q4_K_M",
    # "yi:34b-chat-q4_0",
    # "yi:34b-chat-q3_K_L",
    # "yi:34b-chat-q3_K_S",
    # "yi:34b-chat-q2_K",
]

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
schema_lookup = Dict{String, Any}([
    "mistral:7b-instruct-v0.2-q4_K_M",
    "yi:34b-chat-fp16",
    "yi:34b-chat-q2_K",
    "yi:34b-chat-q3_K_L",
    "yi:34b-chat-q3_K_S",
    "yi:34b-chat-q4_0",
    "yi:34b-chat-q4_K_M",
    "yi:34b-chat-q5_0",
    "yi:34b-chat-q5_K_M",
    "yi:34b-chat-q5_K_S",
    "yi:34b-chat-q6_K",
    "yi:34b-chat-q8_0",
] .=> Ref(PT.OllamaSchema()))

# ## Run Benchmark - High-level Interface
fn_definitions = find_definitions("code_generation")

# or if you want only one test case:
# fn_definitions = [
#     joinpath("code_generation", "utility_functions", "clean_column", "definition.toml"),
# ]
# num_gpu = floor(Int, 21 / 65 * 60)

evals = run_benchmark(; fn_definitions,
    models = model_options,
    prompt_labels = prompt_options,
    experiment = "yi-quantization-effects-default",
    auto_save = true, verbose = true,
    device,
    save_dir = "yi-quantization-effects",
    num_samples = 5, schema_lookup, http_kwargs = (; readtimeout = 1000),
    api_kwargs = (; options = (; num_gpu = 99)));

# ## Quick Eval
using DataFramesMeta
using Statistics
df_all = allcombinations(DataFrame,
    "model" => model_options,
    "prompt_label" => prompt_options,
    "fn_definitions" => fn_definitions)
@rtransform!(df_all, :name=split(:fn_definitions, "/")[end - 1])

## Load data
df = load_evals("yi-quantization-effects"; max_history = 0)

# Overall summary by test case
@chain df begin
    # @rsubset :model=="yi:34b-chat-q3_K_L" :prompt_label=="JuliaExpertCoTTask"
    @by [:name] begin #:prompt_label, :name] begin
        :score = mean(:score)
        :count_zeros = count(==(0), :score)
        :count = $nrow
    end
    # leftjoin(df_all, _, on = [:model, :prompt_label, :name], validate = (true, true))
    # @rtransform :count = coalesce(:count, 0)
    # @rsubset :count < 10
    @orderby :count
end