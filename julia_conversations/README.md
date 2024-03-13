# Julia Conversations

Please PR and add any relevant and MOSTLY CORRECT conversations with/in/about Julia in this folder. The goal is to have a collection of conversations that are useful for training Julia knowledge into smaller models.

Ideally, add a folder suggesting some topic/category - it will be reorganized later.

## Saving Conversations

It's really easy with PromptingTools.jl. Just use the `save_conversation` function.

```julia
using PromptingTools, Dates
using PromptingTools: save_conversation

# Use return_all=true to get all the inputs & outputs
conv = aigenerate("Give me example of code to create Julia dictionary"; return_all=true)

# We like the answer, let's save it! 
# Let's use a descriptive name and add a timestamp to the filename.
save_conversation("creating_julia_dict__$(Dates.now()).json",conv)
```
And now you can open the PR and add it to this folder!

If you use `@ai_str` macros, you can always access the last conversation in:

```julia
using PromptingTools
const PT = PromptingTools

# Just ask any question
ai"Give me example of code to create Julia dictionary"

# If we like the answer, we can save the last conversation via
conv = PT.CONV_HISTORY[end] # last conversation via ai"" macro
# Let's use a descriptive name and add a timestamp to the filename.
save_conversation("creating_julia_dict__$(Dates.now()).json",conv)
```