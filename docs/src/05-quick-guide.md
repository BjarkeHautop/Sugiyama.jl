# Getting Started

Plotting requires loading a [Makie](https://docs.makie.org/stable/) backend
and [GraphMakie.jl](https://github.com/JuliaPlots/GraphMakie.jl). Below we use
CairoMakie, and [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl) to build
graphs:

```@example quick
using Sugiyama
using Graphs
using CairoMakie
using GraphMakie
```

`SugiyamaLayout` follows the same "callable struct" convention as
[NetworkLayout.jl](https://github.com/JuliaGraphs/NetworkLayout.jl), so it can
be passed directly as the `layout` keyword to `graphplot`.

## Laying out an adjacency matrix

`sugiyama` (and the `SugiyamaLayout` callable) take the adjacency matrix of a
directed graph and return one coordinate per vertex, as a
`Vector{Point{2,Float64}}`:

```@example quick
adj = [0 1 1 0;
       0 0 0 1;
       0 0 0 1;
       0 0 0 0]

positions = sugiyama(adj)
```

Vertex `i` of `adj` corresponds to `positions[i]`. Here vertex 1 has two
children (2 and 3), which both point to vertex 4, so vertices 2 and 3 land
on the same rank, side by side, above vertex 4:

```@example quick
g = SimpleDiGraph(adj)
graphplot(g; layout = SugiyamaLayout(), ilabels = repr.(1:nv(g)))
```

## Using a `Graphs.jl` graph

An `AbstractGraph` can be passed directly instead of an adjacency matrix, to
`sugiyama`/`SugiyamaLayout` as well as to `graphplot`:

```@example quick
sugiyama(g)
```

## Customizing the layout

Both `sugiyama` and `SugiyamaLayout` accept keyword arguments to control node
spacing, direction, and the ranking/crossing-minimization heuristics used
internally. For example, laying out top-to-bottom instead of left-to-right:

```@example quick
graphplot(g; layout = SugiyamaLayout(; direction = :down), ilabels = repr.(1:nv(g)))
```

See the [Reference](@ref reference) for the full list of keyword arguments.

## Cycles

Cycles are broken internally (by implicitly reversing edges) so that any
directed graph can be laid out, not just DAGs:

```@example quick
cyclic = SimpleDiGraph(3)
add_edge!(cyclic, 1, 2)
add_edge!(cyclic, 2, 3)
add_edge!(cyclic, 3, 1)

graphplot(cyclic; layout = SugiyamaLayout(), ilabels = repr.(1:nv(cyclic)))
```

## Disconnected graphs

Weakly connected components are laid out independently and placed side by
side:

```@example quick
disconnected = SimpleDiGraph(4)
add_edge!(disconnected, 1, 2)
add_edge!(disconnected, 3, 4)

graphplot(disconnected; layout = SugiyamaLayout(), ilabels = repr.(1:nv(disconnected)))
```

## A more complex graph

```@example quick
using CausalStructures
```

Here we use [CausalStructures.jl](https://github.com/BjarkeHautop/CausalStructures.jl), for generating and plotting a DAG:

```@example quick
dag = DAG("C --> X, A --> X + K, X --> F + D, K --> Y, D --> Y + G, Y --> H")

ns = nodes(dag)
node_index = Dict(n => i for (i, n) in enumerate(ns))

adj = zeros(Int, length(ns), length(ns))
for e in CausalStructures.edges(dag)
    adj[node_index[e.src], node_index[e.dst]] = 1
end

positions = sugiyama(adj)
plot(dag; layout = positions)
```
