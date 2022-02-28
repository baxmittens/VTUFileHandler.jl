module VTUHandler

using Base64, CodecZlib
#include(joinpath(".","XMLParser.jl"))
using XMLParser

include(joinpath(".","VTUFileHandler","defs.jl"))

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

struct VTUDataField{T}
	dat::Vector{T}
	VTUDataField(x::Vector{T}) where {T} = new{T}(x)
	VTUDataField(::Type{T}) where {T} = new{T}()
	VTUDataField(x::Base.ReinterpretArray{T, A, B, Vector{C}, D}) where {T,A,B,C,D} = new{T}(x)
end

mutable struct VTUData
	names::Vector{String}
	header::Vector{VTUHeader}
	data::Vector{VTUDataField}
	interp_data::Vector{VTUDataField{Float64}}
	idat::Vector{Int}
	VTUData(names,header,data,interp_data,idat) = new(names,header,data,interp_data,idat)
	function VTUData(dataarrays::Vector{XMLElement},appendeddata::Vector{XMLElement},headertype::Union{Type{UInt32},Type{UInt64}},offsets::Vector{Int},compressed_dat::Bool)
		names = Vector{String}()
		data = Vector{VTUDataField}()
		header = Vector{VTUHeader}()
		for (i,el) in enumerate(dataarrays)
			_type = replace(getAttribute(el,"type"),"\""=>"")
			type = eval(Meta.parse(_type))
			_format = getAttribute(el,"format")
			_name = getAttribute(el,"Name")
			if findfirst(x->x==_name,interpolation_keywords) != nothing	|| findfirst(x->x==_name,uncompress_keywords) != nothing
				if _format == "appended" || _format == "\"appended\""
					vtuheader = readappendeddata!(data,i,appendeddata,offsets,type,headertype,compressed_dat)
				else
					vtuheader = readdataarray!(data,el,type,headertype,compressed_dat)
				end
				push!(names,_name)
				push!(header,vtuheader)				
			end
		end
		idat = findall(map(y->findfirst(x->x==y,interpolation_keywords)!=nothing,names))
		interp_data = data[idat]
		return new(names,header,data,interp_data,idat)
	end
end

include(joinpath(".","VTUFileHandler","vtudata_utils.jl"))
include(joinpath(".","VTUFileHandler","vtudata_math.jl"))

function deletefieldata!(xmlroot)
	dataarrays = getElements(xmlroot,"DataArray")
	fielddata = getElements(xmlroot,"FieldData")[1]
	_offset = parse(Int,replace(getAttribute(dataarrays[length(fielddata.content)+1],"offset"),"\""=>""))
	empty!(fielddata.content)
	els = getElements(xmlroot,"DataArray")
	for el in els
		setAttribute(el,"offset",string(parse(Int,replace(getAttribute(el,"offset"),"\""=>""))-_offset))
	end
	appendeddata = getElements(xmlroot,"AppendedData")
	appendeddata[1].content[1] = String(deleteat!(collect(appendeddata[1].content[1]),2:_offset+1))
end

mutable struct VTUFile
	name::String
	xmlroot::XMLElement
	dataarrays::Vector{XMLElement}
	appendeddata::Vector{XMLElement}
	headertype::Union{Type{UInt32},Type{UInt64}}
	offsets::Vector{Int}
	data::VTUData
	compressed_dat::Bool
	VTUFile(name,xmlroot,dataarrays,appendeddata,headertype,offsets,data) = new(name,xmlroot,dataarrays,appendeddata,headertype,offsets,data,true)
	VTUFile(name,xmlroot,dataarrays,appendeddata,headertype,offsets,data,compr_dat) = new(name,xmlroot,dataarrays,appendeddata,headertype,offsets,data,compr_dat)
	function VTUFile(name::String)
		state = IOState(name);
		xmlroot = readXMLElement(state);
		if !isempty(getElements(xmlroot,"FieldData"))
			deletefieldata!(xmlroot)
		end
		dataarrays = getElements(xmlroot,"DataArray")
		appendeddata = getElements(xmlroot,"AppendedData")
		vtkfile = getElements(xmlroot,"VTKFile")
		@assert length(vtkfile) == 1
		compressed_dat = false
		if hasAttributekey(vtkfile[1],"compressor")
			compressed_dat = true
		end
		#headertype = eval(Symbol(getAttribute(first(vtkfile),"header_type")))
		attr = replace(getAttribute(first(vtkfile),"header_type"),"\""=>"")
		headertype = eval(Meta.parse(attr))
		offsets = Vector{Int}()
		for el in dataarrays
			if hasAttributekey(el,"offset")
				_offset = replace(getAttribute(el,"offset"),"\""=>"")
				offset = parse(Int,_offset)
				push!(offsets,offset)
			else
				push!(offsets,0)
			end
		end
		retval = new(name,xmlroot,dataarrays,appendeddata,headertype,offsets,VTUData(dataarrays,appendeddata,headertype,offsets,compressed_dat),compressed_dat)
		return retval	
	end
end

include(joinpath(".","VTUFileHandler","utils.jl"))
include(joinpath(".","VTUFileHandler","vtufile_math.jl"))

end #module VTUHandler