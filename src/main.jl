# Entry point CLI cho RELIM.

include(joinpath(@__DIR__, "algorithm", "relim.jl"))

function main()
    opts = parse_cli(copy(ARGS))
    txns = load_spmf(opts.input)
    n = length(txns)
    smin_disp = opts.absolute ? "$(Int(opts.minsup)) (absolute)" :
                                "$(opts.minsup) (relative; abs = $(ceil(Int, opts.minsup * n)))"
    println("Input        : ", opts.input)
    println("# transactions: ", n)
    println("minsup       : ", smin_disp)

    t = @elapsed result = relim(txns, opts.minsup; relative = !opts.absolute)
    save_spmf(result, opts.output)

    println("# frequent itemsets: ", length(result))
    println("Runtime (s)  : ", round(t; digits = 4))
    println("Output       : ", opts.output)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
