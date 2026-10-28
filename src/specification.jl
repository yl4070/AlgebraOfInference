

"""
    Spec, SpecList

Specification types for testing.
"""
struct Spec
    colnames
    formula::Union{Nothing,StatsModels.FormulaTerm}
    label::AbstractString
end

struct SpecList
    specs::Vector{Spec}
end

"""
    Base.+

Construct SpecList from Spec
"""
+(s1::Spec,s2::Spec) = SpecList([s1, s2])
+(sl::SpecList, sp::Spec) = begin 
    push!(sl.specs, sp)
    sl
end
+(sp::Spec, sl::SpecList) = begin 
    push!(sl.specs, sp)
    sl
end
+(sl1::SpecList, sl2::SpecList) = SpecList([sl1.specs..., sl2.specs...])



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
    TestSpec

Type that contains the full test specification.
"""
struct StatsTest
    name
    args
    kwargs
end
struct StatsTestList
    tests::Vector{StatsTest}
end
+(t1::StatsTest, t2::StatsTest) = StatsTestList([t1, t2])
+(t::StatsTest, tl::StatsTestList) = begin 
    push!(tl.tests, t)
    tl
end
+(tl::StatsTestList, t::StatsTest) = begin
    push!(tl.tests, t)
    tl
end
+(tl1::StatsTestList, tl2::StatsTestList) = begin
    append!(tl1.tests, tl2.tests)
    tl1
end
    
Base.length(sl::SpecList) = length(sl.specs)

struct TestSpec
    spec::Spec
    test::StatsTest
end

struct TestSpecList
    tests::Vector{TestSpec}
end

+(t1::TestSpec, t2::TestSpec) = TestSpecList([t1, t2])
+(t::TestSpec, tl::TestSpecList) = begin
    push!(tl.tests, t)
    tl
end
+(tl::TestSpecList, t::TestSpec) = begin
    push!(tl.tests, t)
    tl
end
+(tl1::TestSpecList, tl2::TestSpecList) = begin
    append!(tl1.tests, tl2.tests)
    tl1
end

Base.length(sl::StatsTestList) = length(sl.tests)
Base.length(tl::TestSpecList) = length(tl.tests)

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


*(sp::Spec, t::StatsTest) = TestSpecList([TestSpec(sp, t)])
*(t::StatsTest, sp::Spec) = TestSpecList([TestSpec(sp, t)])
*(sp::Spec, tl::StatsTestList) = TestSpecList([TestSpec(sp, t) for t in tl.tests])
*(tl::StatsTestList, sp::Spec) = TestSpecList([TestSpec(sp, t) for t in tl.tests])
*(sl::SpecList, t::StatsTest) = TestSpecList([TestSpec(sp, t) for sp in sl.specs])
*(t::StatsTest, sl::SpecList) = TestSpecList([TestSpec(sp, t) for sp in sl.specs])
*(sl::SpecList, tl::StatsTestList) = TestSpecList(vec([TestSpec(sp, t) for sp in sl.specs, t in tl.tests]))
*(tl::StatsTestList, sl::SpecList) = TestSpecList(vec([TestSpec(sp, t) for sp in sl.specs, t in tl.tests]))



function _showlines(io::IO, items)

    for (i, item) in enumerate(items)

        (i > 1) && print(io, '\n')
        show(io, item)
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


function Base.show(io::IO, sl::SpecList)

    _showlines(io, sl.specs)
end


function Base.show(io::IO, t::StatsTest)

    print(io, string(t.name))
    isempty(t.args) || print(io, " with args: ", t.args)
    isempty(t.kwargs) || print(io, " with kwargs: ", t.kwargs)
end

function Base.show(io::IO, tl::StatsTestList)

    _showlines(io, tl.tests)
end

function Base.show(io::IO, t::TestSpec)

    show(io, t.spec)
    print(io, " | ")
    show(io, t.test)
end
function Base.show(io::IO, t::TestSpecList)

    _showlines(io, t.tests)
end

