using JuliaLLMLeaderboard
using Test

# # Example Definition

## Reference Function
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

## Reference testset
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

## Create definition
d = Dict("code_generation" => Dict("name" => "Wrap String",
    "version" => "1.0",
    "prompt" => "Write a function `wrap_string`. It iterates over words and it will add a new line each time a maximum `text_width::Int=10` would be exceed. Provide an example",
    "criteria" => ["parsed", "executed", "passed_unit_tests", "executed_examples"],
    "examples" => ["This function will wrap words into lines"],
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
    ]))

## Save definition
fn_definition = joinpath("code_generation", "utility_functions", "wrap_string", "definition.toml")
save_definition(fn_definition, d)

# Check that it works
definition = load_definition(fn_definition)["code_generation"]

