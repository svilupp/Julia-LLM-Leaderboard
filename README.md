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
  - [Contributing Your Test Case](#contributing-your-test-case)
    - [Anatomy of `definition.toml`](#anatomy-of-definitiontoml)
  - [Running Evaluation / Adding More Results](#running-evaluation--adding-more-results)
  - [Feedback and Improvements](#feedback-and-improvements)


## Introduction
Welcome to the Julia Code Generation Benchmark Repository! 

This project is designed for the Julia community to compare the code generation capabilities of various AI models. Unlike academic benchmarks, our focus is practicality and simplicity: "Generate code, run it, and see if it works(-ish)."

This repository aims to understand how different AI models and prompting strategies perform in generating syntactically correct Julia code to guide users in choosing the best model for their needs.

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
| gpt-4-1106-preview | 22.4 |    83.2 |           76.5 |               74.7 |              75.1 |           65.7 |         66.3 |
| gpt-3.5-turbo-1106 | 25.4 |    72.9 |           77.4 |               80.2 |              27.5 |           66.4 |         58.3 |
|      mistral-small | 33.0 |    65.1 |           66.2 |               57.3 |              45.4 |           31.1 |         49.7 |
|     mistral-medium | 22.5 |    53.0 |           73.3 |               47.0 |              44.5 |           42.1 |         47.1 |
|       mistral-tiny | 10.7 |    43.9 |           41.4 |               22.3 |              35.7 |           37.7 |         32.0 |
|      gpt-3.5-turbo | 16.1 |    54.6 |           49.6 |               16.2 |              20.2 |           10.4 |         27.9 |


Same information, but as a bar chart:

![Model-Prompt-Scores-for-Paid-API](assets/model-prompt-comparison-paid.png)

In addition, we can consider the performance (score) versus the cost (measured in US cents):

![Cost-vs-Score](assets/paid-cost-vs-score-scatter.png)

### OSS Models

Open-source models are generally not as good as the paid APIs, but they are getting close! Note that the "mistral-small" is already available to be run locally and there will be many future fine-tunes!

The best-performing model is "yi:34b-chat", followed closely by the recently released "orca2:13b" model.

| model                  | AsIs | InJulia | JuliaExpertAsk | JuliaExpertCoTTask | JuliaRecapCoTTask | JuliaRecapTask | AverageScore |
|------------------------|------|---------|----------------|--------------------|-------------------|----------------|--------------|
|            yi:34b-chat | 17.9 |    25.0 |           24.3 |               16.4 |              27.5 |           23.9 |         22.5 |
|              orca2:13b | 12.5 |    23.9 |           36.4 |               20.0 |              27.5 |           10.7 |         21.8 |
| phind-codellama:34b-v2 | 12.5 |    25.0 |           29.3 |               28.2 |              20.0 |           15.2 |         21.7 |
|     starling-lm:latest | 16.1 |    22.9 |           35.4 |                7.1 |              18.4 |           23.2 |         20.5 |
|              magicoder | 17.9 |    31.1 |           34.4 |                5.4 |              16.1 |           16.4 |         20.2 |
|  openhermes2.5-mistral | 12.5 |    25.0 |           31.1 |                8.9 |              16.8 |           19.6 |         19.0 |
| codellama:13b-instruct |  8.9 |    21.0 |           35.0 |               12.5 |              23.2 |           12.5 |         18.8 |
|   codellama:13b-python | 14.3 |    19.6 |           12.9 |               20.2 |              20.9 |           20.5 |         18.1 |
|                 llama2 | 10.7 |    22.1 |           27.5 |               14.3 |              16.1 |           14.3 |         17.5 |
|        stablelm-zephyr |  8.9 |    16.1 |           24.5 |               17.9 |              10.7 |           26.8 |         17.5 |



Same information, but as a bar chart:

![Model-Prompt-Scores-for-Paid-API](assets/model-prompt-comparison-oss.png)

### Overall Time to Run vs Score

Clearly, the paid APIs win (the latest GPT-3.5-Turbo release), but that's not the whole story.

![Elapsed-vs-Score](assets/all-elapsed-vs-score-scatter.png)

TODO: Improve color scheme

### Prompting Templates

We hope to be able to provide some guidance around prompting strategies, eg, when is it better to use a "JuliaExpert*" prompt template vs an "In Julia, answer XYZ" prompt.

Learnings so far: 

- Never use the "AsIs" prompt (ie, raw task definition). ALWAYS add some context around the language, situation, etc.
- Even a simple "In Julia, answer XYZ" prompt can be quite effective. Note that the bigger prompts might be confusing the smaller models, hence why this prompt is so effective on average.

| Prompt Template    | Elapsed (s) | Avg. Score (Max 100 pts) |
|--------------------|-------------|--------------------------|
|     JuliaExpertAsk |         9.4 |                     42.2 |
|            InJulia |        14.7 |                     37.8 |
| JuliaExpertCoTTask |        16.4 |                     28.0 |
|  JuliaRecapCoTTask |        18.0 |                     27.8 |
|     JuliaRecapTask |        20.9 |                     27.3 |
|               AsIs |        14.1 |                     16.4 |


Make your own analysis with `examples/summarize_results.jl`!

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
- **packages**: Packages that are made available to the model (to avoid failures due to a failed dependency).
- **reference_solution**: A reference solution to the problem, provided as a string of Julia code (no code fences).

See an example in `examples/create_definition.jl`.

## Running Evaluation / Adding More Results
1. **Existing Evaluations**: Check `scripts/code_gen_benchmark.jl` for the example of previous evaluations.
2. **Run Your Evaluation**: Choose your model and prompt, and run the test.
3. **Save Results**: Store both the conversation and the evaluation.
4. **Open a PR**: Include the part of the code snippet you changed in the PR comments. We generally require 1-2 independent verifications of your result.

## Feedback and Improvements
We highly value community input. If you have suggestions or ideas for improvement, please open an issue. All contributions are welcome!