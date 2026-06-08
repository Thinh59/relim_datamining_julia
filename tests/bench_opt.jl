# ============================================================
# Benchmark so sánh bản cơ bản (Level 1, counter_only=false) và
# bản tối ưu (Level 3, counter_only=true) của Relim.
#
# Đo: thời gian (ms) bằng BenchmarkTools, bộ nhớ cấp phát (MB) bằng @allocated.
# Chạy: julia --project=. tests/bench_opt.jl
# ============================================================

using BenchmarkTools
using Printf
include(joinpath(@__DIR__, "..", "src", "algorithm", "relim.jl"))

# (tên hiển thị, đường dẫn, minsup tương đối)
const CASES = [
    ("Mushroom", "data/benchmark/mushroom.txt", 0.30),
    ("Chess",    "data/benchmark/chess.txt",    0.80),
]

function bench_case(name, path, ms)
    txns = load_spmf(path)
    txns = [sort(unique(t)) for t in txns if !isempty(t)]
    n = length(txns)

    # Warm-up (loại chi phí biên dịch JIT)
    relim(txns, ms; counter_only=false)
    relim(txns, ms; counter_only=true)

    nF = length(relim(txns, ms; counter_only=true))

    # Thời gian: lấy min của nhiều mẫu (ổn định nhất)
    t_base = @belapsed relim($txns, $ms; counter_only=false)
    t_opt  = @belapsed relim($txns, $ms; counter_only=true)

    # Bộ nhớ cấp phát
    m_base = @allocated relim(txns, ms; counter_only=false)
    m_opt  = @allocated relim(txns, ms; counter_only=true)

    @printf("%-10s n=%-6d minsup=%.2f  |F|=%d\n", name, n, ms, nF)
    @printf("   Time(ms): base=%.2f  opt=%.2f  (x%.2f nhanh hon)\n",
            t_base*1e3, t_opt*1e3, t_base/t_opt)
    @printf("   Mem(MB) : base=%.2f  opt=%.2f  (giam %.1f%%)\n",
            m_base/2^20, m_opt/2^20, 100*(1 - m_opt/m_base))
    flush(stdout)
end

for (name, path, ms) in CASES
    isfile(path) || (println("SKIP $name (khong co file)"); continue)
    bench_case(name, path, ms)
end
