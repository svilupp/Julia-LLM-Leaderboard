# # Results for Claude Models
#
# The below captures the performance of the Claude models on normal prompts vs XML-formatted prompts.
#
# Reminder: The below scores are on a scale 0-100, where 100 is the best possible score and 0 means the generated code was not even parseable.

## Imports
using JuliaLLMLeaderboard
using CairoMakie, AlgebraOfGraphics
using MarkdownTables, DataFramesMeta
using Statistics: mean, median, quantile, std;

## ! Configuration
SAVE_PLOTS = false
DIR_RESULTS = joinpath(pkgdir(JuliaLLMLeaderboard), "code_generation")
PROMPTS = [
    "JuliaExpertCoTTask",
    "JuliaExpertAsk",
    "JuliaExpertCoTTaskXML",
    "JuliaExpertAskXML"
];

# ## Load Latest Results
# Use only the 10 most recent evaluations available for each definition/model/prompt
df = @chain begin
    load_evals(DIR_RESULTS; max_history = 10)
    @rsubset occursin("claude-3", :model) && :prompt_label in PROMPTS
end;

# ## Overview by Prompt Template

# Bar chart with Claude models and selected prompt templates
fig = @chain df begin
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
        axis = (
            xticklabelrotation = 45, title = "Comparison of Prompts Templates for Claude"))
end
SAVE_PLOTS && save("assets/claude-prompt-comparison-paid.png", fig)
fig

# Table:
output = @chain df begin
    @by [:model, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :model :AverageScore=mean(:score) |> x -> round(x, digits = 1)
    unstack(:model, :prompt_label, :score; fill = missing)
    ## transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :model)
    @orderby -:AverageScore
end
## markdown_table(output, String) |> clipboard
markdown_table(output)