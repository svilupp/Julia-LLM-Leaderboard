## Imports
using Pkg;
Pkg.activate(Base.current_project());
using JuliaLLMLeaderboard
using CairoMakie, AlgebraOfGraphics
using MarkdownTables, DataFramesMeta
using Statistics: mean, median, quantile, std;

# Options
model_options = ["llama2", "llama3:8b", "codellama:13b", "magicoder:7b-s-cl-q6_K", "openhermes2.5-mistral", "starling-lm:latest", "yi:34b-chat",
    "codellama:13b-instruct", "magicoder", "stablelm-zephyr",
    "orca2:13b", "phind-codellama:34b-v2",
    "deepseek-coder:33b-instruct-q4_K_M", "solar:10.7b-instruct-v1-q4_K_M",
    "mistral:7b-instruct-q4_K_M", "openchat:7b-v3.5-1210-q4_K_M", "phi:2.7b-chat-v2-q6_K",
    "mistral:7b-instruct-v0.2-q6_K", "dolphin-phi:2.7b-v2.6-q6_K",
    "nous-hermes2:34b-yi-q4_K_M", "mistral:7b-instruct-v0.2-q4_0",
    "mistral:7b-instruct-v0.2-q4_K_M", "gemma:7b-instruct-q6_K"]

PROMPTS = [
    "JuliaExpertCoTTask",
    "JuliaExpertAsk",
    "InJulia",
    "JuliaRecapTask",
    "JuliaRecapCoTTask"
];

## ! Configuration
SAVE_PLOTS = true
DIR_RESULTS_MAIN = joinpath(@__DIR__, "..", "code_generation")
DIR_RESULTS_WAIT = @__DIR__
print(DIR_RESULTS_WAIT)

## Load Data
df_main = @chain begin
    load_evals(DIR_RESULTS_MAIN; max_history = 10)
    @rsubset :model in model_options && :prompt_label in PROMPTS
end;
df_wait = @chain begin
    load_evals(DIR_RESULTS_WAIT; max_history = 10)
    @rsubset :model in model_options && :prompt_label in PROMPTS
end;

## Keep only models and prompts that we have in df_main as well
df_compare = semijoin(df_main, df_wait, on = [:model, :prompt_label]);
## Merge into one DataFrame
df = vcat(@rtransform(df_compare, :source="Main"),
    @rtransform(df_wait, :source="Waitlist"); cols = :union)

# # Test Case Comparison
# Bar chart with the new vs old test cases
using CSV;
CSV.write("test.csv", df)
fig = @chain df begin
    @by [:name, :source] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :cnt = $nrow
    end
    @aside local average_ = @by(_, :name, :avg=mean(:score)) |>
                            x -> @orderby(x, -:avg).name
    data(_) *
    mapping(:name => sorter(average_) => "Test Cases",
        :score => "Avg. Score (Max 100 pts)",
        color = :source => "Source"        ## dodge = :source
    ) * visual(BarPlot)
    draw(;
        figure = (; size = (900, 600)),
        axis = (xticklabelrotation = 45, title = "Waitlisted Tests"))
end
SAVE_PLOTS && save("assets/waitlist-test-comparison-local.png", fig)
fig

# # Performance by Prompt
# Bar chart with the new vs old test cases by prompt template
fig = @chain df begin
    @by [:name, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :cnt = $nrow
    end
    @aside local average_ = @by(_, :name, :avg=mean(:score)) |>
                            x -> @orderby(x, -:avg).name
    data(_) *
    mapping(:name => sorter(average_) => "Test Cases",
        :score => "Avg. Score (Max 100 pts)",
        color = :prompt_label => "Prompt",
        dodge = :prompt_label) * visual(BarPlot)
    draw(;
        figure = (; size = (900, 600)),
        axis = (xticklabelrotation = 45, title = "Test Cases by Prompt"))
end
SAVE_PLOTS && save("assets/waitlist-test-prompt-comparison-local.png", fig)
fig

# Table
output = @chain df_wait begin
    @by [:name, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :name :AverageScore=mean(:score) |>
                                                x -> round(x, digits = 1)
    unstack(:name, :prompt_label, :score; fill = 0.0)
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :name)
    @orderby -:AverageScore
end

# # Performance by Model
# Show only test cases (too many models to show)
fig = @chain df_wait begin
    @by [:name, :model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
        :score_median = median(:score)
        :cnt = $nrow
    end
    @aside local average_ = @by(_, :name, :avg=mean(:score)) |>
                            x -> @orderby(x, -:avg).name
    data(_) *
    mapping(:name => sorter(average_) => "Test Cases",
        :score => "Avg. Score (Max 100 pts)",
        color = :model => "Model",
        dodge = :model) * visual(BarPlot)
    draw(;
        figure = (; size = (900, 600)),
        axis = (xticklabelrotation = 45, title = "Test Cases by Model"))
end
SAVE_PLOTS && save("assets/waitlist-test-model-comparison-local.png", fig)
fig

# Table
output = @chain df_wait begin
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
## markdown_table(output, String) |> clipboard
markdown_table(output)