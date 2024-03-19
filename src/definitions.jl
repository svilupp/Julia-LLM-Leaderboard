
## Anatomy of `definition.toml`
# Required fields in `definition.toml` include:
# - **name**: Corresponding to the file path.
# - **contributor**: The creator of the test case (and their collaborators).
# - **criteria**: The evaluation criteria (eg, parsing, execution, unit_tests, examples).
# - **prompt**: The problem statement or task.
# - **version**: The version of the test case. Starts at "1.0".
# - **examples**: Example scenarios for testing, provided as a vector of executable statements using the function name (eg, `my_function(1, 2)`).
# - **unit_tests**: Tests to validate the code, provided as a vector of `@test X = Z` statements.
# - **imports**: Packages that are made available to the model (to avoid failures due to a failed dependency).
# - **reference_solution**: A reference solution to the problem, provided as a string of Julia code (no code fences).
#
# Optional fields:
# - `examples_setup`: A setup code to run before each example. Eg, build some input objects.
# - `examples_teardown`: A teardown code to run after each example. Eg, delete the input objects that were created in the setup, or undo any changes.
# - `unit_tests_setup`: A setup code to run before each unit test. Eg, build test objects that can be used in all individual test cases.
# - `unit_tests_teardown`: A teardown code to run after each unit test. Eg, delete test objects that were created in the setup, or undo any changes.

"""
    validate_definition(definition::AbstractDict; evaluate::Bool=true, verbose::Bool=true)

Validates the `definition.toml` file for the code generation benchmark. 
    
Returns `true` if the definition is valid.

# Keyword Arguments
- `evaluate`: a boolean whether to evaluate the definition. If not specified, it will evaluate the definition.
- `verbose`: a boolean whether to print progress during the evaluation. If not specified, it will print progress.
- `kwargs`: keyword arguments to pass to code parsing function (`PT.AICode`).

# Example
```julia
fn_definition = joinpath("code_generation", "utility_functions", "event_scheduler", "definition.toml")
definition = load_definition(fn_definition)
validate_definition(definition)
# output: true
```
"""
function validate_definition(definition::AbstractDict;
        evaluate::Bool = true,
        verbose::Bool = true,
        kwargs...)
    # Check top-level key for benchmark category
    allowed_category = ["code_generation"]
    category = first(keys(definition))
    @assert category in allowed_category "Unknown category: $category. Each definition must start with benchmark category key. Allowed categories: $(join(allowed_category, ", "))."

    ## move inside the category
    definition = definition[category]

    ## Check required fields
    haskey(definition, "name") || error("Missing field: name")
    haskey(definition, "contributor") || error("Missing field: contributor")
    haskey(definition, "criteria") || error("Missing field: criteria")
    haskey(definition, "prompt") || error("Missing field: prompt")
    haskey(definition, "version") || error("Missing field: version")
    haskey(definition, "examples") || error("Missing field: examples")
    haskey(definition, "unit_tests") || error("Missing field: unit_tests")
    haskey(definition, "imports") || error("Missing field: packages")
    haskey(definition, "reference_solution") || error("Missing field: reference_solution")

    ## Check field types
    @assert typeof(definition["name"])<:AbstractString "Field `name` must be a string"
    @assert typeof(definition["contributor"])<:AbstractString "Field `contributor` must be a string"
    @assert typeof(definition["prompt"])<:AbstractString "Field `prompt` must be a string"
    @assert typeof(definition["version"])<:AbstractString "Field `version` must be a string"
    @assert typeof(definition["criteria"])<:Vector{<:AbstractString} "Field `criteria` must be a vector of strings"
    @assert typeof(definition["examples"])<:Vector{<:AbstractString} "Field `criteria` must be a vector of strings"
    @assert typeof(definition["unit_tests"])<:Vector{<:AbstractString} "Field `criteria` must be a vector of strings"
    @assert typeof(definition["imports"])<:Vector{<:AbstractString} "Field `criteria` must be a vector of strings"
    @assert typeof(definition["reference_solution"])<:AbstractString "Field `reference_solution` must be a string"
    if haskey(definition, "examples_setup")
        @assert typeof(definition["examples_setup"])<:AbstractString "Field `examples_setup` must be a string"
    end
    if haskey(definition, "examples_teardown")
        @assert typeof(definition["examples_teardown"])<:AbstractString "Field `examples_teardown` must be a string"
    end
    if haskey(definition, "unit_tests_setup")
        @assert typeof(definition["unit_tests_setup"])<:AbstractString "Field `unit_tests_setup` must be a string"
    end
    if haskey(definition, "unit_tests_teardown")
        @assert typeof(definition["unit_tests_teardown"])<:AbstractString "Field `unit_tests_teardown` must be a string"
    end

    ## Not empty
    isempty(definition["name"]) && error("Field `name` must not be empty")
    isempty(definition["contributor"]) && error("Field `contributor` must not be empty")
    isempty(definition["prompt"]) && error("Field `prompt` must not be empty")
    isempty(definition["version"]) && error("Field `version` must not be empty")
    isempty(definition["reference_solution"]) &&
        error("Field `reference_solution` must not be empty")
    isempty(definition["criteria"]) && error("Field `criteria` must not be empty")
    if "executed_examples" in definition["criteria"]
        isempty(definition["examples"]) &&
            error("Field `examples` must not be empty if criteria includes `executed_examples`")
    end
    if "passed_unit_tests" in definition["criteria"]
        isempty(definition["unit_tests"]) &&
            error("Field `unit_tests` must not be empty if criteria includes `passed_unit_tests`")
    end

    ## Evaluation
    if evaluate
        imports_required = if !isempty(definition["imports"])
            "using " * join(definition["imports"], ", ")
        else
            ""
        end
        ## Run the function
        cb = PT.AICode(definition["reference_solution"];
            prefix = imports_required,
            verbose,
            kwargs...)
        @assert isvalid(cb) "Error: Failed to parse the reference solution. Please check the reference solution."

        ## Run all examples
        if "executed_examples" in definition["criteria"]
            example_count = run_code_blocks_additive(cb,
                definition["examples"];
                verbose,
                setup_code = get(definition, "examples_setup", ""),
                teardown_code = get(definition, "examples_teardown", ""))
            example_length = length(definition["examples"])
            @assert example_count>0 "Failed to execute any examples. Please check the examples."
            example_count < example_length &&
                @warn "Failed to execute all examples. Expected $example_length, got $example_count"
            verbose && @info "Passed $(example_count)/$(example_length) examples"
        end

        ## Run all unit tests
        if "passed_unit_tests" in definition["criteria"]
            test_count = run_code_blocks_additive(cb,
                definition["unit_tests"];
                verbose,
                setup_code = get(definition, "unit_tests_setup", ""),
                teardown_code = get(definition, "unit_tests_teardown", ""))
            test_length = length(definition["unit_tests"])
            @assert test_count>0 "Failed to execute any unit tests. Please check the unit tests."
            test_count < test_length &&
                @warn "Failed to execute all unit tests. Expected $test_length, got $test_count"
            verbose && @info "Passed $(test_count)/$(test_length) tests"
        end
    end
    return true
end

"Saves the test case `definition` to a TOML file under `filename`."
function save_definition(filename::AbstractString,
        definition::AbstractDict;
        evaluate::Bool = false,
        verbose::Bool = true,
        kwargs...)
    ## Validate the definition
    @assert validate_definition(definition; evaluate, verbose, kwargs...) "Failed to validate the definition. Please fix the errors."
    ## Save it
    open(filename, "w") do io
        TOML.print(io, definition)
    end
end

"Loads the test case definition from a TOML file under `filename`."
function load_definition(filename)
    return TOML.tryparse(open(filename, "r"))
end

"Finds all `definition.toml` filenames in the given path. Returns a list of filenames to load."
function find_definitions(dir::AbstractString = ".")
    definitions = AbstractString[]
    for (root, dirs, files) in walkdir(dir)
        for file in files
            if file == "definition.toml"
                push!(definitions, joinpath(root, file))
            end
        end
    end
    return definitions
end