# # Inspect Results
# How to inspect evaluations/conversations? 

using JuliaLLMLeaderboard
using PromptingTools
const PT = PromptingTools

# # Load Results
# It automatically scores the evaluations and adds the score column to the DataFrame (change it with score=false)
df = load_evals("code_generation")

# # Explore

# Check the full table in VSCode Table Viewer
vscodedisplay(df)

# Don't like some score? Take a evaluation filename to obtain the associated conversation:
conv = load_conversation_from_eval(df.filename[1])

# You can preview the conversation in VSCode Markdown Preview (or whichever editor you have as default)
# If you use VSCode, right click on the tab and select "Open Preview" for nicer display
# (We hijack InteractiveUtils.edit system to open a file... hence, the name of the function)
edit(conv)

# If you want to see the markdown rendered in REPL, use the following:
preview(conv)

# Or maybe you want to see the code blocks and their errors?
cb = PT.AICode(last(conv))

cb.error

