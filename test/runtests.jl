module TestLazyImports

using LazyImports
using Test

module TestShim
    using LazyImports
    @shim_import Test="8dfed614-e22c-5e08-85e1-65c5234f0b40"
end

module TestLazy
    using LazyImports
    @lazy_import Test="8dfed614-e22c-5e08-85e1-65c5234f0b40"
end

@testset "LazyImports.jl" begin
    @test TestShim.Test.detect_ambiguities === Test.detect_ambiguities
    @test TestLazy.Test.detect_ambiguities === Test.detect_ambiguities
end

end  # module
