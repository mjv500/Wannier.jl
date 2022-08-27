"""
    struct RGrid(basis, X, Y, Z)

Represents a regular grid of points.

# Fields
- `basis`: each column is a basis vector of the grid,
    usually just the lattice vectors.
- `X`: `nx * ny * nz` array of fractional coordinate w.r.t `basis`,
    the x coordinate of each point in the grid.
- `Y`: `nx * ny * nz` array of fractional coordinate w.r.t `basis`,
    the y coordinate of each point in the grid.
- `Z`: `nx * ny * nz` array of fractional coordinate w.r.t `basis`,
    the z coordinate of each point in the grid.

!!! tip

    The `X`, `Y`, and `Z` are usually generated by `LazyGrids.ndgrid`.
    They are fractional and can be outside of `[0, 1)`, so the `basis`
    are not necessarily the spanning vectors of the grid.
    See also [`origin`](@ref origin) and [`span_vectors`](@ref span_vectors).

    Usually the grid does not contain the periodically repeated points,
    e.g., the x coordinate can be `[0.0, 0.25, 0.5, 0.75]` without `1.0`
    which is repeatition of `0.0`.
"""
struct RGrid{T<:Real,XT<:AbstractArray3,YT<:AbstractArray3,ZT<:AbstractArray3}
    # spanning vectors, 3 * 3, each column is a spanning vector
    basis::Mat3{T}

    # usually these are LazyGrids
    # x fractional coordinate, nx * ny * nz
    X::XT
    # y fractional coordinate, nx * ny * nz
    Y::YT
    # z fractional coordinate, nx * ny * nz
    Z::ZT
end

function RGrid(basis::AbstractMatrix, X, Y, Z)
    size(X) == size(Y) == size(Z) || error("X, Y, Z must have the same size")
    return RGrid(Mat3(basis), X, Y, Z)
end

"""
    origin(rgrid::RGrid)

Get the origin, i.e. the 1st point, of the `RGrid`.
"""
function origin(rgrid::RGrid)
    O = [rgrid.X[1, 1, 1], rgrid.Y[1, 1, 1], rgrid.Z[1, 1, 1]]
    origin = rgrid.basis * O
    return origin
end

"""
    span_vectors(rgrid::RGrid)

Get the spanning vectors of the `RGrid`.

Each column in the returned matrix is a spanning vector.

!!! note

    There is no limit constraint on the fractional coordinates `X`, `Y`, and `Z`,
    so the spanning vectors are not necessarily the basis vectors,
    they can be fractional of the basis vectors, or multiple times of that.
"""
function span_vectors(rgrid::RGrid)
    O = [rgrid.X[1, 1, 1], rgrid.Y[1, 1, 1], rgrid.Z[1, 1, 1]]
    v1 = [rgrid.X[end, 1, 1], rgrid.Y[end, 1, 1], rgrid.Z[end, 1, 1]] - O
    v2 = [rgrid.X[1, end, 1], rgrid.Y[1, end, 1], rgrid.Z[1, end, 1]] - O
    v3 = [rgrid.X[1, 1, end], rgrid.Y[1, 1, end], rgrid.Z[1, 1, end]] - O
    # to cartesian
    v1 = rgrid.basis * v1
    v2 = rgrid.basis * v2
    v3 = rgrid.basis * v3
    # each column is a vector
    spanvec = hcat(v1, v2, v3)
    return spanvec
end

"""
    cartesianize_xyz(rgrid::RGrid)

Return `X`, `Y`, `Z` in cartesian coordinates.

The size of the returned `X`, `Y`, `Z` are `nx * ny * nz`.
"""
function cartesianize_xyz(rgrid::RGrid)
    XYZ = vcat(reshape(rgrid.X, :)', reshape(rgrid.Y, :)', reshape(rgrid.Z, :)')
    XYZᶜ = rgrid.basis * XYZ
    Xᶜ = reshape(XYZᶜ[1, :], size(rgrid.X)...)
    Yᶜ = reshape(XYZᶜ[2, :], size(rgrid.X)...)
    Zᶜ = reshape(XYZᶜ[3, :], size(rgrid.X)...)
    return Xᶜ, Yᶜ, Zᶜ
end
