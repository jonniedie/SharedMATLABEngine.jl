function _mat_str(str; repl=false)
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
    _mat_str(expr)
end

macro matrepl_str(expr)
    _mat_str(expr; repl=true)
end