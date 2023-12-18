# Julia LLM Leaderboard

Comparison of Julia language generation capabilities of various Large Language Models

> [!WARNING]  
> This is a work in progress (pre-0.1.0). Please check back later for more updates.

- [Julia LLM Leaderboard](#julia-llm-leaderboard)
  - [Introduction](#introduction)
  - [Test Cases](#test-cases)
  - [Automated Evaluation Methodology](#automated-evaluation-methodology)
  - [Results (Preview)](#results-preview)
    - [Paid APIs](#paid-apis)
    - [OSS Models](#oss-models)
    - [Overall Time to Run vs Score](#overall-time-to-run-vs-score)
    - [Prompting Templates](#prompting-templates)
  - [Running Evaluation / Adding More Results](#running-evaluation--adding-more-results)
  - [Debugging](#debugging)
  - [Contributing Your Test Case](#contributing-your-test-case)
    - [Anatomy of `definition.toml`](#anatomy-of-definitiontoml)
  - [Feedback and Improvements](#feedback-and-improvements)


## Introduction
Welcome to the Julia Code Generation Benchmark Repository! 

This project is designed for the Julia community to compare the code generation capabilities of various AI models. Unlike academic benchmarks, our focus is practicality and simplicity: "Generate code, run it, and see if it works(-ish)."

This repository aims to understand how different AI models and prompting strategies perform in generating syntactically correct Julia code to guide users in choosing the best model for their needs.

Itchy fingers? Jump to `examples/` or just run your own benchmark with `run_benchmark()` (eg, `examples/code_gen_benchmark.jl`).

## Test Cases
Test cases are defined in a `definition.toml` file, providing a standard structure for each test. If you want to contribute a test case, please follow the instructions in the [Contributing Your Test Case](#contributing-your-test-case) section.

## Automated Evaluation Methodology
Each model's and prompt's performance is evaluated based on several criteria:
1. **Parsing**: Does the generated code parse correctly in Julia?
2. **Execution**: Can the code execute without errors?
3. **Unit Tests**: Do the included unit tests pass?
4. **Example Runs**: Does the code run in a provided example scenario?

At the moment, all criteria are weighed equally and each test case can earn a maximum of 100 points. If a code passes all criteria, it gets 100/100 points. If it fails one criterion (eg, all unit tests), it gets 75/100 points. If it fails two criteria (eg, it runs but all examples and unit tests are broken), it gets 50 points, and so on.

## Results (Preview)
To provide a glimpse of the repository's functionality, we have included example results for the first 14 test cases. 

> [!WARNING]  
> These scores might change as we evolve the supporting functionality.

Remember that the benchmark is quite challenging for any model - a single extra space or parentheses and the score might become 0 (="unable to parse")!

### Paid APIs

Across the board, GPT-4 tends to be among the best-performing models. However, "mistral-small" (the recently released "Mixtral 8x7B" model) is quite impressive and it beats the default GPT-3.5 Turbo model in most cases.

| model              | AsIs | InJulia | JuliaExpertAsk | JuliaExpertCoTTask | JuliaRecapCoTTask | JuliaRecapTask | AverageScore |
|--------------------|------|---------|----------------|--------------------|-------------------|----------------|--------------|
| gpt-4-1106-preview | 20.6 |    85.0 |           76.5 |               74.7 |              80.1 |           79.6 |         69.4 |
| gpt-3.5-turbo-1106 | 23.6 |    75.3 |           77.4 |               80.2 |              32.9 |           72.0 |         60.2 |
|     mistral-medium | 18.9 |    63.0 |           73.3 |               66.6 |              62.9 |           67.9 |         58.8 |
|      mistral-small | 36.3 |    71.2 |           66.2 |               64.8 |              62.6 |           46.2 |         57.9 |
|       mistral-tiny |  1.8 |    55.0 |           43.2 |               41.1 |              57.0 |           46.1 |         40.7 |
|      gpt-3.5-turbo | 20.0 |    67.7 |           53.9 |               22.9 |              27.7 |           14.0 |         34.4 |

Same information, but as a bar chart:

![Model-Prompt-Scores-for-Paid-API](assets/model-prompt-comparison-paid.png)

In addition, we can consider the performance (score) versus the cost (measured in US cents):

![Cost-vs-Score](assets/paid-cost-vs-score-scatter.png)

### OSS Models

Open-source models are generally not as good as the paid APIs, but they are getting close! Note that the "mistral-small" is already available to be run locally and there will be many future finetunes!

The best-performing model is "orca2:13b", which is impressive given its size!

| model                  | AsIs | InJulia | JuliaExpertAsk | JuliaExpertCoTTask | JuliaRecapCoTTask | JuliaRecapTask | AverageScore |
|------------------------|------|---------|----------------|--------------------|-------------------|----------------|--------------|
|              orca2:13b | 12.5 |    25.7 |           40.0 |               36.1 |              31.1 |           26.1 |         28.6 |
| phind-codellama:34b-v2 | 12.5 |    34.6 |           35.4 |               33.9 |              23.6 |           30.2 |         28.4 |
|            yi:34b-chat | 14.3 |    27.5 |           32.0 |               27.4 |              31.4 |           34.5 |         27.9 |
|   codellama:13b-python | 10.7 |    23.2 |           23.9 |               42.7 |              37.3 |           28.0 |         27.7 |
|              magicoder | 16.1 |    32.9 |           40.1 |               17.3 |              30.7 |           27.9 |         27.5 |
|     starling-lm:latest | 14.3 |    28.2 |           42.9 |               20.4 |              20.2 |           36.4 |         27.1 |
| codellama:13b-instruct |  7.1 |    26.3 |           40.4 |               28.9 |              36.1 |           17.9 |         26.1 |
|  openhermes2.5-mistral | 10.7 |    27.9 |           36.4 |               29.8 |              22.1 |           27.1 |         25.7 |
|        stablelm-zephyr |  7.1 |    20.0 |           34.1 |               32.9 |              23.2 |           36.8 |         25.7 |
|                 llama2 |  8.9 |    23.9 |           32.9 |               37.2 |              25.0 |           16.1 |         24.0 |


Same information, but as a bar chart:

![Model-Prompt-Scores-for-Paid-API](assets/model-prompt-comparison-oss.png)

### Overall Time to Run vs Score

Clearly, the paid APIs win (the latest release: GPT-3.5-Turbo-1106), but that's not the whole story.

![Elapsed-vs-Score](assets/all-elapsed-vs-score-scatter.png)

### Prompting Templates

We hope to be able to provide some guidance around prompting strategies, eg, when is it better to use a "JuliaExpert*" prompt template vs an "In Julia, answer XYZ" prompt.

Learnings so far: 

- Never use the "AsIs" prompt (ie, raw task definition). ALWAYS add some context around the language, situation, etc.
- Even a simple "In Julia, answer XYZ" prompt can be quite effective. Note that the bigger prompts ("CoT" stands for Chain of Thought) might be confusing the smaller models, hence why this prompt is so effective on average.

| Prompt Template    | Elapsed (s, median) | Avg. Score (Max 100 pts) |
|--------------------|---------------------|--------------------------|
|     JuliaExpertAsk |                 6.9 |                     53.6 |
|            InJulia |                11.3 |                     50.6 |
| JuliaExpertCoTTask |                13.9 |                     46.4 |
|     JuliaRecapTask |                19.3 |                     43.9 |
|  JuliaRecapCoTTask |                16.0 |                     42.1 |
|               AsIs |                10.4 |                     16.2 |


Make your own analysis with `examples/summarize_results.jl`!

## Running Evaluation / Adding More Results
1. **Existing Evaluations**: Check `scripts/code_gen_benchmark.jl` for the example of previous evaluations.
2. **Run Your Evaluation**: Choose your model and prompt, and run the test.
3. **Save Results**: Store both the conversation and the evaluation.
4. **Open a PR**: Include the part of the code snippet you changed in the PR comments. We generally require 1-2 independent verifications of your result.

Want to run some experiments and save the results? Check out `examples/experiment_hyperparameter_scan.jl`!

## Debugging

Want to review some of the past benchmark runs? Check out `examples/summarize_results.jl` for overall statistics and `examples/debugging_results.jl` for reviewing the individual conversations/model responses.

## Contributing Your Test Case
To contribute a test case:

1. **Naming Convention**: Create nested folders following the format `code_generation/category/test_case_name/definition.toml`.
2. **Saving Results**: Store the full conversation and the evaluation results in a path nested by a model name like `code_generation/category/test case/model/evaluation__PROMPT__STRATEGY__TIMESTAMP.json` and `code_generation/category/test case/model/conversation__PROMPT__STRATEGY__TIMESTAMP.json`

### Anatomy of `definition.toml`
Required fields in `definition.toml` include:
- **name**: Corresponding to the file path.
- **contributor**: The creator of the test case (and their collaborators).
- **criteria**: The evaluation criteria (eg, parsing, execution, unit_tests, examples).
- **prompt**: The problem statement or task.
- **version**: The version of the test case. Starts at "1.0".
- **examples**: Example scenarios for testing, provided as a vector of executable statements using the function name (eg, `my_function(1, 2)`).
- **unit_tests**: Tests to validate the code, provided as a vector of `@test X = Z` statements.
- **imports**: Packages that are made available to the model (to avoid failures due to a failed dependency).
- **reference_solution**: A reference solution to the problem, provided as a string of Julia code (no code fences).

See an example in `examples/create_definition.jl`. 
You can validate your test case definitions with `validate_definition()`.

## Feedback and Improvements
We highly value community input. If you have suggestions or ideas for improvement, please open an issue. All contributions are welcome!