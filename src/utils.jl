# TODO: add suffix with randint

"Provide a current timestamp in the format yyyymmdd_HHMMSS"
timestamp_now() = Dates.format(now(), dateformat"yyyymmdd_HHMMSS")

function get_query_cost(msg::AIMessage, model::AbstractString, model_costs=PT.MODEL_COSTS)
    # divide by 1000 because the costs are stated for 1K tokens
    cost = msg.tokens .* get(model_costs, model, (0.0, 0.0)) ./ 1000 |> sum
end