#!/usr/bin/env julia
import ArgParse
import Wannier as Wan

function parse_commandline()
    s = ArgParse.ArgParseSettings()
    @ArgParse.add_arg_table s begin
        # "--opt1"
        #     help = "an option with an argument"
        "--fermi_energy", "-f"
            help = "Fermi energy"
            arg_type = Union{Int, Float64}
            default = 0
        # "--flag1"
        #     help = "an option without argument, i.e. a flag"
        #     action = :store_true
        "qebands"
            help = "Filename of QE bands.x output bands.dat file"
            required = true
        "qeprojs"
            help = "Filename of QE projwfc.x output prefix.proj.dat.projwfc_up file"
            required = true
    end
    return ArgParse.parse_args(s)
end

function main()
    parsed_args = parse_commandline()
    
    f_qe_bands = parsed_args["qebands"]
    f_qe_projs = parsed_args["qeprojs"]
    fermi_energy = parsed_args["fermi_energy"]

    qe_bands = Wan.InOut.read_qe_bands(f_qe_bands)
    qe_projs = Wan.InOut.read_qe_projwfcup(f_qe_projs)

    Wan.plot_bands_projectabilities(qe_bands, qe_projs; fermi_energy=fermi_energy)

    print("Hit <enter> to continue")
    readline()
end

main()
