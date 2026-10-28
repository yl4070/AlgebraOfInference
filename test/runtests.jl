using AlgebraOfInference
using Test

@testset "AlgebraOfInference.jl" begin
    sp1 = specify(:a)
    sp2 = specify("b")
    sl = (sp1 + sp2)
    @test sl[1] == sp1
    @test sl[2] == sp2

    sp3 = specify("c")
    sl2 = sl + sp3
    @test sl2[3] == sp3
    @test length(sl) == 2

    include("hypotests.jl")
    include("alltests.jl")
end
