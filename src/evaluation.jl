
"Runner for `examples` specified, returns count of examples executed without an error. `verbose=true` will provide more information about the test failures."
function run_examples(cb::AICode, examples::AbstractVector{<:AbstractString}; verbose::Bool=false)
    # Find the name of the function
    function_name = PT.extract_function_name(cb.code) |> Symbol
    examples_successful = 0
    for (i, example) in enumerate(examples)
        success = try
            @eval(cb.output, $(function_name)($example))
            true
        catch e
            if verbose
                @info "Example Failure (i: $i): $(e)"
            end
            false

        end
        examples_successful += success
    end
    return examples_successful
end

"Test runner for `unit_tests` specified, returns count of successful unit tests. `verbose=true` will provide more information about the test failures."
function run_unit_tests(cb::AICode, unit_tests::AbstractVector{<:AbstractString}; verbose::Bool=false)
    tests_successful = 0
    cb_copy = copy(cb)
    for (i, test) in enumerate(unit_tests)
        eval!(cb_copy; suffix=test)
        success = isvalid(cb_copy)
        if verbose && !success
            @info "Test Failure (i: $i): $(cb_copy.stdout)"
        end
        tests_successful += success
    end
    return tests_successful
end

function evaluate_1shot(; conversation, fn_definition, definition, model, prompt_label, timestamp=timestamp_now(), prompt_strategy="1SHOT", verbose::Bool=false)

    ## prepare output paths -- .../model/conversation__PROMPTABC__1SHOT__TIMESTAMP.json
    fn_evaluation = joinpath(splitpath(fn_definition)[1:end-1]..., model, "evaluation__$(prompt_label)__$(prompt_strategy)__$(timestamp).json")
    mkpath(dirname(fn_evaluation))
    fn_conversation = joinpath(splitpath(fn_definition)[1:end-1]..., model, "conversation__$(prompt_label)__$(prompt_strategy)__$(timestamp).json")
    mkpath(dirname(fn_conversation))

    ## Process the code
    msg = last(conversation)
    cb = AICode(msg)

    ## Run all examples
    example_count = run_examples(cb, definition["examples"]; verbose)

    ## Run all unit tests
    test_count = run_unit_tests(cb, definition["unit_tests"]; verbose)

    ## Create eval object
    evaluation = (; name=definition["name"], parsed=!isnothing(cb.expression),
        executed=isvalid(cb),
        unit_tests_passed=test_count, examples_executed=example_count, tokens=msg.tokens,
        elapsed_seconds=msg.elapsed, cost=get_query_cost(msg, model), model,
        timestamp, prompt_strategy, prompt_label)

    ## Save Evaluation
    JSON3.write(fn_evaluation, evaluation)
    ## Save conversation
    PT.save_template(fn_conversation, conversation; content="Code Gen Benchmark")

    return true
end

