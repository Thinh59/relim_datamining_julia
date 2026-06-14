using Test

@testset "All RELIM Tests" begin
    @testset "Unit Tests" begin
        include("test_unit.jl")
    end

    @testset "Correctness Check with SPMF" begin
        include("test_correctness.jl")
    end
end
