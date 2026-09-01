module Sugiyama

using GeometryBasics: Point

export SugiyamaLayout, sugiyama, sugiyama_paths

include("graph.jl")
include("cycles.jl")
include("ranking.jl")
include("ordering.jl")
include("coordinates.jl")

"""
    SugiyamaLayout(; kwargs...)(adj_matrix)
    sugiyama(adj_matrix; kwargs...)

Layered ("hierarchical") layout for directed graphs: vertices are grouped
into ranks, edge crossings between ranks are heuristically minimized, and
coordinates are assigned within each rank. Ranking and crossing
minimization follow Gansner, Koutsofios, North & Vo (1993,
[doi 10.1109/32.221135](https://doi.org/10.1109/32.221135)); coordinate
assignment follows Brandes & Köpf (2002,
[doi 10.1007/3-540-45848-4_3](https://doi.org/10.1007/3-540-45848-4_3)).

Takes the adjacency matrix of a directed graph and returns coordinates of
the nodes as `Point{2,Ptype}`. Cycles are broken
by implicitly reversing edges; disconnected components are laid out
independently and placed side by side.

## Keyword Arguments
- `Ptype=Float64`: Determines the output type `Point{2,Ptype}`.
- `nodesize=Float64[]`: Size of each node. Filled up with `ones` or
  truncated to match the number of nodes.
- `nodespacing=1.0`: Minimum gap between neighboring nodes, both within a
  rank and between ranks.
- `dummysize=0.0`: Width of the invisible "dummy" nodes used internally to
  route edges spanning more than one rank.
- `minimum_length=1`: Minimum number of ranks every edge must span.
- `ranking_type=:networksimplex`: `:networksimplex` minimizes total edge
  length (as in the papers above); `:longestpath`, `:up` and `:down` are
  cheaper longest-path schedules (from both ends, from sources only, and
  from sinks only, respectively).
- `crossing_minimization=:barycenter`: `:barycenter` or `:median` heuristic
  used to reorder each rank.
- `transpose=true`: Follow up with a greedy pairwise-swap pass that further
  reduces crossings, at the cost of runtime.
- `direction=:right`: Which way ranks flow: `:down`, `:up`, `:left` or
  `:right`.

This implementation is a Julia port of
[rust-sugiyama](https://github.com/paddison/rust-sugiyama).
"""
struct SugiyamaLayout{Ptype,T}
    nodesize::Vector{T}
    nodespacing::Float64
    dummysize::Float64
    minimum_length::Int
    ranking_type::Symbol
    crossing_minimization::Symbol
    transpose::Bool
    direction::Symbol
end

function SugiyamaLayout(;
    Ptype = Float64,
    nodesize = Float64[],
    nodespacing = 1.0,
    dummysize = 0.0,
    minimum_length = 1,
    ranking_type = :networksimplex,
    crossing_minimization = :barycenter,
    transpose = true,
    direction = :right,
)
    minimum_length >= 1 || throw(ArgumentError("minimum_length must be >= 1"))
    direction in (:down, :up, :left, :right) ||
        throw(ArgumentError("direction must be one of :down, :up, :left, :right"))
    ranking_type in (:networksimplex, :longestpath, :up, :down) || throw(
        ArgumentError(
            "ranking_type must be one of :networksimplex, :longestpath, :up, :down",
        ),
    )
    crossing_minimization in (:barycenter, :median) ||
        throw(ArgumentError("crossing_minimization must be :barycenter or :median"))
    return SugiyamaLayout{Ptype,eltype(nodesize)}(
        nodesize,
        Float64(nodespacing),
        Float64(dummysize),
        Int(minimum_length),
        ranking_type,
        crossing_minimization,
        transpose,
        direction,
    )
end

(algo::SugiyamaLayout)(adj_matrix) = layout(algo, adj_matrix)

sugiyama(adj_matrix; kwargs...) = layout(SugiyamaLayout(; kwargs...), adj_matrix)

"""
    sugiyama_paths(adj_matrix; kwargs...) -> (positions, edge_paths)

Like `sugiyama`, but also returns the routing of each edge as a
polyline. `edge_paths` is a `Dict{Tuple{Int,Int},Vector{Point{2,Ptype}}}`
mapping each nonzero `(i, j)` entry of `adj_matrix` to
`[positions[i], bend points..., positions[j]]`.

Accepts the same keyword arguments as [`SugiyamaLayout`](@ref).
"""
sugiyama_paths(adj_matrix; kwargs...) =
    layout_with_paths(SugiyamaLayout(; kwargs...), adj_matrix)

"""
Throws `ArgumentError` if matrix is not square. Returns size.
"""
function assertsquare(M::AbstractMatrix)
    (a, b) = size(M)
    a != b && throw(ArgumentError("Adjacency matrix needs to be square!"))
    return a
end

function layout(algo::SugiyamaLayout, adj_matrix::AbstractMatrix)
    positions, _ = _layout(algo, adj_matrix, false)
    return positions
end

"""
    layout_with_paths(algo::SugiyamaLayout, adj_matrix) -> (positions, edge_paths)

Implementation of [`sugiyama_paths`](@ref) for an already-constructed
`algo`.
"""
function layout_with_paths(algo::SugiyamaLayout, adj_matrix::AbstractMatrix)
    return _layout(algo, adj_matrix, true)
end

function _layout(
    algo::SugiyamaLayout{Ptype,T},
    adj_matrix::AbstractMatrix,
    want_paths::Bool,
) where {Ptype,T}
    n = assertsquare(adj_matrix)
    positions = Vector{Point{2,Ptype}}(undef, n)
    edge_paths = want_paths ? Dict{Tuple{Int,Int},Vector{Point{2,Ptype}}}() : nothing
    n == 0 && return positions, edge_paths

    nodesize = ones(Float64, n)
    for i = 1:min(n, length(algo.nodesize))
        nodesize[i] = Float64(algo.nodesize[i])
    end

    edgelist = Tuple{Int,Int}[]
    for j = 1:n, i = 1:n
        i != j && !iszero(adj_matrix[i, j]) && push!(edgelist, (i, j))
    end

    xoffset = 0.0
    for comp in _weakly_connected_components(n, edgelist)
        m = length(comp)
        localid = Dict(v => k for (k, v) in enumerate(comp))

        sub = SugiGraph()
        for v in comp
            _add_vertex!(
                sub;
                width = nodesize[v] + algo.nodespacing,
                height = nodesize[v] + algo.nodespacing,
            )
        end
        comp_edges = Tuple{Int,Int}[]
        for (i, j) in edgelist
            (haskey(localid, i) && haskey(localid, j)) || continue
            _add_edge!(sub, localid[i], localid[j])
            want_paths && push!(comp_edges, (i, j))
        end

        xs, ys, local_paths = layout_component!(sub, algo; want_paths)

        minx, maxx = extrema(view(xs, 1:m))
        for (k, v) in enumerate(comp)
            positions[v] = to_point(Ptype, xs[k] - minx + xoffset, ys[k], algo.direction)
        end

        if want_paths
            all_points = [
                to_point(Ptype, xs[k] - minx + xoffset, ys[k], algo.direction) for
                k = 1:_nv(sub)
            ]
            for (oid, ij) in enumerate(comp_edges)
                edge_paths[ij] = all_points[local_paths[oid]]
            end
        end

        xoffset += (maxx - minx) + algo.nodespacing
    end
    return positions, edge_paths
end

function to_point(::Type{Ptype}, x::Float64, y::Float64, direction::Symbol) where {Ptype}
    if direction === :down
        Point{2,Ptype}(x, -y)
    elseif direction === :up
        Point{2,Ptype}(x, y)
    elseif direction === :right
        Point{2,Ptype}(y, x)
    else # :left
        Point{2,Ptype}(-y, x)
    end
end

"""Weakly connected components of the graph given by `n` vertices `1:n` and
directed edge list `edgelist`, as sorted vectors of (global) vertex ids."""
function _weakly_connected_components(n::Int, edgelist::Vector{Tuple{Int,Int}})
    adj = [Int[] for _ = 1:n]
    for (i, j) in edgelist
        push!(adj[i], j)
        push!(adj[j], i)
    end
    visited = falses(n)
    comps = Vector{Int}[]
    for start = 1:n
        visited[start] && continue
        comp = Int[]
        stack = [start]
        visited[start] = true
        while !isempty(stack)
            v = pop!(stack)
            push!(comp, v)
            for w in adj[v]
                if !visited[w]
                    visited[w] = true
                    push!(stack, w)
                end
            end
        end
        push!(comps, sort!(comp))
    end
    return comps
end

"""Run all four layout phases on a single weakly-connected component `g`
(vertices `1:m` are the "real" input vertices; the pipeline may append
dummy vertices after that). Returns `(xs, ys, local_paths)` covering every
vertex of the (possibly grown) graph; `local_paths` is `nothing` unless
`want_paths`, in which case it holds, for each edge originally added to
`g` (in that order), the chain of vertex ids it was routed through: real
endpoints plus any dummy vertices."""
function layout_component!(g::SugiGraph, algo::SugiyamaLayout; want_paths::Bool = false)
    # `g.edges` at this point are exactly the caller's original edges
    # (self-origin, ids `1:length(g.edges)`), so this is the last point
    # `.tail`/`.head` can be read directly as the pre-transform endpoints.
    tails = want_paths ? [e.tail for e in g.edges] : Int[]
    heads = want_paths ? [e.head for e in g.edges] : Int[]

    remove_cycles!(g)
    rank!(g, algo.minimum_length, algo.ranking_type)
    insert_dummy_vertices!(g, algo.minimum_length, algo.dummysize)
    local_paths = want_paths ? extract_edge_paths(g, tails, heads) : nothing
    layers = ordering(g, algo.crossing_minimization, algo.transpose)

    layouts = create_layouts(g, layers)
    align_to_smallest_width_layout!(layouts)
    xcoords = calculate_relative_coords(layouts)

    n = _nv(g)
    xs = [xcoords[v] for v = 1:n]
    xs .-= minimum(xs)

    rank_to_max_height = Dict{Int,Float64}()
    for v = 1:n
        r = g.verts[v].rank
        rank_to_max_height[r] = max(get(rank_to_max_height, r, 0.0), g.verts[v].height)
    end
    ranks_sorted = sort!(collect(keys(rank_to_max_height)))
    rank_to_y = Dict{Int,Float64}()
    top = -rank_to_max_height[ranks_sorted[1]] * 0.5
    for r in ranks_sorted
        mh = rank_to_max_height[r]
        rank_to_y[r] = top + mh * 0.5
        top += mh
    end
    ys = [rank_to_y[g.verts[v].rank] for v = 1:n]

    return xs, ys, local_paths
end

end
