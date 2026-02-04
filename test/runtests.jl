using AlgebraOfInference
using Test

@testset "AlgebraOfInference.jl" begin
    sp1 = specify(:a)
    sp2 = specify("b")
    sl = (sp1 + sp2)
    @test sl.specs[1] == sp1
    @test sl.specs[2] == sp2

    sp3 = specify("c")
    sl2 = sl + sp3 
    @test sl2.specs[3] == sp3

    t1 = testwith(:ttest)
    t2 = testwith(:ttest,  mu = 0, sig = 1)
    @test length((sl2 * (t1 + t2)).tests) == 6
end
