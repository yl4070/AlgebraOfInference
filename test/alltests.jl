# Every test constructor exported by HypothesisTests.jl, driven through the
# `specify`/`testwith` interface and checked against a direct HypothesisTests
# call. `TwoSampleTTest` and `TwoSampleZTest` are exported result types rather
# than constructors, so they are checked for a clean error instead.
#
# Matrix-valued columns drive the multivariate and regression tests; a one-row
# specification supplies scalars, which is how the count-based Fisher test is
# reached.

using Random, Statistics
using Distributions: Normal

rng = MersenneTwister(2024)
n = 20
x  = randn(rng, n) .+ 2.0
y  = randn(rng, n) .+ 2.5
z  = randn(rng, n)
bb = [true, false, true, true, false, true, false, false, true, true]
cnt  = [10, 20, 30, 15]
cnt2 = [8, 22, 28, 12]
tab  = [10 5; 3 12]
ang1 = 2π .* rand(rng, 12)
ang2 = mod.(ang1 .+ 0.4 .+ 0.1 .* randn(rng, 12), 2π)
X1 = randn(rng, 20, 2)
X2 = randn(rng, 20, 2) .+ 0.7
Xr = hcat(ones(20), randn(rng, 20), randn(rng, 20))
e  = randn(rng, 20)
e1 = randn(rng, 30)
e2 = e1 .+ 0.2 .* randn(rng, 30)
ts = cumsum(randn(rng, 60))
a1 = randn(rng, 12)
a2 = randn(rng, 14) .+ 0.8
a3 = randn(rng, 11) .- 0.4
px = [1.0, 2.0, 3.0, 4.0]
py = [5.0, 6.0, 7.0, 8.0]
dtab = (a = [10], b = [5], c = [3], d = [12])
dbin = (successes = [3], trials = [10])

d = (; x, y, z, bb, cnt, cnt2, tab, ang1, ang2, X1, X2, Xr, e, e1, e2, ts,
       a1, a2, a3, px, py)

# One specification and one test: run it and take the p-value.
runpkg(spec, test, data = d) = pvalue(only((spec * test)(data)))

gv2  = vcat(a1, a2)
grp2 = vcat(fill("A", length(a1)), fill("B", length(a2)))
gd2  = (v = gv2, grp = grp2)
gv   = vcat(a1, a2, a3)
grp  = vcat(fill("A", length(a1)), fill("B", length(a2)), fill("C", length(a3)))
gd   = (v = gv, grp = grp)


@testset "HypothesisTests.jl coverage" begin

    @testset "one-sample" begin
        @test runpkg(specify(:x), testwith(OneSampleTTest)) ≈ pvalue(OneSampleTTest(x))
        @test runpkg(specify(:x), testwith(OneSampleTTest, 2.0)) ≈ pvalue(OneSampleTTest(x, 2.0))
        @test runpkg(specify(:x), testwith(OneSampleZTest)) ≈ pvalue(OneSampleZTest(x))
        @test runpkg(specify(:x), testwith(OneSampleZTest, 2.0)) ≈ pvalue(OneSampleZTest(x, 2.0))
        @test runpkg(specify(:x), testwith(ShapiroWilkTest)) ≈ pvalue(ShapiroWilkTest(x))
        @test runpkg(specify(:x), testwith(JarqueBeraTest)) ≈ pvalue(JarqueBeraTest(x))
        @test runpkg(specify(:ts), testwith(ADFTest, :constant, 1)) ≈ pvalue(ADFTest(ts, :constant, 1))
        @test runpkg(specify(:ts), testwith(BoxPierceTest, 2)) ≈ pvalue(BoxPierceTest(ts, 2))
        @test runpkg(specify(:ts), testwith(LjungBoxTest, 2)) ≈ pvalue(LjungBoxTest(ts, 2))
        @test runpkg(specify(:x), testwith(SignTest)) ≈ pvalue(SignTest(x))
        @test runpkg(specify(:x), testwith(SignTest, 3.0)) ≈ pvalue(SignTest(x, 3.0))
        @test runpkg(specify(:x), testwith(SignedRankTest)) ≈ pvalue(SignedRankTest(x))
        @test runpkg(specify(:x), testwith(ExactSignedRankTest)) ≈ pvalue(ExactSignedRankTest(x))
        @test runpkg(specify(:x), testwith(ApproximateSignedRankTest)) ≈
              pvalue(ApproximateSignedRankTest(x))
        @test runpkg(specify(:ang1), testwith(RayleighTest)) ≈ pvalue(RayleighTest(ang1))
        # Paired form: two columns are one sample of differences.
        @test runpkg(specify(:x, :y), testwith(OneSampleTTest)) ≈ pvalue(OneSampleTTest(x, y))
        @test runpkg(specify(:x), testwith(WaldWolfowitzTest)) ≈ pvalue(WaldWolfowitzTest(x))
        @test runpkg(specify(:bb), testwith(BinomialTest)) ≈ pvalue(BinomialTest(bb))
        # Success/trial counts are scalars, supplied by a one-row table.
        @test runpkg(specify(:successes, :trials), testwith(BinomialTest), dbin) ≈
              pvalue(BinomialTest(3, 10))
        @test runpkg(specify(:x), testwith(ApproximateOneSampleKSTest, Normal(2, 1))) ≈
              pvalue(ApproximateOneSampleKSTest(x, Normal(2, 1)))
        @test runpkg(specify(:x), testwith(ExactOneSampleKSTest, Normal(2, 1))) ≈
              pvalue(ExactOneSampleKSTest(x, Normal(2, 1)))
        @test runpkg(specify(:x), testwith(OneSampleADTest, Normal(2, 1))) ≈
              pvalue(OneSampleADTest(x, Normal(2, 1)))
        @test runpkg(specify(:X1), testwith(OneSampleHotellingT2Test)) ≈
              pvalue(OneSampleHotellingT2Test(X1))
    end

    @testset "contingency tables" begin
        @test runpkg(specify(:cnt), testwith(ChisqTest)) ≈ pvalue(ChisqTest(cnt))
        @test runpkg(specify(:tab), testwith(ChisqTest)) ≈ pvalue(ChisqTest(tab))
        @test runpkg(specify(:cnt, :cnt2), testwith(ChisqTest)) ≈ pvalue(ChisqTest(cnt, cnt2))
        @test runpkg(specify(:cnt), testwith(PowerDivergenceTest)) ≈
              pvalue(PowerDivergenceTest(cnt))
        @test runpkg(specify(:tab), testwith(PowerDivergenceTest)) ≈
              pvalue(PowerDivergenceTest(tab))
        @test runpkg(specify(:cnt), testwith(MultinomialLRTest)) ≈ pvalue(MultinomialLRTest(cnt))
        @test runpkg(specify(:tab), testwith(MultinomialLRTest)) ≈ pvalue(MultinomialLRTest(tab))

        # Fisher's exact test takes four counts, not samples: a one-row table
        # supplies them as scalars.
        @test runpkg(specify(:a, :b, :c, :d), testwith(FisherExactTest), dtab) ≈
              pvalue(FisherExactTest(10, 5, 3, 12))
    end

    @testset "two-sample" begin
        @test runpkg(specify(:x, :y), testwith(EqualVarianceTTest)) ≈ pvalue(EqualVarianceTTest(x, y))
        @test runpkg(specify(:x, :y), testwith(EqualVarianceTTest, 0.5)) ≈
              pvalue(EqualVarianceTTest(x, y, 0.5))
        @test runpkg(specify(:x, :y), testwith(UnequalVarianceTTest)) ≈
              pvalue(UnequalVarianceTTest(x, y))
        @test runpkg(specify(:x, :y), testwith(EqualVarianceZTest)) ≈ pvalue(EqualVarianceZTest(x, y))
        @test runpkg(specify(:x, :y), testwith(UnequalVarianceZTest)) ≈
              pvalue(UnequalVarianceZTest(x, y))
        @test runpkg(specify(:x, :y), testwith(VarianceFTest)) ≈ pvalue(VarianceFTest(x, y))
        @test runpkg(specify(:x, :y), testwith(ApproximateTwoSampleKSTest)) ≈
              pvalue(ApproximateTwoSampleKSTest(x, y))
        @test runpkg(specify(:x, :y), testwith(MannWhitneyUTest)) ≈ pvalue(MannWhitneyUTest(x, y))
        @test runpkg(specify(:x, :y), testwith(ExactMannWhitneyUTest)) ≈
              pvalue(ExactMannWhitneyUTest(x, y))
        @test runpkg(specify(:x, :y), testwith(ApproximateMannWhitneyUTest)) ≈
              pvalue(ApproximateMannWhitneyUTest(x, y))
        @test runpkg(specify(:x, :y), testwith(SignedRankTest)) ≈ pvalue(SignedRankTest(x, y))
        @test runpkg(specify(:x, :y), testwith(ExactSignedRankTest)) ≈ pvalue(ExactSignedRankTest(x, y))
        @test runpkg(specify(:x, :y), testwith(ApproximateSignedRankTest)) ≈
              pvalue(ApproximateSignedRankTest(x, y))
        @test runpkg(specify(:x, :y), testwith(SignTest)) ≈ pvalue(SignTest(x, y))
        @test runpkg(specify(:x, :y), testwith(CorrelationTest)) ≈ pvalue(CorrelationTest(x, y))
        @test runpkg(specify(:x, :y, :z), testwith(CorrelationTest)) ≈
              pvalue(CorrelationTest(x, y, z))
        @test runpkg(specify(:ang1, :ang2), testwith(FisherTLinearAssociation)) ≈
              pvalue(FisherTLinearAssociation(ang1, ang2))
        @test runpkg(specify(:ang1, :ang2), testwith(JammalamadakaCircularCorrelation)) ≈
              pvalue(JammalamadakaCircularCorrelation(ang1, ang2))
        @test runpkg(specify(:e1, :e2), testwith(ClarkWestTest)) ≈ pvalue(ClarkWestTest(e1, e2))
        @test runpkg(specify(:e1, :e2), testwith(ClarkWestTest, 2)) ≈
              pvalue(ClarkWestTest(e1, e2, 2))
        @test runpkg(specify(:e1, :e2), testwith(DieboldMarianoTest; loss = abs2, lookahead = 1)) ≈
              pvalue(DieboldMarianoTest(e1, e2; loss = abs2, lookahead = 1))
        @test runpkg(specify(:px, :py), testwith(ExactPermutationTest, mean)) ≈
              pvalue(ExactPermutationTest(px, py, mean))
        @test 0 ≤ runpkg(specify(:x, :y), testwith(ApproximatePermutationTest, mean, 1000)) ≤ 1
    end

    @testset "multivariate and regression" begin
        @test runpkg(specify(:X1, :X2), testwith(BartlettTest)) ≈ pvalue(BartlettTest(X1, X2))
        @test runpkg(specify(:X1, :X2), testwith(EqualCovHotellingT2Test)) ≈
              pvalue(EqualCovHotellingT2Test(X1, X2))
        @test runpkg(specify(:X1, :X2), testwith(UnequalCovHotellingT2Test)) ≈
              pvalue(UnequalCovHotellingT2Test(X1, X2))
        @test runpkg(specify(:Xr, :e), testwith(WhiteTest; type = :linear)) ≈
              pvalue(WhiteTest(Xr, e; type = :linear))
        @test runpkg(specify(:Xr, :e), testwith(DurbinWatsonTest; p_compute = :approx)) ≈
              pvalue(DurbinWatsonTest(Xr, e; p_compute = :approx))
        @test runpkg(specify(:Xr, :e), testwith(BreuschGodfreyTest, 1)) ≈
              pvalue(BreuschGodfreyTest(Xr, e, 1))
        @test runpkg(specify(:Xr, :e), testwith(BreuschPaganTest)) ≈ pvalue(BreuschPaganTest(Xr, e))
    end

    @testset "k-sample" begin
        @test runpkg(specify(:a1, :a2, :a3), testwith(KruskalWallisTest)) ≈
              pvalue(KruskalWallisTest(a1, a2, a3))
        @test runpkg(specify(:a1, :a2, :a3), testwith(OneWayANOVATest)) ≈
              pvalue(OneWayANOVATest(a1, a2, a3))
        @test runpkg(specify(:a1, :a2, :a3), testwith(BrownForsytheTest)) ≈
              pvalue(BrownForsytheTest(a1, a2, a3))
        @test runpkg(specify(:a1, :a2, :a3), testwith(FlignerKilleenTest)) ≈
              pvalue(FlignerKilleenTest(a1, a2, a3))
        @test runpkg(specify(:a1, :a2, :a3), testwith(LeveneTest)) ≈ pvalue(LeveneTest(a1, a2, a3))
        @test runpkg(specify(:a1, :a2, :a3), testwith(LeveneTest; statistic = median)) ≈
              pvalue(LeveneTest(a1, a2, a3; statistic = median))
        @test 0 ≤ runpkg(specify(:a1, :a2, :a3), testwith(KSampleADTest; nsim = 200)) ≤ 1
    end

    @testset "formula grouping" begin
        @test runpkg(specify(@formula(v ~ grp)), testwith(EqualVarianceTTest), gd2) ≈
              pvalue(EqualVarianceTTest(a1, a2))
        @test runpkg(specify(@formula(v ~ grp)), testwith(MannWhitneyUTest), gd2) ≈
              pvalue(MannWhitneyUTest(a1, a2))
        @test runpkg(specify(@formula(v ~ grp)), testwith(KruskalWallisTest), gd) ≈
              pvalue(KruskalWallisTest(a1, a2, a3))
        @test runpkg(specify(@formula(v ~ grp)), testwith(OneWayANOVATest), gd) ≈
              pvalue(OneWayANOVATest(a1, a2, a3))
        @test runpkg(specify(@formula(v ~ grp)), testwith(LeveneTest), gd) ≈
              pvalue(LeveneTest(a1, a2, a3))
        @test 0 ≤ runpkg(specify(@formula(v ~ grp)), testwith(KSampleADTest; nsim = 200), gd) ≤ 1
    end

    @testset "non-constructors and errors" begin
        # These two names are exported result types, not test constructors.
        @test_throws ArgumentError testwith(TwoSampleTTest)
        @test_throws ArgumentError testwith(TwoSampleZTest)

        # A multi-row specification cannot supply Fisher's four counts; the
        # error should say so instead of raising a MethodError.
        err = try
            runpkg(specify(:x, :y, :z, :e), testwith(FisherExactTest))
            nothing
        catch caught
            caught
        end
        @test err isa ArgumentError
        @test occursin("scalar", sprint(showerror, err))
    end
end
