# # Results for Open-Source LLM Models
#
# The below captures the benchmark performance of the open-source models. Most of these were run through Ollama.ai on a consumer-grade laptop.
#
# Please note that the below models vary in their "open-source-ness" (what has been actually released) and their licencing terms (what they can be used for).
# Be careful - some of the below models are for research purposes only (eg, Microsoft Phi).
#
# Reminder: The below scores are on a scale 0-100, where 100 is the best possible score and 0 means the generated code was not even parseable.

## Imports
using JuliaLLMLeaderboard
using CairoMakie, AlgebraOfGraphics
using MarkdownTables, DataFramesMeta
using Statistics: mean, median, quantile, std;
unscrub_string(s::AbstractString) = split(s, "_") .|> titlecase |> x -> join(x, " ");

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
MODEL_SIZES = Dict("orca2:13b" => "10-29",
    "mistral:7b-instruct-v0.2-q4_0" => "4-9",
    "nous-hermes2:34b-yi-q4_K_M" => ">30",
    "starling-lm:latest" => "4-9",
    "dolphin-phi:2.7b-v2.6-q6_K" => "<4",
    "stablelm-zephyr" => "<4",
    "codellama:13b-python" => "10-29",
    "magicoder:7b-s-cl-q6_K" => "4-9",
    "phi:2.7b-chat-v2-q6_K" => "<4",
    "magicoder" => "4-9",
    "mistral:7b-instruct-q4_K_M" => "4-9",
    "solar:10.7b-instruct-v1-q4_K_M" => "10-29",
    "codellama:13b-instruct" => "10-29",
    "openhermes2.5-mistral" => "4-9",
    "llama2" => "4-9",
    "yi:34b-chat" => ">30",
    "deepseek-coder:33b-instruct-q4_K_M" => ">30",
    "phind-codellama:34b-v2" => ">30",
    "openchat:7b-v3.5-1210-q4_K_M" => "4-9",
    "mistral:7b-instruct-v0.2-q6_K" => "4-9",
    "mistral:7b-instruct-v0.2-q4_K_M" => "4-9")
PROMPTS = [
    "JuliaExpertCoTTask",
    "JuliaExpertAsk",
    "InJulia",
    "JuliaRecapTask",
    "JuliaRecapCoTTask",
];

# ## Load Results
# Use only the 5 most recent evaluations available for each definition/model/prompt
df = @chain begin
    load_evals(DIR_RESULTS; max_history = 5)
    @rsubset !any(startswith.(:model, PAID_MODELS_DEFAULT)) && :prompt_label in PROMPTS
end;

# ## Model Comparison

# Highest average score by model:
fig = @chain df begin
    @by [:model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    @orderby -:score
    @rtransform :size_group = MODEL_SIZES[:model]
    @aside local size_order = ["<4", "4-9", "10-29", ">30"]
    @aside local order_ = _.model
    data(_) *
    mapping(:model => sorter(order_) => "Model",
        :score => "Avg. Score (Max 100 pts)",
        color = :size_group => sorter(size_order) => "Parameter Size (Bn)") *
    visual(BarPlot; bar_labels = :y, label_offset = 0)
    draw(;
        figure = (; size = (900, 600)),
        legend = (; position = :bottom),
        axis = (;
            limits = (nothing, nothing, 0, 100),
            xticklabelrotation = 45,
            title = "Open-Source LLM Model Performance"))
end
SAVE_PLOTS && save("assets/model-comparison-oss.png", fig)
fig

# Table:
output = @chain df begin
    @by [:model] begin
        :elapsed = mean(:elapsed_seconds)
        :elapsed_median = mean(:elapsed_seconds)
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

# Note that our sample size is low, so the rankings could easily change (we have high standard deviations of the estimated means).
# That the results only as indicative.

# ## Overview by Prompt Template

# Bar chart with all OSS models and various prompt templates
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
    draw(; figure = (size = (900, 600),),
        axis = (xticklabelrotation = 45, title = "Comparison for OSS Models"),
        legend = (; position = :bottom))
end
SAVE_PLOTS && save("assets/model-prompt-comparison-oss.png", fig)
fig

# Table:
output = @chain df begin
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

# ## Other Considerations

# Comparison of Time-to-generate vs Average Score
fig = @chain df begin
    @aside local xlims = quantile(df.elapsed_seconds, [0.01, 0.99])
    @by [:model, :prompt_label] begin
        :elapsed = mean(:elapsed_seconds)
        :elapsed_median = median(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :cnt = $nrow
    end
    data(_) * mapping(:elapsed => "Avg. Elapsed Time (s)",
        :score => "Avg. Score (Max 100 pts)",
        color = :model => "Model")
    draw(; figure = (size = (800, 800),),
        axis = (xticklabelrotation = 45,
            title = "Elapsed Time vs Score for OSS Models",
            limits = (xlims..., nothing, nothing)),
        palettes = (; color = Makie.ColorSchemes.tab20.colors))
end
SAVE_PLOTS && save("assets/elapsed-vs-score-scatter-oss.png", fig)
fig

# Table:
# - Point per second is the average score divided by the average elapsed time
output = @chain df begin
    @by [:model, :prompt_label] begin
        :elapsed = mean(:elapsed_seconds)
        :elapsed_median = median(:elapsed_seconds)
        :score_avg = mean(:score)
        :score_median = median(:score)
        :cnt = $nrow
    end
    @rtransform :point_per_second = :score_avg / :elapsed
    @orderby -:point_per_second
    ## 
    transform(_,
        names(_, Not(:model, :prompt_label)) .=> ByRow(x -> round(x, digits = 1)),
        renamecols = false)
    rename(_, names(_) .|> unscrub_string)
end
## markdown_table(output, String) |> clipboard
markdown_table(output)