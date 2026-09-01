# Sugiyama

<!-- ![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://BjarkeHautop.github.io/Sugiyama.jl/stable) -->
[![Development documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://BjarkeHautop.github.io/Sugiyama.jl/dev)
[![Test workflow status](https://github.com/BjarkeHautop/Sugiyama.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/BjarkeHautop/Sugiyama.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/BjarkeHautop/Sugiyama.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/BjarkeHautop/Sugiyama.jl)
[![Lint workflow Status](https://github.com/BjarkeHautop/Sugiyama.jl/actions/workflows/Lint.yml/badge.svg?branch=main)](https://github.com/BjarkeHautop/Sugiyama.jl/actions/workflows/Lint.yml?query=branch%3Amain)
[![Docs workflow Status](https://github.com/BjarkeHautop/Sugiyama.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/BjarkeHautop/Sugiyama.jl/actions/workflows/Docs.yml?query=branch%3Amain)
[![BestieTemplate](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/JuliaBesties/BestieTemplate.jl/main/docs/src/assets/badge.json)](https://github.com/JuliaBesties/BestieTemplate.jl)

A Julia package for Sugiyama layout of directed graphs, given as an adjacency matrix (or, with Graphs.jl loaded,
an `AbstractGraph`).

## Installation

Not yet registered. Install from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/BjarkeHautop/Sugiyama.jl")
```

## Usage

`sugiyama` (and the `SugiyamaLayout` callable) accept the adjacency matrix of a
directed graph and return a `Vector{Point{2,Float64}}` of node coordinates,
one per row/column of the matrix:

```julia
using Sugiyama

adj = [0 1 0;
       0 0 1;
       0 0 0]

positions = sugiyama(adj)
positions = SugiyamaLayout(; direction=:right)(adj)
```

If [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl) is loaded, an
`AbstractGraph` can be passed instead:

```julia
using Sugiyama, Graphs

g = SimpleDiGraph(3)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)

positions = sugiyama(g)
```

## See also

[LayeredLayouts](https://github.com/oxinabox/LayeredLayouts.jl) for the Zarate algorithm, which is a more expensive algorithm (but produces better layouts), and [NetworkLayout](https://github.com/JuliaGraphs/NetworkLayout.jl) for other layout algorithms.

## Attribution

This implementation is a Julia port of
[rust-sugiyama](https://github.com/paddison/rust-sugiyama).
