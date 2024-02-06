```@meta
EditURL = "../../../examples/summarize_results_test_cases.jl"
```

# Results by Test Cases

We currently have only a few test cases across 2 categories: `data_analysis` and `utility_functions` (see folder `code_generation/`).

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
];
PROMPTS = [
    "JuliaExpertCoTTask",
    "JuliaExpertAsk",
    "InJulia",
    "JuliaRecapTask",
    "JuliaRecapCoTTask",
];
````

## Load Results
Use only the 5 most recent evaluations available for each definition/model/prompt

````julia
df = load_evals(DIR_RESULTS; max_history = 5);
fn_definitions = find_definitions(DIR_RESULTS);

````

There are currently 14 test cases.

## Tabular Overview
Overview of all test cases, sorted by average score and with the winning model highlighted (separated by Paid vs Open-Source)

````julia
# Pre-aggregate winning models
top_model = @chain df begin
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
    @rtransform :average_score=round(:average_score; digits = 1) :average_elapsed=round(:average_elapsed;
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
<div><div style = "float: left;"><span>14×8 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "header"><th class = "rowNumber" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">Name</th><th style = "text-align: left;">Average Score</th><th style = "text-align: left;">Average Elapsed</th><th style = "text-align: left;">Count Zero Score</th><th style = "text-align: left;">Count Full Score</th><th style = "text-align: left;">Count Samples</th><th style = "text-align: left;">Paid Winner</th><th style = "text-align: left;">Oss Winner</th></tr><tr class = "subheader headerLastRow"><th class = "rowNumber" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Union{Missing, String}" style = "text-align: left;">String?</th><th title = "Union{Missing, String}" style = "text-align: left;">String?</th></tr></thead><tbody><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">timezone_bumper</td><td style = "text-align: right;">52.8</td><td style = "text-align: right;">12.2</td><td style = "text-align: right;">293</td><td style = "text-align: right;">314</td><td style = "text-align: right;">917</td><td style = "text-align: left;">mistral-medium (97.3)</td><td style = "text-align: left;">deepseek-coder:33b-instruct-q4_K_M (100.0)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">FloatWithUnits</td><td style = "text-align: right;">57.6</td><td style = "text-align: right;">11.1</td><td style = "text-align: right;">340</td><td style = "text-align: right;">474</td><td style = "text-align: right;">1027</td><td style = "text-align: left;">gpt-3.5-turbo-0125 (94.0)</td><td style = "text-align: left;">qwen:72b-chat-v1.5-q4_K_M (99.0)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">weather_data_analyzer</td><td style = "text-align: right;">44.3</td><td style = "text-align: right;">17.8</td><td style = "text-align: right;">373</td><td style = "text-align: right;">41</td><td style = "text-align: right;">975</td><td style = "text-align: left;">gpt-4-0125-preview (87.8)</td><td style = "text-align: left;">magicoder:7b-s-cl-q6_K (83.7)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">keep_only_names</td><td style = "text-align: right;">46.3</td><td style = "text-align: right;">10.2</td><td style = "text-align: right;">343</td><td style = "text-align: right;">182</td><td style = "text-align: right;">923</td><td style = "text-align: left;">gpt-4-0125-preview (85.2)</td><td style = "text-align: left;">magicoder:7b-s-cl-q6_K (83.3)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">wrap_string</td><td style = "text-align: right;">48.1</td><td style = "text-align: right;">14.2</td><td style = "text-align: right;">300</td><td style = "text-align: right;">44</td><td style = "text-align: right;">920</td><td style = "text-align: left;">gpt-4-0125-preview (93.7)</td><td style = "text-align: left;">magicoder:7b-s-cl-q6_K (83.3)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">clean_column</td><td style = "text-align: right;">49.5</td><td style = "text-align: right;">9.5</td><td style = "text-align: right;">303</td><td style = "text-align: right;">208</td><td style = "text-align: right;">956</td><td style = "text-align: left;">gpt-4-0125-preview (84.5)</td><td style = "text-align: left;">mistral:7b-instruct-v0.2-q4_0 (77.8)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">ispersonal</td><td style = "text-align: right;">35.1</td><td style = "text-align: right;">13.8</td><td style = "text-align: right;">341</td><td style = "text-align: right;">174</td><td style = "text-align: right;">925</td><td style = "text-align: left;">gpt-3.5-turbo-0125 (74.0)</td><td style = "text-align: left;">qwen:72b-chat-v1.5-q2_K (69.0)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">event_scheduler</td><td style = "text-align: right;">34.5</td><td style = "text-align: right;">17.4</td><td style = "text-align: right;">425</td><td style = "text-align: right;">53</td><td style = "text-align: right;">974</td><td style = "text-align: left;">gpt-4-0125-preview (94.4)</td><td style = "text-align: left;">phind-codellama:34b-v2 (62.2)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">q_and_a_extractor</td><td style = "text-align: right;">30.0</td><td style = "text-align: right;">16.3</td><td style = "text-align: right;">433</td><td style = "text-align: right;">0</td><td style = "text-align: right;">945</td><td style = "text-align: left;">gpt-4-1106-preview (47.6)</td><td style = "text-align: left;">magicoder:7b-s-cl-q6_K (54.4)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: left;">add_yearmonth</td><td style = "text-align: right;">35.4</td><td style = "text-align: right;">14.4</td><td style = "text-align: right;">362</td><td style = "text-align: right;">67</td><td style = "text-align: right;">980</td><td style = "text-align: left;">gpt-4-0125-preview (76.2)</td><td style = "text-align: left;">codellama:13b-instruct-q4_K_M (53.2)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: left;">pig_latinify</td><td style = "text-align: right;">25.3</td><td style = "text-align: right;">18.5</td><td style = "text-align: right;">390</td><td style = "text-align: right;">0</td><td style = "text-align: right;">921</td><td style = "text-align: left;">gpt-4-1106-preview (54.8)</td><td style = "text-align: left;">deepseek-coder:33b-instruct-q4_K_M (51.1)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: left;">audi_filter</td><td style = "text-align: right;">28.0</td><td style = "text-align: right;">15.1</td><td style = "text-align: right;">445</td><td style = "text-align: right;">49</td><td style = "text-align: right;">974</td><td style = "text-align: left;">gpt-3.5-turbo-0125 (60.0)</td><td style = "text-align: left;">nous-hermes2:34b-yi-q4_K_M (48.3)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">13</td><td style = "text-align: left;">count_model_rows</td><td style = "text-align: right;">38.2</td><td style = "text-align: right;">12.4</td><td style = "text-align: right;">363</td><td style = "text-align: right;">99</td><td style = "text-align: right;">975</td><td style = "text-align: left;">gpt-4-0125-preview (98.4)</td><td style = "text-align: left;">codellama:13b-instruct-q4_K_M (47.9)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">14</td><td style = "text-align: left;">extract_julia_code</td><td style = "text-align: right;">29.3</td><td style = "text-align: right;">13.5</td><td style = "text-align: right;">425</td><td style = "text-align: right;">0</td><td style = "text-align: right;">951</td><td style = "text-align: left;">gpt-4-0125-preview (51.6)</td><td style = "text-align: left;">yi:34b-chat (46.1)</td></tr></tbody></table></div>
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
````

### Test Case: `add_yearmonth`

- Definition file: `code_generation/data_analysis/add_yearmonth/definition.toml`
- Prompt: "Given a DataFrame `df` with column `dt` representing DateTimes. Write a function `add_yearmonth` that creates a new column `ym` by extracting year and month from `dt` and concatenating them together as an integer in format: “yyyymm”."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: DataFrames, Dates
- Defined examples: 4
- Defined unit tests: 4
- Reference solution: 

`````julia
using DataFrames, Dates

function add_yearmonth(df::DataFrame)
    return transform(df, :dt => ByRow(dt -> year(dt) * 100 + month(dt)) => :ym)
end

`````

**Winning Paid Model:** "gpt-4-0125-preview" with average score 76.2 (Full score: 11/25, Zero score: 0/25) 

**Winning Locally-hosted Model:** "codellama:13b-instruct-q4_K_M" with average score 53.2 (Full score: 4/25, Zero score: 5/25) 



### Test Case: `audi_filter`

- Definition file: `code_generation/data_analysis/audi_filter/definition.toml`
- Prompt: "You are given a DataFrame `df_cars` with car data with columns `manufacturer` and `model`. Write a function audi_filter that filters down the dataset to only the rows with manufacturer “audi” and model being “a4 or “a4 quattro”, then it should create a new column `audi_a4_type` that equals `true` across all rows. Then return the resulting DataFrame."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: DataFrames
- Defined examples: 2
- Defined unit tests: 5
- Reference solution: 

`````julia
using DataFrames

function audi_filter(df::DataFrame)
    # Filter for Audi A4 and Audi A4 Quattro
    filtered_df = filter(row -> row.manufacturer == "audi" && (row.model == "a4" || row.model == "a4 quattro"), eachrow(df)) |> DataFrame
    # Add new column
    filtered_df.audi_a4_type .= true
    return filtered_df
end

`````

**Winning Paid Model:** "gpt-3.5-turbo-0125" with average score 60.0 (Full score: 7/25, Zero score: 0/25) 

**Winning Locally-hosted Model:** "phind-codellama:34b-v2" with average score 53.5 (Full score: 6/20, Zero score: 3/20) 



### Test Case: `count_model_rows`

- Definition file: `code_generation/data_analysis/count_model_rows/definition.toml`
- Prompt: "Given a DataFrame df_cars with column `model`, write a function `count_model_rows` that groups data by model and calculate how many rows there are for each."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: DataFrames
- Defined examples: 2
- Defined unit tests: 5
- Reference solution: 

`````julia
using DataFrames

function count_model_rows(df::DataFrame)
    grouped_df = groupby(df, :model)
    return combine(grouped_df, nrow => :count)
end

`````

**Winning Paid Model:** "gpt-4-0125-preview" with average score 98.4 (Full score: 23/25, Zero score: 0/25) 

**Winning Locally-hosted Model:** "phind-codellama:34b-v2" with average score 49.9 (Full score: 4/20, Zero score: 3/20) 



### Test Case: `weather_data_analyzer`

- Definition file: `code_generation/data_analysis/weather_data_analyzer/definition.toml`
- Prompt: "You are given a list of daily temperature data `temps` (numbers). Write a function `weather_data_analyzer` that performs statistical analyses on this data (use `Statistics` package). The function should return results in named tuple (construct it with `(; key1=value1,key2=value2)` syntax) containing the `average`, `max`, `min` temperatures, and a `trend` (can be only: `:increasing`, `:decreasing`, or `:stable`). If the list is empty, the function should return a named tuple with all values set to `nothing`."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: Statistics
- Defined examples: 5
- Defined unit tests: 5
- Reference solution: 

`````julia
using Statistics

function weather_data_analyzer(temps)
    if isempty(temps)
        return (; average=nothing, max=nothing, min=nothing, trend=nothing)
    else
        average = mean(temps)
        max_temp = maximum(temps)
        min_temp = minimum(temps)
        trend = if all(diff(temps) .> 0)
            :increasing
        elseif all(diff(temps) .< 0)
            :decreasing
        else
            :stable
        end
        return (; average=average, max=max_temp, min=min_temp, trend=trend)
    end
end

`````

**Winning Paid Model:** "gpt-4-0125-preview" with average score 87.8 (Full score: 12/25, Zero score: 0/25) 

**Winning Locally-hosted Model:** "magicoder:7b-s-cl-q6_K" with average score 83.7 (Full score: 0/15, Zero score: 0/15) 



### Test Case: `FloatWithUnits`

- Definition file: `code_generation/utility_functions/FloatWithUnits/definition.toml`
- Prompt: "Given a struct `FloatWithUnits` with fields `value` and `unit` (make sure to define it!), write a `show` method for it that will concatenate the value and unit with a space like this "1.8 meters"."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: 
- Defined examples: 2
- Defined unit tests: 3
- Reference solution: 

`````julia
struct FloatWithUnits
    value::Float64
    unit::String
end
Base.show(io::IO, f::FloatWithUnits) = print(io, f.value, " ", f.unit)

`````

**Winning Paid Model:** "mistral-medium" with average score 98.0 (Full score: 23/25, Zero score: 0/25) 

**Winning Locally-hosted Model:** "qwen:72b-chat-v1.5-q4_K_M" with average score 99.0 (Full score: 24/25, Zero score: 0/25) 



### Test Case: `clean_column`

- Definition file: `code_generation/utility_functions/clean_column/definition.toml`
- Prompt: "Write a function `clean_column` that cleans a column name (`col`) by lowercasing it, stripping any leading or trailing whitespaces, and replacing any spaces and hyphens with an underscore, eg, "My Column" becomes "my_column"."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: 
- Defined examples: 3
- Defined unit tests: 5
- Reference solution: 

`````julia
function clean_column(col)
    return lowercase(col) |> strip |> x -> replace(x, r"[\s-]" => "_")
end

`````

**Winning Paid Model:** "gpt-4-1106-preview" with average score 90.5 (Full score: 11/25, Zero score: 0/25) 

**Winning Locally-hosted Model:** "mistral:7b-instruct-v0.2-q6_K" with average score 83.0 (Full score: 10/15, Zero score: 1/15) 



### Test Case: `event_scheduler`

- Definition file: `code_generation/utility_functions/event_scheduler/definition.toml`
- Prompt: "You are given a list of events where each event is a tuple with a start and a finish time (in the format 'YYYY-MM-DD HH:MM'). Write a function `event_scheduler` that checks for any scheduling conflicts among the events. The function should return "No conflicts" if there are no overlapping events and "Conflict" if any events overlap in time. If the list is empty, return "No events". Use package Dates for parsing."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: Dates
- Defined examples: 5
- Defined unit tests: 5
- Reference solution: 

`````julia
using Dates

function event_scheduler(events)
    if isempty(events)
        return "No events"
    end
    
    # Sort the events based on the start time
    sorted_events = sort(events, by = e -> Dates.DateTime(e[1], "yyyy-mm-dd HH:MM"))
    
    # Check for conflicts
    for i in 1:length(sorted_events)-1
        if Dates.DateTime(sorted_events[i][2], "yyyy-mm-dd HH:MM") > Dates.DateTime(sorted_events[i+1][1], "yyyy-mm-dd HH:MM")
            return "Conflict"
        end
    end
    
    return "No conflicts"
end

`````

**Winning Paid Model:** "gpt-4-0125-preview" with average score 94.4 (Full score: 15/25, Zero score: 0/25) 

**Winning Locally-hosted Model:** "phind-codellama:34b-v2" with average score 66.8 (Full score: 4/20, Zero score: 3/20) 



### Test Case: `extract_julia_code`

- Definition file: `code_generation/utility_functions/extract_julia_code/definition.toml`
- Prompt: "You are provided a markdown document `md` with julia language code blocks. Write a function `extract_julia_code` that extracts all the code blocks, removes code fences and joins the code blocks (if there are multiple) together with a newline. Return a String. Do not provide any examples."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: 
- Defined examples: 4
- Defined unit tests: 5
- Reference solution: 

`````julia
function extract_julia_code(md::AbstractString)
    code_blocks = eachmatch(r"```julia
(.*?)
```"s, md)
    join([code.captures[1] for code in code_blocks], "
")
end

`````

**Winning Paid Model:** "mistral-small" with average score 52.2 (Full score: 0/25, Zero score: 3/25) 

**Winning Locally-hosted Model:** "yi:34b-chat" with average score 53.0 (Full score: 0/20, Zero score: 2/20) 



### Test Case: `ispersonal`

- Definition file: `code_generation/utility_functions/ispersonal/definition.toml`
- Prompt: "Write a function `ispersonal` that returns a trait if the provided Vehicle type is a personal vehicle for everyday driving. All vehicles are subtypes of AbstractVehicle. Function must work for types: Car, Motorcycle, Bus, Truck. The first two should return true, the latter two should return false . The function should default to false for any other subtype of AbstractVehicle. Provide an example."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: 
- Defined examples: 4
- Defined unit tests: 5
- Reference solution: 

`````julia
abstract type AbstractVehicle end

struct Car <: AbstractVehicle end
struct Motorcycle <: AbstractVehicle end
struct Bus <: AbstractVehicle end
struct Truck <: AbstractVehicle end

ispersonal(vehicle::AbstractVehicle) = false
ispersonal(vehicle::Union{Car,Motorcycle}) = true

`````

**Winning Paid Model:** "gpt-3.5-turbo-0125" with average score 74.0 (Full score: 15/25, Zero score: 3/25) 

**Winning Locally-hosted Model:** "qwen:72b-chat-v1.5-q2_K" with average score 69.0 (Full score: 15/25, Zero score: 5/25) 



### Test Case: `keep_only_names`

- Definition file: `code_generation/utility_functions/keep_only_names/definition.toml`
- Prompt: "Write a function `keep_only_names` which iterates over the provided list of words (`words`) and removes all words that do not start with a capital letter (eg, remove "dog" but keep "Dog")."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: 
- Defined examples: 4
- Defined unit tests: 5
- Reference solution: 

`````julia
function keep_only_names(words)
    return filter(word -> isuppercase(first(word)), words)
end

`````

**Winning Paid Model:** "gpt-4-1106-preview" with average score 91.0 (Full score: 12/25, Zero score: 0/25) 

**Winning Locally-hosted Model:** "magicoder:7b-s-cl-q6_K" with average score 83.3 (Full score: 9/15, Zero score: 0/15) 



### Test Case: `pig_latinify`

- Definition file: `code_generation/utility_functions/pig_latinify/definition.toml`
- Prompt: "Write a pig latin transformer called `pig_latinify` that operates on a vector of strings. It iterates over each string and changes it to pig latin. Each iteration should run on a separate thread."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: Base.Threads
- Defined examples: 4
- Defined unit tests: 5
- Reference solution: 

`````julia
function to_pig_latin(word::AbstractString)
    vowels = "aeiouAEIOU"
    first_vowel_idx = findfirst(c -> c in vowels, word)
    if isnothing(first_vowel_idx) || first_vowel_idx == 1
        return word * "ay"
    else
        return word[first_vowel_idx:end] * word[1:first_vowel_idx-1] * "ay"
    end
end

function pig_latinify(words::Vector{<:AbstractString})
    transform = similar(words)
    Threads.@threads for i in 1:length(words)
        transform[i] = to_pig_latin(words[i])
    end
    return transform
end

`````

**Winning Paid Model:** "gpt-4-1106-preview" with average score 61.4 (Full score: 0/25, Zero score: 0/25) 

**Winning Locally-hosted Model:** "deepseek-coder:33b-instruct-q4_K_M" with average score 57.9 (Full score: 0/15, Zero score: 0/15) 



### Test Case: `q_and_a_extractor`

- Definition file: `code_generation/utility_functions/q_and_a_extractor/definition.toml`
- Prompt: "You are given a markdown-formatted text `md`. Write a function `q_and_a_extractor` to extract all text in the markdown sections Question and Answer (starting with `# Question` and `# Answer`, respectively) and return the answer in a tuple like `(question,answer)`. Strip any leading spaces and newlines from the extracted text."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: 
- Defined examples: 3
- Defined unit tests: 5
- Reference solution: 

`````julia
function q_and_a_extractor(md::AbstractString)
    question = match(r"(?<=# Question
).*?(?=
# [A-Za-z]+|$)"s, md)
    answer = match(r"(?<=# Answer
).*?(?=
# [A-Za-z]+|$)"s, md)

    return (question === nothing ? "" : strip(question.match)),
    (answer === nothing ? "" : strip(answer.match))
end

`````

**Winning Paid Model:** "gpt-4-1106-preview" with average score 53.3 (Full score: 0/25, Zero score: 2/25) 

**Winning Locally-hosted Model:** "magicoder:7b-s-cl-q6_K" with average score 54.4 (Full score: 0/15, Zero score: 2/15) 



### Test Case: `timezone_bumper`

- Definition file: `code_generation/utility_functions/timezone_bumper/definition.toml`
- Prompt: "Write a function `timezone_bumper(dt,bump)` that increases any provided timestamp by `bump::Int` hours (defaults to +3 hours). Make sure it works only for DateTime types and throws an error for Date types."
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: Dates
- Defined examples: 5
- Defined unit tests: 5
- Reference solution: 

`````julia
using Dates

function timezone_bumper(timestamp::DateTime, bump::Int=3)
    return timestamp + Hour(bump)
end


`````

**Winning Paid Model:** "mistral-medium" with average score 97.0 (Full score: 22/25, Zero score: 0/25) 

**Winning Locally-hosted Model:** "deepseek-coder:33b-instruct-q4_K_M" with average score 100.0 (Full score: 15/15, Zero score: 0/15) 



### Test Case: `wrap_string`

- Definition file: `code_generation/utility_functions/wrap_string/definition.toml`
- Prompt: "Write a function `wrap_string`. It iterates over words and it will add a new line each time a maximum `text_width::Int=10` would be exceeded. Provide an example"
- Evaluation criteria: `parsed`, `executed`, `passed_unit_tests`, `executed_examples`
- Allowed imports: 
- Defined examples: 2
- Defined unit tests: 6
- Reference solution: 

`````julia
function wrap_string(text::AbstractString, text_width::Int=10)
    words = split(text)
    line_length = 0
    wrapped_text = ""
    num_words = length(words)
    for i in eachindex(words)
        word = words[i]
        # +1 for separator length for all but the last word
        sep_length = (i == num_words) ? 0 : 1
        if line_length + length(word) + sep_length > text_width
            wrapped_text *= "
"
            line_length = 0
        end
        wrapped_text *= word * " "
        line_length += length(word) + 1
    end
    return strip(wrapped_text)
end

`````

**Winning Paid Model:** "gpt-4-1106-preview" with average score 97.8 (Full score: 14/25, Zero score: 0/25) 

**Winning Locally-hosted Model:** "magicoder:7b-s-cl-q6_K" with average score 83.3 (Full score: 2/15, Zero score: 0/15) 





---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

