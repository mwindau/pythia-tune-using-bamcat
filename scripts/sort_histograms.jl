# load in parallel. If you use csv files, parallel needs to be true
parallel=true

# Create container object with all the histograms
container = load_Histcontainer_from_folder(MCPATH,parallel=parallel,mode_csv=mode_csv)

# Sort the histograms by observable
sorted = sort_Histcontainer_by_observable(container)

# Vector with all the observable names
observables = get_observables_from_container(sorted)