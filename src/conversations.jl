"Loads the conversation from the corresponding evaluation file."
function load_conversation_from_eval(filename_eval::AbstractString)
    filename_conversation = replace(filename_eval, "evaluation__" => "conversation__")
    return PT.load_conversation(filename_conversation)
end

"""
    preview(msg::PT.AbstractMessage)

Render a single `AbstractMessage` as a markdown-formatted string, highlighting the role of the message sender and the content of the message.

This function identifies the type of the message (User, Data, System, AI, or Unknown) and formats it with a header indicating the sender's role, followed by the content of the message. The output is suitable for nicer rendering, especially in REPL or markdown environments.

# Arguments
- `msg::PT.AbstractMessage`: The message to be rendered.

# Returns
- `String`: A markdown-formatted string representing the message.

# Example
```julia
msg = PT.UserMessage("Hello, world!")
println(PT.preview(msg))
```

This will output:
```
# User Message
Hello, world!
```
"""
function preview(msg::PT.AbstractMessage)
    role = if msg isa Union{PT.UserMessage, PT.UserMessageWithImages}
        "User Message"
    elseif msg isa PT.DataMessage
        "Data Message"
    elseif msg isa PT.SystemMessage
        "System Message"
    elseif msg isa PT.AIMessage
        "AI Message"
    else
        "Unknown Message"
    end
    content = if msg isa PT.DataMessage
        length_ = msg.content isa AbstractArray ? " (Size: $(size(msg.content)))" : ""
        "Data: $(typeof(msg.content))$(length_)"
    else
        msg.content
    end
    return """# $role\n$(content)\n\n"""
end

"""
    preview(conversation::AbstractVector{<:PT.AbstractMessage})

Render a conversation, which is a vector of `AbstractMessage` objects, as a single markdown-formatted string. Each message is rendered individually and concatenated with separators for clear readability.

This function is particularly useful for displaying the flow of a conversation in a structured and readable format. It leverages the `PT.preview` method for individual messages to create a cohesive view of the entire conversation.

# Arguments
- `conversation::AbstractVector{<:PT.AbstractMessage}`: A vector of messages representing the conversation.

# Returns
- `String`: A markdown-formatted string representing the entire conversation.

# Example
```julia
conversation = [
    PT.SystemMessage("Welcome"),
    PT.UserMessage("Hello"),
    PT.AIMessage("Hi, how can I help you?")
]
println(PT.preview(conversation))
```

This will output:
```
# System Message
Welcome
---
# User Message
Hello
---
# AI Message
Hi, how can I help you?
---
```
"""
function preview(conversation::AbstractVector{<:PT.AbstractMessage})
    io = IOBuffer()
    print(io, join(preview.(conversation), "---\n"))
    String(take!(io)) |> Markdown.parse
end

countlines_string(s::AbstractString) = countlines(IOBuffer(s))
"""
    InteractiveUtils.edit(conversation::AbstractVector{<:PT.AbstractMessage}, bookmark::Int=-1)

Opens the conversation in a preview window formatted as markdown
(In VSCode, right click on the tab and select "Open Preview" to format it nicely).

See also: `preview` (for rendering as markdown in REPL)
"""
function InteractiveUtils.edit(conversation::AbstractVector{<:PT.AbstractMessage},
        bookmark::Int = -1)
    filename = tempname() * ".md"
    line = bookmark
    line_count = 0
    io = IOBuffer()
    ## write all messages into IO
    for (i, msg) in enumerate(conversation)
        txt = preview(msg)
        if i == bookmark
            line = line_count + 1
        end
        print(io, txt)
        line_count += countlines_string(txt)
    end
    open(filename, "w") do f
        write(f, String(take!(io)))
    end
    # which line to open on, if negative, open on last line
    line = line < 0 ? line_count : line
    # open the file in a preview window in a default editor
    edit(filename, line)
end
