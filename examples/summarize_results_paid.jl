# # Results for Paid LLM APIs
#
# The below captures the performance of 3 models from two commercial LLM APIs: OpenAI (GPT-3.5 Turbo, GPT-4, ...) and MistralAI (tiny, small, medium).
#
# There are many other providers, but OpenAI is the most commonly used. 
# MistralAI commercial API has launched recently and has a very good relationship with the Open-Source community, so we've added it as a challenger
# to compare OpenAI's cost effectiveness ("cost per point", ie, how many cents would you pay for 1pt in this benchmark)
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
PAID_MODELS_DEFAULT = [
    "gpt-3.5-turbo",
    "gpt-3.5-turbo-1106",
    "gpt-3.5-turbo-0125",
    "gpt-4-1106-preview",
    "gpt-4-0125-preview",
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
    "claude-2.1",
    "gemini-1.0-pro-latest"
];
PROMPTS = [
    "JuliaExpertCoTTask",
    "JuliaExpertAsk",
    "InJulia",
    "JuliaRecapTask",
    "JuliaRecapCoTTask"
];

# ## Load Latest Results
# Use only the 10 most recent evaluations available for each definition/model/prompt
df = @chain begin
    load_evals(DIR_RESULTS; max_history = 10)
    @rsubset :model in PAID_MODELS_DEFAULT && :prompt_label in PROMPTS
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
    @aside local order_ = _.model
    data(_) *
    mapping(:model => sorter(order_) => "Model",
        :score => "Avg. Score (Max 100 pts)") *
    visual(BarPlot; bar_labels = :y,
        label_offset = 0)
    draw(;
        axis = (limits = (nothing, nothing, 0, 100),
            xticklabelrotation = 45,
            title = "Paid APIs Performance"))
end
SAVE_PLOTS && save("assets/model-comparison-paid.png", fig)
fig

# Table:
output = @chain df begin
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

# While the victory of GPT-4 is not surprising, note that the our sample size is small and the standard deviation is quite high.

# ## Overview by Prompt Template

# Bar chart with all paid models and various prompt templates
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
        figure = (; size = (900, 600)),
        axis = (xticklabelrotation = 45, title = "Comparison for Paid APIs"))
end
SAVE_PLOTS && save("assets/model-prompt-comparison-paid.png", fig)
fig

# Table:
# - Surprised by the low performance of some models (eg, GPT 3.5 Turbo) on the CoT prompts? It's because the model accidentally sends a "stop" token before it writes the code.
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

# Comparison of Cost vs Average Score
fig = @chain df begin
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
    draw(;
        axis = (xticklabelrotation = 45,
            title = "Cost vs Score for Paid APIs"))
end
SAVE_PLOTS && save("assets/cost-vs-score-scatter-paid.png", fig)
fig

# Table:
# - Point per cent is the average score divided by the average cost in US cents
output = @chain df begin
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
    rename(_, names(_) .|> unscrub_string)
end
## markdown_table(output, String) |> clipboard
markdown_table(output)

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
    draw(; figure = (size = (600, 600),),
        axis = (xticklabelrotation = 45,
            title = "Elapsed Time vs Score for Paid APIs",
            limits = (xlims..., nothing, nothing)),
        palettes = (; color = Makie.ColorSchemes.tab20.colors))
end
SAVE_PLOTS && save("assets/elapsed-vs-score-scatter-paid.png", fig)
fig

# Table:
# - Point per second is the average score divided by the average elapsed time
output = @chain df begin
    @by [:model, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score_avg = mean(:score)
        :score_median = median(:score)
        :cnt = $nrow
    end
    @rtransform :point_per_second = :score_avg / :elapsed
    @orderby -:point_per_second
    ## 
    transform(_,
        names(_, Not(:model, :prompt_label, :cost)) .=> ByRow(x -> round(x, digits = 1)),
        renamecols = false)
    @rtransform :cost_cents = round(:cost * 100; digits = 2)
    select(Not(:cost))
    rename(_, names(_) .|> unscrub_string)
end
## markdown_table(output, String) |> clipboard
markdown_table(output)

# ## Test Case Performance

# Performance of different models across each test case
output = @chain df begin
    @by [:model, :name] begin
        :score = mean(:score)
    end
    ## 
    @aside average_ = @by _ :name :AverageScore=mean(:score) |> x -> round(x, digits = 1)
    unstack(:name, :model, :score; fill = 0.0)
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :name)
    @orderby -:AverageScore
end
markdown_table(output)