# SharedMATLABEngine.jl

## NOTICE:
This seems to be broken on newer versions of MATLAB due to some changes in the Python API. Or something. I don't know. If you have any ideas for how to fix it, let me know. I also don't have a recent MATLAB license, so it's a little tough to debug stuff.

![](assets/car-engine.png)

SharedMATLABEngine allows Julia to share data with an open MATLAB session through a MATLAB command line embedded in the Julia REPL. The functionality is similar to [MATLAB.jl](https://github.com/JuliaInterop/MATLAB.jl). The main advantage of SharedMATLABEngine.jl over MATLAB.jl is the ability to connect to an already open named MATLAB engine session. The advantages of MATLAB.jl over SharedMATLABEngine.jl are... well a lot. A lot more effort has gone into that project than this one. Unless you really need to connect to an already open MATLAB session, you should probably use MATLAB.jl.

SharedMATLABEngine goes through a PyCall and the uses the matlab.engine interface in Python.

## Installation
Since SharedMATLABEngine connects through the Python API for the MATLAB Engine, [Python must first be installed](https://www.python.org/downloads/).

Once Python is installed, the MATLAB Engine API for Python needs to be set up. In the MATLAB command prompt, enter:
```matlab
>> cd (fullfile(matlabroot,'extern','engines','python'))

>> system('python setup.py install')
```

Finally, SharedMATLABEngine must be installed in Julia. To do so, press the `]` key in the Julia REPL to enter Pkg mode and enter:
```julia-repl
(@v1.x) pkg> add SharedMATLABEngine
```

From here, SharedMATLABEngine should work. If not, check out the [documentation for installing the MATLAB Engine API in Python](https://www.mathworks.com/help/matlab/matlab_external/install-the-matlab-engine-for-python.html).


## Connecting to a MATLAB Session
### Sharing the MATLAB Engine
To begin using SharedMATLABEngine, open up a MATLAB session and enter the following in the Command Window: 
```matlab
>> matlab.engine.shareEngine
```
We can now see the name of the shared engine
```matlab
>> matlab.engine.engineName

ans =

    'MATLAB_77164'
```
### Connecting Julia to the MATLAB Engine
To connect the Julia REPL to the MATLAB session, enter:
```julia
julia> using SharedMATLABEngine

julia> connect_matlab()
```
Once connected, you will see the message:
```julia
REPL mode SharedMATLABEngine initialized. Press > to enter and backspace to exit.
```
If multiple shared MATLAB Engine sessions are open, you can specify the one you want to connect to as a string argument such as `connect_matlab("MATLAB_77164")`. To see a list of available MATLAB sessions, call `find_matlab()`.


## General Use
Now that we are connected, the MATLAB command line can be accessed from the Julia REPL by typing `>`
```matlab
>> a = magic(3)

a =

     8     1     6
     3     5     7
     4     9     2
```

Julia variables and commands can be interpolated into MATLAB commands via the `$` operator.
```matlab
julia> n = 1
1

>> $a21 = a($(n+1), 1)
3.0

>> b = {zeros($a21), 'some words'}

b =

  1×2 cell array

    {3×3 double}    {'some words'}


>> [$z, c] = b{:}

c =

    'some words'

julia> (a21, z)
(3.0, [0.0 0.0 0.0; 0.0 0.0 0.0; 0.0 0.0 0.0])
```
The `mat"` string macro can also be used to call MATLAB commands without switching the Julia REPL to MATLAB mode
```julia
julia> b = a21 .+ mat"a+1"
3×3 Matrix{Float64}:
 12.0   5.0  10.0
  7.0   9.0  11.0
  8.0  13.0   6.0
```
Variables from the MATLAB workspace can be accessed through the exported `matlab_workspace` variable.
```julia
julia> matlab_workspace.a
3×3 Matrix{Float64}:
 8.0  1.0  6.0
 3.0  5.0  7.0
 4.0  9.0  2.0
```

## Tips
### Defualt Sharing
To make MATLAB share sessions by default, open your startup file for editing with
```matlab
>> edit(fullfile(userpath,'startup.m'))
```
paste the following lines
```matlab
try
    matlab.engine.shareEngine;
catch e
    warning(['Cannot share MATLAB session.  ' e.message])
end
```
and save the file.

## Attributions
<div>Icon modified from <a href="https://www.flaticon.com/free-icon/car-engine_2061956?term=engine&page=1&position=24&page=1&position=24&related_id=2061956&origin=search" title="car-engine">car-engine</a> made by <a href="https://www.freepik.com" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>
