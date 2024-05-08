# # Results by Prompt Templates
# What prompt you use can sometimes matter more than the model. 
# Here we compare the performance of various prompt templates in PromptingTools.jl package.
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
    "gemini-1.0-pro-latest",
    "deepseek-chat",
    "deepseek-coder"
];
PROMPTS = [
    "JuliaExpertCoTTask",
    "JuliaExpertAsk",
    "InJulia",
    "JuliaRecapTask",
    "JuliaRecapCoTTask"
];

# ## Load Results
# Use only the 5 most recent evaluations available for each definition/model/prompt
df = @chain begin
    load_evals(DIR_RESULTS; max_history = 5)
    @rsubset :prompt_label in PROMPTS
    ## remove qwen models as they are not correct!
    @rsubset !occursin("qwen", :model)
end;

# ## Overview of Prompt Templates
# We've added an "AsIs" prompt template, which is just the raw task definition (nothing added). 
# As you can see below, it's pretty bad, because the models fail to detect from the context that they should produce Julia code.
# In short, always use a prompt template, even if it's just a simple one.

# Show scatter plot elapsed / score, where prompts are separated by different colors.
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
        color = :prompt_label => "Prompt")
    draw(; figure = (size = (600, 600),),
        axis = (xticklabelrotation = 45,
            title = "Elapsed Time vs Score by Prompt [PRELIMINARY]",
            limits = (xlims..., nothing, nothing)),
        palettes = (; color = Makie.ColorSchemes.tab20.colors))
end
SAVE_PLOTS && save("assets/elapsed-vs-score-scatter-prompts.png", fig)
fig

# A few learnings so far: 
#
# - Never use the "AsIs" prompt (ie, raw task definition). ALWAYS add some context around the language, situation, etc.
# - Even a simple "In Julia, answer XYZ" prompt can be quite effective. Note that the bigger prompts ("CoT" stands for Chain of Thought) might be confusing the smaller models, hence why this prompt is so effective on average.

# Table:
output = @chain df begin
    @by [:prompt_label] begin
        :elapsed = mean(:elapsed_seconds)
        :elapsed_median = median(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
    end
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    @orderby -:score
    rename("prompt_label" => "Prompt Template",
        "score" => "Avg. Score (Max 100 pts)",
        "elapsed_median" => "Elapsed (s, median)",
        "elapsed" => "Elapsed (s, average)",
        "score_median" => "Median Score (Max 100 pts)")
end
## markdown_table(output, String) |> clipboard
markdown_table(output)
