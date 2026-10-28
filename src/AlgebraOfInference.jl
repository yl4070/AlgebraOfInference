module AlgebraOfInference

using Reexport
@reexport using HypothesisTests
using StatsModels
using Tables: columns, getcolumn, columnnames, columntable
import Base: *, +

export @formula
export specify, testwith, table

function _iscallable(f)

    try
        return !isempty(methods(f))
    catch
        return false
    end
end

include("specification.jl")
include("composition.jl")
include("StatsTests.jl")
include("table.jl")

end



