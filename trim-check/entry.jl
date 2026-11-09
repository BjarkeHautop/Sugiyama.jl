module TrimCheck

using Sugiyama

# Covers the calls TrimTrace cannot check: those allowlisted in test/trim-allow.txt, written
# with literal values.

# --- Ptype with a literal type ----------------------------------------------

function _check_ptype()
    A = [0 1 1; 0 0 1; 0 0 0]
    sugiyama(A; Ptype = Float32)
    sugiyama_paths(A; Ptype = Float32)
    SugiyamaLayout(; Ptype = Float32)(A)
    SugiyamaLayout(; Ptype = Float32, nodesize = [1, 2, 3])(A)
    return nothing
end

Base.@ccallable function trim_check_run()::Cint
    _check_ptype()
    return Cint(0)
end

end # module
