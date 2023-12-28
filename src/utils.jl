"Provide a current timestamp in the format yyyymmdd_HHMMSS. If `add_random` is true, a random number between 100 and 999 is appended to avoid overrides."
function timestamp_now(; add_random::Bool = true)
    timestamp = Dates.format(now(), dateformat"yyyymmdd_HHMMSS")
    if add_random
        timestamp *= "__$(rand(100:999))"
    end
    return timestamp
end

function get_query_cost(msg::AIMessage, model::AbstractString,
        cost_of_token_prompt::Number = get(PT.MODEL_REGISTRY,
            model,
            (; cost_of_token_prompt = 0.0)).cost_of_token_prompt,
        cost_of_token_generation::Number = get(PT.MODEL_REGISTRY, model,
            (; cost_of_token_generation = 0.0)).cost_of_token_generation)
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

"""
    tmapreduce(f, op, itr; tasks_per_thread::Int = 2, kwargs...)

A parallelized version of the `mapreduce` function leveraging multi-threading.

The function `f` is applied to each element of `itr`, and then the results are reduced using an associative two-argument function `op`.

# Arguments
- `f`: A function to apply to each element of `itr`.
- `op`: An associative two-argument reduction function.
- `itr`: An iterable collection of data.

# Keyword Arguments
- `tasks_per_thread::Int = 2`: The number of tasks spawned per thread. Determines the granularity of parallelism.
- `kwargs...`: Additional keyword arguments to pass to the inner `mapreduce` calls.

# Implementation Details
The function divides `itr` into chunks, spawning tasks for processing each chunk in parallel. The size of each chunk is determined by `tasks_per_thread` and the number of available threads (`nthreads`). The results from each task are then aggregated using the `op` function.

# Notes
This implementation serves as a general replacement for older patterns. The goal is to introduce this function or a version of it to base Julia in the future.

# Example
```julia
using Base.Threads: nthreads, @spawn
result = tmapreduce(x -> x^2, +, 1:10)
```

The above example squares each number in the range 1 through 10 and then sums them up in parallel.

Source: [Julia Blog post](https://julialang.org/blog/2023/07/PSA-dont-use-threadid/#better_fix_work_directly_with_tasks)
"""
function tmapreduce(f, op, itr; tasks_per_thread::Int = 2, kwargs...)
    chunk_size = max(1, length(itr) ÷ (tasks_per_thread * Threads.nthreads()))
    tasks = map(Iterators.partition(itr, chunk_size)) do chunk
        Threads.@spawn mapreduce(f, op, chunk; kwargs...)
    end
    mapreduce(fetch, op, tasks; kwargs...)
end