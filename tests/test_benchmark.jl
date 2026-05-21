using Profile
using BenchmarkTools
using Random
using StatsBase

include(joinpath(@__DIR__, "../src/algorithm/relim.jl"))

function run_benchmark()
    datasets = [
        ("chess", "data/benchmark/chess.txt", [0.90, 0.80, 0.70, 0.60, 0.50]),
        ("mushroom", "data/benchmark/mushroom.txt", [0.50, 0.40, 0.30, 0.20, 0.10]),
        ("retail", "data/benchmark/retail.txt", [0.05, 0.04, 0.03, 0.02, 0.01]),
        ("accidents", "data/benchmark/accidents.txt", [0.90, 0.80, 0.70, 0.60, 0.50]),
        ("T10I4D100K", "data/benchmark/T10I4D100K.txt", [0.05, 0.04, 0.03, 0.02, 0.01])
    ]

    println("1. RUNTIME & ITEMSETS VS MINSUP")
    for (name, filepath, minsups) in datasets
        println("Dataset: $name")
        txns = load_spmf(filepath)
        for ms in minsups
            t = @elapsed res = relim(txns, ms; relative=true)
            println("  Minsup $ms: Runtime = $(round(t*1000, digits=2)) ms, #Itemsets = $(length(res))")
        end
        println()
    end

    println("2. MEMORY USAGE")
    mem_minsups = [
        ("chess", 0.50), ("mushroom", 0.10), ("retail", 0.01),
        ("accidents", 0.50), ("T10I4D100K", 0.01)
    ]
    for (name, ms) in mem_minsups
        filepath = "data/benchmark/$name.txt"
        txns = load_spmf(filepath)
        # compile first
        relim(txns, ms; relative=true)
        GC.gc()
        allocs = @allocated relim(txns, ms; relative=true)
        println("Dataset: $name, Minsup $ms -> Peak Memory (Allocated): $(round(allocs / 1024^2, digits=2)) MB")
    end
    println()

    println("3. SCALABILITY (RETAIL DATASET)")
    txns = load_spmf("data/benchmark/retail.txt")
    n_total = length(txns)
    percentages = [0.10, 0.25, 0.50, 0.75, 1.00]
    fixed_minsup_abs = max(1, ceil(Int, 0.01 * n_total)) # absolute
    for p in percentages
        n = round(Int, p * n_total)
        subset = txns[1:n]
        t = @elapsed relim(subset, fixed_minsup_abs; relative=false)
        println("  Subset $(round(p*100))% ($n trans) -> Runtime: $(round(t*1000, digits=2)) ms")
    end
    println()

    println("4. EFFECT OF TRANSACTION LENGTH")
    function generate_synthetic_db(n_trans, avg_len, n_items, seed=42)
        Random.seed!(seed)
        db = Vector{Vector{Int}}()
        for _ in 1:n_trans
            len = max(1, round(Int, avg_len + randn() * 2))
            items = sort(sample(1:n_items, min(len, n_items), replace=false))
            push!(db, items)
        end
        return db
    end

    avg_lens = [5, 10, 15, 20, 25, 30]
    n_trans = 10000
    n_items = 100
    for al in avg_lens
        db = generate_synthetic_db(n_trans, al, n_items)
        t = @elapsed relim(db, 0.1; relative=true)
        println("  AvgLen $al -> Runtime: $(round(t*1000, digits=2)) ms")
    end
end

run_benchmark()
