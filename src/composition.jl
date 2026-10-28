"""
    Composite{T}

A list of algebraic objects (`Spec`, `StatsTest` or `TestSpec`) built with `+`
and `*`. `+` concatenates composites and `*` takes their Cartesian product.

`Composite` is an `AbstractVector`, so indexing, iteration and `length` come for
free. Operations are pure: they always return a new composite.
"""
struct Composite{T} <: AbstractVector{T}
    items::Vector{T}
end

const Atomic = Union{Spec,StatsTest,TestSpec}

const SpecList = Composite{Spec}
const StatsTestList = Composite{StatsTest}
const TestSpecList = Composite{TestSpec}

Base.size(c::Composite) = size(c.items)
Base.getindex(c::Composite, i::Int) = c.items[i]
Base.IndexStyle(::Type{<:Composite}) = IndexLinear()


# -- concatenation -----------------------------------------------------------

+(a::T, b::T) where {T<:Atomic} = Composite{T}([a, b])
+(c::Composite{T}, x::T) where {T<:Atomic} = Composite{T}(vcat(c.items, x))
+(x::T, c::Composite{T}) where {T<:Atomic} = Composite{T}(vcat(x, c.items))
+(a::Composite{T}, b::Composite{T}) where {T<:Atomic} = Composite{T}(vcat(a.items, b.items))


# -- Cartesian product -------------------------------------------------------

_atoms(x::Atomic) = (x,)
_atoms(c::Composite{T}) where {T<:Atomic} = c.items

_product(specs, tests) = Composite{TestSpec}(
    vec([TestSpec(s, t) for s in _atoms(specs), t in _atoms(tests)])
)

*(a::Union{Spec,SpecList}, b::Union{StatsTest,StatsTestList}) = _product(a, b)
*(a::Union{StatsTest,StatsTestList}, b::Union{Spec,SpecList}) = _product(b, a)


# -- printing ----------------------------------------------------------------

function _showlines(io::IO, items)

    for (i, item) in enumerate(items)

        (i > 1) && print(io, '\n')
        show(io, item)
    end
end

Base.show(io::IO, c::Composite) = _showlines(io, c.items)
Base.show(io::IO, ::MIME"text/plain", c::Composite) = show(io, c)
