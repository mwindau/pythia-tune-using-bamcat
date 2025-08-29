# This script runs the whole tuning process.

# The MC histograms used for tuning need to be in either .yoda or .csv files in folders called 0000, 0001 and so on. 
# If you use a .yoda file, it needs to be the output of a rivet analysis. This is recommended if you want to use all of the observables present in the .yoda file.
# If you only want specific observables from the analysis, you can use a .csv file. The .csv file needs to be called output.csv and the first line needs to say BEGIN HISTO1D "observable name"
# Then the first column contains the x_edges, the middle one the bin contents and the last one the bin errors. The last row needs to say 0 for the last two columns, since the x_edges contain one more entry. 
# Afterwards comes a line with END, an empty line and then everything again for the next observable. An example .csv file can be found in the tuning_samples folder.
# The folders need to contain a .dat file with the parameters used to generate the histograms. 

# Path to MC histograms
MCPATH = "tuning_samples/"

# Necessary packages. This should be toml with everything necessary, but it isnt at the moment...
include("./BAMCAT/myfitter.jl")

# Workflow to load histograms, sort them and create the interpolation

# depending on mode of MC samples
mode_csv = true # true if files are saved as .csv files

include("./scripts/sort_histograms.jl")

# Parameterization
# At the moment you can use three different surrogate models. 
# Either a curve_fit :quadratic or :cubic parameters, a linear (:linear_grid) interpolation if the parameter values are sampled on a grid.
# Or the parameterization used in the professor (:prof) paper (inverting the pseudo inverse matrix). Using the linear model is only possible with parallel = true and the professor method is only possible with parallel = false.

include("./scripts/create_parameterization.jl")

# Data and Input for EFTfitter
# Inputs jl handels the conversion of the interpolation to be added to the EFTFitter model
# returns 'measurements' and 'correlations' to define the EFTmodel later
include("./scripts/inputs.jl") #Please check for DATA file paths in here

# Fit with EFTfitter
# Define your Posterior, build the EFTfitter Model and sample your Posterior
include("./scripts/run_EFTfitter.jl")