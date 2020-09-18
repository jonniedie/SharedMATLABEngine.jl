# Pretty hacky way of evaluating in this module
struct Engine end

function Base.getproperty(::Engine, s::Symbol)
    prop = py"getattr(eng, $(string(s)))"
    if s == :workspace
        return Workspace(prop)
    else
        return prop
    end
end

Base.propertynames(me::Engine) = Symbol.(py"dir(eng)")


# This is only here to convert outputs of the engine workspace
struct Workspace
    pyobj::PyCall.PyObject
end

Base.getproperty(::Workspace, s::Symbol) = Base.eval(Main, _mat_str(string(s)))

# Not sure why I have to do it this way here but not in the mat" string macro
function Base.setproperty!(::Workspace, s::Symbol, x)
    x_str = string(x)
    if x isa AbstractVector
        x_str = replace(x_str, ","=>";")
    end
    str = string(s) * " = " * x_str
    _mat_str(str)
    return nothing
end

Base.getindex(ws::Workspace, s) = getproperty(ws, Symbol(s))

Base.keys(ws::Workspace) = keys(getfield(ws, :pyobj))

Base.propertynames(ws::Workspace) = propertynames(getfield(ws, :pyobj))

Base.show(io::IO, ws::Workspace) = print(io, getfield(ws, :pyobj))



"""
    connect_matlab(; background=false)
    connect_matlab(engine_name; background=false)

Connect to a named MATLAB session. This must be done before using the integrated MATLAB REPL.
If no name engine name is given, it will connect to the first named session returned from
`find_matlab()`.

## Examples
```julia
julia> using SharedMATLAB

julia> connect_matlab(:default_engine);
REPL mode SharedMATLAB initialized. Press > to enter and backspace to exit.

>> a = magic(3)

a =

     8     1     6
     3     5     7
     4     9     2


>> \$a21 = a(2,1)
3.0

julia> a21 .+ mat"a"
3×3 Array{Float64,2}:
 11.0   4.0   9.0
  6.0   8.0  10.0
  7.0  12.0   5.0
```
"""
function connect_matlab(name=nothing; background=false)
    # Note: Don't fix the indentation here, it breaks Julia syntax highlighting
py"""
eng = matlab.engine.connect_matlab($name, background=$background)
"""
    start_repl()
    return Engine()
end


"""
    start_matlab(; option="-nodesktop", background=false)

Start new MATLAB session
"""
function start_matlab(; option="-nodesktop", background=false)
py"""
eng = matlab.engine.start_matlab(option=$option, background=$(background))
"""
    start_repl()
    return Engine()
end


"""
    find_matlab()

Find available MATLAB sessions
"""
find_matlab() = py"matlab.engine.find_matlab()"


function start_repl()
    if isinteractive()
        initrepl(str -> Meta.parse("SharedMATLAB.matrepl\"$str\"");
            prompt_text = ">> ",
            start_key = ">",
            prompt_color = :default,
            mode_name = "SharedMATLAB",
        )
    end
    return nothing
end