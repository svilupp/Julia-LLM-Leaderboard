# # Example To Summarize Results

## Imports
using JuliaLLMLeaderboard
using CairoMakie, AlgebraOfGraphics, DataFramesMeta
using MarkdownTables
using Statistics: mean

# # Load Results
df = load_evals("code_generation")

# ## Table Output
# By Model / Prompt
output = @chain df begin
    @by [:model, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :model :AverageScore = mean(:score) |> x -> round(x, digits=1)
    unstack(:model, :prompt_label, :score)
    leftjoin(average_, on=:model)
end
markdown_table(output, String) |> clipboard

# ## Plots

fig = @chain df begin
    data(_) * mapping(:model => "Model", :score => "Score (Max 100 pts)", color=:prompt_label => "Prompts", dodge=:prompt_label) * visual(BarPlot)
    draw(; axis=(xticklabelrotation=45, title="Comparison on 1 Test Case [PRELIMINARY]"))
end
save("assets/model-prompt-comparison.png", fig)


# ## Per model
# Models, points, elapsed, cost, 
# TODO: add more thorough analysis -- trade off speed vs score and cost vs score

# ## Per prompt (same model)
# TODO: add more thorough analysis
output = @chain df begin
    @by [:prompt_label] begin
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits=1)), renamecols=false)
    rename("elapsed" => "Elapsed (s)", "score" => "Avg. Score (Max 100 pts)")
end
markdown_table(output, String) |> clipboard