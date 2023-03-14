function add!(zd1::VTUFile, zd2::VTUFile)
	add!(zd1.data,zd2.data)
	return nothing
end

function minus!(zd1::VTUFile, zd2::VTUFile)
	minus!(zd1.data,zd2.data)
	return nothing
end

function add!(zd1::VTUFile, a::Number)
	add!(zd1.data, a)
	return nothing
end

function mul!(zd1::VTUFile, c::Number)
	mul!(zd1.data, c)
	return nothing
end

function mul!(zd1::VTUFile, zd2::VTUFile, zd3::VTUFile)
	mul!(zd1.data, zd2.data, zd3.data)
	return nothing
end

function mul!(zd1::VTUFile, zd2::VTUFile, fac::Float64)
	mul!(zd1.data, zd2.data, fac)
	return nothing
end

function pow!(zd1::VTUFile, a::Number)
	pow!(zd1.data, a)
	return nothing
end

function div!(zd1::VTUFile, a::Number)
	div!(zd1.data, a)
	return nothing
end

function div!(zd1::VTUFile, zd2::VTUFile, zd3::VTUFile)
	div!(zd1.data, zd2.data, zd3.data)
	return nothing
end

function max!(zd1::VTUFile, zd2::VTUFile)
	max!(zd1.data, zd2.data)
	return nothing
end

function min!(zd1::VTUFile, zd2::VTUFile)
	min!(zd1.data, zd2.data)
	return nothing
end

function +(tpf1::VTUFile, tpf2::VTUFile)
	ret = similar(tpf1)
	add!(ret,tpf1)
	add!(ret,tpf2)
	return ret
end

function +(tpf1::VTUFile)
	ret = similar(tpf1)
	add!(ret,tpf1)
	return ret
end

function -(tpf1::VTUFile, tpf2::VTUFile)
	ret = similar(tpf1)
	add!(ret,tpf1)
	minus!(ret,tpf2)
	return ret
end

function -(tpf1::VTUFile)
	ret = similar(tpf1)
	minus!(ret,tpf1)
	return ret
end

function *(tpf1::VTUFile, tpf2::VTUFile)
	ret = similar(tpf1)
	mul!(ret,tpf1,tpf2)
	return ret
end

function +(tpf::VTUFile, a::Number)
	ret = similar(tpf)
	add!(ret,tpf)
	add!(ret,a)
	return ret
end
+(a::Number,tpf::VTUFile) = tpf+a

function -(tpf::VTUFile, a::T) where T<:Number
	ret = similar(tpf)
	add!(ret,tpf)
	add!(ret,-a)
	return ret
end

function -(a::T,tpf::VTUFile) where T<:Number
	ret = similar(tpf)
	add!(ret,a)
	minus!(ret,tpf)
	return ret
end

function *(tpf::VTUFile, a::T) where T<:Number
	ret = similar(tpf)
	add!(ret,tpf)
	mul!(ret,a)
	return ret
end
*(a::T,tpf::VTUFile) where T<:Number = tpf*a

function /(tpf::VTUFile, a::T) where T<:Number
	ret = similar(tpf)
	add!(ret,tpf)
	div!(ret,a)
	return ret
end

function /(tpf1::VTUFile, tpf2::VTUFile)
	ret = similar(tpf1)
	div!(ret,tpf1,tpf2)
	return ret
end

function ^(tpf::VTUFile, a::T) where T<:Number
	ret = similar(tpf)
	add!(ret,tpf)
	pow!(ret,a)
	return ret
end

function norm(tpf::VTUFile)
	return norm(tpf.data)
end

function <(tpf1::VTUFile, tpf2::VTUFile)
	return tpf1.data<tpf2.data
end