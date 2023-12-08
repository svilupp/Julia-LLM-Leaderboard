# TODO: add suffix with randint

"Provide a current timestamp in the format yyyymmdd_HHMMSS. If `add_random` is true, a random number between 100 and 999 is appended to avoid overrides."
function timestamp_now(; add_random::Bool=true)
    timestamp = Dates.format(now(), dateformat"yyyymmdd_HHMMSS")
    if add_random
        timestamp *= "__$(rand(100:999))"
    end
    return timestamp
end

function get_query_cost(msg::AIMessage, model::AbstractString, model_costs=PT.MODEL_COSTS)
    # divide by 1000 because the costs are stated for 1K tokens
    cost = msg.tokens .* get(model_costs, model, (0.0, 0.0)) ./ 1000 |> sum
end