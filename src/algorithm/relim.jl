# API public:
#   relim(transactions, minsup; relative=true, counter_only=true) ->
#       Vector{Tuple{Vector{Int}, Int}}
#
# Tuỳ chọn:
#   - `relative=true`  : minsup in [0,1] (mặc định, phù hợp CLI/SPMF).
#   - `relative=false` : minsup là số tuyệt đối.
#   - `counter_only`   : bật/tắt Counter-Only Optimization để so sánh L1 vs L3.

include(joinpath(@__DIR__, "..", "structures.jl"))
include(joinpath(@__DIR__, "..", "utils.jl"))

#  Hàm chính: Trả về tất cả frequent itemsets cùng support tuyệt đối.

function relim(transactions::Vector{Vector{Int}}, minsup::Real;
               relative::Bool=true,
               counter_only::Bool=true)::Vector{Tuple{Vector{Int},Int}}

    n = length(transactions)
    minsup_abs = relative ? max(1, ceil(Int, minsup * n)) : Int(minsup)

    # Bước 1: đếm support của từng item (1 lần quét)
    counts = Dict{Int,Int}()
    for t in transactions, x in t
        counts[x] = get(counts, x, 0) + 1
    end

    # Bước 2: lọc item phổ biến 
    freq_items = [it for (it, c) in counts if c >= minsup_abs]
    isempty(freq_items) && return Tuple{Vector{Int},Int}[]

    # Remap: item phổ biến -> chỉ số 1..k, sắp theo cnt TĂNG DẦN
    sort!(freq_items; by = it -> (counts[it], it))
    k = length(freq_items)
    item2idx = Dict{Int,Int}(it => i for (i, it) in enumerate(freq_items))
    idx2item = freq_items  # 1..k -> item gốc

    # Bước 3: với mỗi giao dịch, giữ lại item phổ biến và sort theo index
    sorted_txns = Vector{Vector{Int}}()
    sizehint!(sorted_txns, n)
    @inbounds for t in transactions
        filtered = Int[]
        sizehint!(filtered, length(t))
        for x in t
            idx = get(item2idx, x, 0)
            idx == 0 || push!(filtered, idx)
        end
        if !isempty(filtered)
            sort!(filtered)
            push!(sorted_txns, filtered)
        end
    end

    # Bước 4: dựng mảng A ban đầu
    A = new_relim_array(k)
    @inbounds for t in sorted_txns
        i = t[1]
        A[i].cnt += 1
        # "Ẩn" item đầu bằng pointer increment: trans_ptr=2 chỉ vào item kế tiếp.
        A[i].head = ListNode(t, 2, A[i].head)
    end

    # Bước 5: đệ quy
    F = Vector{Tuple{Vector{Int},Int}}()
    prefix = Int[]
    recursive_relim!(A, prefix, minsup_abs, F, idx2item, counter_only)
    return F
end

# Đệ quy chính

function recursive_relim!(A::RelimArray,
                          prefix::Vector{Int},
                          smin::Int,
                          F::Vector{Tuple{Vector{Int},Int}},
                          idx2item::Vector{Int},
                          counter_only::Bool)
    k = length(A)
    @inbounds for i in 1:k
        c = A[i].cnt
        if c >= smin
            push!(prefix, idx2item[i])
            push!(F, (sort(copy(prefix)), c))

            # Conditional DB cho prefix cup {item i}: chứa các item j > i
            # (vì giao dịch được sort theo index tăng dần, item dẫn đầu mới
            # luôn có index lớn hơn i). Cấp phát mảng cùng kích thước k để
            # giữ indexing nhất quán; các entry j <= i sẽ luôn trống.
            A_cond = build_conditional(A[i], k, counter_only)
            recursive_relim!(A_cond, prefix, smin, F, idx2item, counter_only)
            pop!(prefix)
        end
        # Elimination: chuyển toàn bộ node trong A[i] sang A[j] tương ứng.
        reassign!(A[i], A)
    end
end

# Xây conditional DB

function build_conditional(entry::RelimEntry, k_cond::Int, counter_only::Bool)::RelimArray
    A_cond = new_relim_array(k_cond)
    node = entry.head
    @inbounds while node !== nothing
        t = node.trans
        p = node.trans_ptr
        L = length(t)
        if p <= L
            j = t[p]
            # Chỉ giữ item có index < i (đã đảm bảo bởi cách remap: item trong
            # mỗi giao dịch sort tăng theo index, và p chỉ vào item < leading
            # item ở tầng cha - thực tế j <= k_cond).
            if j <= k_cond
                A_cond[j].cnt += 1
                if p + 1 <= L
                    A_cond[j].head = ListNode(t, p + 1, A_cond[j].head)
                elseif !counter_only
                    # Bản L1: vẫn cấp node "rỗng" để giữ tính tổng quát.
                    A_cond[j].head = ListNode(t, p + 1, A_cond[j].head)
                end
            end
        end
        node = node.next
    end
    return A_cond
end

# Reassign (Elimination)

function reassign!(entry::RelimEntry, A::RelimArray)
    node = entry.head
    @inbounds while node !== nothing
        nxt = node.next
        t = node.trans
        p = node.trans_ptr
        L = length(t)
        if p <= L
            j = t[p]
            node.trans_ptr = p + 1
            node.next = A[j].head
            A[j].head = node
            A[j].cnt += 1
        end
        node = nxt
    end
    entry.head = nothing
    entry.cnt = 0
    return entry
end
