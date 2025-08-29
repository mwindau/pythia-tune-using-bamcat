#Manually editable ranges for the prior
par_lims = BAT.NamedTupleDist(
	p1 = Uniform(1.78,4.78), #pT0Ref
    p2 = Uniform(0.2,2.0), #aLund
    #p3 = Uniform(0.2,2.0), #bLund
    p3 = Uniform(0.2,0.44), #sigma
)

parameters = par_lims

# Build EFTfitter model
model = EFTfitterModel(parameters, measurements, correlations)

# Posterior
posterior = PosteriorMeasure(model)

algorithm = MCMCSampling(mcalg = MetropolisHastings(), nsteps = 10^5, nchains = 10, strict=false)

# for more information during sampling
ENV["JULIA_DEBUG"] = "BAT"

# Start sampling
@time samples_posterior_using_all_observables = bat_sample(posterior, algorithm).result

# Save sampled data
#JLD2.@save "samples_posterior_using_all_observables.jld2" samples_posterior_using_all_observables

# Plot marginalized posteriors
gr()
plotsamples = plot(samples_posterior_using_all_observables,  dpi=750, xtickfontsize=11, ytickfontsize=11, xguidefontsize=17, yguidefontsize=17, titlefontsize=20, legendfontsize=12, margin=5Plots.mm, vsel_label=["pT0Ref", "aLund", "sigma"], size=(1800, 1200), left_margin=40Plots.px, globalmode = true)
plot!([], label=nothing, legend=:left)