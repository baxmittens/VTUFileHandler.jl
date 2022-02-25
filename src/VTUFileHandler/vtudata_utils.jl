#function _deepcopy(vtud::VTUDataField{T}) where {T<:Number}
#	len = length(vtud.dat)
#	dat = Vector{T}(undef,len)
#	for i = 1:len
#		dat[i] = vtud.dat[i] 
#	end
#	return VTUDataField(dat)
#end

function Base.deepcopy(vtud::VTUData)
	ipdat = vtud.interp_data
	#ip = GC.@preserve ipdat map(deepcopy,ipdat)
	ip = map(deepcopy,ipdat)
	return VTUData(vtud.names,vtud.header,deepcopy(vtud.data),ip,vtud.idat)
end

function fill_zeros(arr::Base.ReinterpretArray{T,N,S,A,IsReshaped}) where {T,N,S,A,IsReshaped}
	fill!(arr.parent,zero(S))
	return nothing
end

function fill_zeros(arr::VTUDataField{T}) where {T}
	fill!(arr,zero(T))
	return nothing
end

#function fill_zeros(arr::Vector{T}) where {T<:Number}
#	fill!(arr,zero(T))
#	return nothing
#end

function Base.similar(vtud::VTUData)
	ret = deepcopy(vtud)
	for dat in ret.interp_data
		fill_zeros(dat)
	end
	return ret
end

function Base.fill!(ret::VTUDataField{T}, c::T) where {T}
	@inbounds for i in 1:length(ret.dat)
		ret.dat[i] = c
	end
	return nothing
end

function Base.fill!(ret::VTUData, c::Float64)
	for dat in ret.interp_data
		fill!(dat,c)
	end
	return nothing
end

function Base.zero(vtud::VTUData)
	ret = similar(vtud)
	fill!(ret,0.0)
	return nothing
end

function update_data!(vtud::VTUData)
	for (i,j) in enumerate(vtud.idat)
		vtud.data[j] = vtud.interp_data[i]
	end
end