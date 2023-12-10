# # Example Definition
# This is an example showing you how to create a `definition.toml` for a function/algorithm/test case.

# ## Import Packages
using JuliaLLMLeaderboard
using Test

# ## Configuration
# Change the second to last element to your function name
function_name = "wrap_string"

# Naming convention: code_generation / <category> / <function_name> / definition.toml
fn_definition = joinpath("code_generation", "utility_functions", function_name, "definition.toml")
mkpath(dirname(fn_definition)) # check that the path exists to avoid errors

# ## Reference Function (Optional)
# This makes it easier to develop the unit tests and examples.
# Still fails a few tests! So not perfect...
function wrap_string(text::String, text_width::Int=10)
    words = split(text)
    wrapped_text = ""
    current_line_length = 0

    for word in words
        if current_line_length + length(word) <= text_width
            wrapped_text *= (current_line_length == 0 ? "" : " ") * word
            current_line_length += length(word) + (current_line_length == 0 ? 0 : 1)
        else
            wrapped_text *= "\n" * word
            current_line_length = length(word)
        end
    end

    return wrapped_text
end

## Reference testset, easier to copy&paste like this
@testset "wrap_string" begin
    wrap_string("", 10) == ""
    @test wrap_string("Hi", 10) == "Hi"
    text = "This function will wrap words into lines"
    output = wrap_string("This function will wrap words into lines", 10)
    @test maximum(length.(split(output, "\n"))) <= 10
    output = wrap_string(text, 20)
    @test maximum(length.(split(output, "\n"))) <= 20
    @test wrap_string(text, length(text)) == text
end

# ## Create definition
# This is the `definition.toml` for the evaluation schema
#
# First key is always `code_generation` (there might be more test sets in the future)
#
# Fields:
# - `name` (required): the name of the test case --> must match the name of the function in the path, in the examples, in the prompt, in the unit tests!
# - `contributor` (required): your name/github handle
# - `version` (required): the version of the test case
# - `prompt` (required): the prompt to use for the test case. Make sure it refers to the function name for the examples and unit tests to run!
# - `criteria` (required): the criteria to use for the test case. Must be a subset of `["parsed", "executed", "passed_unit_tests", "executed_examples"]`
# - `examples` (required): the examples to use for the test case. Must be a vector of strings, which represent valid Julia expressions.
# - `unit_tests` (required): the unit tests to use for the test case. Must be a vector of strings, which represent valid unit tests annotated with `@test`.

d = Dict("code_generation" => Dict("name" => function_name,
    "contributor" => "svilupp",
    "version" => "1.0",
    # Notice that we refer to the function name in the prompt!
    "prompt" => "Write a function `wrap_string`. It iterates over words and it will add a new line each time a maximum `text_width::Int=10` would be exceed. Provide an example",
    "criteria" => ["parsed", "executed", "passed_unit_tests", "executed_examples"],
    "examples" => ["wrap_string(\"This function will wrap words into lines\")", "wrap_string(\"This function will wrap words into lines\", 15)"],
    "unit_tests" => [
        """@test wrap_string("", 10) == "" """,
        """@test wrap_string("Hi", 10) == "Hi" """,
        """
        output = wrap_string("This function will wrap words into lines", 10)
        @test maximum(length.(split(output, "\n"))) <= 10
        """,
        """
        output = wrap_string("This function will wrap words into lines", 20)
        @test maximum(length.(split(output, "\n"))) <= 20
        """,
        """@test wrap_string(text, length(text)) == text """,
        "imports" => ["Test"]
    ]))

## Save definition
save_definition(fn_definition, d)

# Check that it works
definition = load_definition(fn_definition)["code_generation"]

# And you're done! Now run the benchmark for it...

# # Working smart
# Do you want help developing your test case? Use the best GenAI models to help you!
#
# Start with your prompt
prompt = "Write a function `wrap_string`. It iterates over words and it will add a new line each time a maximum `text_width::Int=10` would be exceed. Provide an example"

# make sure it's the same as in the prompt above!
function_name = "wrap_string"
fn_definition = joinpath("code_generation", "utility_functions", function_name, "definition.toml")
mkpath(dirname(fn_definition)) # check that the path exists to avoid errors

# Add some extras to also get the tests (and ideally not too verbose)
prompt_extras = "Provide 3-5 unit tests with `@test`, make the unit tests as terse as possible while testing the correct functionality."
msg = aigenerate(:JuliaExpertAsk; ask=prompt * prompt_extras, model="gpt4t")
preview(msg)# show preview in REPL

# Steps:
# - Copy out the function definition, the examples and unit tests. 
# - Make sure they run as expected (sometimes it takes 1-2 tweaks even for GPT-4)
# - Add """ fences to create string inputs and create variables: examples, unit_tests


d = Dict("code_generation" => Dict("name" => function_name,
    "contributor" => "svilupp",
    "version" => "1.0",
    "prompt" => prompt,
    "criteria" => ["parsed", "executed", "passed_unit_tests", "executed_examples"],
    "examples" => examples,
    "unit_tests" => unit_tests,
    "imports" => ["Test"]
))


# Sense check that the examples work
for example in d["examples"]
    @eval(Main, $(Meta.parseall(example)))
end

# Sense check that the examples work
for unit in d["unit_tests"]
    @eval(Main, $(Meta.parseall(unit)))
end

# Now we can save it...
save_definition(fn_definition, d)

# # Test the definition
# You should always test your definition before running the benchmark. Pass it to the best model (gpt4t) and see if it works.
#
# If GPT-4 fails, you're unlikely get any points for the other open source models! Perhaps tweak the prompt a bit to be more clear?

msg = aigenerate(:JuliaExpertAsk; ask=prompt, model="gpt4t", return_all=true)
@assert isvalid(AICode(last(msg))) "Code gen failed. Is the prompt okay? Or is it just that hard?"

# Try evaluating it -- add auto_save=false not to polute our benchmark
eval = evaluate_1shot(; conversation=msg, fn_definition, definition=d["code_generation"], model="gpt4t", prompt_label="JuliaExpertAsk", timestamp=timestamp_now(), device="Apple-MacBook-Pro-M1", prompt_strategy="1SHOT", verbose=true, auto_save=false)

# # Feeling Ambitious?
# Why not use `aiextract` and generate the whole TOML definition automatically by GPT-4?
#
# Note: You want to add some "thinking" opportunities for the model, otherwise it will just copy the examples and unit tests.


# # The End