using Documenter, LazyImports

makedocs(;
    modules=[LazyImports],
    sitename="LazyImports.jl",
    authors="Takafumi Arakaki",
)

deploydocs(;
    repo="github.com/tkf/LazyImports.jl",
)
