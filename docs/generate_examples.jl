using Literate

## ! Config
example_files = [
    joinpath(pkgdir(JuliaLLMLeaderboard), "examples", "summarize_results_oss.jl"),
    joinpath(pkgdir(JuliaLLMLeaderboard), "examples", "summarize_results_paid.jl"),
    joinpath(pkgdir(JuliaLLMLeaderboard), "examples", "summarize_results_prompts.jl"),
]
output_dir = joinpath(@__DIR__, "src", "examples")

# Run the production loop
for fn in example_files
    Literate.markdown(fn, output_dir; execute = true)
end

# TODO: change meta fields at the top of each file!