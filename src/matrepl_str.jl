_interpolate(expr) = expr
function _interpolate(expr::Expr)
    if expr.head == :($)
        x = Base.eval(Main, expr.args[1])
        return x isa AbstractVector ? reshape(x, length(x), 1) : x
    else
        return Expr(expr.head, _interpolate.(expr.args)...)
    end
    return expr
end

function _convert_mat(pyobj)
    shape = py"np.shape($pyobj)"
    return _convert_mat(pyobj, shape)
end
_convert_mat(pyobj, shape::Tuple{}) = pyobj
_convert_mat(pyobj, shape::Tuple) = [_convert_mat(reduce((obj, i)->obj[i], Tuple(inds), init=pyobj)) for inds in CartesianIndices(shape)]

function _matrepl_str(str)
    expr = Meta.parse(str)
    if expr isa Expr && expr.head == :(=)
        lhs, rhs = expr.args
        rhs = _interpolate(rhs)
        if lhs isa Expr && lhs.head == :($)
            rhs = _convert_mat(py"eng.eval($(string(rhs)), nargout=1)")
            return esc(:($(lhs.args[1]) = $rhs))
        else
            str = string(lhs) * "=" * string(rhs)
            return quote $(py"eng.eval($str, nargout=0)") end
        end
    end
    
    return quote $(_convert_mat(py"eng.eval($str, nargout=1)")) end
end


"""
    matrepl"...MATLAB code..."
    out = matrepl"...MATLAB code..."

Runs MATLAB code in open MATLAB engine session

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
macro matrepl_str(expr)
    _matrepl_str(expr)
end