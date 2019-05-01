using Documenter, LazyImports

makedocs(;
    modules=[LazyImports],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/tkf/LazyImports.jl/blob/{commit}{path}#L{line}",
    sitename="LazyImports.jl",
    authors="Takafumi Arakaki",
    assets=[],
)

deploydocs(;
    repo="github.com/tkf/LazyImports.jl",
)
