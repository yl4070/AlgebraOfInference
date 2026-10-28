import HypothesisTests

struct TestRes{S,R}
    spec::S
    res::R
end

HypothesisTests.pvalue(t::TestRes) = HypothesisTests.pvalue(t.res)


"""
    apply

apply tests

"""


(t::TestSpecList)(data) = apply(t, data)
(t::TestSpec)(data) = apply(t, data)

function apply(tl::TestSpecList, data)

    [
        ts(data) for ts in tl
    ]
end


function apply(t::TestSpec, data)

    cols = prepare_columns(t.spec, data)

    TestRes(t.spec, run_test(t.test, cols))
end


"""
    prepare_columns(spec, data)

Turn a specification into the positional arguments of a hypothesis test: one
sample per column name, or one sample per level of the grouping variable when
the specification is a formula.
"""
function prepare_columns(spec::Spec, data)

    if !isempty(spec.colnames)

        return [_getcolumn(data, col) for col in spec.colnames]
    end

    spec.formula === nothing && throw(ArgumentError(
        "Specification $(spec) has neither column names nor a formula."
    ))

    _formula_columns(spec.formula, data)
end


function _getcolumn(data, col)

    try
        return getcolumn(data, col)
    catch
        throw(ArgumentError(
            "Column $(repr(col)) was not found in the data. " *
            "Available columns: $(columnnames(data))."
        ))
    end
end


function _formula_columns(f::StatsModels.FormulaTerm, data)

    lhs_vars = StatsModels.termvars(f.lhs)
    rhs_vars = StatsModels.termvars(f.rhs)

    length(lhs_vars) == 1 || throw(ArgumentError(
        "A formula specification needs exactly one response variable; got $(lhs_vars)."
    ))
    length(rhs_vars) == 1 || throw(ArgumentError(
        "A formula specification needs exactly one grouping variable; got $(rhs_vars)."
    ))

    # The response goes through modelcols so that transformations such as
    # `log(a) ~ g` are honoured. The grouping variable is taken raw: modelling
    # it would dummy-code a categorical variable and lose the levels.
    y = _as_vector(StatsModels.modelcols(f.lhs, data), "response $(lhs_vars[1])")
    g = _getcolumn(data, rhs_vars[1])

    levels = unique(g)
    length(levels) >= 2 || throw(ArgumentError(
        "Grouping variable $(rhs_vars[1]) has $(length(levels)) level(s); " *
        "at least 2 are needed."
    ))

    [
        _as_vector(getindex(y, findall(==(level), g)), "group $(repr(level))") for
        level in levels
    ]
end


_as_vector(x::AbstractVector, _) = x

function _as_vector(x::AbstractMatrix, what)

    size(x, 2) == 1 || throw(ArgumentError(
        "Expected $(what) to be a single column, got a $(size(x, 1))×$(size(x, 2)) matrix. " *
        "A formula specification needs exactly one response and one grouping variable."
    ))

    vec(x)
end

_as_vector(x, what) = throw(ArgumentError(
    "Expected $(what) to be a vector; got $(typeof(x))."
))


"""
    run_test(test, cols)

Call a test on the samples produced by a specification, turning an arity
mismatch (the usual symptom of a formula with the wrong grouping variable)
into an error that names the test and the number of samples.
"""
function run_test(t::StatsTest, cols)

    f = t.name

    _iscallable(f) || throw(ArgumentError("Test $(f) is not callable."))

    vals = (cols..., t.args...)

    if isempty(t.kwargs) && !applicable(f, vals...)
        hint = isempty(t.args) ? _applicable_arity(f) : ""
        throw(ArgumentError(
            "Test $(string(f)) cannot be applied to $(length(cols)) sample(s) " *
            "of length(s) $(map(length, cols)) with args $(t.args). " *
            "Check the specification: a grouping formula that is not categorical " *
            "usually produces one sample per row. " * hint
        ))
    end

    f(vals...; t.kwargs...)
end


function _applicable_arity(f)

    # Probe with the kinds of sample a specification can produce, rather than
    # reporting every declared method arity (a parametric test constructor
    # usually has a long internal one).
    probes = Any[fill(1.0, 2), fill(1, 2), ["a", "b"]]

    arities = [n for n in 1:6 if any(probe -> applicable(f, ntuple(_ -> probe, n)...), probes)]

    isempty(arities) ? "" : "The test accepts $(join(arities, " or ")) sample(s)."
end
