"Loads the conversation from the corresponding evaluation file."
function load_conversation_from_eval(filename_eval::AbstractString)
    filename_conversation = replace(filename_eval, "evaluation__" => "conversation__")
    return PT.load_conversation(filename_conversation)
end

function preview(msg::PT.AbstractMessage)
    role = if msg isa Union{PT.UserMessage,PT.UserMessageWithImages}
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
    """# $role\n$(msg.content)\n\n"""
end

"Renders the conversation as markdown."
function preview(conversation::AbstractVector{<:PT.AbstractMessage})
    io = IOBuffer()
    print(io, preview.(conversation)...)
    String(take!(io)) |> Markdown.parse
end

countlines_string(s::AbstractString) = countlines(IOBuffer(s))
"""
    InteractiveUtils.edit(conversation::AbstractVector{<:PT.AbstractMessage}, bookmark::Int=-1)

Opens the conversation in a preview window formatted as markdown
(In VSCode, right click on the tab and select "Open Preview" to format it nicely).

See also: `preview` (for rendering as markdown in REPL)
"""
function InteractiveUtils.edit(conversation::AbstractVector{<:PT.AbstractMessage}, bookmark::Int=-1)
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

