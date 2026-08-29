module SugiyamaGraphsExt

import Sugiyama
import Graphs

function Sugiyama.layout(algo::Sugiyama.Sugiyama, g::Graphs.AbstractGraph)
    return Sugiyama.layout(algo, Graphs.adjacency_matrix(g))
end

end # module
