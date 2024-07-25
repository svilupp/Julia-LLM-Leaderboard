# # Comparison of Paid LLM APIs vs Local Models
#
# While several locally-hosted models are very impressive, there is still a big gap in performance.
#
# This gap would be smaller if we could run any of the 70bn models locally, unfortunately, that’s not the case for me.
#
# Reminder: The below scores are on a scale 0-100, where 100 is the best possible score and 0 means the generated code was not even parseable.

## Imports
using JuliaLLMLeaderboard
using CairoMakie, AlgebraOfGraphics
using MarkdownTables, DataFramesMeta
using Statistics: mean, median, quantile;
unscrub_string(s::AbstractString) = split(s, "_") .|> titlecase |> x -> join(x, " ");

## ! Configuration
SAVE_PLOTS = false
DIR_RESULTS = joinpath(pkgdir(JuliaLLMLeaderboard), "code_generation")
PAID_MODELS_DEFAULT = [
    "gpt-3.5-turbo",
    "gpt-3.5-turbo-1106",
    "gpt-3.5-turbo-0125",
    "gpt-4-1106-preview",
    "gpt-4-0125-preview",
    "gpt-4-turbo-2024-04-09",
    "gpt-4o-2024-05-13",
    "gpt-4o-mini-2024-07-18",
    "mistral-tiny",
    "mistral-small",
    "mistral-medium",
    "mistral-large",
    "mistral-small-2402",
    "mistral-medium-2312",
    "mistral-large-2402",
    "claude-3-opus-20240229",
    "claude-3-sonnet-20240229",
    "claude-3-haiku-20240307",
    "claude-3-5-sonnet-20240620",
    "claude-2.1",
    "gemini-1.0-pro-latest",
    "deepseek-chat",
    "deepseek-coder",
    "codestral-2405",
    "mistral-large-2407"
];
PROMPTS = [
    "JuliaExpertCoTTask",
    "JuliaExpertAsk",
    "InJulia",
    "JuliaRecapTask",
    "JuliaRecapCoTTask"
];

# ## Load Latest Results
# Use only the 5 most recent evaluations available for each definition/model/prompt
df = @chain begin
    load_evals(DIR_RESULTS; max_history = 5)
    @rsubset :prompt_label in PROMPTS
    ## remove qwen models as they are not correct!
    @rsubset !occursin("qwen", :model)
end;

# ## Comparison by Model
# Highest average score by model:
fig = @chain df begin
    @by [:model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @orderby -:score
    @rtransform :is_paid = :model in PAID_MODELS_DEFAULT
    @rsubset !endswith(:model, "--optim")
    @aside local order_ = _.model
    data(_) *
    mapping(:model => sorter(order_) => "Model",
        :score => "Avg. Score (Max 100 pts)",
        color = :is_paid => "Paid API or Locally-hosted") *
    visual(BarPlot; bar_labels = :y, label_offset = 0, label_formatter = x -> round(Int, x))
    draw(;
        figure = (; size = (900, 600)),
        legend = (; position = :bottom),
        axis = (;
            limits = (nothing, nothing, 0, 100),
            xticklabelrotation = 45,
            title = "LLM Model Performance [PRELIMINARY]"))
end
fig

# Table:
output = @chain df begin
    @by [:model] begin
        :elapsed = mean(:elapsed_seconds)
        :elapsed_median = mean(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :count_zero_score = count(iszero, :score)
        :count_full_score = count(==(100), :score)
    end
    @rtransform :is_paid = :model in PAID_MODELS_DEFAULT
    @rsubset !endswith(:model, "--optim")
    transform(_,
        names(_, Not(:model, :is_paid)) .=> ByRow(x -> round(x, digits = 1)),
        renamecols = false)
    @orderby -:score
    rename(_, names(_) .|> unscrub_string)
end
## markdown_table(output, String) |> clipboard
markdown_table(output)