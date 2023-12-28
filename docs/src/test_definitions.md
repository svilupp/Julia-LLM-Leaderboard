```@meta
CurrentModule = JuliaLLMLeaderboard
```

# Develop Your Test Case

All test cases are defined in `definition.toml` files with the structure described below.

## Folder Structure / Convention

1. **Naming Convention**: Create nested folders following the format `code_generation/category/test_case_name/definition.toml`.
2. **Saving Results**: Store the full conversation and the evaluation results in a path nested by a model name like `code_generation/category/test case/model/evaluation__PROMPT__STRATEGY__TIMESTAMP.json` and `code_generation/category/test case/model/conversation__PROMPT__STRATEGY__TIMESTAMP.json`

## Anatomy of `definition.toml`
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