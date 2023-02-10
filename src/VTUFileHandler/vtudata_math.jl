function add!(zd1::VTUDataField{Float64}, zd2::VTUDataField{Float64})
	@inbounds for i in 1:length(zd1.dat)
		zd1.dat[i] += zd2.dat[i]
	end
	return nothing
end

function minus!(zd1::VTUDataField{Float64}, zd2::VTUDataField{Float64})
	@inbounds for i in 1:length(zd1.dat)
		zd1.dat[i] -= zd2.dat[i]
	end
	return nothing
end

function add!(zd1::VTUDataField{Float64}, a::Number)
	@inbounds for i in 1:length(zd1.dat)
		zd1.dat[i] += a
	end
	return nothing
end

function mul!(zd1::VTUDataField{Float64}, c::Number)
	@inbounds for i in 1:length(zd1.dat)
		zd1.dat[i] *= c
	end
	return nothing
end

function mul!(zd1::VTUDataField{Float64}, zd2::VTUDataField{Float64}, zd3::VTUDataField{Float64})
	@inbounds for i in 1:length(zd1.dat)
		zd1.dat[i] = zd2.dat[i] * zd3.dat[i]
	end
	return nothing
end

function mul!(zd1::VTUDataField{Float64}, zd2::VTUDataField{Float64}, fac::Float64)
	@inbounds for i in 1:length(zd1.dat)
		zd1.dat[i] = zd2.dat[i] * fac
	end
	return nothing
end

function pow!(zd1::VTUDataField{Float64}, a::Number)
	@inbounds for i in 1:length(zd1.dat)
		zd1.dat[i] ^= a
	end
	return nothing
end

function div!(zd1::VTUDataField{Float64}, a::Number)
	@inbounds for i in 1:length(zd1.dat)
		zd1.dat[i] /= a
	end
	return nothing
end

function max!(zd1::VTUDataField{Float64}, zd2::VTUDataField{Float64})
	@inbounds for i in 1:length(zd1.dat)
		zd1.dat[i] = max(zd1.dat[i],zd2.dat[i])
	end
	return nothing
end

function min!(zd1::VTUDataField{Float64}, zd2::VTUDataField{Float64})
	@inbounds for i in 1:length(zd1.dat)
		zd1.dat[i] = min(zd1.dat[i],zd2.dat[i])
	end
	return nothing
end

function add!(zd1::VTUData, zd2::VTUData)
	for (dat1,dat2) in zip(zd1.interp_data,zd2.interp_data)
		add!(dat1,dat2)
	end
	return nothing
end

function minus!(zd1::VTUData, zd2::VTUData)
	for (dat1,dat2) in zip(zd1.interp_data,zd2.interp_data)
		minus!(dat1,dat2)
	end
	return nothing
end

function add!(zd1::VTUData, a::Number)
	for dat in zd1.interp_data	
		add!(dat,a)
	end
	return nothing
end

function mul!(zd1::VTUData, c::Number)
	for dat in zd1.interp_data	
		mul!(dat,c)
	end
	return nothing
end


function mul!(zd1::VTUData, zd2::VTUData, zd3::VTUData)
	for (dat1,dat2,dat3) in zip(zd1.interp_data,zd2.interp_data,zd3.interp_data)
		mul!(dat1,dat2,dat3)
	end
	return nothing
end

function mul!(zd1::VTUData, zd2::VTUData, fac::Float64)
	for (dat1,dat2) in zip(zd1.interp_data,zd2.interp_data)
		mul!(dat1,dat2,fac)
	end
	return nothing
end

function pow!(zd1::VTUData, a::Number)
	for dat in zd1.interp_data	
		pow!(dat,a)
	end
	return nothing
end

function div!(zd1::VTUData, a::Number)
	for dat in zd1.interp_data	
		div!(dat,a)
	end
	return nothing
end

function div!(zd1::VTUData, zd2::VTUData, zd3::VTUData)
	for (dat1,dat2,dat3) in zip(zd1.interp_data,zd2.interp_data,zd3.interp_data)
		div!(dat1,dat2,dat3)
	end
	return nothing
end

function max!(zd1::VTUData, zd2::VTUData)
	for (dat1,dat2) in zip(zd1.interp_data,zd2.interp_data)
		max!(dat1,dat2)
	end
	return nothing
end

function min!(zd1::VTUData, zd2::VTUData)
	for (dat1,dat2) in zip(zd1.interp_data,zd2.interp_data)
		min!(dat1,dat2)
	end
	return nothing
end


import Base: +,-,*,/,^

function +(tpf1::VTUData, tpf2::VTUData)
	ret = similar(tpf1)
	add!(ret,tpf1)
	add!(ret,tpf2)
	return ret
end

function -(tpf1::VTUData, tpf2::VTUData)
	ret = similar(tpf1)
	add!(ret,tpf1)
	minus!(ret,tpf2)
	return ret
end

function *(tpf1::VTUData, tpf2::VTUData)
	ret = similar(tpf1)
	mul!(ret,tpf1,tpf2)
	return ret
end

function /(tpf1::VTUData, tpf2::VTUData)
	ret = similar(tpf1)
	div!(ret,tpf1,tpf2)
	return ret
end

function +(tpf::VTUData, a::Number)
	ret = similar(tpf)
	add!(ret,tpf)
	add!(ret,a)
	return ret
end
+(a::Number,tpf::VTUData) = tpf+a

function -(tpf::VTUData, a::T) where T<:Number
	ret = similar(tpf)
	add!(ret,tpf)
	add!(ret,-a)
	return ret
end

function -(a::T,tpf::VTUData) where T<:Number
	ret = similar(tpf)
	add!(ret,a)
	minus!(ret,tpf)
	return ret
end

function *(tpf::VTUData, a::T) where T<:Number
	ret = similar(tpf)
	add!(ret,tpf)
	mul!(ret,a)
	return ret
end
*(a::T,tpf::VTUData) where T<:Number = tpf*a

function /(tpf::VTUData, a::T) where T<:Number
	ret = similar(tpf)
	add!(ret,tpf)
	div!(ret,a)
	return ret
end

function ^(tpf::VTUData, a::T) where T<:Number
	ret = similar(tpf)
	add!(ret,tpf)
	pow!(ret,a)
	return ret
end