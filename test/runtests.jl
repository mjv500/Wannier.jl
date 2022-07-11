using Wannier
using Test

const TEST_PATH = @__DIR__
const FIXTURE_PATH = "$TEST_PATH/fixtures"


@testset "Wannier.jl" begin
    include("io/w90.jl")
    include("io/model.jl")
    include("bvector.jl")
    include("spread.jl")
    include("util/kpoint.jl")
    include("util/io.jl")

    include("wannierize/max_localize.jl")
    include("wannierize/opt_rotate.jl")
    include("wannierize/split.jl")
    include("wannierize/parallel_transport.jl")

    include("cli/help.jl")

    include("interpolate/band.jl")
end
