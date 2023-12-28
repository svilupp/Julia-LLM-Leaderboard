# Julia LLM Leaderboard

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://svilupp.github.io/Julia-LLM-Leaderboard/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://svilupp.github.io/Julia-LLM-Leaderboard/dev/)
[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)

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
| gpt-4-1106-preview | 25.4 |    81.6 |           79.3 |               75.5 |              76.5 |           79.7 |         69.6 |
|     mistral-medium | 21.4 |    66.1 |           72.7 |               70.9 |              59.5 |           69.0 |         59.9 |
|      mistral-small | 25.7 |    68.2 |           66.2 |               58.0 |              57.5 |           54.2 |         55.0 |
| gpt-3.5-turbo-1106 | 24.7 |    76.7 |           69.6 |               76.3 |              18.7 |           58.3 |         54.0 |
|       mistral-tiny |  3.6 |    56.7 |           43.5 |               37.0 |              50.1 |           47.8 |         39.8 |
|      gpt-3.5-turbo | 24.4 |    72.0 |           59.9 |               29.9 |              22.6 |           13.1 |         37.0 |

Same information, but as a bar chart:

![Model-Prompt-Scores-for-Paid-API](assets/model-prompt-comparison-paid.png)

In addition, we can consider the performance (score) versus the cost (measured in US cents):

![Cost-vs-Score](assets/paid-cost-vs-score-scatter.png)

### OSS Models

Open-source models are generally not as good as the paid APIs, but they are getting close! Note that the "mistral-small" is already available to be run locally and there will be many future finetunes!

The best-performing models are around 33/34Bn parameters - Phind CodeLlama and Deepseek Coder. Magicoder and OpenChat-1210 from the 7Bn parameter class are also quite good.

| model                              | AsIs | InJulia | JuliaExpertAsk | JuliaExpertCoTTask | JuliaRecapCoTTask | JuliaRecapTask | AverageScore |
|------------------------------------|------|---------|----------------|--------------------|-------------------|----------------|--------------|
|             phind-codellama:34b-v2 | 18.1 |    60.5 |           65.6 |               55.1 |              53.7 |           55.4 |         51.4 |
| deepseek-coder:33b-instruct-q4_K_M | 25.4 |    59.4 |           41.4 |               49.8 |              62.1 |           61.0 |         49.8 |
|                          magicoder | 10.1 |    56.5 |           46.2 |               43.4 |              55.3 |           48.1 |         43.3 |
|       openchat:7b-v3.5-1210-q4_K_M |  5.0 |    56.4 |           46.0 |               46.9 |              49.0 |           51.4 |         42.4 |
|             codellama:13b-instruct | 13.4 |    49.1 |           45.3 |               44.8 |              44.9 |           47.6 |         40.9 |
|                 starling-lm:latest | 11.0 |    49.6 |           54.2 |               37.9 |              41.8 |           51.0 |         40.9 |
|                        yi:34b-chat | 13.8 |    46.4 |           50.3 |               42.0 |              42.7 |           49.0 |         40.7 |
|              openhermes2.5-mistral |  7.4 |    44.9 |           50.1 |               49.9 |              42.8 |           48.0 |         40.5 |
|      mistral:7b-instruct-v0.2-q6_K |  4.5 |    43.3 |           38.1 |               53.4 |              46.4 |           53.1 |         39.8 |
|     solar:10.7b-instruct-v1-q4_K_M |  7.2 |    42.8 |           37.9 |               20.0 |              30.4 |           35.6 |         29.0 |
|         mistral:7b-instruct-q4_K_M |  6.7 |    34.7 |           34.0 |               26.6 |              35.2 |           34.3 |         28.6 |
|                             llama2 | 11.9 |    24.0 |           32.5 |               33.2 |              28.6 |           24.5 |         25.8 |
|                          orca2:13b |  4.2 |    26.0 |           19.2 |               29.8 |              24.1 |           24.2 |         21.2 |
|                    stablelm-zephyr |  3.0 |    22.7 |           18.7 |               21.8 |              19.5 |           26.1 |         18.6 |
|               codellama:13b-python | 10.0 |    11.9 |           15.1 |               14.0 |              11.5 |           14.7 |         12.9 |
|              phi:2.7b-chat-v2-q6_K |  3.6 |     7.1 |            8.1 |                7.1 |               8.7 |            9.4 |          7.4 |



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

There are several optional fields:
- **examples_setup**: Code to run before each example eval, provided as a string of Julia code (no code fences). Used to setup any variables or functions needed for the examples.
- **examples_teardown**: Code to run after each example eval, provided as a string of Julia code (no code fences). Used to clean up any variables or functions needed for the examples.
- **unit_tests_setup**: Code to run before each unit test eval, provided as a string of Julia code (no code fences). Used to setup any variables or functions needed for the unit tests.
- **unit_tests_teardown**: Code to run after each unit test eval, provided as a string of Julia code (no code fences). Used to clean up any variables or functions needed for the unit tests.

The above fields can improve re-use of code across the examples/unit tests.

See an example in `examples/create_definition.jl`. 
You can validate your test case definitions with `validate_definition()`.

## Feedback and Improvements
We highly value community input. If you have suggestions or ideas for improvement, please open an issue. All contributions are welcome!