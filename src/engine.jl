"""
    matlab_engine()
    matlab_engine(engine_name)

Connect to a named MATLAB session. This must be done before using the integrated MATLAB REPL.

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

julia> a21 .+ matrepl"a"
3×3 Array{Float64,2}:
 11.0   4.0   9.0
  6.0   8.0  10.0
  7.0  12.0   5.0
```
"""
function matlab_engine(engine_name)
    # Note: Don't fix the indentation here, it breaks Julia syntax highlighting
py"""
import matlab.engine
import numpy as np
eng = matlab.engine.connect_matlab($(string(engine_name)))
"""
    # return py"eng"
end

function matlab_engine()
py"""
import matlab.engine
import numpy as np
eng = matlab.engine.start_matlab()
"""
    # return py"eng"
end