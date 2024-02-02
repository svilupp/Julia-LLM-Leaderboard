# ## Quick Eval
using JuliaLLMLeaderboard
using DataFramesMeta
using Statistics
## Load data
df = load_evals("magicoder-quantization-effects"; max_history = 0)

# # Analysis

@chain df begin
    # @rsubset :model=="yi:34b-chat-q3_K_L" :prompt_label=="JuliaExpertCoTTask"
    @rsubset :experiment == "magicoder-quantization-effects-default"
    @by [:model] begin
        :score = mean(:score)
        :count_zero = count(==(0), :score)
        :count_full = count(==(100), :score)
        :count = $nrow
    end
    @orderby -:score
end
output = @chain df begin
    @rsubset :experiment == "magicoder-quantization-effects-default"
    @by [:model, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :model :AverageScore=mean(:score) |> x -> round(x, digits = 1)
    unstack(:model, :prompt_label, :score; fill = 0.0)
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :model)
    @orderby -:AverageScore
end
output = @chain df begin
    @rsubset :experiment == "magicoder-quantization-effects-default"
    @rsubset :model == "magicoder:7b-s-cl-q4_0"
    @by [:name, :model] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :name :AverageScore=mean(:score) |> x -> round(x, digits = 1)
    unstack(:name, :model, :score; fill = 0.0)
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :name)
    @orderby -:AverageScore
end

output = @chain df begin
    @rsubset :experiment == "magicoder-quantization-effects-default"
    @rsubset :model=="magicoder:7b-s-cl-q4_0" :prompt_label!="AsIs"
    @by [:name, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :name :AverageScore=mean(:score) |> x -> round(x, digits = 1)
    unstack(:name, :prompt_label, :score; fill = 0.0)
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :name)
    @orderby -:AverageScore
end

@chain df begin
    @rsubset :experiment == "magicoder-quantization-effects-default"
    @rsubset :model=="magicoder:7b-s-cl-q6_K" :prompt_label!="AsIs"
    @rsubset :prompt_label=="JuliaExpertAsk" :name=="FloatWithUnits"
end

@chain df begin
    @rsubset :prompt_label=="JuliaExpertAsk" :name=="weather_data_analyzer"
    @rsubset :experiment == "magicoder-quantization-effects-default"
    @rsubset :model == "magicoder:7b-s-cl-q6_K" || :model == "magicoder:7b-s-cl-q4_0"
    @by :model :score=mean(:score)
end
## 2×2 DataFrame
##  Row │ model                   score   
##      │ String                  Float64 
## ─────┼─────────────────────────────────
##    1 │ magicoder:7b-s-cl-q4_0     78.0
##    2 │ magicoder:7b-s-cl-q6_K     84.0

# # Comparison with old benchmark
dfx = load_evals("code_generation"; max_history = 0)

@chain dfx begin
    @rsubset :model=="magicoder:7b-s-cl-q6_K" :prompt_label!="AsIs"
    @by [:name, :prompt_label] begin
        :cost = mean(:cost)
        :elapsed = mean(:elapsed_seconds)
        :score = mean(:score)
    end
    @aside average_ = @by _ :name :AverageScore=mean(:score) |> x -> round(x, digits = 1)
    unstack(:name, :prompt_label, :score; fill = 0.0)
    transform(_, names(_, Number) .=> ByRow(x -> round(x, digits = 1)), renamecols = false)
    leftjoin(average_, on = :name)
    @orderby -:AverageScore
end

## For reference: 47.5 for magicoder q4_0 / 68.33 for 7b-s-cl-q6_K --> Something has change in Ollama/llama.cpp since December!!
@chain dfx begin
    @rsubset :model=="magicoder" :prompt_label=="JuliaExpertAsk" :name=="weather_data_analyzer"
    mean(_.score)
end
@chain dfx begin
    @rsubset :model=="magicoder:7b-s-cl-q6_K" :prompt_label=="JuliaExpertAsk" :name=="weather_data_analyzer"
    mean(_.score)
end