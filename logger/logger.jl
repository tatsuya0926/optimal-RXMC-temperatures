module MyLogger

using Logging
using Dates

export init_logger

struct FileLogger <: AbstractLogger
    io::IO
    level::LogLevel
end

Logging.min_enabled_level(logger::FileLogger) = logger.level

function Logging.shouldlog(
        logger::FileLogger,
        level, _module, group, id
    )
    return level ≥ logger.level
end

function Logging.handle_message(
    logger::FileLogger,
    level, message, _module, group, id, file, line;
    kwargs...
    )
    ts  = Dates.format(Dates.now(), dateformat"yyyy-mm-dd HH:MM:SS")
    lvl = uppercase(string(level))
    print(logger.io, "[", ts, "] [", lvl, "] ", message, "\n")
    flush(logger.io)
end

function init_logger(
    path::Union{Nothing,String}=nothing;
    dir::Union{Nothing,String}=nothing,
    level::Union{LogLevel,String,Symbol}=Logging.Info
    )
    """
        init_logger(
            path::Union{Nothing,String}=nothing;
            dir::Union{Nothing,String}=nothing,
            level::Union{LogLevel,String,Symbol}=Logging.Info
        )
    
    - `path`: File name (automatically generated with a timestamp if omitted)
    - `dir`: Destination directory (current directory if omitted)
    - `level`: Log level can be specified as `LogLevel`, a string, or a symbol. Specifying an invalid level will throw an `ArgumentError`.
        - e.g. `Logging.Debug`, `"Debug"`, `:Debug`, `"warning"`, `:ERROR`, etc.
    """
    lvl = begin
        if level isa LogLevel
            level
        elseif level isa Symbol || level isa String
            name = uppercase(string(level))
            mapping = Dict(
                "DEBUG" => Logging.Debug,
                "INFO" => Logging.Info,
                "WARN" => Logging.Warn,
                "WARNING" => Logging.Warn,
                "ERROR" => Logging.Error,
                "FATAL" => Logging.Error
            )
            if haskey(mapping, name)
                mapping[name]
            else
                throw(ArgumentError("Invalid log level: $level"))
            end
        else
            throw(ArgumentError("Invalid type for level: $(typeof(level))"))
        end
    end

    filename = isnothing(path) ? string(Dates.format(Dates.now(), dateformat"yyyymmdd-HHMMSS"), ".log") : path

    if dir !== nothing
        mkpath(dir)
    end

    filepath = dir === nothing ? filename : joinpath(dir, filename)
    io = open(filepath, "a")
    atexit(() -> close(io))
    flogger = FileLogger(io, lvl)
    global_logger(flogger)

    @info "Logger initialized: path=$(filepath), level=$(lvl)"
    return nothing
end

end