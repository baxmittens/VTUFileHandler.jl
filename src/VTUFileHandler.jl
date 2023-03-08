module VTUFileHandler

using Base64, CodecZlib
using XMLParser

import LinearAlgebra: mul!, norm
import Base: +,-,*,/,^
import AltInplaceOpsInterface: add!, minus!, pow!, max!, min!


include(joinpath(".","VTUFileHandler","defs.jl"))

"""
    VTUHeader(::Type{T},input::Vector{UInt8}) where {T<:Union{UInt32,UInt64}}

Computes the VTUHeader based on the headertype and a Base64 decoded input data array.

# Constructor
- `::Type{T}`: headertype, either UInt32 or UInt64
- `input::Vector{UInt8}`: input data

# Fields
- `num_blocks::T` : number of blocks
- `blocksize::T` : size of blocks
- `last_blocksize::T` : size of last block (can be different)
- `compressed_blocksizes::T` : size of compressed blocks
"""	
struct VTUHeader{T<:Union{UInt32,UInt64}}
	num_blocks::T
	blocksize::T
	last_blocksize::T
	compressed_blocksizes::Vector{T}
	function VTUHeader(::Type{T}) where {T<:Union{UInt32,UInt64}}
		return new{T}(zero(T),zero(T),zero(T),T[])
	end
	function VTUHeader(::Type{T},input::Vector{UInt8}) where {T<:Union{UInt32,UInt64}}
		dat = reinterpret(T,input)
		num_blocks = dat[1]
		blocksize = dat[2]
		last_blocksize = dat[3]
		compressed_blocksizes=Vector{T}(undef,num_blocks)
		for (j,i) = enumerate(4:length(dat))
			compressed_blocksizes[j] = dat[i]
		end	
		return new{T}(num_blocks,blocksize,last_blocksize,compressed_blocksizes)
	end
	function VTUHeader(a::T,b::T,c::T,d::Vector{T}) where {T<:Union{UInt32,UInt64}}
		return new{T}(a,b,c,d)
	end
end

include(joinpath(".","VTUFileHandler","vtuheader_utils.jl"))
include(joinpath(".","VTUFileHandler","io.jl"))

"""
    VTUDataField(x::Vector{T}) where {T} = new{T}(x)

Container for VTU field data.

# Constructor
- `x::Vector{T}`: Vector with VTU field data

# Fields
- `dat::Vector{T}` : VTU field data
"""	
struct VTUDataField{T}
	dat::Vector{T}
	VTUDataField(x::Vector{T}) where {T} = new{T}(x)
	VTUDataField(::Type{T}) where {T} = new{T}()
	VTUDataField(x::Base.ReinterpretArray{T, A, B, Vector{C}, D}) where {T,A,B,C,D} = new{T}(x)
end

"""
    VTUData(dataarrays::Vector{AbstractAbstractXMLElement},appendeddata::Vector{AbstractAbstractXMLElement},headertype::Union{Type{UInt32},Type{UInt64}},offsets::Vector{Int},compressed_dat::Bool)

Container for VTU data.


# Constructor
- `dataarrays::Vector{AbstractAbstractXMLElement}`: Vector with all XML elements with tag `DataArray` of VTU file
- `appendeddata::Vector{AbstractAbstractXMLElement}`: Vector with all XML elements with tag `AppendedData`
- `headertype::Union{Type{UInt32},Type{UInt64}}` : Type of VTU header
- `offsets::Vector{Int}` : Offset of each field data in the compressed appended data 
- `compressed_dat::Bool` : True if data is compressed

# Fields
- `names::Vector{String}` : Name of each data field
- `header::Vector{VTUHeader}` : Vector with [`VTUHeader`](@ref)s.
- `data::Vector{VTUDataField}` : Vector with [`VTUDataField`](@ref)s
- `interp_data::Vector{VTUDataField{Float64}}` : Vector with [`VTUDataField`](@ref)s
- `idat::Vector{Int}` : Vector indexing the `data`-fields onto which the math operators should be applied

For a [`VTUDataField`](@ref) to appear in `data`, the appropriate keyword has to be added via [`add_uncompress_keywords`](@ref) or [`add_interpolation_keywords`](@ref). 
For a [`VTUDataField`](@ref) to appear in `interp_data` the appropriate keyword has to be added via [`add_interpolation_keywords`](@ref).
For more information, see [`VTUKeyWords`](@ref).
"""	
struct VTUData
	names::Vector{String}
	header::Vector{VTUHeader}
	data::Vector{VTUDataField}
	interp_data::Vector{VTUDataField{Float64}}
	idat::Vector{Int}
	VTUData(names::Vector{String},header::Vector{VTUHeader},data::Vector{VTUDataField},interp_data::Vector{VTUDataField{Float64}},idat::Vector{Int}) = new(names,header,data,interp_data,idat)
	function VTUData(dataarrays::Vector{AbstractXMLElement},appendeddata::Vector{AbstractXMLElement},headertype::Union{Type{UInt32},Type{UInt64}},offsets::Vector{Int},compressed_dat::Bool)
		names = Vector{String}()
		data = Vector{VTUDataField}()
		header = Vector{VTUHeader}()
		for (i,el) in enumerate(dataarrays)
			_type = replace(getAttribute(el,"type"),"\""=>"")
			type = eval(Meta.parse(_type))
			_format = getAttribute(el,"format")
			_name = getAttribute(el,"Name")
			if findfirst(x->x==_name,vtukeywords.interpolation_keywords) != nothing	|| findfirst(x->x==_name,vtukeywords.uncompress_keywords) != nothing
				if _format == "appended" || _format == "\"appended\""
					vtuheader = readappendeddata!(data,i,appendeddata,offsets,type,headertype,compressed_dat)
				else
					vtuheader = readdataarray!(data,el,type,headertype,compressed_dat)
				end
				push!(names,_name)
				push!(header,vtuheader)				
			end
		end
		idat = findall(map(y->findfirst(x->x==y,vtukeywords.interpolation_keywords)!=nothing,names))
		interp_data = data[idat]
		return new(names,header,data,interp_data,idat)
	end
end

include(joinpath(".","VTUFileHandler","vtudata_utils.jl"))
include(joinpath(".","VTUFileHandler","vtudata_math.jl"))

function deletefieldata!(xmlroot)
	dataarrays = getElements(xmlroot,"DataArray")
	fielddata = getElements(xmlroot,"FieldData")[1]
	#_offset = parse(Int,replace(getAttribute(dataarrays[length(fielddata.content)+1],"offset"),"\""=>""))
	_offset = parse(Int,getAttribute(dataarrays[length(fielddata.content)+1],"offset"))
	empty!(fielddata.content)
	els = getElements(xmlroot,"DataArray")
	for el in els
		#setAttribute(el,"offset",string(parse(Int,replace(getAttribute(el,"offset"),"\""=>""))-_offset))
		setAttribute(el,"offset",string(parse(Int,getAttribute(el,"offset"))-_offset))
	end
	appendeddata = getElements(xmlroot,"AppendedData")
	appendeddata[1].content[1] = String(deleteat!(collect(appendeddata[1].content[1]),2:_offset+1))
end

"""
    VTUFile(name::String)

Loads a VTU file.
Don't forget to set the proper fieldnames via `set_uncompress_keywords` and `set_interpolation_keywords`.

# Constructor
- `name::String`: path to vtu file

# Fields
- `name::String`: path to vtu file; destination for file writing
- `xmlroot::AbstractXMLElement`: VTU file in XML represantation
- `dataarrays::Vector{AbstractXMLElement}`: Vector with all XML elements with tag `DataArray` of VTU file
- `headertype::Union{Type{UInt32},Type{UInt64}}`: type of header
- `offsets::Vector{Int}`: Offset of each field data in the compressed appended data 
- `data::VTUData`: Conatainer with  [`VTUData`](@ref)
- `compressed_dat::Bool` : True if data is compressed

# Example
```julia
set_uncompress_keywords("temperature","points")
set_interpolation_keywords("temperature")
vtufile = VTUFile("./path-to-vtu/example.vtu");
```
"""	
mutable struct VTUFile
	name::String
	xmlfile::XMLFile
	xmlroot::AbstractXMLElement
	dataarrays::Vector{AbstractXMLElement}
	appendeddata::Vector{AbstractXMLElement}
	headertype::Union{Type{UInt32},Type{UInt64}}
	offsets::Vector{Int}
	data::VTUData
	compressed_dat::Bool
	VTUFile(name,xmlfile,xmlroot,dataarrays,appendeddata,headertype,offsets,data) = new(name,xmlfile,xmlroot,dataarrays,appendeddata,headertype,offsets,data,true)
	VTUFile(name,xmlfile,xmlroot,dataarrays,appendeddata,headertype,offsets,data,compr_dat) = new(name,xmlfile,xmlroot,dataarrays,appendeddata,headertype,offsets,data,compr_dat)
	function VTUFile(name::String)
		#state = IOState(name);
		#xmlroot = readXMLElement(state);
		xmlfile = read(XMLFile, name)
		xmlroot = xmlfile.element
		if !isempty(getElements(xmlroot,"FieldData"))
			deletefieldata!(xmlroot)
		end
		dataarrays = getElements(xmlroot,"DataArray")
		appendeddata = getElements(xmlroot,"AppendedData")
		#vtkfile = getElements(xmlroot,"VTKFile")
		#@assert length(vtkfile) == 1
		compressed_dat = false
		if hasAttributekey(xmlroot,"compressor")
			compressed_dat = true
		end
		attr = getAttribute(xmlroot,"header_type")
		headertype = eval(Meta.parse(attr))
		offsets = Vector{Int}()
		for el in dataarrays
			if hasAttributekey(el,"offset")
				#_offset = replace(getAttribute(el,"offset"),"\""=>"")
				_offset = getAttribute(el,"offset")
				offset = parse(Int,_offset)
				push!(offsets,offset)
			else
				push!(offsets,0)
			end
		end
		retval = new(name,xmlfile,xmlroot,dataarrays,appendeddata,headertype,offsets,VTUData(dataarrays,appendeddata,headertype,offsets,compressed_dat),compressed_dat)
		return retval	
	end
end

include(joinpath(".","VTUFileHandler","utils.jl"))
include(joinpath(".","VTUFileHandler","vtufile_math.jl"))
include(joinpath(".","VTUFileHandler","globaltolocal.jl"))

export VTUHeader, VTUFile, set_uncompress_keywords, add_uncompress_keywords, set_interpolation_keywords, add_interpolation_keywords, add!, minus!, pow!, div!, min!, max!

end #module VTUHandler
