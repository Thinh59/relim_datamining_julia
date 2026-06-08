# ============================================================
# Unit test (Level 2, Chương 3): kiểm chứng tính đúng đắn của CÀI ĐẶT một
# cách độc lập, không phụ thuộc dữ liệu/công cụ ngoài, bằng cách đối chứng
# với brute-force (liệt kê mọi tập con + đếm support).
#
# (Phần so sánh với SPMF trên benchmark ở các file
#  test_correctness.jl / test_benchmark.jl -- thuộc Chương 4.)
#
# Chạy: julia --project=. tests/test_unit.jl
# ============================================================

using Test
using Random
include(joinpath(@__DIR__, "..", "src", "algorithm", "relim.jl"))

# Brute-force: liệt kê mọi subset, đếm support. Chỉ dùng cho test.
function brute_force_fim(transactions::Vector{Vector{Int}}, minsup_abs::Int)
    items = sort(collect(Set(reduce(vcat, transactions; init = Int[]))))
    result = Tuple{Vector{Int},Int}[]
    sets = [Set(t) for t in transactions]
    for mask in 1:(2^length(items) - 1)
        subset = Int[]
        for (j, it) in enumerate(items)
            (mask >> (j - 1)) & 1 == 1 && push!(subset, it)
        end
        sub_s = Set(subset)
        c = count(t -> issubset(sub_s, t), sets)
        c >= minsup_abs && push!(result, (sort(subset), c))
    end
    return result
end

normalize(res) = Set((Tuple(sort(s)), c) for (s, c) in res)

@testset "RELIM unit tests" begin
    @testset "Toy example (paper-like)" begin
        txns = [[1, 3, 4], [2, 3, 5], [1, 2, 3, 5], [2, 5]]
        got = relim(txns, 2; relative = false)
        @test length(got) == 9
        @test normalize(got) == normalize(brute_force_fim(txns, 2))
    end

    @testset "Empty / no frequent items" begin
        @test isempty(relim(Vector{Vector{Int}}(), 0.5))
        @test isempty(relim([[1, 2], [3, 4]], 5; relative = false))
    end

    @testset "Single-item transactions" begin
        txns = [[1], [1], [2], [2], [2]]
        got = relim(txns, 0.4)  # abs = 2
        @test normalize(got) == Set([((1,), 2), ((2,), 3)])
    end

    @testset "All items frequent (dense)" begin
        txns = [[1, 2, 3], [1, 2, 3], [1, 2, 3]]
        got = relim(txns, 1.0)
        @test normalize(got) == normalize(brute_force_fim(txns, 3))
        @test length(got) == 7  # 2^3 - 1
    end

    @testset "Counter-Only ON vs OFF cho cùng kết quả" begin
        txns = [[1, 3, 4], [2, 3, 5], [1, 2, 3, 5], [2, 5], [1, 2, 3]]
        on  = relim(txns, 2; relative = false, counter_only = true)
        off = relim(txns, 2; relative = false, counter_only = false)
        @test normalize(on) == normalize(off)
    end

    @testset "Randomized small databases vs brute force" begin
        Random.seed!(42)
        for _ in 1:10
            n = rand(5:15)
            nitems = rand(3:6)
            txns = [unique(rand(1:nitems, rand(1:nitems))) for _ in 1:n]
            smin_abs = rand(1:max(1, div(n, 2)))
            got = relim(txns, smin_abs; relative = false)
            @test normalize(got) == normalize(brute_force_fim(txns, smin_abs))
        end
    end
end
