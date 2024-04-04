# # Results by Test Cases
# 
# We currently have only a few test cases across 2 categories: `data_analysis` and `utility_functions` (see folder `code_generation/`).
#
# In this note, we preview each test case and highlight the highest the best performing model for it.
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
    "gemini-1.0-pro-latest"
];
PROMPTS = [
    "JuliaExpertCoTTask",
    "JuliaExpertAsk",
    "InJulia",
    "JuliaRecapTask",
    "JuliaRecapCoTTask",
    "JuliaExpertAskXML",
    "JuliaExpertCoTTaskXML"
];
struct MD #hide
    str::AbstractString #hide
end #hide
Base.show(io::IO, mime::MIME"text/markdown", md::MD) = print(io, md.str) #hide

# ## Load Results
# Use only the 5 most recent evaluations available for each definition/model/prompt
df = load_evals(DIR_RESULTS; max_history = 5);
fn_definitions = find_definitions(DIR_RESULTS);

MD("There are currently $(length(fn_definitions)) test cases.") #hide

# ## Tabular Overview
# Overview of all test cases, sorted by average score and with the winning model highlighted (separated by Paid vs Open-Source)

## Pre-aggregate winning models
top_model = @chain df begin
    ## remove qwen models as they are not correct!
    @rsubset !occursin("qwen", :model)
    @rsubset !endswith(:model, "--optim")
    @by [:model, :name] :score=mean(:score)
    @rtransform :is_paid = :model in PAID_MODELS_DEFAULT
    @orderby -:score
    combine(first, groupby(_, [:name, :is_paid]))
    @rtransform :winner = "$(:model) ($(round(:score;digits=1)))"
    select(Not(:model, :score))
end
## Aggregate by test case
@chain df begin
    @rsubset :prompt_label in PROMPTS
    @by :name begin
        :average_score = mean(:score)
        :average_elapsed = mean(:elapsed_seconds)
        :count_zero_score = count(iszero, :score)
        :count_full_score = count(==(100), :score)
        :count_samples = $nrow
    end
    @rtransform :average_score=round(:average_score; digits = 1) :average_elapsed=round(
        :average_elapsed;
        digits = 1)
    leftjoin(_,
        @rsubset(top_model, :is_paid),
        on = [:name],
        validate = (true, true),
        makeunique = true)
    leftjoin(_,
        @rsubset(top_model, :is_paid==false),
        on = [:name],
        validate = (true, true),
        makeunique = true)
    select(Not(:is_paid, :is_paid_1))
    rename(:winner => :paid_winner, :winner_1 => :oss_winner)
    rename(_, names(_) .|> unscrub_string)
end

# ## Individual Test Cases

io = IOBuffer()
for fn in fn_definitions
    ## fn = fn_definitions[1]
    d = load_definition(fn)["code_generation"]

    println(io, "### Test Case: $("`"*(d["name"])*"`")")
    println(io)
    println(io, "- Definition file: `$(relpath(fn,pkgdir(JuliaLLMLeaderboard)))`")
    println(io, "- Prompt: \"$(d["prompt"])\"")
    println(io, "- Evaluation criteria: $(join("`".*d["criteria"].*"`",", "))")
    println(io, "- Allowed imports: $(join(d["imports"],", "))")
    println(io, "- Defined examples: $(length(get(d,"examples",[])))")
    println(io, "- Defined unit tests: $(length(get(d,"unit_tests",[])))")
    println(io, "- Reference solution: \n\n`````julia\n$(d["reference_solution"])\n`````\n")
    ## Paid model winner
    winner = @chain df begin
        @rsubset :model in PAID_MODELS_DEFAULT && :prompt_label in PROMPTS
        @rsubset :name == d["name"]
        @by :model begin
            :score = mean(:score)
            :elapsed = mean(:elapsed_seconds)
            :count_zero_score = count(iszero, :score)
            :count_full_score = count(==(100), :score)
            :cnt = $nrow
        end
        @orderby -:score
        first
    end
    println(io,
        "**Winning Paid Model:** \"$(winner.model)\" with average score $(round(winner.score;digits=1)) (Full score: $(winner.count_full_score)/$(winner.cnt), Zero score: $(winner.count_zero_score)/$(winner.cnt)) \n")
    ## OSS winner
    winner = @chain df begin
        @rsubset !any(startswith.(:model, PAID_MODELS_DEFAULT)) && :prompt_label in PROMPTS
        @rsubset :name == d["name"]
        @by :model begin
            :score = mean(:score)
            :elapsed = mean(:elapsed_seconds)
            :count_zero_score = count(iszero, :score)
            :count_full_score = count(==(100), :score)
            :cnt = $nrow
        end
        @orderby -:score
        first
    end
    println(io,
        "**Winning Locally-hosted Model:** \"$(winner.model)\" with average score $(round(winner.score;digits=1)) (Full score: $(winner.count_full_score)/$(winner.cnt), Zero score: $(winner.count_zero_score)/$(winner.cnt)) \n")
    println(io, "\n")
end
MD(String(take!(io)))