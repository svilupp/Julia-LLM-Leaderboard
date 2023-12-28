# # Summary of Paid LLM APIs
#
# The below captures the performance of 3 models from two commercial LLM APIs: OpenAI (GPT-3.5, GPT-4, ...) and MistralAI (tiny, small, medium).
# There are many other providers, but OpenAI is the most commonly used. 
# MistralAI commercial API has launched recently and has a very good relationship with the Open-Source community, so we've added it as a challenger
# to compare OpenAI's cost effectiveness ("cost per point", ie, how many cents would you pay for 1pt in this benchmark)

## Imports
using JuliaLLMLeaderboard
using CairoMakie, AlgebraOfGraphics
using MarkdownTables, DataFramesMeta
using Statistics: mean, median, quantile;

## ! Configuration
SAVE_PLOTS = false
DIR_RESULTS = joinpath(pkgdir(JuliaLLMLeaderboard), "code_generation")
PAID_MODELS_DEFAULT = [
    "gpt-3.5-turbo",
    "gpt-3.5-turbo-1106",
    "gpt-4-1106-preview",
    "mistral-tiny",
    "mistral-small",
    "mistral-medium",
];
PAID_MODELS_ALL = ["gpt-3.5-turbo", "gpt-3.5-turbo-1106", "gpt-4-1106-preview",
    "mistral-tiny", "mistral-small", "mistral-medium",
    "gpt-3.5-turbo--optim", "gpt-3.5-turbo-1106--optim", "gpt-4-1106-preview--optim",
    "mistral-tiny--optim", "mistral-small--optim", "mistral-medium--optim"];
PROMPTS = [
    "JuliaExpertCoTTask",
    "JuliaExpertAsk",
    "InJulia",
    "JuliaRecapTask",
    "JuliaRecapCoTTask",
];

# ## Load Latest Results
# Use only the 5 most recent evaluations available for each definition/model/prompt
df = load_evals(DIR_RESULTS; max_history = 5);

# ## Model Comparison

# Highest average score by model:
output = @chain df begin
    @rsubset :model in PAID_MODELS_DEFAULT
    @rsubset :prompt_label in PROMPTS
    @by [:model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    @orderby -:score
    @aside local order_ = _.model
    data(_) *
    mapping(:model => sorter(order_) => "Model",
        :score => "Avg. Score (Max 100 pts)") * visual(BarPlot; bar_labels = :y,
        label_offset = 0)
    draw(;
        axis = (limits = (nothing, nothing, 0, 100),
            xticklabelrotation = 45,
            title = "Paid APIs Performance [PRELIMINARY]"))
end

# Table:
output = @chain df begin
    @rsubset :model in PAID_MODELS_DEFAULT
    @rsubset :prompt_label in PROMPTS
    @by [:model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
        :count_zero_score = count(iszero, :score)
        :count_full_score = count(isone, :score)
    end
    transform(_,
        [:elapsed, :score] .=> ByRow(x -> round(x, digits = 1)),
        renamecols = false)
    @rtransform :cost_cents = round(:cost * 100; digits = 2)
    select(Not(:cost))
    @orderby -:score
end
formatted = markdown_table(output, String)
## formatted |> clipboard
formatted

# ## Overview by Prompt Template

# Bar chart with all paid models and various prompt templates
fig = @chain df begin
    @rsubset :model in PAID_MODELS_DEFAULT
    @rsubset :prompt_label in PROMPTS
    @by [:model, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :cnt = $nrow
    end
    @aside local average_ = @by(_, :model, :avg=mean(:score)) |>
                            x -> @orderby(x, -:avg).model
    data(_) *
    mapping(:model => sorter(average_) => "Model",
        :score => "Avg. Score (Max 100 pts)",
        color = :prompt_label => "Prompts",
        dodge = :prompt_label) * visual(BarPlot)
    draw(;
        axis = (xticklabelrotation = 45, title = "Comparison for Paid APIs [PRELIMINARY]"))
end
SAVE_PLOTS && save("assets/model-prompt-comparison-paid.png", fig)
fig

# Table:
output = @chain df begin
    @rsubset :model in PAID_MODELS_DEFAULT
    @rsubset :prompt_label in PROMPTS
    @by [:model, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :model :AverageScore=mean(:score) |> x -> round(x, digits = 1)
    unstack(:model, :prompt_label, :score; fill = 0.0)
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :model)
    @orderby -:AverageScore
end
formatted = markdown_table(output, String)
## formatted |> clipboard
formatted

# ## Other Considerations

# Comparison of Cost vs Average Score
fig = @chain df begin
    @rsubset :model in PAID_MODELS_DEFAULT
    @rsubset :prompt_label in PROMPTS
    @by [:model, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :cnt = $nrow
    end
    data(_) * mapping(:cost => (x -> x * 100) => "Avg. Cost (US Cents/query)",
        :score => "Avg. Score (Max 100 pts)",
        color = :model => "Model")
    draw(; axis = (xticklabelrotation = 45, title = "Cost vs Score [PRELIMINARY]"))
end
SAVE_PLOTS && save("assets/paid-cost-vs-score-scatter.png", fig)
fig

# Table:
fig = @chain df begin
    @rsubset :model in PAID_MODELS_DEFAULT
    @rsubset :prompt_label in PROMPTS
    @by [:model, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score_avg = mean(:score)
        :score_median = median(:score)
        :cnt = $nrow
    end
    @rtransform :point_per_cent = :score_avg / :cost / 100
    @orderby -:point_per_cent
    ## 
    transform(_,
        names(_, Not(:model, :prompt_label, :cost)) .=> ByRow(x -> round(x, digits = 1)),
        renamecols = false)
    @rtransform :cost_cents = round(:cost * 100; digits = 2)
    select(Not(:cost))
end
formatted = markdown_table(output, String)
## formatted |> clipboard
formatted