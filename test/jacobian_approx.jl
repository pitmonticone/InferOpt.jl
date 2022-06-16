using InferOpt
using LinearAlgebra
using Random
using Test
using Zygote

one_hot_argmax_approximations = [PerturbedLogNormal(one_hot_argmax; ε=1, M=5000)]

for approx in one_hot_argmax_approximations
    @testset verbose = true "$approx" begin
        θ = [1, 3, 5, 4, 2]
        # Compute jacobian with reverse mode
        jac = Zygote.jacobian(approx, θ)[1]
        # Only diagonal should be positive
        @test all(diag(jac) .> 0)
        @test all(jac - Diagonal(jac) .<= 0)
        # Order of diagonal coefficients should follow order of θ
        @test sortperm(diag(jac)) == sortperm(θ)
    end
end
