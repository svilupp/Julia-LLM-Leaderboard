using Literate

## ! Config
example_files = [
    joinpath(pkgdir(JuliaLLMLeaderboard), "examples", "summarize_results.jl"),
]
output_dir = joinpath(@__DIR__, "src", "examples")

# Run the production loop
for fn in example_files
    Literate.markdown(fn, output_dir; execute = true)
end

# TODO: change meta fields at the top of each file!