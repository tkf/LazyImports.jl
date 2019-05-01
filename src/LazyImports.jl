module LazyImports

export @shim_import, @lazy_import

using Base: Docs
using Pkg: TOML
using UUIDs

abstract type AbstractModuleShim end

struct ShimModule <: AbstractModuleShim
    uuid::UUID
    name::Symbol
end

struct LazyModule <: AbstractModuleShim
    uuid::UUID
    name::Symbol
end

_uuid(m::AbstractModuleShim) = getfield(m, :uuid)
Base.nameof(m::AbstractModuleShim) = getfield(m, :name)

Base.PkgId(m::AbstractModuleShim) = Base.PkgId(_uuid(m), String(nameof(m)))

getmodule(m::ShimModule) = Base.loaded_modules[Base.PkgId(m)]
getmodule(m::LazyModule) = Base.require(Base.PkgId(m))

Base.getproperty(m::AbstractModuleShim, name::Symbol) =
    getproperty(getmodule(m), name)

Docs.Binding(m::AbstractModuleShim, name::Symbol) =
    Docs.Binding(getmodule(m), name)

topmodule(m::Module) = parentmodule(m) == m ? m : topmodule(parentmodule(m))

function _uuidfor(__module__::Module, name::Symbol)
    root = topmodule(__module__)
    jlpath = pathof(root)
    if jlpath == nothing
        error("""
        Module $__module__ does not have associated file.
        """)
    end
    tomlpath = joinpath(dirname(dirname(jlpath)), "Project.toml")
    if !isfile(tomlpath)
        error("""
        `LazyImports` needs package `$(nameof(root))` to use `Project.toml`
        file.  `Project.toml` is not found at:
            $tomlpath
        """)
    end
    pkg = TOML.parsefile(tomlpath)
    found = get(get(pkg, "deps", Dict()), String(name), false) ||
        get(get(pkg, "extras", Dict()), String(name), nothing)

    # Just to be extremely careful, editing Project.toml should
    # invalidate the compilation cache since the UUID may be changed
    # or removed:
    include_dependency(tomlpath)

    found !== nothing && return UUID(found)
    error("""
    Package `$name` is not listed in `[deps]` or `[extras]` of `Project.toml`
    file for `$(nameof(root))` found at:
        $tomlpath
    If you are developing `$(nameof(root))`, add `$name` to the dependency.
    Otherwise, please report this to `$(nameof(root))`'s issue tracker.
    """)
end

_uuid(id::UUID) = id
_uuid(id) = UUID(id)

create(factory, __module__, name) = factory(_uuidfor(__module__, name), name)

import_expr(factory, __module__, name::Symbol) =
    :(const $name = $create($factory, $__module__, $(QuoteNode(name))))

function import_expr(factory, ::Any, expr::Expr)
    @assert expr.head == :(=)
    name, uuid = expr.args
    :(const $name = $factory($_uuid($uuid), $(QuoteNode(name))))
end

"""
    @shim_import Module
    @shim_import Module = UUID

See `?@lazy_import`.
"""
macro shim_import(expr)
    esc(import_expr(ShimModule, __module__, expr))
end

"""
    @lazy_import Module
    @lazy_import Module = UUID

Construct a module-like object for `Module`.  Accessing `Module.f`
imports and then get `f` from `Module`.  The `UUID` can be omitted if
`Module` is listed in `[deps]` or `[extras]` of `Project.toml` file of
the package using `@lazy_import`.
"""
macro lazy_import(expr)
    esc(import_expr(LazyModule, __module__, expr))
end

end # module
