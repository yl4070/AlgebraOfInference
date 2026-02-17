module AlgebraOfInference

using Reexport
@reexport using HypothesisTests
using StatsModels
using Tables: columns, getcolumn, columnnames, columntable
import Base: *, +

export @formula
export specify, testwith, table

_iscallable(f) = !isempty(methods(f))

include("specification.jl")
include("StatsTests.jl")
include("table.jl")

end



