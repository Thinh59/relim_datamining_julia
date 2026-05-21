using Test
include(joinpath(@__DIR__, "../src/algorithm/relim.jl"))

function parse_spmf_output(filepath::String)
    result = Dict{Vector{Int}, Int}()
    if !isfile(filepath) return result end
    open(filepath) do io
        for line in eachline(io)
            s = strip(line)
            isempty(s) && continue
            parts = split(s, "#SUP:")
            if length(parts) == 2
                items_str = strip(parts[1])
                items = isempty(items_str) ? Int[] : parse.(Int, split(items_str))
                sup = parse(Int, strip(parts[2]))
                result[sort(items)] = sup
            end
        end
    end
    return result
end

function compare_with_spmf(our_result_dict, spmf_output_file)
    spmf_result = parse_spmf_output(spmf_output_file)
    our_set = Set(keys(our_result_dict))
    spmf_set = Set(keys(spmf_result))
    
    union_len = length(union(our_set, spmf_set))
    match_rate = union_len == 0 ? 1.0 : length(intersect(our_set, spmf_set)) / union_len
    
    support_correct = true
    for k in intersect(our_set, spmf_set)
        if our_result_dict[k] != spmf_result[k]
            support_correct = false
            break
        end
    end
    return match_rate, support_correct
end

@testset "Correctness Check with SPMF" begin
    tests = [
        ("chess", "data/benchmark/chess.txt", [1598, 2557]),
        ("mushroom", "data/benchmark/mushroom.txt", [812, 4062]),
        ("retail", "data/benchmark/retail.txt", [882, 4408]),
        ("accidents", "data/benchmark/accidents.txt", [170091, 255137]),
        ("T10I4D100K", "data/benchmark/T10I4D100K.txt", [1000, 5000])
    ]

    for (name, filepath, minsups) in tests
        if !isfile(filepath)
            println("Bỏ qua $name vì chưa có file data.")
            continue
        end
        @testset "Dataset: $name" begin
            # Đọc và làm sạch dữ liệu (unique + sort)
            txns = load_spmf(filepath)
            txns = [sort(unique(t)) for t in txns if !isempty(t)]
            n_txns = length(txns)
            
            # Ghi file sạch để "mớm" cho SPMF chạy
            clean_filepath = "clean_$(name).txt"
            open(clean_filepath, "w") do io
                for t in txns
                    println(io, join(t, " "))
                end
            end
            
            for ms_abs in minsups
                @testset "Minsup: $ms_abs" begin
                    spmf_out = "spmf_$(name)_$(ms_abs).txt"
                    
                    # Công thức hack để ép Java SPMF làm tròn ra đúng ms_abs
                    ms_pct = (ms_abs - 0.01) / n_txns
                    
                    spmf_cmd = `java -jar spmf.jar run Relim $clean_filepath $spmf_out $ms_pct`
                    run(pipeline(spmf_cmd, stdout=devnull, stderr=devnull))
                    
                    our_result_array = relim(txns, ms_abs; relative=false)
                    our_result_dict = Dict(sort(iset) => sup for (iset, sup) in our_result_array)
                    
                    match_rate, support_correct = compare_with_spmf(our_result_dict, spmf_out)
                    println("[$name] Minsup $ms_abs -> Match Rate: $(round(match_rate*100, digits=2))%, Support Correct: $support_correct")
                    
                    @test match_rate == 1.0
                    @test support_correct == true
                    rm(spmf_out, force=true)
                end
            end
            rm(clean_filepath, force=true)
        end
    end
end
