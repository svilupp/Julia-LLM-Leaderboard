function save_definition(filename::AbstractString, definition::AbstractDict)
    open(filename, "w") do io
        TOML.print(io, definition)
    end
end

# TODO: finish
validate_definition(definition) = true

function load_definition(filename)
    return TOML.tryparse(open(filename, "r"))
end
