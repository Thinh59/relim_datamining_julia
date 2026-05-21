function load_spmf(path::AbstractString)::Vector{Vector{Int}}
    txns = Vector{Vector{Int}}()
    open(path) do io
        for line in eachline(io)
            s = strip(line)
            isempty(s) && continue
            s = replace(s, "," => " ")
            # Dùng unique để loại bỏ item trùng lặp trong 1 dòng
            push!(txns, unique(parse.(Int, split(s))))
        end
    end
    return txns
end

function save_spmf(results::Vector{Tuple{Vector{Int},Int}}, path::AbstractString)
    open(path, "w") do io
        for (iset, sup) in results
            print(io, join(sort(iset), ' '))
            println(io, " #SUP: ", sup)
        end
    end
    return path
end

function count_support(itemset::AbstractVector{Int}, transactions::Vector{Vector{Int}})::Int
    s = Set(itemset)
    c = 0
    for t in transactions
        issubset(s, Set(t)) && (c += 1)
    end
    return c
end

function parse_cli(args::Vector{String})
    input = ""; output = "frequent_itemsets.txt"; minsup = 0.0; absolute = false
    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--input"
            input = args[i+1]; i += 2
        elseif a == "--output"
            output = args[i+1]; i += 2
        elseif a == "--minsup"
            minsup = parse(Float64, args[i+1]); i += 2
        elseif a == "--absolute"
            absolute = true; i += 1
        else
            error("Tham số không nhận diện: $a")
        end
    end
    return (input=input, output=output, minsup=minsup, absolute=absolute)
end
