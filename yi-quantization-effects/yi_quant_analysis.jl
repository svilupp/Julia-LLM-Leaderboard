# # Report for Quantization Effects on Yi34b
# This report summarizes how the performance on LLM Leaderboard changes with different quantizations of Yi34b model
# 
# Different quantizations have been benchmarked against Julia LLM Leaderboard (v0.2.0, 14 test cases).
#
# Hardware: 4x NVIDIA RTX 4090 (Thank you, [01.ai](https://github.com/01-ai)!)
# Backend: Ollama v0.1.22
# Frontend: PromptingTools.jl v0.10

using JuliaLLMLeaderboard
using DataFramesMeta
using CairoMakie, AlgebraOfGraphics, MarkdownTables
using Statistics

## ! Configuration
SAVE_PLOTS = false
SAVE_DIR = joinpath(@__DIR__);
RESULTS_DIR = SAVE_DIR;

# # Load Results
# Load all available evals
df = @chain begin
    load_evals(RESULTS_DIR; max_history = 0)
end;

# # Default Parameters
# These results are produced with default parameters set on Ollama (includes `temperature=0.7`)
df_default = @chain df begin
    @rsubset :experiment == "yi-quantization-effects-default"
end;

# ## Model Comparison
# Highest average score by model:
fig = @chain df_default begin
    @by [:model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    @orderby -:score
    data(_) *
    mapping(:model => sorter(order_) => "Model Weights Type",
        :score => "Avg. Score (Max 100 pts)") *
    visual(BarPlot; bar_labels = :y, label_offset = 0)
    draw(;
        figure = (; size = (900, 600)),
        legend = (; position = :bottom),
        axis = (;
            limits = (nothing, nothing, 0, 100),
            xticklabelrotation = 45,
            title = "Yi34b Performance on Temp=0.7"))
end
SAVE_PLOTS && save(joinpath(SAVE_DIR, "model-comparison-default.png"), fig)
fig

# Table:
output = @chain df_default begin
    @by [:model] begin
        :elapsed = mean(:elapsed_seconds)
        :elapsed_median = median(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :score_std_deviation = std(:score)
        :count_zero_score = count(iszero, :score)
        :count_full_score = count(==(100), :score)
    end
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    @orderby -:score
    rename(_, names(_) .|> unscrub_string)
end
## markdown_table(output, String) |> clipboard
markdown_table(output)

# ## Overview by Prompt Template

# Bar chart with all OSS models and various prompt templates
fig = @chain df_default begin
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
    mapping(:model => sorter(average_) => "Model Weights Type",
        :score => "Avg. Score (Max 100 pts)",
        color = :prompt_label => "Prompts",
        dodge = :prompt_label) * visual(BarPlot)
    draw(; figure = (size = (900, 600),),
        axis = (xticklabelrotation = 45, title = "Comparison for OSS Models"),
        legend = (; position = :bottom))
end
SAVE_PLOTS && save(joinpath(SAVE_DIR, "model-prompt-comparison-default.png"), fig)
fig

# Table:
output = @chain df_default begin
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
## markdown_table(output, String) |> clipboard
markdown_table(output)

# TODO: add the other temperatures and then show all together

# # End
@chain df begin
    # @rsubset :model=="yi:34b-chat-q3_K_L" :prompt_label=="JuliaExpertCoTTask"
    @by [:model] begin
        :score = mean(:score)
        :count_zero = count(==(0), :score)
        :count_full = count(==(100), :score)
        :count = $nrow
    end
    @orderby -:score
end
output = @chain df begin
    @rsubset :experiment == "yi-quantization-effects-default"
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
output = @chain df begin
    @rsubset :experiment == "yi-quantization-effects-default"
    @by [:name, :model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :name :AverageScore=mean(:score) |> x -> round(x, digits = 1)
    unstack(:name, :model, :score; fill = 0.0)
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :name)
    @orderby -:AverageScore
end