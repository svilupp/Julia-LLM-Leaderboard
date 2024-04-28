
# # Run the Benchmark
#
# It will evaluate arbitrary number of models and prompts, and save the results in sub-folders of where the definition file was stored.
# It saves: `evaluation__PROMPTABC__1SHOT__TIMESTAMP.json` and `conversation__PROMPTABC__1SHOT__TIMESTAMP.json`

# ## Imports
using Pkg;
Pkg.activate(Base.current_project());
using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools
## Pkg.add("https://github.com/tylerjthomas9/GoogleGenAI.jl.git");
## using GoogleGenAI # needed if you want to run Gemini!

# ## Run for a single test case
device = "Apple-MacBook-Pro-M1" # "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model"

# How many samples to generate for each model/prompt combination
num_samples = 5

# Select models to run
#
# Paid Models:
model_options = [
    "gpt-3.5-turbo",
    "gpt-3.5-turbo-1106",
    "gpt-3.5-turbo-0125",
    "gpt-4-1106-preview",
    "gpt-4-0125-preview",
    "mistral-tiny",
    "mistral-small-2402",
    "mistral-medium-2312",
    "mistral-large-2402",
    "claude-3-opus-20240229"
    "claude-3-sonnet-20240229",
    "claude-3-haiku-20240307",
    "claude-2.1"
]
## "gemini-1.0-pro-latest"

# Or OSS models:
model_options = ["llama2", "openhermes2.5-mistral", "starling-lm:latest", "yi:34b-chat",
    "codellama:13b-instruct", "magicoder", "stablelm-zephyr",
    "orca2:13b", "phind-codellama:34b-v2",
    "deepseek-coder:33b-instruct-q4_K_M", "solar:10.7b-instruct-v1-q4_K_M",
    "mistral:7b-instruct-q4_K_M", "openchat:7b-v3.5-1210-q4_K_M", "phi:2.7b-chat-v2-q6_K",
    "mistral:7b-instruct-v0.2-q6_K", "dolphin-phi:2.7b-v2.6-q6_K",
    "nous-hermes2:34b-yi-q4_K_M", "mistral:7b-instruct-v0.2-q4_0",
    "mistral:7b-instruct-v0.2-q4_K_M", "gemma:7b-instruct-q6_K"]

# Select prompt templates to run (for reference check: `aitemplates("Julia")`)
prompt_options = [
    "JuliaExpertCoTTask",
    "JuliaExpertAsk",
    "InJulia",
    ## "AsIs", # no need to prove that it's worse
    "JuliaRecapTask",
    "JuliaRecapCoTTask"
]

# Define the schema for unknown models, eg, needed if you use non-OpenAI models, provide a key for each model you use
schema_lookup = Dict{String, Any}(model_options .=> Ref(PT.OllamaSchema()))
## schema_lookup = merge(schema_lookup, Dict("gemini-1.0-pro-latest" => PT.GoogleSchema()))
## schema_lookup = merge(schema_lookup,
##     Dict(["claude-3-opus-20240229",
##         "claude-3-sonnet-20240229",
##         "claude-3-haiku-20240307",
##         "claude-2.1"] .=> Ref(PT.AnthropicSchema())))

# ## Run Benchmark - High-level Interface
fn_definitions = find_definitions("code_generation_waitlist/")

# or if you want only one test case:
# fn_definitions = [joinpath("code_generation", "utility_functions", "event_scheduler", "definition.toml")]
evals = run_benchmark(; fn_definitions = fn_definitions, models = model_options,
    prompt_labels = prompt_options,
    experiment = "", auto_save = true, verbose = true, device,
    num_samples = num_samples, schema_lookup, http_kwargs = (; readtimeout = 250));
# Note: On Mac M1 with Ollama, you want to set api_kwargs=(; options=(; num_gpu=99)) for Ollama to have normal performance

# ## Fill missing combinations
# Sometimes APIs fail, this way to can re-run the missing samples

using DataFramesMeta
using Statistics
df_all = allcombinations(DataFrame,
    "model" => model_options,
    "prompt_label" => prompt_options,
    "fn_definitions" => fn_definitions)
@rtransform!(df_all, :name=split(:fn_definitions, "/")[end - 1])

## Load data
df = load_evals("code_generation"; max_history = 0)

# Overall summary by test case
df_missing = @chain df begin
    @rsubset :model in model_options
    @by [:model, :prompt_label, :name] begin
        :score = mean(:score)
        :count_zeros = count(==(0), :score)
        :count = $nrow
    end
    leftjoin(df_all, _, on = [:model, :prompt_label, :name], validate = (true, true))
    @rtransform :count_missing = num_samples - coalesce(:count, 0)
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
        experiment = "",
        auto_save = true, verbose = true,
        device,
        ## save_dir = "yi-quantization-effects",
        num_samples = row.count_missing, schema_lookup,
        http_kwargs = (; readtimeout = 200))
end