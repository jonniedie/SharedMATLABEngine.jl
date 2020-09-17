_convert_mat(thing) = thing
_convert_mat(dict::Dict) = NamedTuple{(Symbol.(keys(dict))...,)}(_convert_mat.(values(dict)))
function _convert_mat(pyobj::PyObject)
    shape = py"np.shape($pyobj)"
    return _convert_mat(pyobj, shape)
end
_convert_mat(pyobj::PyObject, shape::Tuple{}) = pyobj
_convert_mat(pyobj::PyObject, shape::Tuple) = [_convert_mat(reduce((obj, i)->obj[i], Tuple(inds), init=pyobj)) for inds in CartesianIndices(shape)]


# This is a vector rather than a Dict because we need to apply these in order. I suppose an
# OrderedDict would be more appropriate, but this seems to be working fine for now.
const EQ_MAP = [
    "===" => "#isidentical",
    "!==" => "#!isidentical#",
    "=="  => "#eq#",
    "~="  => "#~eq#",
    "!="  => "#!eq",
    "<="  => "#le#",
    ">="  => "#ge#",
    "=>"  => "#pair#",
]

function _preprocess(str)
    return reduce(EQ_MAP; init=str) do str, pair
        replace(str, pair)
    end
end

function _postprocess(str)
    return reduce(EQ_MAP; init=str) do str, pair
        replace(str, reverse(pair))
    end
end

interpolate(expr) = interpolate(string(expr))
function interpolate(str::String)
    str = string("\"\"\"", replace(str, "\"\"\"" => "\\\"\"\""), "\"\"\"")
    return Base.eval(Main, _interpolate(Meta.parse(str)))
end

function _interpolate(expr::Expr)
    if expr.head == :call
        _interpolate(Base.eval(Main, expr))
    else
        Expr(expr.head, _interpolate.(expr.args)...)
    end
end
_interpolate(sym::Symbol) = _interpolate(Base.eval(Main, sym))
_interpolate(v::AbstractVector) = reshape(v, :, 1)
_interpolate(thing) = thing


function _matrepl_str(str; repl=false)
    
    strs = split(_preprocess(str), "=")
    lhs, rhs = (length(strs)==1 ? (strs[1], "") : (strs[1], join(strs[2:end]))) .|> _postprocess
    rhs = interpolate(rhs)
    lhs = Meta.parse(lhs)

    if rhs == ""
        lhs = interpolate(string(lhs))
        nargout = Int(!repl)
        return quote $(_convert_mat(py"eng.eval($(string(lhs)), nargout=$nargout)")) end
    elseif lhs isa Expr && lhs.head == :($)
        rhs = _convert_mat(py"eng.eval($(string(rhs)), nargout=1)")
        return esc(:($(lhs.args[1]) = $rhs))
    else
        str = string(lhs) * "=" * string(rhs)
        return quote $(py"eng.eval($str, nargout=0)") end
    end
end


"""
    mat"...MATLAB code..."
    out = mat"...MATLAB code..."

Runs MATLAB code in open MATLAB engine session

## Examples
```julia
julia> using SharedMATLAB

julia> matlab_engine(:default_engine);
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
macro mat_str(expr)
    _matrepl_str(expr)
end

macro matrepl_str(expr)
    _matrepl_str(expr; repl=true)
end