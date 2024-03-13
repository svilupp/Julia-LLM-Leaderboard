
# # Evaluate results
using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools
using CairoMakie, AlgebraOfGraphics
using MarkdownTables, DataFramesMeta
using Statistics: mean, median, quantile, std;

# ! Config
SAVE_PLOTS = false
DIR_RESULTS = @__DIR__

# # Load data
df = load_evals("experiments/cheater-7b-finetune"; max_history = 0)
df_all = load_evals("code_generation"; max_history = 0)

df_combined = @chain df begin
    @rtransform :model = :model ==
                         "cognitivecomputations/dolphin-2.6-mistral-7b-dpo-laser" ?
                         "dolphin-2.6-mistral" : :model
    vcat(_, @rsubset(df_all, :model=="gpt-4-1106-preview"), cols = :intersect)
end

# ## Model Comparison

# Highest average score by model:
fig = @chain df_combined begin
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
        :score => "Avg. Score (Max 100 pts)") *
    visual(BarPlot; bar_labels = :y,
        label_offset = 0)
    draw(;
        axis = (limits = (nothing, nothing, 0, 100),
            xticklabelrotation = 45,
            title = "Cheater-7b Performance"))
end
SAVE_PLOTS && save(joinpath(DIR_RESULTS, "model-comparison.png"), fig)
fig

# Table:
output = @chain df_combined begin
    @by [:model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
        :score_std_deviation = std(:score)
        :count_zero_score = count(iszero, :score)
        :count_full_score = count(==(100), :score)
    end
    transform(_,
        [:elapsed, :score, :score_std_deviation] .=> ByRow(x -> round(x, digits = 1)),
        renamecols = false)
    @rtransform :cost_cents = round(:cost * 100; digits = 2)
    select(Not(:cost))
    @orderby -:score
    rename(_, names(_) .|> unscrub_string)
end
## markdown_table(output, String) |> clipboard
markdown_table(output)

# ## Overview by Prompt Template

# Bar chart with all paid models and various prompt templates
fig = @chain df_combined begin
    @by [:model, :name] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :cnt = $nrow
    end
    @aside local average_ = @by(_, :name, :avg=mean(:score)) |>
                            x -> @orderby(x, -:avg).name
    data(_) *
    mapping(:name => sorter(average_) => "Test Case",
        :score => "Avg. Score (Max 100 pts)",
        color = :model => "Model",
        dodge = :model) * visual(BarPlot)
    draw(;
        figure = (size = (800, 600),),
        axis = (xticklabelrotation = 45, title = "Test Case Comparison"))
end
SAVE_PLOTS && save(joinpath(DIR_RESULTS, "test-case-comparison.png"), fig)
fig

# Table:
output = @chain df_combined begin
    @by [:model, :name] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :name :AverageScore=mean(:score) |> x -> round(x, digits = 1)
    unstack(:name, :model, :score; fill = 0.0)
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :name)
    @orderby -:AverageScore
    select(Not(:AverageScore))
end
## markdown_table(output, String) |> clipboard
markdown_table(output)