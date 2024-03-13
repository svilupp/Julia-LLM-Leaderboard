
# # Evaluate results
using Pkg;
Pkg.activate(Base.current_project());
using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools
using DataFramesMeta
using Statistics

## Load data
df = load_evals("cheater-7b"; max_history = 0)
@chain df begin
    @by [:model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
end
@chain df begin
    @rsubset :model != "cheater-7b"
    @by [:name] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
end
@chain df begin
    @rsubset :model == "cheater-7b.Q5_K_M"
    mean(_.score)
end
@chain df begin
    @rsubset :model == "cheater-7b.Q5_K_M"
    @by [:name] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
end
