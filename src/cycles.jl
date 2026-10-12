# Phase 0: cycle removal.
#
# Ranking (phase 1) needs a topological order, so by the time it runs the
# graph must have no directed cycles. We make the graph acyclic by running a
# DFS and reversing every "back edge" found (an edge to a vertex that is
# currently on the DFS stack).

function _cycles_dfs!(
    g::SugiGraph,
    v::Int,
    visited::BitVector,
    onstack::BitVector,
    to_reverse::Vector{Int},
)
    visited[v] = true
    onstack[v] = true
    for eid in copy(g.out[v])
        e = g.edges[eid]
        e === nothing && continue
        w = e.head
        if !visited[w]
            _cycles_dfs!(g, w, visited, onstack, to_reverse)
        elseif onstack[w]
            push!(to_reverse, eid)
        end
    end
    return onstack[v] = false
end

function remove_cycles!(g::SugiGraph)
    n = _nv(g)
    visited = falses(n)
    onstack = falses(n)
    to_reverse = Int[]

    for v = 1:n
        visited[v] || _cycles_dfs!(g, v, visited, onstack, to_reverse)
    end

    for eid in to_reverse
        e = g.edges[eid]
        tail, head, weight = e.tail, e.head, e.weight
        origin = g.origin[eid]
        _rem_edge!(g, eid)
        _add_edge!(g, head, tail; weight, origin)
    end
    return g
end
