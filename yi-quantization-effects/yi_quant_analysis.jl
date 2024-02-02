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
SAVE_PLOTS = true
SAVE_DIR = joinpath(@__DIR__);
RESULTS_DIR = SAVE_DIR;

# # Load Results
# Load all available evals
df = @chain begin
    load_evals(RESULTS_DIR; max_history = 0)
end;

# # Default Parameters
# These results are produced with default parameters set on Ollama (includes `temperature=0.7`)
df_focus = @chain df begin
    @rsubset :experiment == "yi-quantization-effects-default"
end;
temp = 0.7

# ## Model Comparison
# Highest average score by model:
fig = @chain df_focus begin
    @by [:model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    @orderby -:score
    @aside local order_ = _.model
    data(_) *
    mapping(:model => sorter(order_) => "Model Weights",
        :score => "Avg. Score (Max 100 pts)") *
    visual(BarPlot; bar_labels = :y, label_offset = 0)
    draw(;
        figure = (; size = (900, 600)),
        legend = (; position = :bottom),
        axis = (;
            limits = (nothing, nothing, 0, 100),
            xticklabelrotation = 45,
            title = "Yi34b Performance on Temp=$temp"))
end
SAVE_PLOTS && save(joinpath(SAVE_DIR, "model-comparison-temp($temp).png"), fig)
fig

# Table:
output = @chain df_focus begin
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
fig = @chain df_focus begin
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
    mapping(:model => sorter(average_) => "Model Weights",
        :score => "Avg. Score (Max 100 pts)",
        color = :prompt_label => "Prompts",
        dodge = :prompt_label) * visual(BarPlot)
    draw(; figure = (size = (900, 600),),
        axis = (xticklabelrotation = 45, title = "Yi34b Performance on Temp=$temp"),
        legend = (; position = :bottom))
end
SAVE_PLOTS && save(joinpath(SAVE_DIR, "model-prompt-comparison-temp($temp).png"), fig)
fig

# Table:
output = @chain df_focus begin
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

# ## Overview by Test Case
output = @chain df_focus begin
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

# # Temperature=0.3
# These results are produced with temperature set to `0.3` on Ollama
df_focus = @chain df begin
    @rsubset :experiment == "yi-quantization-effects-temp0.3"
end;
temp = 0.3

# ## Model Comparison
# Highest average score by model:
fig = @chain df_focus begin
    @by [:model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    @orderby -:score
    @aside local order_ = _.model
    data(_) *
    mapping(:model => sorter(order_) => "Model Weights",
        :score => "Avg. Score (Max 100 pts)") *
    visual(BarPlot; bar_labels = :y, label_offset = 0)
    draw(;
        figure = (; size = (900, 600)),
        legend = (; position = :bottom),
        axis = (;
            limits = (nothing, nothing, 0, 100),
            xticklabelrotation = 45,
            title = "Yi34b Performance on Temp=$temp"))
end
SAVE_PLOTS && save(joinpath(SAVE_DIR, "model-comparison-temp($temp).png"), fig)
fig

# Table:
output = @chain df_focus begin
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
fig = @chain df_focus begin
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
    mapping(:model => sorter(average_) => "Model Weights",
        :score => "Avg. Score (Max 100 pts)",
        color = :prompt_label => "Prompts",
        dodge = :prompt_label) * visual(BarPlot)
    draw(; figure = (size = (900, 600),),
        axis = (xticklabelrotation = 45, title = "Yi34b Performance on Temp=$temp"),
        legend = (; position = :bottom))
end
SAVE_PLOTS && save(joinpath(SAVE_DIR, "model-prompt-comparison-temp($temp).png"), fig)
fig

# Table:
output = @chain df_focus begin
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

# ## Overview by Test Case
output = @chain df_focus begin
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

# # Temperature=0.5
# These results are produced with temperature set to `0.5` on Ollama
df_focus = @chain df begin
    @rsubset :experiment == "yi-quantization-effects-temp0.5"
end;
temp = 0.5

# ## Model Comparison
# Highest average score by model:
fig = @chain df_focus begin
    @by [:model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    @orderby -:score
    @aside local order_ = _.model
    data(_) *
    mapping(:model => sorter(order_) => "Model Weights",
        :score => "Avg. Score (Max 100 pts)") *
    visual(BarPlot; bar_labels = :y, label_offset = 0)
    draw(;
        figure = (; size = (900, 600)),
        legend = (; position = :bottom),
        axis = (;
            limits = (nothing, nothing, 0, 100),
            xticklabelrotation = 45,
            title = "Yi34b Performance on Temp=$temp"))
end
SAVE_PLOTS && save(joinpath(SAVE_DIR, "model-comparison-temp($temp).png"), fig)
fig

# Table:
output = @chain df_focus begin
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
fig = @chain df_focus begin
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
    mapping(:model => sorter(average_) => "Model Weights",
        :score => "Avg. Score (Max 100 pts)",
        color = :prompt_label => "Prompts",
        dodge = :prompt_label) * visual(BarPlot)
    draw(; figure = (size = (900, 600),),
        axis = (xticklabelrotation = 45, title = "Yi34b Performance on Temp=$temp"),
        legend = (; position = :bottom))
end
SAVE_PLOTS && save(joinpath(SAVE_DIR, "model-prompt-comparison-temp($temp).png"), fig)
fig

# Table:
output = @chain df_focus begin
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

# ## Overview by Test Case
output = @chain df_focus begin
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

# # Comparison Across Temperatures

fig = @chain df begin
    @by [:experiment, :model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :cnt = $nrow
    end
    ## drop models without samples
    @transform groupby(_, :model) :cnt_experiments=unique(:experiment) |> length
    @rsubset :cnt_experiments > 1
    select(Not(:cnt_experiments))
    @aside local average_ = @by(_, :model, :avg=mean(:score)) |>
                            x -> @orderby(x, -:avg).model
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    data(_) *
    mapping(:model => sorter(average_) => "Model Weights",
        :score => "Avg. Score (Max 100 pts)",
        color = :experiment => "Prompts",
        dodge = :experiment) * visual(BarPlot; bar_labels = :y,
        label_offset = 0)
    draw(; figure = (size = (800, 600),),
        axis = (xticklabelrotation = 0, title = "Yi34b Performance Across Temperatures"),
        legend = (; position = :bottom))
end
SAVE_PLOTS && save(joinpath(SAVE_DIR, "model-temperature-comparison.png"), fig)
fig

output = @chain df begin
    @by [:experiment, :model] begin
        :elapsed = mean(:elapsed_seconds)
        :elapsed_median = median(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :score_std_deviation = std(:score)
        :count_zero_score = count(iszero, :score)
        :count_full_score = count(==(100), :score)
    end
    ## drop models without samples
    @transform groupby(_, :model) :cnt_experiments=unique(:experiment) |> length
    @rsubset :cnt_experiments > 1
    select(Not(:cnt_experiments))
    @rtransform :experiment = split(:experiment, "-")[end] |> titlecase
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    @orderby -:score
    rename(_, names(_) .|> unscrub_string)
end
## markdown_table(output, String) |> clipboard
markdown_table(output)

# # Comparison with Prompt in Chinese
# Only compares:
# - prompt template: "JuliaExpertAsk" (translated to Chinese -> "JuliaExpertAskZH")
# - test case: "wrap_string" 
# - temperature: 0.7

df_zh = @chain df begin
    vcat(load_evals(joinpath(RESULTS_DIR, "..", "yi-quantization-effects-zh");
        max_history = 0))
    ## we have samples only for default temp
    @rsubset endswith(:experiment, "-default") startswith(:prompt_label, "JuliaExpertAsk") :name=="wrap_string"
    @rtransform :experiment = occursin("zh", :experiment) ? "Chinese" : "English"
end;

# ## Experiment Comparison
# Table:
output = @chain df_zh begin
    @by [:experiment] begin
        :elapsed = mean(:elapsed_seconds)
        :elapsed_median = median(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :score_std_deviation = std(:score)
        :count_zero_score = count(iszero, :score)
        :count_full_score = count(==(100), :score)
        :count_samples = $nrow
    end
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    @orderby -:score
    rename(_, names(_) .|> unscrub_string)
end
## markdown_table(output, String) |> clipboard
markdown_table(output)

# ## Overview by Model Weights

# Bar chart with all OSS models and various prompt templates
fig = @chain df_zh begin
    @by [:model, :experiment] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :cnt = $nrow
    end
    @aside local average_ = @by(_, :model, :avg=mean(:score)) |>
                            x -> @orderby(x, -:avg).model
    data(_) *
    mapping(:model => sorter(average_) => "Model Weights",
        :score => "Avg. Score (Max 100 pts)",
        color = :experiment => "Prompts",
        dodge = :experiment) * visual(BarPlot)
    draw(; figure = (size = (900, 600),),
        axis = (xticklabelrotation = 45,
            title = "Yi34b Performance in English vs Chinese"),
        legend = (; position = :bottom))
end
SAVE_PLOTS && save(joinpath(SAVE_DIR, "model-comparison-english-chinese.png"), fig)
fig

# Table:
output = @chain df_zh begin
    @by [:model, :experiment] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :model :AverageScore=mean(:score) |> x -> round(x, digits = 1)
    unstack(:model, :experiment, :score; fill = 0.0)
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :model)
    @orderby -:AverageScore
end
## markdown_table(output, String) |> clipboard
markdown_table(output)

# # The End