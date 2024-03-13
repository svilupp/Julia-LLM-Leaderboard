using JuliaLLMLeaderboard
using DataFramesMeta, JSON3
using Statistics: mean, median, quantile, std;
using PromptingTools
const PT = PromptingTools

# ! Configuration
DIR_RESULTS = joinpath(pkgdir(JuliaLLMLeaderboard), "code_generation")
# They either have no full scores, or very few
EXCLUDED_TESTS = ["extract_julia_code", "pig_latinify", "q_and_a_extractor"]
PAID_MODELS_DEFAULT = [
    "gpt-3.5-turbo",
    "gpt-3.5-turbo-1106",
    "gpt-3.5-turbo-0125",
    "gpt-4-1106-preview",
    "gpt-4-0125-preview",
    "mistral-tiny",
    "mistral-small",
    "mistral-medium"
];
N_SAMPLES = 50

# # Load Data
df = @chain begin
    load_evals(DIR_RESULTS; max_history = 0)
end;

# Explore scores by test case
@chain df begin
    @rsubset :score == 100 && !in(:name, EXCLUDED_TESTS)
    @by :name :cnt=$nrow
end

# Explore scores by model
@chain df begin
    @rsubset :score == 100 && !in(:name, EXCLUDED_TESTS)
    @by :model :cnt=$nrow
    @orderby -:cnt
end

## Subset to balance the number of examples per test case
df_trainset = @chain df begin
    @select :name :model :score :filename :tokens
    @rsubset :score == 100 && !in(:name, EXCLUDED_TESTS)
    ## Mark paid models, we're prioritize them
    @rtransform :model_paid=in(:model, PAID_MODELS_DEFAULT) :tokens_generated=last(:tokens)
    ## Sort by paid models first, then by fewer tokens generated
    @orderby -:model_paid :tokens_generated
    ## take 50 examples for each test case
    combine(x -> first(x, N_SAMPLES), groupby(_, :name))
end

# Save to sharegpt format
struct ShareGPTSchema <: PT.AbstractPromptSchema end
function sharegpt_role(::PT.AbstractMessage)
    throw(ArgumentError("Unsupported message type $(typeof(msg))"))
end
sharegpt_role(::PT.AIMessage) = "gpt"
sharegpt_role(::PT.UserMessage) = "human"
sharegpt_role(::PT.SystemMessage) = "system"
function PT.render(::ShareGPTSchema, conv::AbstractVector{<:PT.AbstractMessage})
    Dict("conversations" => [Dict("from" => sharegpt_role(msg), "value" => msg.content)
                             for msg in conv])
end
function export_sharegpt(
        filename::String, vect::Vector{<:AbstractVector{<:PT.AbstractMessage}})
    @assert endswith(filename, ".jsonl") "Filename must end with `.jsonl` (JSON Lines format)."
    io = IOBuffer()
    for i in eachindex(vect)
        conv = vect[i]
        gpt_conv = PT.render(ShareGPTSchema(), conv)
        JSON3.write(io, gpt_conv)
        # separate each conversation by newline
        i < length(vect) && print(io, "\n")
    end
    write(filename, String(take!(io)))
    return nothing
end

# Export and save
conversations = df_trainset.filename .|> load_conversation_from_eval
## PT.render(ShareGPTSchema(), conversations[1])
export_sharegpt(
    joinpath(@__DIR__, "leaderboard_code_gen_data_trainset11.jsonl"), conversations)

s = read(joinpath(@__DIR__, "leaderboard_code_gen_data_trainset11.jsonl"), String)
split(s, "\n") .|> length |> maximum