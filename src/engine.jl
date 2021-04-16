mutable struct Workspace
    obj::PyObject
end

PyCall.PyObject(ws::Workspace) = getfield(ws, :obj)

function Base.show(io::IO, ws::Workspace)
    println(io, "MATLAB workspace with properties")
    print(io, PyObject(ws))
end

Base.getproperty(ws::Workspace, s::Symbol) = _convert_py_output(PyObject(ws).__getitem__(string(s)))
Base.setproperty!(ws::Workspace, s::Symbol, val) = PyObject(ws).__setitem__(string(s), val)
Base.propertynames(ws::Workspace) = (print(PyObject(ws)); ()) # A hack because reasons

Base.getindex(ws::Workspace, s) = _convert_py_output(PyObject(ws).__getitem__(string(s)))
Base.setindex!(ws::Workspace, val, s) = PyObject(ws).__setitem__(string(s), val)


"""
    eng = connect_matlab(; background=false)
    eng = connect_matlab(engine_name; background=false)

Connect to a named MATLAB session. This must be done before using the integrated MATLAB REPL.
If no name engine name is given, it will connect to the first named session returned from
`find_matlab()`.

## Examples
```julia
julia> using SharedMATLABEngine

julia> connect_matlab(:default_engine);
REPL mode MATLAB initialized. Press > to enter and backspace to exit.

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
    copy!(eng, matlab_engine.connect_matlab(name, background=background))
    setfield!(matlab_workspace, :obj, eng.workspace)
    start_repl()
    return eng
end


"""
    eng = start_matlab(; option="-nodesktop", background=false)

Start new MATLAB session
"""
function start_matlab(; option="-nodesktop", background=false)
    copy!(eng, matlab_engine.start_matlab(option=option, background=background))
    setfield!(matlab_workspace, :obj, eng.workspace)
    start_repl()
    return eng
end


"""
    find_matlab()

Find available MATLAB sessions
"""
find_matlab() = matlab_engine.find_matlab()


function start_repl()
    if isinteractive()
        initrepl(str -> Meta.parse("SharedMATLABEngine.matrepl\"$str\"");
            prompt_text = ">> ",
            start_key = ">",
            prompt_color = :default,
            mode_name = "MATLAB",
        )
    end
    return nothing
end