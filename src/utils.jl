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
    # This is taken from https://github.com/JuliaInterop/MATLAB.jl/blob/6e859c1a126b345662b0282a70c9c0c89d9a2762/src/matstr.jl#L99
    str = string("\"\"\"", replace(str, "\"\"\"" => "\\\"\"\""), "\"\"\"")
    return string(Base.eval(Main, _interpolate(Meta.parse(str))))
end

function _interpolate(expr::Expr)
    if expr.head == :call
        expr = _interpolate(Base.eval(Main, expr))
    elseif expr.head == :vect
        expr = Expr(:call, :reshape, expr, :, 1)
    else
        expr = Expr(expr.head, _interpolate.(expr.args)...)
    end
    return expr
end
_interpolate(sym::Symbol) = _interpolate(Base.eval(Main, sym))
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
_string_string(s) = string(s)


_string_for_matlab(x::AbstractVector) = replace(string(x), ","=>";")
_string_for_matlab(x) = string(x)