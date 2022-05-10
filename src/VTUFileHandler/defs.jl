interpolation_keywords = ["displacement","epsilon","pressure_interpolated","sigma","temperature_interpolated","\"displacement\"","\"epsilon\"","\"pressure_interpolated\"","\"sigma\"","\"temperature_interpolated\""]
uncompress_keywords = ["connectivity","offsets","bulk_node_ids","bulk_element_ids","Points","MaterialIDs","\"connectivity\"","\"offsets\"","\"bulk_node_ids\"","\"bulk_element_ids\"","\"Points\"","\"MaterialIDs\"","types","\"types\""]

"""
    VTUKeyWords

Container for interpolation and uncompress keywords. Will be created as a module-global constant value `vtukeywords`.

# Fields
- `interpolation_keywords::Vector{String}` : Vector with names of VTU fields onto which the math operators should apply 
- `uncompress_keywords` : Vector with names of VTU field that should be uncompressed and stored in memory

# Standard values

By default, keywords were set that match results of the simulation software [OpenGeoSys](https://www.opengeosys.org/). 

```julia
interpolation_keywords = ["displacement","epsilon","pressure_interpolated","sigma","temperature_interpolated"]
uncompress_keywords = ["connectivity","offsets","bulk_node_ids","bulk_element_ids","Points","MaterialIDs"]
```

# Example

If a VTU result file e.g. owns a field named `field1` to which the math operators should be applied, it can be added via: 
```julia
add_interpolation_keywords(["field1"]])
```
"""	
mutable struct VTUKeyWords
	interpolation_keywords::Vector{String}
	uncompress_keywords::Vector{String}
end

const vtukeywords = VTUKeyWords(interpolation_keywords,uncompress_keywords)

"""
	set_uncompress_keywords(uk::Vector{String})

Sets all fields that should be accessible and therefore needs to be uncompressed 

# Arguments
- `uk::Vector{String}`: fieldnames
"""
function set_uncompress_keywords(uk::Vector{String})
	vtukeywords.uncompress_keywords = uk
	for k in copy(uk)
		push!(vtukeywords.uncompress_keywords, "\""*k*"\"") #hack for downwards compatibility with older ogs6-versions
	end
	return nothing
end

"""
	add_uncompress_keywords(uk::Vector{String})

Adds fields that should be accessible and therefore needs to be uncompressed 

# Arguments
- `uk::Vector{String}`: fieldnames
"""
function add_uncompress_keywords(uk::Vector{String})
	for k in copy(uk)
		push!(vtukeywords.uncompress_keywords, "\""*k*"\"") #hack for downwards compatibility with older ogs6-versions
	end
	for k in copy(uk)
		push!(vtukeywords.uncompress_keywords, k) #hack for downwards compatibility with older ogs6-versions
	end
	return nothing
end

"""
	set_interpolation_keywords(ik::Vector{String})

Sets all fields onto which the math operators should be applied

# Arguments
- `ik::Vector{String}`: fieldnames
"""
function set_interpolation_keywords(ik::Vector{String})
	vtukeywords.interpolation_keywords = ik
	for k in copy(ik)
		push!(vtukeywords.interpolation_keywords, "\""*k*"\"") #hack for downwards compatibility with older ogs6-versions
	end
	return nothing
end

"""
	add_interpolation_keywords(ik::Vector{String})

Adds fields onto which the math operators should be applied

# Arguments
- `ik::Vector{String}`: fieldnames
"""
function add_interpolation_keywords(ik::Vector{String})
	for k in copy(ik)
		push!(vtukeywords.interpolation_keywords, "\""*k*"\"") #hack for downwards compatibility with older ogs6-versions
	end
	for k in copy(ik)
		push!(vtukeywords.interpolation_keywords, k) #hack for downwards compatibility with older ogs6-versions
	end
	return nothing	
end
