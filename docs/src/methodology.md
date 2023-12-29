```@meta
CurrentModule = JuliaLLMLeaderboard
```

# Automated Evaluation Methodology

Each model's and prompt's performance is evaluated based on several criteria:
1. **Parsing**: Does the generated code parse correctly in Julia?
2. **Execution**: Can the code execute without errors?
3. **Unit Tests**: Do the included unit tests pass?
4. **Example Runs**: Does the code run in a provided example scenario?

At the moment, all criteria are weighed equally and each test case can earn a maximum of 100 points. 

If a code passes all criteria, it gets 100/100 points. 

If it fails one criterion (eg, all unit tests), it gets 75/100 points. 

If it fails two criteria (eg, it runs but all examples and unit tests are broken), it gets 50 points, and so on.

## Definition.toml

Each test case is defined in a `definition.toml` file with the structure described in [Anatomy of `definition.toml`](@ref).

We chose TOML format because it is human-readable and easy to edit in a text editor / GITHub.

## Repo Structure / Naming Convention

To enhance transparency and reproducibility, we save all conversations and evaluations in a nested folder structure.

**Folder Convention**:  
- Definitions are saved in nested folders following the format `code_generation/category/test_case_name/definition.toml`
- Evaluation results are saved in nested sub-folders, keyed by the model:
  - Evaluation result: `code_generation/category/test_case_name/model/evaluation__PROMPT__STRATEGY__TIMESTAMP.json`
  - Conversation: `code_generation/category/test_case_name/model/conversation__PROMPT__STRATEGY__TIMESTAMP.json`

You can load any conversation with `PromptingTools.load_conversation()` and display it with `edit` or `preview` depending on your IDE/preference.

You can load any evaluation with `JSON3.read` and score it with `score_eval`.
