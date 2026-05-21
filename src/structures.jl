# Cấu trúc dữ liệu cho RELIM: ListNode, RelimEntry, RelimArray.

mutable struct ListNode
    trans::Vector{Int}
    trans_ptr::Int
    next::Union{ListNode,Nothing}
end

mutable struct RelimEntry
    cnt::Int
    head::Union{ListNode,Nothing}
end

RelimEntry() = RelimEntry(0, nothing)

const RelimArray = Vector{RelimEntry}

new_relim_array(k::Int)::RelimArray = [RelimEntry() for _ in 1:k]
