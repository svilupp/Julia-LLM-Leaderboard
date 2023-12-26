# # Summary of Benchmark Results

## Imports
using JuliaLLMLeaderboard
using CairoMakie, AlgebraOfGraphics, DataFramesMeta
using MarkdownTables
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

# # Load Results
# Use only the latest evaluation available for each definition/model/prompt
df = load_evals(DIR_RESULTS; max_history = 3);

# ## Paid Models

# By Model / Prompt 
# Table:
output = @chain df begin
    @rsubset :model in PAID_MODELS_DEFAULT
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

# Plot:
fig = @chain df begin
    @rsubset :model in PAID_MODELS_DEFAULT
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

# Cost vs Score
fig = @chain df begin
    @rsubset :model in PAID_MODELS_DEFAULT
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

# ## OSS Models

# By Model / Prompt 
# Table:
output = @chain df begin
    @rsubset :model ∉ PAID_MODELS_ALL
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

# Plot:
fig = @chain df begin
    @rsubset :model ∉ PAID_MODELS_ALL
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

# ## Per model
# Models, points, elapsed, cost, 
# TODO: add more thorough analysis -- trade off speed vs score and cost vs score

# ## Per prompt (same model)
# Apply Median to elapsed
output = @chain df begin
    ## @rsubset :model in PAID_MODELS_ALL
    @by [:prompt_label] begin
        :elapsed = mean(:elapsed_seconds)
        :elapsed_median = median(:elapsed_seconds)
        :score = mean(:score)
    end
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    @orderby -:score
    rename("prompt_label" => "Prompt Template",
        "elapsed_median" => "Elapsed (s, median)",
        "score" => "Avg. Score (Max 100 pts)")
end
formatted = markdown_table(output, String)
## formatted |> clipboard
formatted

# Show scatter plot elapsed / score, where model is a color
fig = @chain df begin
    @aside local xlims = quantile(df.elapsed_seconds, [0.01, 0.99])
    @rsubset !occursin("--optim", :model)
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
    draw(; figure = (size = (600, 600),),
        axis = (xticklabelrotation = 45,
            title = "Elapsed Time vs Score [PRELIMINARY]",
            limits = (xlims..., nothing, nothing)),
        palettes = (; color = Makie.ColorSchemes.tab20.colors))
end
SAVE_PLOTS && save("assets/all-elapsed-vs-score-scatter.png", fig)
fig
