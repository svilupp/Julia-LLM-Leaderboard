using JuliaLLMLeaderboard
using PromptingTools
using Documenter
using SparseArrays, LinearAlgebra
using PromptingTools.Experimental.RAGTools
using JSON3, Serialization, DataFramesMeta
using Statistics: mean

DocMeta.setdocmeta!(JuliaLLMLeaderboard,
    :DocTestSetup,
    :(using JuliaLLMLeaderboard);
    recursive = true)

# Convert .jl scripts to markdown
include("generate_examples.jl")

makedocs(;
    modules = [JuliaLLMLeaderboard],
    authors = "J S <49557684+svilupp@users.noreply.github.com> and contributors",
    repo = "https://github.com/svilupp/Julia-LLM-Leaderboard/blob/{commit}{path}#{line}",
    sitename = "JuliaLLMLeaderboard.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        repolink = "https://github.com/svilupp/Julia-LLM-Leaderboard",
        canonical = "https://svilupp.github.io/Julia-LLM-Leaderboard",
        edit_link = "main",
        assets = String[],
        size_threshold = nothing),
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "Methodology" => "methodology.md",
        "Test Definitions" => "test_definitions.md",
        "Results" => [
            "Paid APIs" => "examples/summarize_results_paid.md",
            "Open-Source Models" => "examples/summarize_results_oss.md",
            "Prompts" => "examples/summarize_results_prompts.md",
        ],
        "F.A.Q." => "frequently_asked_questions.md",
        "Reference" => "reference.md",
    ])

deploydocs(;
    repo = "github.com/svilupp/Julia-LLM-Leaderboard.jl",
    devbranch = "main")
