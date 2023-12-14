# # Example how to inspect a certain run

## Imports
using JuliaLLMLeaderboard
using DataFramesMeta

# Load everything
df = load_evals("code_generation"; max_history=1)

# Inspect some result
row = @chain df begin
    @rsubset :prompt_label == "InJulia" :name == "event_scheduler" :model == "mistral-small"
end

# take the evaluation filename and use it to load up the conversation
conv = row.filename[end] |> load_conversation_from_eval
edit(conv) # Opens a preview in VSCode, alternatively use `preview(conv)`

# Check out the code parsing results and errors
cb = AICode(last(conv); skip_unsafe=true)
cb.error