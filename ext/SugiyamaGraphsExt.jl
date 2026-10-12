module SugiyamaGraphsExt

import Sugiyama
import Graphs

function Sugiyama.layout(algo::Sugiyama.SugiyamaLayout, g::Graphs.AbstractGraph)
    # Built by hand rather than with `Graphs.adjacency_matrix`, which picks its
    # element type at runtime and so doesn't compile under `--trim=safe`.
    n = Graphs.nv(g)
    adj = falses(n, n)
    for e in Graphs.edges(g)
        i, j = Graphs.src(e), Graphs.dst(e)
        adj[i, j] = true
        Graphs.is_directed(g) || (adj[j, i] = true)
    end
    return Sugiyama.layout(algo, adj)
end

end # module
