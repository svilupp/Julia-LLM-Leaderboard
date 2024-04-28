using Literate

## ! Config
example_files = [
    joinpath(pkgdir(JuliaLLMLeaderboard), "examples", "summarize_results_local.jl"),
    joinpath(pkgdir(JuliaLLMLeaderboard), "examples", "summarize_results_paid.jl"),
    joinpath(pkgdir(JuliaLLMLeaderboard), "examples", "summarize_results_prompts.jl"),
    joinpath(pkgdir(JuliaLLMLeaderboard), "examples", "summarize_results_test_cases.jl"),
    joinpath(pkgdir(JuliaLLMLeaderboard), "examples",
        "summarize_results_test_cases_waitlist.jl"),
    joinpath(pkgdir(JuliaLLMLeaderboard), "examples", "compare_paid_vs_local.jl")
]
output_dir = joinpath(@__DIR__, "src", "examples")

# Run the production loop
for fn in example_files
    Literate.markdown(fn, output_dir; execute = true)
end

# TODO: change meta fields at the top of each file!