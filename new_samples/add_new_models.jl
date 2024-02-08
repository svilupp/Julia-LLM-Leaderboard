
# # Add fresh model samples / re-run the old samples
#
# It will evaluate arbitrary number of models and prompts, and save the results in sub-folders of where the definition file was stored.
# It saves: `evaluation__PROMPTABC__1SHOT__TIMESTAMP.json` and `conversation__PROMPTABC__1SHOT__TIMESTAMP.json`

# TODOs:
# fix _ in the model names
# dedupe magicoder
# dedupe codellama
# add a note about Q4 vs no tag

# ## Imports
using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools

# ## Run for a single test case
device = "NVIDIA-RTX-4090-4x" # "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model"

# Select models to run
model_options = [
# "qwen:72b-chat-fp16",
# "qwen:72b-chat-v1.5-q4_K_M",
# "qwen:72b-chat-v1.5-q2_K",
# "qwen:14b-chat-v1.5-q6_K",
# "qwen:14b-chat-v1.5-q4_K_M",
# "qwen:7b-chat-v1.5-q6_K",
# "qwen:7b-chat-v1.5-q4_K_M",
# "qwen:4b-chat-v1.5-q6_K",
# "qwen:1.8b-chat-v1.5-q6_K",
# "qwen:0.5b-chat-v1.5-q6_K"
]
model_options = [
    # "megadolphin:120b-v2.2-q4_K_M",
    # "deepseek-coder:33b-instruct-q4_K_M",
    # "codellama:34b-code-q4_K_M",
    # "phind-codellama:34b-v2-q4_K_M",
    # "phind-codellama:34b-v2",
    # "nous-hermes2:34b-yi-q4_K_M",
    "dolphin-mixtral:8x7b-v2.7-q4_K_M",
    "nous-hermes2-mixtral:8x7b-dpo-q4_K_M",
    "codellama:13b-instruct",
    "openchat:7b-v3.5-0106-q4_K_M",
    "openchat:7b-v3.5-0106-q6_K",
    "magicoder",
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
schema_lookup = Dict{String, Any}(model_options .=> Ref(PT.OllamaSchema()))

# ## Run Benchmark - High-level Interface
fn_definitions = find_definitions("code_generation/")

# or if you want only one test case:
# fn_definitions = [joinpath("code_generation", "utility_functions", "event_scheduler", "definition.toml")]
for m in model_options
    @info "RUNNING: $m"
    evals = run_benchmark(; fn_definitions, models = [m],
        prompt_labels = prompt_options,
        experiment = "",
        save_dir = "new_samples",
        auto_save = true, verbose = true, device,
        num_samples = 10, schema_lookup,
        api_kwargs = (; options = (; num_gpu = 99)),
        http_kwargs = (; readtimeout = 200))
end
# Note: On Mac M1 with Ollama, you want to set api_kwargs=(; options=(; num_gpu=99)) for Ollama to have normal performance

# Voila! You can now find the results in the `temp/` folder or in the vector `evals`!

@assert false "stop here!"
# ## Find missing samples
using DataFramesMeta
using Statistics
df_all = allcombinations(DataFrame,
    "model" => model_options,
    "prompt_label" => prompt_options,
    "fn_definitions" => fn_definitions)
@rtransform!(df_all, :name=split(:fn_definitions, "/")[end - 1])

## Load data
df = load_evals("new_samples"; max_history = 0)
@by df :model :cnt=$nrow

# Overall summary by test case
df_missing = @chain df begin
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
        experiment = "qwen-quantization-effects",
        save_dir = "qwen-quantization-effects",
        auto_save = true, verbose = true,
        device,
        num_samples = row.count_missing, schema_lookup,
        http_kwargs = (; readtimeout = 600),
        api_kwargs = (; options = (; num_gpu = 99)))
end

# # Cross compare
df = load_evals("qwen-quantization-effects"; max_history = 0)
@chain df begin
    @rsubset :model=="qwen:72b-chat-v1.5-q4_K_M" :name=="add_yearmonth"
    @by :model :score=mean(:score)
end
dfx = load_evals("code_generation"; max_history = 0)
@chain dfx begin
    @rsubset :model=="qwen:72b-chat-v1.5-q4_K_M" :name=="add_yearmonth"
    @by :model :score=mean(:score)
end