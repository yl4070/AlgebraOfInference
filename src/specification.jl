

"""
    Spec

A specification for testing: either a set of column names or a formula (with
its grouping variable).

The `+`/`*` algebra that collects these is defined in `composition.jl`.
"""
struct Spec
    colnames
    formula::Union{Nothing,StatsModels.FormulaTerm}
    label::AbstractString
end



function specify(args...; label = "")

    if length(args) == 1 && args[1] isa StatsModels.FormulaTerm

        (label == "") && (label = string(args[1]))

        Spec(Symbol[], args[1], label)

    elseif !isempty(args) && all(arg -> arg isa Union{AbstractString,Symbol}, args)

        cols = Symbol[Symbol(arg) for arg in args]
        (label == "") && (label = join(string.(cols), ":"))

        Spec(cols, nothing, label)

    elseif isempty(args)
        throw(ArgumentError("No specification is provided."))
    else
        throw(ArgumentError(
            "Specification is not allowed: expected column names (Symbol or String) " *
            "or a single @formula; got $(map(typeof, args))."
        ))
    end
end


"""
    StatsTest

A test with its callable, positional arguments and keyword arguments.
"""
struct StatsTest
    name
    args
    kwargs
end

"""
    TestSpec

A specification paired with the test to apply to it.
"""
struct TestSpec
    spec::Spec
    test::StatsTest
end

"""
    testwith(:testname, args...)

Interface to construct tests.

Provide names of the test or test function.
"""

function testwith(test, args...; kwargs...)

    if _iscallable(test)
        StatsTest(test, args, (; kwargs...))
    else
        throw(ArgumentError("No proper test is provided: $(test) is not callable."))
    end
end



function Base.show(io::IO, s::Spec)

    if !isempty(s.label)

        print(io, s.label)
    elseif isempty(s.colnames)

        print(io, something(s.formula, ""))
    else
        print(io, join(s.colnames, ":"))
    end
end


function Base.show(io::IO, t::StatsTest)

    print(io, string(t.name))
    isempty(t.args) || print(io, " with args: ", t.args)
    isempty(t.kwargs) || print(io, " with kwargs: ", t.kwargs)
end

function Base.show(io::IO, t::TestSpec)

    show(io, t.spec)
    print(io, " | ")
    show(io, t.test)
end

