```@meta
EditURL = "../../../examples/summarize_results_test_cases_waitlist.jl"
```

# Results by Test Cases - WAITLIST

Preview of test cases on the waitlist, to be added to the main evaluation.

In this note, we preview each test case and highlight the highest the best performing model for it.

Reminder: The below scores are on a scale 0-100, where 100 is the best possible score and 0 means the generated code was not even parseable.

````julia
# Imports
using JuliaLLMLeaderboard
using CairoMakie, AlgebraOfGraphics
using MarkdownTables, DataFramesMeta, Markdown
using Statistics: mean, median, quantile;
unscrub_string(s::AbstractString) = split(s, "_") .|> titlecase |> x -> join(x, " ");

# ! Configuration
SAVE_PLOTS = false
DIR_RESULTS = joinpath(pkgdir(JuliaLLMLeaderboard), "code_generation_waitlist")
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
````

## Load Results
Use only the 5 most recent evaluations available for each definition/model/prompt

````julia
df = load_evals(DIR_RESULTS; max_history = 5);
fn_definitions = find_definitions(DIR_RESULTS);

````

There are currently 3 test cases.

## Tabular Overview
Overview of all test cases, sorted by average score and with the winning model highlighted (separated by Paid vs Open-Source)

````julia
# Pre-aggregate winning models
top_model = @chain df begin
    # remove qwen models as they are not correct!
    @rsubset !occursin("qwen", :model)
    @rsubset !endswith(:model, "--optim")
    @by [:model, :name] :score=mean(:score)
    @rtransform :is_paid = :model in PAID_MODELS_DEFAULT
    @orderby -:score
    combine(first, groupby(_, [:name, :is_paid]))
    @rtransform :winner = "$(:model) ($(round(:score;digits=1)))"
    select(Not(:model, :score))
end
# Aggregate by test case
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
````

```@raw html
<div><div style = "float: left;"><span>3×8 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "header"><th class = "rowNumber" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">Name</th><th style = "text-align: left;">Average Score</th><th style = "text-align: left;">Average Elapsed</th><th style = "text-align: left;">Count Zero Score</th><th style = "text-align: left;">Count Full Score</th><th style = "text-align: left;">Count Samples</th><th style = "text-align: left;">Paid Winner</th><th style = "text-align: left;">Oss Winner</th></tr><tr class = "subheader headerLastRow"><th class = "rowNumber" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Union{Missing, String}" style = "text-align: left;">String?</th><th title = "Union{Missing, String}" style = "text-align: left;">String?</th></tr></thead><tbody><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">find_mean</td><td style = "text-align: right;">79.6</td><td style = "text-align: right;">8.4</td><td style = "text-align: right;">9</td><td style = "text-align: right;">94</td><td style = "text-align: right;">150</td><td style = "text-align: left;">mistral-small-2402 (91.7)</td><td style = "font-style: italic; text-align: left;">missing</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">find_median</td><td style = "text-align: right;">64.2</td><td style = "text-align: right;">8.5</td><td style = "text-align: right;">8</td><td style = "text-align: right;">4</td><td style = "text-align: right;">150</td><td style = "text-align: left;">gpt-4-0125-preview (81.3)</td><td style = "font-style: italic; text-align: left;">missing</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">find_mode</td><td style = "text-align: right;">63.5</td><td style = "text-align: right;">8.9</td><td style = "text-align: right;">12</td><td style = "text-align: right;">19</td><td style = "text-align: right;">150</td><td style = "text-align: left;">claude-3-opus-20240229 (77.8)</td><td style = "font-style: italic; text-align: left;">missing</td></tr></tbody></table></div>
```

## Individual Test Cases

````julia
io = IOBuffer()
for fn in fn_definitions
    # fn = fn_definitions[1]
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
    # Paid model winner
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
    # OSS winner
    # winner = @chain df begin
    #     @rsubset !any(startswith.(:model, PAID_MODELS_DEFAULT)) && :prompt_label in PROMPTS
    #     @rsubset :name == d["name"]
    #     @by :model begin
    #         :score = mean(:score)
    #         :elapsed = mean(:elapsed_seconds)
    #         :count_zero_score = count(iszero, :score)
    #         :count_full_score = count(==(100), :score)
    #         :cnt = $nrow
    #     end
    #     @orderby -:score
    #     first
    # end
    # println(io,
    #     "**Winning Locally-hosted Model:** \"$(winner.model)\" with average score $(round(winner.score;digits=1)) (Full score: $(winner.count_full_score)/$(winner.cnt), Zero score: $(winner.count_zero_score)/$(winner.cnt)) \n")
    println(io, "\n")
end
MD(String(take!(io)))
````

### Test Case: `find_mean`

- Definition file: `code_generation_waitlist/statistics/find_mean/definition.toml`
- Prompt: "Write a function `find_mean`. It computes the weighted mean of array `A` with weight vector `w`. Provide an example"
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: Test
- Defined examples: 4
- Defined unit tests: 5
- Reference solution: 

`````julia
function find_mean(data::AbstractVector, weights::AbstractVector)
    @assert length(data) == length(weights) "Data and weights must have the same length"
    
    total_weight = sum(weights)
    @assert total_weight != 0 "Total weight cannot be zero"
    
    sum_product = sum(data .* weights)
    
    return sum_product / total_weight
end

`````

**Winning Paid Model:** "mistral-small-2402" with average score 91.7 (Full score: 21/25, Zero score: 0/25) 



### Test Case: `find_median`

- Definition file: `code_generation_waitlist/statistics/find_median/definition.toml`
- Prompt: "Write a function `find`. It computes median over arbitrary array. Provide an example"
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: Test, Statistics
- Defined examples: 4
- Defined unit tests: 10
- Reference solution: 

`````julia
function find_median(v::AbstractVector)
    isempty(v) && throw(ArgumentError("median of an empty array is undefined."))
    eltype(v)>:Missing && any(ismissing, v) && return missing
    any(x -> x isa Number && isnan(x), v) && return convert(eltype(v), NaN)
    inds = axes(v, 1)
    n = length(inds)
    mid = div(first(inds)+last(inds),2)
    if isodd(n)
        return middle(partialsort!(v,mid))
    else
        m = partialsort!(v, mid:mid+1)
        return middle(m[1], m[2])
    end
end

`````

**Winning Paid Model:** "gpt-4-0125-preview" with average score 81.3 (Full score: 1/25, Zero score: 1/25) 



### Test Case: `find_mode`

- Definition file: `code_generation_waitlist/statistics/find_mode/definition.toml`
- Prompt: "Write a function `find_mode`. It computes mode over arbitrary array. Provide an example"
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: Test
- Defined examples: 4
- Defined unit tests: 4
- Reference solution: 

`````julia
function find_mode(a::AbstractArray{T}) where T
    isempty(a) && error("mode: input array cannot be empty.")
    cnts = Dict{T,Int}()
    # first element
    mc = 1
    mv = a[1]
    cnts[mv] = 1
    # find the mode along with table construction
    for i = 2 : length(a)
        @inbounds x = a[i]
        if haskey(cnts, x)
            c = (cnts[x] += 1)
            if c > mc
                mc = c
                mv = x
            end
        else
            cnts[x] = 1
            # in this case: c = 1, and thus c > mc won't happen
        end
    end
    return mv
end

`````

**Winning Paid Model:** "claude-3-opus-20240229" with average score 77.8 (Full score: 2/25, Zero score: 0/25) 





---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

