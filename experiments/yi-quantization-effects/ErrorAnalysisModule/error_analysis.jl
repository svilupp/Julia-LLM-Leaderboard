# ---
# title: "Error Analysis for Yi34b"
# author: "svilupp"
# date: "2024-02-02"
# format:
#   html:
#     toc: true
#     toc-depth: 2
#     code-fold: true
#     self-contained: true
# jupyter: julia6-1.10
# ---
cd(@__DIR__)
## using Pkg;
## Pkg.activate("."; io = devnull)
## Pkg.develop(path = "../..") # root repo LLMLeaderboard
## Pkg.develop(path = "../../../../LLMTextAnalysis") # latest LLMTextAnalysis
## Pkg.add([
##     "DataFramesMeta",
##     "Arrow",
##     "CategoricalArrays",
##     "Statistics",
##     "StatsPlots",
##     "PlotlyJS",
## ])

using Pkg;
Pkg.activate(".", io = devnull);
## Import useful packages
using JuliaLLMLeaderboard
using DataFramesMeta, CategoricalArrays, Arrow
using Statistics
using LLMTextAnalysis
using JuliaLLMLeaderboard.ProgressMeter
PT = JuliaLLMLeaderboard.PromptingTools
using JuliaLLMLeaderboard.JSON3
using StatsPlots
using Serialization, LinearAlgebra

## ! Configuration
plotlyjs();
ERRORS_FILE = "df_errors.arrow";

# # Harvest all error messages
## main_dir = joinpath(@__DIR__, "..")
## df = load_evals(main_dir; max_history = 0)

## fn_definitions = find_definitions(joinpath(pkgdir(JuliaLLMLeaderboard), "code_generation"))
## evals = []
## cnt = 0
## p = Progress(nrow(df); showspeed = true, desc = "Evaluating... ")
## for (dir, _, files) in walkdir(main_dir)
##     dir_start = length(evals) + 1
##     for file in files
##         ## cnt >= 2 && break
##         if startswith(file, "evaluation__")
##             fn_evaluation = joinpath(dir, file)
##             ## @info "Processing $fn_evaluation"
##             fn_conversation = replace(fn_evaluation, "evaluation" => "conversation")
##             evaluation = JSON3.read(fn_evaluation) |> copy
##             conversation = PT.load_conversation(fn_conversation)

##             parts = splitpath(fn_conversation)
##             definition_str = joinpath(evaluation[:name], "definition.toml")
##             fn_definition = findfirst(fn -> occursin(definition_str, fn), fn_definitions) |>
##                             x -> fn_definitions[x]

##             definition = load_definition(fn_definition)["code_generation"]
##             ## if !occursin("codellama:70b-instruct-q4_K_M", evaluation[:model])
##             ##     continue
##             ## end
##             try
##                 parameters = get(evaluation, :parameters, Dict()) |> NamedTuple
##                 experiment = get(evaluation, :experiment, "")
##                 eval_, debug_ = evaluate_1shot(; conversation, parameters,
##                     fn_definition,
##                     definition, model = evaluation[:model],
##                     device = evaluation[:device],
##                     schema = evaluation[:schema],
##                     timestamp = evaluation[:timestamp],
##                     prompt_label = evaluation[:prompt_label],
##                     prompt_strategy = evaluation[:prompt_strategy],
##                     verbose = false, auto_save = false,
##                     version_pt = evaluation[:version_pt], experiment,
##                     execution_timeout = 10, return_debug = true)
##                 push!(evals, merge(eval_, (; debug = debug_)))
##             catch e
##                 @error "Failed for $fn_evaluation with error: $e"
##                 break
##             end
##             cnt += 1
##             next!(p;
##                 showvalues = [
##                     (:dir, dir),
##                     (:file, file),
##                 ])
##         end
##     end
##     dir_end = length(evals)
##     if dir_start < dir_end
##         @info "AVG Directory Score: $(round(mean(score_eval.(@view(evals[dir_start:dir_end]))), digits = 2)) ($dir)"
##     end
## end

## Double check that the avg. score makes sense
## score_eval.(evals) |> mean

## Save the data
## Note: Unwraps data to test-item level, removes all successful runs and is weighted by number of failures 
## (ie, is NOT representative of the actual score distribution!!)
## scores = score_eval.(evals)
## df_errors = @chain begin
##     DataFrame(evals)
##     @transform :score = scores
##     @rsubset !isempty(:debug)
##     flatten(:debug)
##     @rtransform begin
##         :error = typeof(:debug.error) |> nameof |> string
##         :stdout = isnothing(:debug.stdout) ? "" : first(:debug.stdout, 512)
##         :failing_lines = join(:debug.failing_lines, "\n")
##     end
##     select(Not(:debug, :parameters))
##     @select :experiment :prompt_label :timestamp :model :name :error :stdout :failing_lines # :parsed :executed :score
## end
## Arrow.write(ERRORS_FILE, df_errors);

# # Load the Data
df_errors = Arrow.Table(ERRORS_FILE) |> DataFrame;

# # Error Type Comparison
# Let's display the distribution of errors for different models (top 5) - where can we see differences between models?
@chain df_errors begin
    ## not interested in Test failures
    @rsubset :error != "FallbackTestSetException" && :error != "TestSetException"
    @by [:model, :error] :count=$nrow
    @transform groupby(_, :model) :share=:count ./ sum(:count)
    ## Pick only top 5 errors
    @aside local top_errors = @by(_, :error, :count=sum(:count)) |>
                              x -> @orderby(x, -:count).error
    @rsubset :error in first(top_errors, 5)
    @transform _ :error=categorical(:error; levels = first(top_errors, 5))
    @df groupedbar(:error, :share, group = :model, bar_position = :dodge, bar_width = 0.7,
        xlabel = "Error Type", ylabel = "Share of Errors",
        yformatter = x -> "$(round(Int,x*100))%",
        xrotation = 45, legendposition = :outertopright,
        title = "Error Distribution for different models", size = (900, 600),
        left_margin = 10StatsPlots.Plots.mm)
end

# # Error Clustering
# Run a topic analysis for the code lines that triggered an error
df_lines = @chain df_errors begin
    ## Remove uninteresting lines (test case failures)
    @rsubset :error != "FallbackTestSetException" && :error != "TestSetException"
    @rtransform :failing_lines = isempty(:failing_lines) ? :stdout : strip(:failing_lines)
    @rsubset !isempty(:failing_lines)
end;
#
## UMAP calculation can take upto 10 minutes, so let's cache the results
if !isfile("error_index.jls")
    index = build_index(df_lines.failing_lines;
        k = 20,
        labeler_kwargs = (; model = "gpt3t"))
    build_clusters!(index; k = 20, labeler_kwargs = (; model = "gpt3t"))
    ## Skip UMAP as it's too slow, do simple PCA
    F = svd(index.embeddings')
    index.plot_data = permutedims(F.U[:, 1:2] * Diagonal(F.S[1:2]))
    ## serialize("error_index.jls", index)
else
    index = deserialize("error_index.jls")
end

plt = plot(index,
    title = "Lines that errored",
    hoverdata = select(df_lines, :model, :error, :name))

# # The End