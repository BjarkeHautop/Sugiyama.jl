module TrimCheck

using Sugiyama
using Graphs: SimpleDiGraph, add_edge!

# Exercises the public API

function _adj()
    # Diamond with a long edge, a cycle and a separate component.
    A = zeros(Int, 7, 7)
    A[1, 2] = A[1, 3] = A[2, 4] = A[3, 4] = A[1, 4] = 1
    A[4, 5] = A[5, 1] = 1
    A[6, 7] = 1
    return A
end

function _check_sugiyama()
    A = _adj()
    sugiyama(A)
    sugiyama(zeros(Int, 0, 0))
    sugiyama(BitMatrix(A .!= 0))
    sugiyama(A; Ptype = Float32)
    sugiyama(A; nodesize = [1.0, 2.0, 3.0], nodespacing = 0.5, dummysize = 0.1)
    sugiyama(A; minimum_length = 2)
    for ranking_type in (:networksimplex, :longestpath, :up, :down)
        sugiyama(A; ranking_type)
    end
    sugiyama(A; crossing_minimization = :median, transpose = false)
    for direction in (:down, :up, :left, :right)
        sugiyama(A; direction)
    end
    return nothing
end

function _check_sugiyama_paths()
    A = _adj()
    sugiyama_paths(A)
    sugiyama_paths(A; Ptype = Float32, direction = :down, minimum_length = 2)
    return nothing
end

function _check_layout()
    A = _adj()
    SugiyamaLayout()(A)
    SugiyamaLayout(; Ptype = Float32, nodesize = [1, 2, 3])(A)
    return nothing
end

# --- ext/SugiyamaGraphsExt.jl -----------------------------------------------

function _check_graphs_ext()
    g = SimpleDiGraph(4)
    add_edge!(g, 1, 2)
    add_edge!(g, 2, 3)
    add_edge!(g, 1, 3)
    SugiyamaLayout()(g)
    return nothing
end

Base.@ccallable function trim_check_run()::Cint
    _check_sugiyama()
    _check_sugiyama_paths()
    _check_layout()
    _check_graphs_ext()
    return Cint(0)
end

end # module
