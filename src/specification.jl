

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

    if length(args) >= 1 && all([arg isa Union{AbstractString,Symbol} for arg in args])

        if label == ""
            label = join(string.(args), ":")
        end
        Spec([args...], nothing, label)

    elseif length(args) == 1 

        if args[1] isa StatsModels.FormulaTerm

            (label == "") && (label = string(args[1]))

            Spec([], args[1], label)
        else
            @error "Specification is not allowed."
        end
    else
        @error "No specification is not provided."
    end
end


"""
    TestSpec

Type that contains the full test specification.
"""
struct StatsTest
    name
    args
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
    push!(tl1.tests, tl2.tests)
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

+(t1::TestSpec, t2::TestSpec) = TestList([t1, t2])
+(t::TestSpec, tl::TestSpecList) = begin 
    push!(tl.tests, t)
    tl
end
+(tl::TestSpecList, t::TestSpec) = begin 
    push!(tl.tests, t)
    tl
end

Base.length(sl::StatsTestList) = length(sl.tests)

"""
    testwith(:testname, args...)

Interface to construct tests.

Provide names of the test or test function.
"""

function testwith(test; args...)
    
    if _iscallable(test)
        StatsTest(test, args)
    else
        @error "No proper test is provided"
    end
end


*(sp::Spec, t::StatsTest) = TestSpecList([TestSpec(sp, t)])
*(sl::SpecList, t::StatsTest) = TestSpecList([TestSpec(sp, t) for sp in sl.specs])
*(sl::SpecList, tl::StatsTestList) = TestSpecList(reshape([TestSpec(sp, t) for sp in sl.specs, t in tl.tests], 1, :)[1,:])



function Base.show(io::IO, s::Spec)

    if s.label != ""

        println(s.label)
    elseif length(s.colnames) == 0

        println(string(s.formula))
    else
        println(s.colnames)
    end
end


function Base.show(io::IO, sl::SpecList)

    for s in sl.specs

        show(io, s)
    end
end



function Base.show(io::IO, t::StatsTest)
    if length(t.args) == 0
        println(string(t.name))
    else

        println(string(t.name), " with args: ", string(t.args))
    end
end

function Base.show(io::IO, tl::StatsTestList)
    for t in tl.tests

        show(io, t)
    end
end

function Base.show(io::IO, t::TestSpec)
    
    show(io, t.spec)
    show(io, t.test)
end
function Base.show(io::IO, t::TestSpecList)
    
    show.(io, t.tests)
end

