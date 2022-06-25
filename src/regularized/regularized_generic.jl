"""
    RegularizedGeneric{ΩF,ΩG,F,G,M,S}

Generic and differentiable regularized prediction function `ŷ(θ) = argmax {θᵀy - Ω(y)}`.

Relies on the Frank-Wolfe algorithm to minimize a concave objective on a polytope.

# Fields
- `Ω::ΩF`
- `∇Ω::ΩG`
- `f::F`
- `∇ₓf::G`
- `maximizer::M`
- `linear_solver::S`

See also: [`DifferentiableFrankWolfe`](@ref).
"""
struct RegularizedGeneric{ΩF,ΩG,F,G,M,S}
    Ω::ΩF
    ∇Ω::ΩG
    f::F
    ∇ₓf::G
    maximizer::M
    linear_solver::S
end

function RegularizedGeneric(Ω, ∇Ω, maximizer; linear_solver=gmres)
    f(y, θ) = Ω(y) - dot(θ, y)
    ∇ₓf(y, θ) = ∇Ω(y) - θ
    return RegularizedGeneric(Ω, ∇Ω, f, ∇ₓf, maximizer, linear_solver)
end

@traitimpl IsRegularized{RegularizedGeneric}

function compute_regularization(regularized::RegularizedGeneric, y::AbstractArray{<:Real})
    return regularized.Ω(y)
end

## Forward pass

function (regularized::RegularizedGeneric)(
    θ::AbstractArray; maximizer_kwargs=(;), fw_kwargs=(;)
)
    (; f, ∇ₓf, maximizer, linear_solver) = regularized
    lmo = LMOWrapper(maximizer, maximizer_kwargs)
    dfw = DifferentiableFrankWolfe(f, ∇ₓf, lmo, linear_solver)
    return dfw(θ; fw_kwargs=fw_kwargs)
end

## Backward pass, only works with vectors

function ChainRulesCore.rrule(
    rc::RuleConfig,
    regularized::RegularizedGeneric,
    θ::AbstractVector{<:Real};
    maximizer_kwargs=(;),
    fw_kwargs=(;),
)
    (; f, ∇ₓf, maximizer, linear_solver) = regularized
    lmo = LMOWrapper(maximizer, maximizer_kwargs)
    dfw = DifferentiableFrankWolfe(f, ∇ₓf, lmo, linear_solver)
    return rrule(rc, dfw, θ; fw_kwargs=fw_kwargs)
end
