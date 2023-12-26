"Provide a current timestamp in the format yyyymmdd_HHMMSS. If `add_random` is true, a random number between 100 and 999 is appended to avoid overrides."
function timestamp_now(; add_random::Bool=true)
    timestamp = Dates.format(now(), dateformat"yyyymmdd_HHMMSS")
    if add_random
        timestamp *= "__$(rand(100:999))"
    end
    return timestamp
end

function get_query_cost(msg::AIMessage, model::AbstractString,
    cost_of_token_prompt::Number=get(PT.MODEL_REGISTRY,
        model,
        (; cost_of_token_prompt=0.0)).cost_of_token_prompt,
    cost_of_token_generation::Number=get(PT.MODEL_REGISTRY, model,
        (; cost_of_token_generation=0.0)).cost_of_token_generation)

    cost = (msg.tokens[1] * cost_of_token_prompt +
            msg.tokens[2] * cost_of_token_generation)

    return cost
end

"""
    @timeout(seconds, expr_to_run, expr_when_fails)

Simple macro to run an expression with a timeout of `seconds`. If the `expr_to_run` fails to finish in `seconds` seconds, `expr_when_fails` is returned.

# Example
```julia
x = @timeout 1 begin
    sleep(1.1)
    println("done")
    1
end "failed"

```
"""
macro timeout(seconds, expr_to_run, expr_when_fails)
    quote
        tsk = @task $(esc(expr_to_run))
        schedule(tsk)
        Timer($(esc(seconds))) do timer
            istaskdone(tsk) || Base.throwto(tsk, InterruptException())
        end
        try
            fetch(tsk)
        catch _
            $(esc(expr_when_fails))
        end
    end
end