# Changelog
## [Unreleased]

### Added
- Capability to evaluate code with AgentCodeFixer loop (set `codefixing_num_rounds>0` )

### Fixed
- Improved code loading and debugging via Julia's code loading mechanism (`include_string`), which allows to better locate the lines that caused the errors (run `evaluate(....; verbose=true)` to see which lines caused the errors or `return_debug=true` to return the debug information as a secondary output).
- Improved error capture and scoring (eg, imports of Base modules are now correctly recognized as "safe")
- Improved detection of parse errors (ie, reduces score of submissions that "executed" only because I didn't detect the parsing error earlier)
- Fixed `mkdir` bug in `run_benchmark`

## [0.1.0]

### Added
- Documentation with detailed methodology, test case definitions, and results across various data cuts.
- Added ~5 samples for each model/prompt/test case combination for more robust results.

### Fixed

## [pre-0.1.0]

### Fixed
- Improved code parsing to accommodate smaller models (eg, imprecise markdown code fences but having a valid code, valid function definition but an invalid follow-on explanation that breaks the execution) - Improved scores for all models.