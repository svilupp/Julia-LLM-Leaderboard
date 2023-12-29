```@meta
EditURL = "../../../examples/summarize_results_test_cases.jl"
```

# Results by Test Cases

We currently have a few test cases across 2 categories: `data_analysis` and `utility_functions` (see folder `code_generation/`).

In this note, we preview each test case and highlight the highest performing model.

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
````

## Load Results
Use only the 5 most recent evaluations available for each definition/model/prompt

````julia
df = load_evals(DIR_RESULTS; max_history = 5);
fn_definitions = find_definitions(DIR_RESULTS);

````

````
There are currently 14 test cases.

````

## Tabular Overview

````julia
@chain df begin
    @rsubset :prompt_label in PROMPTS
    @by :name begin
        :score = mean(:score)
        :elapsed = mean(:elapsed_seconds)
        :count_zero_score = count(iszero, :score)
        :count_full_score = count(==(100), :score)
    end
    rename(_, names(_) .|> unscrub_string)
end
````

```@raw html
<div><div style = "float: left;"><span>14×5 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "header"><th class = "rowNumber" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">Name</th><th style = "text-align: left;">Score</th><th style = "text-align: left;">Elapsed</th><th style = "text-align: left;">Count Zero Score</th><th style = "text-align: left;">Count Full Score</th></tr><tr class = "subheader headerLastRow"><th class = "rowNumber" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Int64" style = "text-align: left;">Int64</th></tr></thead><tbody><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">add_yearmonth</td><td style = "text-align: right;">39.2758</td><td style = "text-align: right;">18.3196</td><td style = "text-align: right;">134</td><td style = "text-align: right;">39</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">audi_filter</td><td style = "text-align: right;">33.5417</td><td style = "text-align: right;">19.2347</td><td style = "text-align: right;">176</td><td style = "text-align: right;">33</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">count_model_rows</td><td style = "text-align: right;">45.068</td><td style = "text-align: right;">15.9486</td><td style = "text-align: right;">128</td><td style = "text-align: right;">75</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">weather_data_analyzer</td><td style = "text-align: right;">49.448</td><td style = "text-align: right;">22.0742</td><td style = "text-align: right;">148</td><td style = "text-align: right;">25</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">FloatWithUnits</td><td style = "text-align: right;">56.7578</td><td style = "text-align: right;">13.7847</td><td style = "text-align: right;">139</td><td style = "text-align: right;">285</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">clean_column</td><td style = "text-align: right;">54.791</td><td style = "text-align: right;">12.1748</td><td style = "text-align: right;">122</td><td style = "text-align: right;">162</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">event_scheduler</td><td style = "text-align: right;">39.1506</td><td style = "text-align: right;">21.5854</td><td style = "text-align: right;">155</td><td style = "text-align: right;">22</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">extract_julia_code</td><td style = "text-align: right;">43.9372</td><td style = "text-align: right;">18.0414</td><td style = "text-align: right;">158</td><td style = "text-align: right;">15</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">ispersonal</td><td style = "text-align: right;">37.7761</td><td style = "text-align: right;">17.3132</td><td style = "text-align: right;">106</td><td style = "text-align: right;">94</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: left;">keep_only_names</td><td style = "text-align: right;">55.925</td><td style = "text-align: right;">13.1114</td><td style = "text-align: right;">106</td><td style = "text-align: right;">121</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">11</td><td style = "text-align: left;">pig_latinify</td><td style = "text-align: right;">31.5346</td><td style = "text-align: right;">22.8135</td><td style = "text-align: right;">152</td><td style = "text-align: right;">0</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">12</td><td style = "text-align: left;">q_and_a_extractor</td><td style = "text-align: right;">40.9944</td><td style = "text-align: right;">20.6472</td><td style = "text-align: right;">155</td><td style = "text-align: right;">1</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">13</td><td style = "text-align: left;">timezone_bumper</td><td style = "text-align: right;">61.8519</td><td style = "text-align: right;">15.7282</td><td style = "text-align: right;">73</td><td style = "text-align: right;">198</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">14</td><td style = "text-align: left;">wrap_string</td><td style = "text-align: right;">54.8465</td><td style = "text-align: right;">17.8363</td><td style = "text-align: right;">99</td><td style = "text-align: right;">27</td></tr></tbody></table></div>
```

## Test Cases

````julia
io = IOBuffer()
for fn in fn_definitions
    # fn = fn_definitions[1]
    d = load_definition(fn)["code_generation"]

    println(io, "### Test Case: $(d["name"])")
    println(io)
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
    println(io, "\n")
end
MD(String(take!(io)))
````

### Test Case: add_yearmonth

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "Given a DataFrame `df` with column `dt` representing DateTimes. Write a function `add_yearmonth` that creates a new column `ym` by extracting year and month from `dt` and concatenating them together as an integer in format: “yyyymm”."
- Allowed imports: DataFrames, Dates
- Defined examples: 4
- Defined unit tests: 4
- Reference solution: 
```julia
using DataFrames, Dates

function add_yearmonth(df::DataFrame)
    return transform(df, :dt => ByRow(dt -> year(dt) * 100 + month(dt)) => :ym)
end

```

**Winning Paid API:** gpt-4-1106-preview with score 72.8 

**Winning Locally-hosted model:** TBU 



### Test Case: audi_filter

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "You are given a DataFrame `df_cars` with car data with columns `manufacturer` and `model`. Write a function audi_filter that filters down the dataset to only the rows with manufacturer “audi” and model being “a4 or “a4 quattro”, then it should create a new column `audi_a4_type` that equals `true` across all rows. Then return the resulting DataFrame."
- Allowed imports: DataFrames
- Defined examples: 2
- Defined unit tests: 5
- Reference solution: 
```julia
using DataFrames

function audi_filter(df::DataFrame)
    # Filter for Audi A4 and Audi A4 Quattro
    filtered_df = filter(row -> row.manufacturer == "audi" && (row.model == "a4" || row.model == "a4 quattro"), eachrow(df)) |> DataFrame
    # Add new column
    filtered_df.audi_a4_type .= true
    return filtered_df
end

```

**Winning Paid API:** gpt-3.5-turbo-1106 with score 58.0 

**Winning Locally-hosted model:** TBU 



### Test Case: count_model_rows

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "Given a DataFrame df_cars with column `model`, write a function `count_model_rows` that groups data by model and calculate how many rows there are for each."
- Allowed imports: DataFrames
- Defined examples: 2
- Defined unit tests: 5
- Reference solution: 
```julia
using DataFrames

function count_model_rows(df::DataFrame)
    grouped_df = groupby(df, :model)
    return combine(grouped_df, nrow => :count)
end

```

**Winning Paid API:** gpt-4-1106-preview with score 98.4 

**Winning Locally-hosted model:** TBU 



### Test Case: weather_data_analyzer

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "You are given a list of daily temperature data `temps` (numbers). Write a function `weather_data_analyzer` that performs statistical analyses on this data (use `Statistics` package). The function should return results in named tuple (construct it with `(; key1=value1,key2=value2)` syntax) containing the `average`, `max`, `min` temperatures, and a `trend` (can be only: `:increasing`, `:decreasing`, or `:stable`). If the list is empty, the function should return a named tuple with all values set to `nothing`."
- Allowed imports: Statistics
- Defined examples: 5
- Defined unit tests: 5
- Reference solution: 
```julia
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

```

**Winning Paid API:** mistral-medium with score 85.4 

**Winning Locally-hosted model:** TBU 



### Test Case: FloatWithUnits

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "Given a struct `FloatWithUnits` with fields `value` and `unit` (make sure to define it!), write a `show` method for it that will concatenate the value and unit with a space like this "1.8 meters"."
- Allowed imports: 
- Defined examples: 2
- Defined unit tests: 3
- Reference solution: 
```julia
struct FloatWithUnits
    value::Float64
    unit::String
end
Base.show(io::IO, f::FloatWithUnits) = print(io, f.value, " ", f.unit)

```

**Winning Paid API:** mistral-medium with score 93.0 

**Winning Locally-hosted model:** TBU 



### Test Case: clean_column

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "Write a function `clean_column` that cleans a column name (`col`) by lowercasing it, stripping any leading or trailing whitespaces, and replacing any spaces and hyphens with an underscore, eg, "My Column" becomes "my_column"."
- Allowed imports: 
- Defined examples: 3
- Defined unit tests: 5
- Reference solution: 
```julia
function clean_column(col)
    return lowercase(col) |> strip |> x -> replace(x, r"[\s-]" => "_")
end

```

**Winning Paid API:** gpt-4-1106-preview with score 90.5 

**Winning Locally-hosted model:** TBU 



### Test Case: event_scheduler

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "You are given a list of events where each event is a tuple with a start and a finish time (in the format 'YYYY-MM-DD HH:MM'). Write a function `event_scheduler` that checks for any scheduling conflicts among the events. The function should return "No conflicts" if there are no overlapping events and "Conflict" if any events overlap in time. If the list is empty, return "No events". Use package Dates for parsing."
- Allowed imports: Dates
- Defined examples: 5
- Defined unit tests: 5
- Reference solution: 
```julia
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

```

**Winning Paid API:** gpt-4-1106-preview with score 63.6 

**Winning Locally-hosted model:** TBU 



### Test Case: extract_julia_code

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "You are provided a markdown document `md` with julia language code blocks. Write a function `extract_julia_code` that extracts all the code blocks, removes code fences and joins the code blocks (if there are multiple) together with a newline. Return a String. Do not provide any examples."
- Allowed imports: 
- Defined examples: 4
- Defined unit tests: 5
- Reference solution: 
```julia
function extract_julia_code(md::AbstractString)
    code_blocks = eachmatch(r"```julia
(.*?)
```"s, md)
    join([code.captures[1] for code in code_blocks], "
")
end

```

**Winning Paid API:** mistral-medium with score 71.2 

**Winning Locally-hosted model:** TBU 



### Test Case: ispersonal

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "Write a function `ispersonal` that returns a trait if the provided Vehicle type is a personal vehicle for everyday driving. All vehicles are subtypes of AbstractVehicle. Function must work for types: Car, Motorcycle, Bus, Truck. The first two should return true, the latter two should return false . The function should default to false for any other subtype of AbstractVehicle. Provide an example."
- Allowed imports: 
- Defined examples: 4
- Defined unit tests: 5
- Reference solution: 
```julia
abstract type AbstractVehicle end

struct Car <: AbstractVehicle end
struct Motorcycle <: AbstractVehicle end
struct Bus <: AbstractVehicle end
struct Truck <: AbstractVehicle end

ispersonal(vehicle::AbstractVehicle) = false
ispersonal(vehicle::Union{Car,Motorcycle}) = true

```

**Winning Paid API:** gpt-3.5-turbo-1106 with score 68.6 

**Winning Locally-hosted model:** TBU 



### Test Case: keep_only_names

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "Write a function `keep_only_names` which iterates over the provided list of words (`words`) and removes all words that do not start with a capital letter (eg, remove "dog" but keep "Dog")."
- Allowed imports: 
- Defined examples: 4
- Defined unit tests: 5
- Reference solution: 
```julia
function keep_only_names(words)
    return filter(word -> isuppercase(first(word)), words)
end

```

**Winning Paid API:** gpt-4-1106-preview with score 91.0 

**Winning Locally-hosted model:** TBU 



### Test Case: pig_latinify

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "Write a pig latin transformer called `pig_latinify` that operates on a vector of strings. It iterates over each string and changes it to pig latin. Each iteration should run on a separate thread."
- Allowed imports: Base.Threads
- Defined examples: 4
- Defined unit tests: 5
- Reference solution: 
```julia
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

```

**Winning Paid API:** gpt-4-1106-preview with score 56.1 

**Winning Locally-hosted model:** TBU 



### Test Case: q_and_a_extractor

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "You are given a markdown-formatted text `md`. Write a function `q_and_a_extractor` to extract all text in the markdown sections Question and Answer (starting with `# Question` and `# Answer`, respectively) and return the answer in a tuple like `(question,answer)`. Strip any leading spaces and newlines from the extracted text."
- Allowed imports: 
- Defined examples: 3
- Defined unit tests: 5
- Reference solution: 
```julia
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

```

**Winning Paid API:** gpt-4-1106-preview with score 69.0 

**Winning Locally-hosted model:** TBU 



### Test Case: timezone_bumper

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "Write a function `timezone_bumper(dt,bump)` that increases any provided timestamp by `bump::Int` hours (defaults to +3 hours). Make sure it works only for DateTime types and throws an error for Date types."
- Allowed imports: Dates
- Defined examples: 5
- Defined unit tests: 5
- Reference solution: 
```julia
using Dates

function timezone_bumper(timestamp::DateTime, bump::Int=3)
    return timestamp + Hour(bump)
end


```

**Winning Paid API:** mistral-medium with score 97.0 

**Winning Locally-hosted model:** TBU 



### Test Case: wrap_string

- Evaluation criteria: parsed, executed, passed_unit_tests, executed_examples
- Definition: "Write a function `wrap_string`. It iterates over words and it will add a new line each time a maximum `text_width::Int=10` would be exceeded. Provide an example"
- Allowed imports: 
- Defined examples: 2
- Defined unit tests: 6
- Reference solution: 
```julia
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

```

**Winning Paid API:** gpt-4-1106-preview with score 97.8 

**Winning Locally-hosted model:** TBU 





---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

