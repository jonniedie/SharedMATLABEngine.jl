"""
    SharedMATLABEngine

## Exports
- connect_matlab
- start_matlab
- find_matlab
- mat"

## Description
Run MATLAB code in an open MATLAB engine session. To get started, call the function
`connect_matlab(engine_name)` in the Julia REPL. To see a list of open engine names, call
`find_matlab()`. Once connected, the MATLAB command line can be accessedfrom the Julia REPL
by typing `>`. Julia variables can be interpolated into MATLAB commands via the `\$` operator.

## Examples
```julia
julia> using SharedMATLABEngine

julia> eng = connect_matlab(:default_engine);
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
module SharedMATLABEngine

using PyCall
using ReplMaker

const Conda = PyCall.Conda

include("utils.jl")
include("engine.jl")
include("matrepl_str.jl")

const np = PyNULL()
const matlab = PyNULL()
const matlab_engine = PyNULL()
const eng = PyNULL()
const matlab_workspace = Workspace(PyNULL())

export matlab_workspace
export connect_matlab, start_matlab, find_matlab
export @mat_str

function __init__()
    copy!(matlab, pyimport_e("matlab"))
    copy!(np, pyimport_e("numpy"))
    copy!(matlab_engine, pyimport_e("matlab.engine"))
end

end
