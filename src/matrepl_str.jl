_convert_py_output(thing) = thing
_convert_py_output(dict::Dict) = NamedTuple{(Symbol.(keys(dict))...,)}(_convert_py_output.(values(dict)))
_convert_py_output(arr::Array{Any}) = _convert_py_output.(arr)
_convert_py_output(arr::Array{PyCall.PyObject}) = _convert_py_output.(arr)

function _convert_py_output(pyobj::PyObject)
    type = py"type($pyobj).__name__"
    if type == "double"
        shape = py"np.shape($pyobj)"
        return _convert_array(pyobj, shape)
    else
        return pyobj
    end
end

_convert_array(pyobj::PyObject, shape::Tuple{}) = pyobj
_convert_array(pyobj::PyObject, shape::Tuple) = [_convert_py_output(reduce((obj, i)->obj[i], Tuple(inds), init=pyobj)) for inds in CartesianIndices(shape)]


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
    return string(Base.eval(Main, _interpolate(Meta.parse(str))))
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


function _try_parse(str)
    try
        Meta.parse(str)
    catch
        str
    end
end


function _split_expression(str)
    strs = split(_preprocess(str), "=")
    lhs = _postprocess(strs[1])
    rhs = _postprocess(length(strs)==1 ? "" : join(strs[2:end]))
    rhs = interpolate(rhs)
    return lhs, rhs
end


_string_string(s::String) = "'$s'"
_string_string(s) = s


function _matrepl_str(str; repl=false)
    lhs, rhs = _split_expression(str)
    lhs_parsed = _try_parse(lhs)

    if rhs == ""
        lhs = interpolate(lhs)
        nargout = Int(!repl)
        return quote $(_convert_py_output(py"eng.eval($lhs, nargout=$nargout)")) end

    elseif lhs_parsed isa Expr && lhs_parsed.head == :($)
        rhs = _convert_py_output(py"eng.eval($rhs, nargout=1)")
        return esc(:($(lhs_parsed.args[1]) = $rhs))

    elseif lhs_parsed isa Expr && (lhs_parsed.head == :vect || lhs_parsed.head == :hcat)
        # rhs = _convert_py_output.(py"eng.eval($rhs, nargout=$(length(lhs_parsed.args)))")
        rhs = py"eng.eval($rhs, nargout=$(length(lhs_parsed.args)))"

        block = map(zip(lhs_parsed.args, rhs)) do (arg, expr)
            if arg isa Expr && arg.head ==:($)
                esc(:($(arg.args[1]) = $(_convert_py_output(expr))))

            else
                str = string(arg) * "=" * _string_string(expr)
                quote $(py"eng.eval($str, nargout=0)") end
            end
        end

        return Expr(:block, block...)

    else
        str = lhs * "=" * rhs
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