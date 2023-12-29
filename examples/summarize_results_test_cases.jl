# # Results by Test Cases
# 
# We currently have a few test cases across 2 categories: `data_analysis` and `utility_functions` (see folder `code_generation/`).
#
# In this note, we preview each test case and highlight the highest performing model.
#
# Reminder: The below scores are on a scale 0-100, where 100 is the best possible score and 0 means the generated code was not even parseable.

## Imports
using JuliaLLMLeaderboard
using CairoMakie, AlgebraOfGraphics
using MarkdownTables, DataFramesMeta, Markdown
using Statistics: mean, median, quantile;
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
fn_definitions = find_definitions(DIR_RESULTS);

println("There are currently $(length(fn_definitions)) test cases.") #hide

# ## Tabular Overview

@chain df begin
    @rsubset :prompt_label in PROMPTS
    @by :name begin
        :score = mean(:score)
        :elapsed = mean(:elapsed_seconds)
        :count_zero_score = count(iszero, :score)
        :count_full_score = count(==(100), :score)
    end
end

# ## Test Cases

for fn in fn_definitions
    ## fn = fn_definitions[1]
    d = load_definition(fn)["code_generation"]

    io = IOBuffer()
    println(io, "### Test Case: $(d["name"])")
    println(io, "- Evaluation criteria: $(join(d["criteria"],", "))")
    println(io, "- Definition: \"$(d["prompt"])\"")
    println(io, "- Allowed imports: $(join(d["imports"],", "))")
    println(io, "- Defined examples: $(length(get(d,"examples",[])))")
    println(io, "- Defined unit tests: $(length(get(d,"unit_tests",[])))")
    println(io, "- Reference solution: \n```julia\n$(d["reference_solution"])\n```\n")
    winner = @chain df begin
        @rsubset :model in PAID_MODELS_DEFAULT && :prompt_label in PROMPTS
        @rsubset :name == d["name"]
        @by :model begin
            :score = mean(:score)
            :elapsed = mean(:elapsed_seconds)
            :count_zero_score = count(iszero, :score)
            :count_full_score = count(==(100), :score)
        end
        @orderby -:score
        first
    end
    println(io,
        "**Winning Paid API:** $(winner.model) with score $(round(winner.score;digits=1)) \n")
    println(io, "**Winning Locally-hosted model:** TBU \n")

    String(take!(io)) |> Markdown.parse |> print
end
