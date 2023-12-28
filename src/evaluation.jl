
"""
    run_code_blocks(cb::AICode, code_blocks::AbstractVector{<:AbstractString};
        verbose::Bool = false, prefix::AbstractString = "",
        setup_code::AbstractString = "", teardown_code::AbstractString = "",
        capture_stdout::Bool = true, execution_timeout::Int = 60)

Runner for provided `code_blocks` (can be either unit tests or examples), returns count of examples executed without an error. 

`code_blocks` should be a vector of strings, each of which is a valid Julia expression that can be evaluated without an error thrown.
Each successful run (no error thrown) is counted as a successful example.
    
# Keyword Arguments
- `verbose=true` will provide more information about the test failures.
- `prefix` is a string that will be prepended to each code block before it's evaluated. Useful for importing packages.
- `setup_code` is a string that will be prepended to each code block before it's evaluated. Useful for setting up the environment/test objects.
- `teardown_code` is a string that will be appended to each code block before it's evaluated. Useful for cleaning up the environment/test objects.
- `capture_stdout` is a boolean whether to capture the stdout of the code execution. Set to `false` if you're evaluating with multithreading (stdout capture is not thread-safe).
- `execution_timeout` is the timeout for the AICode code execution in seconds. Defaults to 60s.

# Returns
- `count_successful` the number of examples that were executed without an error thrown.

# Example
```julia
using JuliaLLMLeaderboard: run_code_blocks
using PromptingTools: AICode

cb = AICode("mysum(a,b)=a+b")
code = "mysum(1,2)"
run_code_blocks(cb, [code])
# Output: 1 (= 1 example executed without an error thrown)
```
"""
function run_code_blocks(cb::AICode, code_blocks::AbstractVector{<:AbstractString};
        verbose::Bool = false, prefix::AbstractString = "",
        setup_code::AbstractString = "", teardown_code::AbstractString = "",
        capture_stdout::Bool = true, execution_timeout::Int = 60)
    ##
    count_successful = 0
    cb_copy = copy(cb)
    for (i, code) in enumerate(code_blocks)
        # Inject the code to evaluate into the AICode object before we parse & eval it
        # suffix means we put it at the end of the code block
        # We run with timeout to avoid infinite loops
        code_joined = string(setup_code, "\n\n", code, "\n\n", teardown_code)
        @timeout execution_timeout begin
            eval!(cb_copy; prefix, suffix = code_joined, capture_stdout)
        end nothing

        success = isvalid(cb_copy)
        if verbose && !success
            @warn "Run Failure (i: $i):\nError: $(cb_copy.error)\nStdOut: $(cb_copy.stdout)"
        end
        count_successful += success
    end
    return count_successful
end

"""
    evaluate_1shot(; conversation, fn_definition, definition, model, prompt_label, schema, parameters::NamedTuple=NamedTuple(), device="UNKNOWN", timestamp=timestamp_now(), version_pt=string(pkgversion(PromptingTools)), prompt_strategy="1SHOT", verbose::Bool=false,
    auto_save::Bool=true, save_dir::AbstractString=dirname(fn_definition), experiment::AbstractString="",
    execution_timeout::Int=60, capture_stdout::Bool=true)

Runs evaluation for a single test case (parse, execute, run examples, run unit tests), including saving the files.

If `auto_save=true`, it saves the following files
- `<model-name>/evaluation__PROMPTABC__1SHOT__TIMESTAMP.json`
- `<model-name>/conversation__PROMPTABC__1SHOT__TIMESTAMP.json` 
into a sub-folder of where the definition file was stored.

# Keyword Arguments
- `conversation`: the conversation to evaluate (vector of messages), eg, from `aigenerate` when `return_all=true`
- `fn_definition`: path to the definition file (eg, `joinpath("code_generation", "utility_functions", "event_scheduler", "definition.toml")`)
- `definition`: the test case definition dict loaded from the definition file. It's subset to only the relevant keys for code generation, eg, `definition=load_definition(fn_definition)["code_generation"]`
- `model`: the model name, eg, `model="gpt4t"`
- `prompt_label`: the prompt label, eg, `prompt_label="JuliaExpertAsk"`
- `schema`: the schema used for the prompt, eg, `schema="-"` or `schema="OllamaManagedSchema()"`
- `parameters`: the parameters used for the generation like `temperature` or `top_p`, eg, `parameters=(; top_p=0.9)`
- `device`: the device used for the generation, eg, `device="Apple-MacBook-Pro-M1"`
- `timestamp`: the timestamp used for the generation. Defaults to `timestamp=timestamp_now()` which is like "20231201_120000"
- `version_pt`: the version of PromptingTools used for the generation, eg, `version_pt="0.1.0"`
- `prompt_strategy`: the prompt strategy used for the generation, eg, `prompt_strategy="1SHOT"`. Fixed for now!
- `verbose`: if `verbose=true`, it will print out more information about the evaluation process, eg, the evaluation errors
- `auto_save`: if `auto_save=true`, it will save the evaluation and conversation files into a sub-folder of where the definition file was stored.
- `save_dir`: the directory where the evaluation and conversation files are saved. Defaults to `dirname(fn_definition)`.
- `experiment`: the experiment name, eg, `experiment="my_experiment"` (eg, when you're doing a parameter search). Defaults to `""` for standard benchmark run.
- `execution_timeout`: the timeout for the AICode code execution in seconds. Defaults to 60s.
- `capture_stdout`: if `capture_stdout=true`, AICode will capture the stdout of the code execution. Set to `false` if you're evaluating with multithreading (stdout capture is not thread-safe). Defaults to `true` to avoid poluting the benchmark.


# Examples
```julia
using JuliaLLMLeaderboard
using PromptingTools

fn_definition = joinpath("code_generation", "utility_functions", "event_scheduler", "definition.toml")
d = load_definition(fn_definition)

msg = aigenerate(:JuliaExpertAsk; ask=d["code_generation"]["prompt"], model="gpt4t", return_all=true)

# Try evaluating it -- auto_save=false not to polute our benchmark
evals = evaluate_1shot(; conversation=msg, fn_definition, definition=d["code_generation"], model="gpt4t", prompt_label="JuliaExpertAsk", timestamp=timestamp_now(), device="Apple-MacBook-Pro-M1", schema="-", prompt_strategy="1SHOT", verbose=true, auto_save=false)
```
"""
function evaluate_1shot(; conversation, fn_definition, definition, model, prompt_label,
        schema, parameters::NamedTuple = NamedTuple(), device = "UNKNOWN",
        timestamp = timestamp_now(), version_pt = string(pkgversion(PromptingTools)),
        prompt_strategy = "1SHOT", verbose::Bool = false,
        auto_save::Bool = true, save_dir::AbstractString = dirname(fn_definition),
        experiment::AbstractString = "",
        execution_timeout::Int = 60, capture_stdout::Bool = true)
    @assert execution_timeout>0 "execution_timeout must be positive"

    ## early exit
    if isnothing(conversation)
        @warn "Conversation is nothing, skipping evaluation."
        return false
    end

    ## Process the code
    msg = last(conversation)
    imports_required = if !isempty(definition["imports"])
        "using " * join(definition["imports"], ", ")
    else
        ""
    end

    ## Run the code
    # For ease of evaluation in "safe" mode (eg, inside a custom module), 
    # but we skip any code lines with Pkg manipulation and importing unknown packages
    # we skip invalid code blocks (in case some later example is poor)
    # we do capture stdout, disabled to be able to process in parallel
    # execution is set to timeout in 60s
    cb = @timeout execution_timeout begin
        PT.AICode(msg;
            prefix = imports_required,
            skip_unsafe = true,
            skip_invalid = true,
            capture_stdout)
    end PT.AICode(msg;
        auto_eval = false,
        prefix = imports_required,
        skip_unsafe = true,
        skip_invalid = true,
        capture_stdout)

    if !isvalid(cb)
        ## We want to measure function defintion separately from examples and test cases, 
        # so we give it one more chance and grab only the code definition
        raw_blocks = PT.extract_code_blocks(msg.content)
        definition_mask = PT.is_julia_code.(raw_blocks) .&&
                          (PT.extract_function_name.(raw_blocks) .== definition["name"])
        definition_idx = findfirst(definition_mask)

        if !isnothing(definition_idx)
            # redefine the code block to be just the function definition
            cb = @timeout execution_timeout begin
                AICode(raw_blocks[definition_idx];
                    prefix = imports_required,
                    skip_unsafe = true,
                    capture_stdout)
            end PT.AICode(raw_blocks[definition_idx];
                auto_eval = false,
                prefix = imports_required,
                skip_unsafe = true,
                skip_invalid = true,
                capture_stdout)
        end
    end

    ## Run all examples
    example_count = if isvalid(cb)
        run_code_blocks(cb, definition["examples"]; verbose,
            prefix = imports_required, capture_stdout, execution_timeout,
            setup_code = get(definition, "examples_setup", ""),
            teardown_code = get(definition, "examples_teardown", ""))
    else
        0
    end

    ## Run all unit tests
    test_count = if isvalid(cb)
        run_code_blocks(cb,
            definition["unit_tests"];
            verbose,
            prefix = imports_required,
            capture_stdout,
            execution_timeout, setup_code = get(definition, "unit_tests_setup", ""),
            teardown_code = get(definition, "unit_tests_teardown", ""))
    else
        0
    end

    ## Create eval dict
    evaluation = (; name = definition["name"], parsed = PT.isparsed(cb),
        executed = isvalid(cb),
        unit_tests_count = length(definition["unit_tests"]),
        examples_count = length(definition["examples"]),
        unit_tests_passed = test_count, examples_executed = example_count,
        tokens = msg.tokens,
        elapsed_seconds = msg.elapsed, cost = get_query_cost(msg, model), model,
        timestamp, prompt_strategy, prompt_label, device,
        version_prompt = definition["version"], schema = string(schema), version_pt,
        parameters, experiment)

    if auto_save
        ## Define paths -- .../model/conversation__PROMPTABC__1SHOT__TIMESTAMP.json
        fn_evaluation = joinpath(save_dir,
            model,
            "evaluation__$(prompt_label)__$(prompt_strategy)__$(timestamp).json")
        fn_conversation = joinpath(save_dir,
            model,
            "conversation__$(prompt_label)__$(prompt_strategy)__$(timestamp).json")
        ## Save Evaluation
        mkpath(dirname(fn_evaluation))
        JSON3.write(fn_evaluation, evaluation)
        ## Save conversation
        mkpath(dirname(fn_conversation))
        save_conversation(fn_conversation, conversation)
    end

    return evaluation
end

"""
    load_evals(base_dir::AbstractString; score::Bool=true, max_history::Int=5, new_columns::Vector{Symbol}=Symbol[], kwargs...)

Loads all evaluation JSONs from a given director loaded in a DataFrame as rows. 
The directory is searched recursively, and all files starting with the prefix `evaluation__` are loaded.

# Keyword Arguments
- `score::Bool=true`: If `score=true`, the function will also call `score_eval` on the resulting DataFrame.
- `max_history::Int=5`: Only `max_history` most recent evaluations are loaded. If `max_history=0`, all evaluations are loaded.

Returns: DataFrame

Note: It loads a fixed set of columns (set in a local variable `eval_cols`), so if you added some new columns, you'll need to pass them to `new_columns::Vector{Symbol}` argument.
"""
function load_evals(base_dir::AbstractString;
        score::Bool = true,
        max_history::Int = 5,
        new_columns::Vector{Symbol} = Symbol[],
        kwargs...)
    @assert max_history>=0 "max_history must be >= 0 (0 means all evaluations are loaded)"
    output = []
    filenames = String[]
    scores = Float64[]
    for (dir, _, files) in walkdir(base_dir)
        for file in files
            if startswith(file, "evaluation__")
                fn = joinpath(dir, file)
                d = JSON3.read(fn)
                push!(output, d)
                push!(filenames, fn)
                # calculate scores (optional)
                score && (push!(scores, score_eval(d)))
            end
        end
    end
    # Combine all dicts into a DataFrame -- define full set of keys explicitly to ensure older evals are loaded as well
    eval_cols = [
        :name,
        :parsed,
        :executed,
        :unit_tests_passed,
        :unit_tests_count,
        :examples_executed,
        :examples_count,
        :tokens,
        :elapsed_seconds,
        :cost,
        :model,
        :prompt_label,
        :prompt_strategy,
        :timestamp,
        :device,
        :schema,
        :version_pt,
        :version_prompt,
        :parameters,
        :experiment,
        new_columns...,
    ]

    df = DataFrame([Dict(c => get(row, c, missing) for c in eval_cols) for row in output])
    df.filename = filenames
    score && (df.score = scores)
    if max_history > 0
        df = @chain df begin
            groupby([:device, :name, :model, :prompt_label, :prompt_strategy])
            combine(_) do sdf
                # take the last `max_history` rows in each group
                last(sort(sdf, :timestamp), max_history)
            end
        end
    end
    ## auto-expand parameters if not missing
    if "parameters" in names(df) && all(!ismissing, df.parameters)
        unique_params = df.parameters .|> keys .|> collect |> Base.Splat(vcat) |> unique
        @rtransform! df $AsTable=Dict(param => get(:parameters, param, missing)
                                      for param in unique_params)
    end
    return df
end
"""
    score_eval(eval::AbstractDict; max_points::Int=100)

    score_eval(parsed, executed, unit_tests_success_ratio, examples_success_ratio; max_points::Int=100)

Scores the evaluation result `eval` by distributing `max_points` equally across the available criteria.
Alternatively, you can provide the individual scores as arguments (see above) with values in the 0-1 range.

Eg, if all 4 criteria are available, each will be worth 25% of points:
- `parsed` (25% if true)
- `executed` (25% if true)
- `unit_tests` (25% if all unit tests passed)
- `examples` (25% if all examples executed without an error thrown)
"""
function score_eval(eval::AbstractDict; max_points::Int = 100)
    parsed = get(eval, :parsed, missing)
    executed = get(eval, :executed, missing)
    unit_tests_success_ratio = get(eval, :unit_tests_passed, missing) /
                               get(eval, :unit_tests_count, missing)
    examples_success_ratio = get(eval, :examples_executed, missing) /
                             get(eval, :examples_count, missing)

    return score_eval(parsed,
        executed,
        unit_tests_success_ratio,
        examples_success_ratio;
        max_points)
end
function score_eval(eval::NamedTuple; kwargs...)
    score_eval(Dict(k => v for (k, v) in zip(keys(eval), values(eval))); kwargs...)
end

"""
    score_eval(parsed, executed, unit_tests_success_ratio, examples_success_ratio; max_points::Int=100)

Score the evaluation result by distributing `max_points` equally across the available criteria.

# Example
```julia
df=@rtransform df :score = score_eval(:parsed, :executed, :unit_tests_passed / :unit_tests_count, :examples_executed / :examples_count)
```
"""
function score_eval(parsed,
        executed,
        unit_tests_success_ratio,
        examples_success_ratio;
        max_points::Int = 100)
    count_categories = count(!ismissing,
        [parsed, executed, unit_tests_success_ratio, examples_success_ratio])
    points_per_category = max_points / count_categories
    total_score = zero(Float64)
    for category_score in [
        parsed,
        executed,
        unit_tests_success_ratio,
        examples_success_ratio,
    ]
        !ismissing(category_score) && (total_score += category_score * points_per_category)
    end
    return total_score::Float64
end
