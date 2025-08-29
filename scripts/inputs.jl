# Load in Data matching your MC samples
# For the case of .csv, the below defined function loads in data saved in .csv files, see examples in /data
# in two matrices called data_histos and data_sumw2, which hold the observable name, histogram and bin errors respectively



"""
    build_matrices(files, observables) -> (data_histos, data_sumw2)

* `files`        – CSV file paths
* `observables`  – expected column names, one per file

Returns `data_histos` and `data_sumw2` matching the order of `observables`.
Raises an error if the number of files and observables don’t match,
or if the observable doesn’t match the first column in the file.
"""
function build_matrices(files::Vector{String}, observables::Vector{String})
    length(files) == length(observables) ||
        error("Number of files and observables must match")

    n = length(files)
    data_histos = Matrix{Any}(undef, n, 2)
    data_sumw2  = Matrix{Any}(undef, n, 2)

    for i in 1:n
        df     = CSV.read(files[i], DataFrame)
        cname  = Base.names(df)[1]

        cname == observables[i] ||
            occursin("ALEPH_1996_S3486095", cname) ||
                error("Expected observable \"$(observables[i])\" but found \"$cname\" in file: $(files[i])")

        edges  = df.xedges
        counts = df[1:end-1, cname]
        errs   = df[1:end-1, :counts_error]

        if occursin("ALEPH_1996_S3486095", cname)
            cname = replace(cname, "S3486095" => "I428072")
        end

        data_histos[i, :] = [cname, Histogram(edges, counts)]
        data_sumw2[i, :]  = [cname, errs]
    end

    return data_histos, data_sumw2
end

# Include the Paths of the observables you want to load. It has to match the used MC observables
files = [
    "data/ATLAS_2010_I882098_d17-x01-y01.csv",
    "data/ATLAS_2010_I882098_d10-x01-y01.csv",
    "data/L3_2004_I652683_d59-x01-y02.csv",
    "data/L3_2004_I652683_d65-x01-y02.csv",
    "data/ALEPH_1996_S3486095_d17-x01-y01.csv",
    "data/EHS_1988_I265504_d06-x01-y01.csv",
]

data_histos, data_sumw2 = build_matrices(files, observables)

#Initiallize some variables for saving the functions of the interpolation and the data
data_histos_names = data_histos[:, 1]
n_hist = length(data_histos_names)
n_bins = [length(data_histos[i_hist, 2].weights) for i_hist = 1:n_hist]


observables_func = []
measurement_vals = []
measurement_errs = []
weights = []

# Vector of Functions for measured distribution
#Go through all observables and save the parameterized functions and the data + uncertainty
for i_hist = 1:n_hist # By manipulating which observables are selected here, you can change the observables used in the sampling
    n_bin = n_bins[i_hist]
    #Test if observable in data is also in MC samples
    if !(data_histos_names[i_hist] in observables)
        print("Observable $(data_histos_names[i_hist]) not in MC samples")
        continue
    end
    ipol_index =
        findall(i -> i == data_histos_names[i_hist][1:end], observables)[1]
    ipol_index
    weight = 1
    if weight == 0
        continue
    end
    for i_bin = 1:n_bin
        if  (data_histos[i_hist, 2].weights[i_bin] != 0) 
            params_vals = ipol[ipol_index, 3][1][i_bin, :][1]
            interp = params_vals
            push!(observables_func, make_per_bin_function_linear(interp))
            push!(measurement_vals, data_histos[i_hist, 2].weights[i_bin])
            push!(measurement_errs, data_sumw2[i_hist, 2][i_bin])
            push!(weights,weight)
        end
    end
end

observables_func = convert(AbstractArray{Function}, observables_func)
measurement_vals = convert(AbstractArray{Float64}, measurement_vals)
measurement_errs = convert(AbstractArray{Float64}, measurement_errs)
weights = convert(Array{Int64},weights)


active_arr = [true for i = 1:length(measurement_vals)]

noerrindex = [i for i in 1:length(measurement_errs) if measurement_errs[i] == 0.0]
#print(measurement_errs)
[active_arr[i] = false for i in noerrindex]
if (length(noerrindex) > 0)
    print("Remove $noerrindex from obvserables due to zero error.")
end

observables_func = observables_func[[i for i in 1:length(observables_func) if .!(i in noerrindex)]]
measurement_vals = measurement_vals[[i for i in 1:length(measurement_vals) if .!(i in noerrindex)]]
measurement_errs = measurement_errs[[i for i in 1:length(measurement_errs) if .!(i in noerrindex)]]
weights = weights[[i for i in 1:length(weights) if .!(i in noerrindex)]]
active_arr = [true for i = 1:length(measurement_vals)]

names = Symbol.("xsec" .* string.(1:length(observables_func)))
named_observables = NamedTuple{Tuple(names)}(observables_func)

observables_objects = Vector{Observable}(undef, length(observables_func))
for i_obj in 1:length(observables_func)
    i_observable = Observable(
        observables_func[i_obj],
        weight = weights[i_obj],
    )    
    observables_objects[i_obj] = i_observable
end


measurements = (
    Rivet = BinnedMeasurement( 
        observables_func,#observables_objects,
        measurement_vals,
        uncertainties = (stat = measurement_errs,),
        active = active_arr,
    ),
)


correlations = (
    stat = NoCorrelation(active = true), # when using NoCorrelation, the identity matrix  is used

)
