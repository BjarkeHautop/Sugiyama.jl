```@meta
CurrentModule = Sugiyama
```

# Sugiyama.jl

Sugiyama.jl computes a layered ("hierarchical") layout for directed graphs:
vertices are grouped into ranks, edge crossings between ranks are
heuristically minimized, and coordinates are assigned within each rank.
Ranking and crossing minimization follow Gansner, Koutsofios, North & Vo
(1993, [doi 10.1109/32.221135](https://doi.org/10.1109/32.221135)); coordinate
assignment follows Brandes & Köpf (2002,
[doi 10.1007/3-540-45848-4_3](https://doi.org/10.1007/3-540-45848-4_3)). This
implementation is a Julia port of
[rust-sugiyama](https://github.com/paddison/rust-sugiyama).

Graphs are given as an adjacency matrix (or, with
[Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl) loaded, as an
`AbstractGraph`), and cycles are broken automatically, so any directed graph
can be laid out, not just DAGs.

## Quick Start

`sugiyama` (and the `SugiyamaLayout` callable) take an adjacency matrix and return one `Point{2,Float64}` per vertex:

```@example example
using Sugiyama

adj = [0 1 0;
       0 0 1;
       0 0 0]

positions = sugiyama(adj)
```

Keyword arguments control node spacing, direction, and the underlying
heuristics:

```@example example
positions = SugiyamaLayout(; direction = :right)(adj)
```
