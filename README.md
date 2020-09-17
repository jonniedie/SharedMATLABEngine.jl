# SharedMATLAB

SharedMATLAB allows MATLAB and Julia to share data through MATLAB commands embedded in the Julia REPL. The functionality is similar to MATLAB.jl. The advantages of SharedMATLAB.jl over MATLAB.jl are an embedded MATLAB REPL and the ability to connect to an already open named MATLAB engine session. The advantages of MATLAB.jl over SharedMATLAB.jl are... well a lot. A lot more effort has gone into that project than this one. Seriously, unless you really need to connect to an already open MATLAB session, you should use MATLAB.jl.

SharedMATLAB goes through a PyCall and the uses the matlab.engine interface in Python.


## Getting Started
To begin using SharedMATLAB, import the library and call the function `matlab_engine(engine_name)`. To see the name of the MATLAB session you want to connect to, call `matlab.engine.engineName` in MATLAB.

```julia
julia> using SharedMATLAB
REPL mode SharedMATLAB initialized. Press > to enter and backspace to exit.

julia> matlab_engine("MATLAB_25596") # Get from matlab.engine.engineName in MATLAB
```

Now the MATLAB command line can be accessed from the Julia REPL by typing `>`.
```matlab
>> a = magic(3)

a =

     8     1     6
     3     5     7
     4     9     2
```

Julia variables can be interpolated into MATLAB commands via the `$` operator.
```matlab
>> \$a21 = a(2,1)
3.0

>> b = $a21 + a

b =

    11     4     9
     6     8    10
     7    12     5
```

And MATLAB command outputs can be accessed in Julia through the `mat"` string macro.
```julia
julia> b = a21 .+ mat"a"
3×3 Array{Float64,2}:
 11.0   4.0   9.0
  6.0   8.0  10.0
  7.0  12.0   5.0
```