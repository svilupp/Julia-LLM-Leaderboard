# Changelog

## [Unreleased]

### Added

### Fixed

## [0.3.0]

### Added
- REMOVED: Comparison of several Qwen-1.5 models (removed due to poor scores caused by invalid GGUF)
- Added benchmark evals for Google Gemini 1.0 Pro (latest version as of 17th Feb 2024)
- Added benchmark evals for Claude 3 models and MistralAI "mistral-large"
- Added benchmark for the latest OpenAI GPT-4 Turbo ("gpt-4-turbo-2024-04-09")

### Fixed
- Changed the wording from "open-source" models to "locally-hosted" models (a more appropriate description)

## [0.2.0]

### Added
- Added new models (OpenAI "0125" versions, Codellama, and more)
- Capability to evaluate code with AgentCodeFixer loop (set `codefixing_num_rounds>0` )
- Automatically set a different seed for commercial API providers (MistralAI, OpenAI) to avoid their caching mechanism
- Re-scored all past submissions with the new methodology

### Fixed
- Improved code loading and debugging via Julia's code loading mechanism (`include_string`), which allows to better locate the lines that caused the errors (run `evaluate(....; verbose=true)` to see which lines caused the errors or `return_debug=true` to return the debug information as a secondary output).
- Improved error capture and scoring (eg, imports of Base modules are now correctly recognized as "safe")
- Improved detection of parse errors (ie, reduces score of submissions that "executed" only because I didn't detect the parsing error earlier)
- Fixed `mkdir` bug in `run_benchmark`

### Removed
- `@timeout` macro has been upstreamed to PromptingTools

### Case Studies
- Quantization effects on Yi34b and Magicoder 7b
- Effect of English vs Chinese on performance with Yi34b

## [0.1.0]

### Added
- Documentation with detailed methodology, test case definitions, and results across various data cuts.
- Added ~5 samples for each model/prompt/test case combination for more robust results.

### Fixed

## [pre-0.1.0]

### Fixed
- Improved code parsing to accommodate smaller models (eg, imprecise markdown code fences but having a valid code, valid function definition but an invalid follow-on explanation that breaks the execution) - Improved scores for all models.