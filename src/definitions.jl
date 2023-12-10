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

"Finds all `definition.toml` filenames in the given path. Returns a list of filenames to load."
function find_definitions(dir::AbstractString=".")
    definitions = AbstractString[]
    for (root, dirs, files) in walkdir(dir)
        for file in files
            if file == "definition.toml"
                push!(definitions, joinpath(root, file))
            end
        end
    end
    return definitions
end