
# Testing for various tests from HypothesisTests.jl

# A test with a keyword argument, to check that keywords reach the test function.
shifted(x, y; shift = 0.0) = OneSampleTTest(x .- y .+ shift)


@testset "specification construction" begin
    @test specify(:a).colnames == [:a]
    @test specify("a", "b").colnames == [:a, :b]
    @test specify("a", "b").label == "a:b"
    @test specify(@formula(a ~ b)).label == "a ~ b"
    @test isempty(specify(@formula(a ~ b)).colnames)
end


@testset "specification errors" begin
    @test_throws ArgumentError specify()
    @test_throws ArgumentError specify(42)
    @test_throws ArgumentError testwith(42)
end


@testset "column specifications" begin
    x = [1.0, 2.0, 3.0, 4.0, 5.0]
    y = [6.0, 7.0, 8.0, 9.0, 10.0]
    tbl = (x = x, y = y)

    ts = specify(:x, :y) * testwith(EqualVarianceTTest)
    @test length(ts) == 1
    @test pvalue(only(ts(tbl))) ≈ pvalue(EqualVarianceTTest(x, y))

    ts1 = specify(:x) * testwith(OneSampleTTest)
    @test pvalue(only(ts1(tbl))) ≈ pvalue(OneSampleTTest(x))
end


@testset "formula specifications" begin
    x = [1.0, 2.0, 3.0, 4.0, 5.0]
    y = [6.0, 7.0, 8.0, 9.0, 10.0]
    tbl = (a = [x; y], g = repeat(["g1", "g2"], inner = 5))

    ts = specify(@formula(a ~ g)) * testwith(EqualVarianceTTest)
    @test pvalue(only(ts(tbl))) ≈ pvalue(EqualVarianceTTest(x, y))

    # Transformations on the response are applied before grouping.
    logtbl = (a = exp.([x; y]), g = repeat(["g1", "g2"], inner = 5))
    fs = specify(@formula(log(a) ~ g)) * testwith(EqualVarianceTTest)
    @test pvalue(only(fs(logtbl))) ≈ pvalue(EqualVarianceTTest(x, y))

    # A continuous grouping variable yields one sample per row: a formula
    # mistake that must surface as an argument error, not a MethodError.
    cont = (a = [x; y], g = [x; y])
    @test_throws ArgumentError (specify(@formula(a ~ g)) * testwith(EqualVarianceTTest))(cont)

    # Only one level is present.
    one = (a = x, g = fill("g1", 5))
    @test_throws ArgumentError (specify(@formula(a ~ g)) * testwith(EqualVarianceTTest))(one)

    # Missing column.
    @test_throws ArgumentError (specify(:nope) * testwith(OneSampleTTest))(tbl)
end


@testset "test arguments and keywords" begin
    x = [1.0, 2.0, 3.0, 4.0, 5.0]
    y = [1.0, 4.0, 2.0, 8.0, 5.0]
    tbl = (x = x, y = y)

    with_arg = specify(:x, :y) * testwith(EqualVarianceTTest, 0.5)
    @test pvalue(only(with_arg(tbl))) ≈ pvalue(EqualVarianceTTest(x, y, 0.5))

    with_kw = specify(:x, :y) * testwith(shifted; shift = 1.0)
    @test pvalue(only(with_kw(tbl))) ≈ pvalue(OneSampleTTest(x .- y .+ 1.0))
end


@testset "algebra" begin
    s = specify(:x) + specify(:y)
    @test length(s) == 2

    t = testwith(EqualVarianceTTest) + testwith(UnequalVarianceTTest)
    @test length(t) == 2

    nested = t + (testwith(OneSampleTTest) + testwith(SignTest))
    @test length(nested) == 4

    ts = s * testwith(EqualVarianceTTest)
    @test length(ts) == 2
    @test ts.tests[1].spec.colnames == [:x]
    @test ts.tests[2].spec.colnames == [:y]

    both = (specify(:x) + specify(:y)) *
           (testwith(EqualVarianceTTest) + testwith(UnequalVarianceTTest))
    @test length(both) == 4

    # Products work in either order.
    @test length(testwith(EqualVarianceTTest) * s) == 2
end


@testset "printing" begin
    @test sprint(show, specify(:x)) == "x"
    @test sprint(show, specify(:x) + specify(:y)) == "x\ny"
    @test sprint(show, testwith(EqualVarianceTTest)) == "EqualVarianceTTest"
    @test sprint(show, testwith(EqualVarianceTTest, 0.5)) == "EqualVarianceTTest with args: (0.5,)"
    @test occursin("a ~ g", sprint(show, specify(@formula(a ~ g))))
end
