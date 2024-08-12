# # Example how to inspect a certain run

## Imports
using PromptingTools
const PT = PromptingTools
using JuliaLLMLeaderboard
using JuliaLLMLeaderboard: load_conversation_from_eval, run_code_main,
                           run_code_blocks_additive
using DataFramesMeta

# Load everything
df = load_evals("code_generation"; max_history = 0)
# df = load_evals("debug"; max_history = 0)

# Inspect some result
# row = @chain df begin
#     @rsubset :prompt_label=="InJulia" :name=="event_scheduler" :model=="mistral-small"
# end

# select which row to inspect
row_idx = 2

# take the evaluation filename and use it to load up the conversation
conv = df.filename[row_idx] |> load_conversation_from_eval
edit(conv) # Opens a preview in VSCode, alternatively use `preview(conv)`

# Check out the code parsing results and errors
cb = AICode(last(conv); skip_unsafe = true)
cb.error

# load the definition
definition = load_definition(joinpath(
    "code_generation", "utility_functions", df.name[row_idx], "definition.toml"))["code_generation"]

## Execute the function definition
cb, debugs = run_code_main(last(conv); return_debug = true)

## Execute the examples
cnt, debugs = run_code_blocks_additive(
    cb, definition["examples"]; return_debug = true, verbose = true)

## Execute the unit tests
cnt, debugs = run_code_blocks_additive(
    cb, definition["unit_tests"]; return_debug = true, verbose = true)

## Run evaluation 1shot
evaluate_1shot(;
    conversation = conv, fn_definition = "", definition = definition,
    auto_save = false, model = "", prompt_label = "", schema = PT.OpenAISchema(),
    return_debug = true, verbose = true)