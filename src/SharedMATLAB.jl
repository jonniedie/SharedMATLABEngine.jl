"""
    SharedMATLAB

## Exports
- matlab_engine
- @mat_str
- mat"

## Description
Run MATLAB code in an open MATLAB engine session. To get started, call the function
`matlab_engine(engine_name)` in the Julia REPL. Now the MATLAB command line can be accessed
from the Julia REPL by typing `>`. Julia variables can be interpolated into MATLAB commands
via the `\$` operator.

## Examples
```julia
julia> using SharedMATLAB
REPL mode SharedMATLAB initialized. Press > to enter and backspace to exit.

julia> matlab_engine(:default_engine)

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
module SharedMATLAB

using PyCall
using ReplMaker

include("engine.jl")
include("matrepl_str.jl")

export matlab_engine
export @mat_str


end
