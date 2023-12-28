# Getting Started

A few different options to get you started:

## Run the Benchmark

See `examples/code_gen_benchmark.jl` for an example of how to run the benchmark.

You can start by launching the benchmark with the default settings:

```julia
using JuliaLLMLeaderboard

# set your device for reference
device = "Apple-MacBook-Pro-M1" # "Apple-MacBook-Pro-M1" or "NVIDIA-GTX-1080Ti", broadly "manufacturer-model"

# which models
model_options = [
    "gpt-3.5-turbo",
    "gpt-3.5-turbo-1106",
    "gpt-4-1106-preview",
    "mistral-tiny",
    "mistral-small",
    "mistral-medium",
]


# which prompts
prompt_options = [
    "JuliaExpertCoTTask",
    "JuliaExpertAsk",
    "InJulia",
    "JuliaRecapTask",
    "JuliaRecapCoTTask",
]

# Which test cases
fn_definitions = find_definitions("code_generation/")

# What experiment are you running (for future reference)
experiment = "my-first-benchmark"

# Run the benchmark -- set `auto_save = false` to disable saving results into files
evals = run_benchmark(; fn_definitions, models = model_options,
    prompt_labels = prompt_options,
    experiment, auto_save = true, verbose = true, device,
    num_samples = 1, http_kwargs = (; readtimeout = 150));

# You can then easily score each of these evaluation runs
scores = score_evals.(evals)
```

## Create Your Analysis

To inspect individual model answers and their associated scores, see `examples/inspect_results.jl` or `examples/debugging_results.jl`.

To compare different models, see `examples/summarize_results_paid.jl`

## Run an Experiment

Want to run some experiments and save the results? Check out `examples/experiment_hyperparameter_scan.jl` for finding the optimal `temperature` and `top_p` !

## Contributing Results

1. **Run Your Evaluation**: Choose your model and prompt, and run the test.
2. **Save Results**: Store both the conversation and the evaluation.
3. **Open a PR**: Include the part of the code snippet you changed in the PR comments. We generally require 1-2 independent verifications of your result or at least 3 samples for each combination (for validity).


