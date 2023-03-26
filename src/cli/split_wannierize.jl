"""
Split valence and conduction Wannier functions.

Usually start from a Wannierization of valence+conduction bands.
Then this command split WFs into two independent groups.

# Args

- `seedname`: seedname for `win`/`amn`/`mmn`/`eig` files

# Options

- `--nval`: number of valence WFs. Default is `n_wann ÷ 2`
- `--outdir-val`: dirname for output valence `amn`/`mmn`/`eig`. Default is `val`
- `--outdir-cond`: dirname for output conduction `amn`/`mmn`/`eig`. Default is `cond`

# Flags

- `--run-disentangle`: read `amn` and run disentangle first, otherwise read `chk` to
    get unitary matrices from `n_bands` to `n_wann`
- `--run-optrot`: max localize w.r.t. single unitary matrix after parallel transport.
    Should further reduce the spread and much closer to the true max localization.
- `--run-maxloc`: run a final max localize w.r.t. all kpoints.
    Should reach the true max localization.
- `--rotate-unk`: generate `unk` files for valence and conduction, for plotting WFs
- `--binary`: write `amn`/`mmn`/`eig`/`unk` in Fortran binary format
"""
@cast function splitvc(
    seedname::String;
    nval::Int=0,
    outdir_val::String="val",
    outdir_cond::String="cond",
    run_disentangle::Bool=false,
    run_optrot::Bool=false,
    run_maxloc::Bool=false,
    rotate_unk::Bool=false,
    binary::Bool=false,
)
    # Input AMN is Silicon s,p projection
    model = read_w90(seedname; amn=false)

    if run_disentangle
        # You can also use disentangle to get a good gauge from initial projection
        model.U .= read_orthonorm_amn("$seedname.amn")
        model.U .= disentangle(model)
    else
        # Get max localized gauge from chk file, 1st try text format, then binary
        if isfile("$seedname.chk.fmt")
            chk = read_chk("$seedname.chk.fmt")
        else
            chk = read_chk("$seedname.chk")
        end
        # We replace the initial projection by the "good" max loc gauge
        model.U .= get_U(chk)
    end

    @info "Valence + conduction initial spread"
    show(omega(model))
    println("\n")

    (nval == 0) && (nval = model.n_wann ÷ 2)
    @info "number of valence WFs = $nval"

    (model_val, Uv), (model_cond, Uc) = split_wannierize(model, nval)

    @info "Valence after parallel transport:"
    show(omega(model_val))
    println("\n")
    @info "Conduction after parallel transport:"
    show(omega(model_cond))
    println("\n")

    if run_optrot
        @info "Run optimal rotation"
        println()
        Wv = opt_rotate(model_val)
        model_val.U .= rotate_U(model_val.U, Wv)
        Wc = opt_rotate(model_cond)
        model_cond.U .= rotate_U(model_cond.U, Wc)
    end

    if run_maxloc
        @info "Run max localization"
        println()
        model_val.U .= max_localize(model_val)
        model_cond.U .= max_localize(model_cond)
    end

    # Write files
    seedname_val = new_seedname(seedname, outdir_val)
    write_w90(seedname_val, model_val; binary=binary)

    seedname_cond = new_seedname(seedname, outdir_cond)
    write_w90(seedname_cond, model_cond; binary=binary)

    # UNK files for plotting WFs
    if rotate_unk
        dir = dirname(seedname)
        if dir == ""
            dir = "."
        end
        outdir_val = dirname(seedname_val)
        outdir_cond = dirname(seedname_cond)
        split_unk(dir, Uv, Uc, outdir_val, outdir_cond; binary=binary)
    end

    return nothing
end

function new_seedname(seedname::String, subdir::String)
    outdir = joinpath(dirname(seedname), subdir)
    !isdir(outdir) && mkdir(outdir)
    return joinpath(outdir, basename(seedname))
end
