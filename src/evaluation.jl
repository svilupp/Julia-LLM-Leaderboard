
"""
    run_code_blocks(cb::AICode, code_blocks::AbstractVector{<:AbstractString}; verbose::Bool=false)

Runner for provided `code_blocks` (can be either unit tests or examples), returns count of examples executed without an error. 

`code_blocks` should be a vector of strings, each of which is a valid Julia expression that can be evaluated without an error thrown.
Each successful run (no error thrown) is counted as a successful example.
    
# Keyword Arguments
- `verbose=true` will provide more information about the test failures.

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
function run_code_blocks(cb::AICode, code_blocks::AbstractVector{<:AbstractString}; verbose::Bool=false, prefix::AbstractString="")
    count_successful = 0
    cb_copy = copy(cb)
    for (i, code) in enumerate(code_blocks)
        # Inject the code to evaluate into the AICode object before we parse & eval it
        # suffix means we put it at the end of the code block
        eval!(cb_copy; prefix, suffix=code)
        success = isvalid(cb_copy)
        if verbose && !success
            @info "Run Failure (i: $i): $(cb_copy.stdout)"
        end
        count_successful += success
    end
    return count_successful
end


"""
    evaluate_1shot(; conversation, fn_definition, definition, model, prompt_label, device="UNKNOWN", timestamp=timestamp_now(), prompt_strategy="1SHOT", verbose::Bool=false, auto_save::Bool=true)

Runs evaluation for a single test case (parse, execute, run examples, run unit tests), including saving the files.

If `auto_save=true`, it saves the following files
- `<model-name>/evaluation__PROMPTABC__1SHOT__TIMESTAMP.json`
- `<model-name>/conversation__PROMPTABC__1SHOT__TIMESTAMP.json` 
into a sub-folder of where the definition file was stored.

# Keyword Arguments


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
function evaluate_1shot(; conversation, fn_definition, definition, model, prompt_label, schema, device="UNKNOWN", timestamp=timestamp_now(), version_pt=string(pkgversion(PromptingTools)), prompt_strategy="1SHOT", verbose::Bool=false, auto_save::Bool=true)

    ## early exit
    if isnothing(conversation)
        @warn "Conversation is nothing, skipping evaluation."
        return false
    end

    ## prepare output paths -- .../model/conversation__PROMPTABC__1SHOT__TIMESTAMP.json
    fn_evaluation = joinpath(splitpath(fn_definition)[1:end-1]..., model, "evaluation__$(prompt_label)__$(prompt_strategy)__$(timestamp).json")
    fn_conversation = joinpath(splitpath(fn_definition)[1:end-1]..., model, "conversation__$(prompt_label)__$(prompt_strategy)__$(timestamp).json")

    ## Process the code
    msg = last(conversation)
    imports_required = if !isempty(definition["imports"])
        "using " * join(definition["imports"], ", ")
    else
        ""
    end

    # For ease of evaluation in "safe" mode (eg, inside a custom module), 
    # but we skip any code lines with Pkg manipulation and importing unknown packages
    cb = PT.AICode(msg; prefix=imports_required, skip_unsafe=true)

    ## Run all examples
    example_count = run_code_blocks(cb, definition["examples"]; verbose, prefix=imports_required)

    ## Run all unit tests
    test_count = run_code_blocks(cb, definition["unit_tests"]; verbose, prefix=imports_required)

    ## Create eval dict
    evaluation = (; name=definition["name"], parsed=PT.isparsed(cb),
        executed=isvalid(cb),
        unit_tests_count=length(definition["unit_tests"]), examples_count=length(definition["examples"]),
        unit_tests_passed=test_count, examples_executed=example_count, tokens=msg.tokens,
        elapsed_seconds=msg.elapsed, cost=get_query_cost(msg, model), model,
        timestamp, prompt_strategy, prompt_label, device, version_prompt=definition["version"], schema=string(schema), version_pt)

    if auto_save
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
    load_evals(dir::AbstractString; score::Bool=true, kwargs...)

Loads all evaluation JSONs from a given director loaded in a DataFrame as rows. 
The directory is searched recursively, and all files starting with the prefix `evaluation__` are loaded.

# Keyword Arguments
- `score::Bool=true`: If `score=true`, the function will also call `score_eval` on the resulting DataFrame.
- `max_history::Int=5`: Only `max_history` most recent evaluations are loaded. If `max_history=0`, all evaluations are loaded.

Returns: DataFrame
"""
function load_evals(dir::AbstractString; score::Bool=true, max_history::Int=5, kwargs...)
    @assert max_history >= 0 "max_history must be >= 0 (0 means all evaluations are loaded)"
    output = []
    filenames = String[]
    scores = Float64[]
    for (dir, _, files) in walkdir(dir)
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
    # Combine all dicts into a DataFrame
    df = DataFrame(output)
    df.filename = filenames
    score && (df.score = scores)
    if max_history > 0
        df = @chain df begin
            @orderby(:device, :name, :model, :prompt_label, :prompt_strategy, :timestamp)
            groupby([:device, :name, :model, :prompt_label, :prompt_strategy])
            combine(_) do sdf
                # take the last `max_history` rows in each group
                last(sdf, max_history)
            end
        end
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
function score_eval(eval::AbstractDict; max_points::Int=100)
    parsed = get(eval, :parsed, missing)
    executed = get(eval, :executed, missing)
    unit_tests_success_ratio = get(eval, :unit_tests_passed, missing) / get(eval, :unit_tests_count, missing)
    examples_success_ratio = get(eval, :examples_executed, missing) / get(eval, :examples_count, missing)

    return score_eval(parsed, executed, unit_tests_success_ratio, examples_success_ratio; max_points)
end

"""
    score_eval(parsed, executed, unit_tests_success_ratio, examples_success_ratio; max_points::Int=100)

Score the evaluation result by distributing `max_points` equally across the available criteria.

# Example
```julia
df=@rtransform df :score = score_eval(:parsed, :executed, :unit_tests_passed / :unit_tests_count, :examples_executed / :examples_count)
```
"""
function score_eval(parsed, executed, unit_tests_success_ratio, examples_success_ratio; max_points::Int=100)
    count_categories = count(!ismissing, [parsed, executed, unit_tests_success_ratio, examples_success_ratio])
    points_per_category = max_points / count_categories
    total_score = zero(Float64)
    for category_score in [parsed, executed, unit_tests_success_ratio, examples_success_ratio]
        !ismissing(category_score) && (total_score += category_score * points_per_category)
    end
    return total_score::Float64
end

