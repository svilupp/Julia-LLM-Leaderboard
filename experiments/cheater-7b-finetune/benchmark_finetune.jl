
# # Run the Benchmark for Cheater 7b
#
# It will evaluate arbitrary number of models and prompts, and save the results in sub-folders of where the definition file was stored.
# It saves: `evaluation__PROMPTABC__1SHOT__TIMESTAMP.json` and `conversation__PROMPTABC__1SHOT__TIMESTAMP.json`

# ## Imports
using Pkg;
Pkg.activate(Base.current_project());
using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools

# ## Run for a single test case
device = "Nvidia-A6000" # "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model"

# How many samples to generate for each model/prompt combination
num_samples = 5

# Set up for vLLM
PT.OPENAI_API_KEY="xx"
provider_url = "http://0.0.0.0:8000/v1" # vLLM server
api_kwargs=(; stop=["<|im_end|>","</s>"], url=provider_url)

# Set up for Llama.cpp
provider_url = "http://localhost:10897/v1" # or set via PT.LOCAL_SERVER
api_kwargs=(; stop=["<|im_end|>","</s>"], url=provider_url)


# Select models to run
#
model_options = [
    # "cheater-7b",
    # "cognitivecomputations/dolphin-2.6-mistral-7b-dpo-laser",
    "cheater-7b.Q5_K_M"
]

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
schema_lookup = Dict{String, Any}(model_options .=> Ref(PT.CustomOpenAISchema()))
## schema_lookup = merge(schema_lookup, Dict("gemini-1.0-pro-latest" => PT.GoogleSchema()))

# ## Run Benchmark - High-level Interface
fn_definitions = find_definitions("code_generation/")

# or if you want only one test case:
# fn_definitions = [joinpath("code_generation", "utility_functions", "event_scheduler", "definition.toml")]
evals = run_benchmark(; fn_definitions, models = model_options,
    prompt_labels = prompt_options,
    save_dir="cheater-7b",
    experiment = "experiments/cheater-7b", auto_save = true, verbose = true, device,
    num_samples = num_samples, schema_lookup, api_kwargs, http_kwargs = (; readtimeout = 150));
# Note: On Mac M1 with Ollama, you want to set api_kwargs=(; options=(; num_gpu=99)) for Ollama to have normal performance