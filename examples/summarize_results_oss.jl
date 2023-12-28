# # Summary of Open-Source LLM Models
# The below captures the benchmark performance of the open-source models. Most of these were run through Ollama.ai on a consumer-grade laptop.
# Please note that the below models vary in their "open-source-ness" (what has been actually released) and their licencing terms (what they can be used for).
# Be careful - some of the below models are for research purposes only (eg, Microsoft Phi).

## Imports
using JuliaLLMLeaderboard
using CairoMakie, AlgebraOfGraphics
using MarkdownTables, DataFramesMeta
using Statistics: mean, median, quantile

# ! Configuration
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

# ## Load Results
# Use only the 5 most recent evaluations available for each definition/model/prompt
df = load_evals(DIR_RESULTS; max_history = 5);

# ## Model Comparison

# Highest average score by model:
fig = @chain df begin
    @rsubset :model ∉ PAID_MODELS_ALL
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
        :score => "Avg. Score (Max 100 pts)") * visual(BarPlot; bar_labels = :y, label_offset = 0)
    draw(;
        figure = (; size = (900, 600)),
        axis = (;
            limits = (nothing, nothing, 0, 100),
            xticklabelrotation = 45,
            title = "Open-Source LLM Model Performance [PRELIMINARY]"))
end
fig

# Table:
output = @chain df begin
    @rsubset :model ∉ PAID_MODELS_ALL
    @rsubset :prompt_label in PROMPTS
    @by [:model] begin
        :elapsed = mean(:elapsed_seconds)
        :elapsed_median = mean(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :count_zero_score = count(iszero, :score)
        :count_full_score = count(isone, :score)
    end
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    @orderby -:score
end
formatted = markdown_table(output, String)
## formatted |> clipboard
formatted

# ## Overview by Prompt Template

# Bar chart with all OSS models and various prompt templates
fig = @chain df begin
    @rsubset :model ∉ PAID_MODELS_ALL
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
    draw(; figure = (size = (900, 600),),
        axis = (xticklabelrotation = 45, title = "Comparison for OSS Models [PRELIMINARY]"),
        legend = (; position = :bottom))
end
SAVE_PLOTS && save("assets/model-prompt-comparison-oss.png", fig)
fig

# Table:
output = @chain df begin
    @rsubset :model ∉ PAID_MODELS_ALL
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