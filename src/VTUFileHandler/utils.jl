import TranscodingStreams
import Dates

function compressdat(vtuheader,dat,headertype,level=5)
	compr_dat = Vector{UInt8}[]
	bytedata = reinterpret(UInt8,dat)
	for i = 1:length(vtuheader.compressed_blocksizes)-1
		_start = (i-1)*vtuheader.blocksize+1
		_stop = i*vtuheader.blocksize
		tmp = bytedata[_start:_stop]
		buf = IOBuffer(append=true)
		zWriter = ZlibCompressorStream(buf,level=level)
		write(zWriter, tmp)
		write(zWriter, TranscodingStreams.TOKEN_END)
		flush(zWriter)
		push!(compr_dat,read(buf))
	end
	_start = (vtuheader.num_blocks-1)*vtuheader.blocksize+1
	tmp = bytedata[_start:end]
	buf = IOBuffer(append=true)
	zWriter = ZlibCompressorStream(buf,level=level)
	write(zWriter, tmp)
	write(zWriter, TranscodingStreams.TOKEN_END)
	flush(zWriter)
	push!(compr_dat,read(buf))
	last_blocksize = headertype(length(tmp))
	compressed_blocksizes = map(x->headertype(length(x)),compr_dat)
	nvtuhead = VTUHeader(vtuheader.num_blocks,vtuheader.blocksize,last_blocksize,compressed_blocksizes)
	return nvtuhead, vcat(compr_dat...)
end

function updateappendeddata!(i,j,el,appendeddata,data,offsets,type,headertype,compressed_dat)
	vtuheader = data.header[j]
	dat = data.data[j].dat
	rangemin = minimum(filter(!isnan,dat))
	rangemax = maximum(filter(!isnan,dat))
	rawdat = appendeddata[1].content[1]
	if compressed_dat
		nvtuhead, compr_dat = compressdat(vtuheader,dat,headertype)
		head = bytes(nvtuhead)
		base_head = Base64.base64encode(head)
		base_dat = Base64.base64encode(compr_dat)
		if i < length(offsets)
			newoff = length(base_head)+length(base_dat)
			diffoff = offsets[i]+newoff-offsets[i+1]
			appendeddata[1].content[1] = rawdat[1:offsets[i]+1]*base_head*base_dat*rawdat[2+offsets[i+1]:end]
		else
			newoff = 0
			diffoff = 0		
			appendeddata[1].content[1] = rawdat[1:offsets[i]+1]*base_head*base_dat
		end
	else
		a = headertype(length(dat)*sizeof(type))
		b = dat
		aa = reinterpret(UInt8,[a])
		bb = reinterpret(UInt8,b)
		base = Base64.base64encode(vcat(aa,bb))
		if i < length(offsets)
			newoff = length(base)
			diffoff = offsets[i]+newoff-offsets[i+1]
			appendeddata[1].content[1] = rawdat[1:offsets[i]+1]*base*rawdat[2+offsets[i+1]:end]
		else
			newoff = 0
			diffoff = 0	
			appendeddata[1].content[1] = rawdat[1:offsets[i]+1]*base
		end
	end
	if i < length(offsets)
		offsets[i+1:end] .+= diffoff
	end
	setAttribute(el,"RangeMin",rangemin)
	setAttribute(el,"RangeMax",rangemax)
	setAttribute(el,"offset",offsets[i])
	return nothing
end

function updatedataarray!(i,j,el,data,offsets,type,headertype,compressed_dat)
	vtuheader = data.header[j]
	dat = data.data[j].dat
	bytedata = reinterpret(UInt8,dat)
	rangemin = minimum(filter(!isnan,dat))
	rangemax = maximum(filter(!isnan,dat))
	if compressed_dat
		nvtuhead, compr_dat = compressdat(vtuheader,dat,headertype,-1)
		head = bytes(nvtuhead)
		base_head = Base64.base64encode(head)
		base_dat = Base64.base64encode(compr_dat)
		el.content[1] = base_head*base_dat
	else
		a = headertype(length(dat)*sizeof(type))
		b = dat
		aa = reinterpret(UInt8,[a])
		bb = reinterpret(UInt8,b)
		el.content[1] = Base64.base64encode(vcat(aa,bb))
	end
	setAttribute(el,"RangeMin",rangemin)
	setAttribute(el,"RangeMax",rangemax)
	return nothing
end

function update_xml!(vtufile::VTUFile)
	dataarrays,appendeddata,headertype,offsets,data,compressed_dat = vtufile.dataarrays,vtufile.appendeddata,vtufile.headertype,vtufile.offsets,vtufile.data,vtufile.compressed_dat
	println("compressed ",compressed_dat)
	j = 0
	update_data!(data)
	if !isempty(appendeddata) && !isempty(appendeddata[1].content)
		println("length appended = ",length(appendeddata[1].content[1]))
	end
	for (i,el) in enumerate(dataarrays)
		_type = replace(getAttribute(el,"type"),"\""=>"")
		type = eval(Meta.parse(_type))
		_format = replace(getAttribute(el,"format"),"\""=>"")
		_name = replace(getAttribute(el,"Name"),"\""=>"")
		if findfirst(x->x==_name,vtukeywords.interpolation_keywords) != nothing || findfirst(x->x==_name,vtukeywords.uncompress_keywords) != nothing
			j+=1			
			if _format == "appended"	
				updateappendeddata!(i,j,el,appendeddata,data,offsets,type,headertype,compressed_dat)
			else
				updatedataarray!(i,j,el,data,offsets,type,headertype,compressed_dat)
			end
		else
			if _format == "appended"
				setAttribute(el,"offset",offsets[i])
			end
		end
	end
end

function timestamp()
	str = string(Dates.unix2datetime(time()))
	str = replace(str,"-"=>"_")
	str = replace(str,":"=>"_")
	str = replace(str,"."=>"_")
end


"""
	write(vtufile::VTUFile,add_timestamp::Bool=true)

Writes a [`VTUFile`](@ref) to destination `vtufile.name`

# Arguments
- `vtufile::VTUFile`: VTU file
- `add_timestamp::Bool`: adds a timestamp to `vtufile.name` if `add_timestamp==true`
"""
function Base.write(vtufile::VTUFile, add_timestamp::Bool=true)
	update_xml!(vtufile)
	name = vtufile.name
	if add_timestamp
		splitstr = split(name,".vtu")
		@assert length(splitstr) == 2 && isempty(splitstr[end])
		name = splitstr[1] * "_" * timestamp() * ".vtu"
	end
	f = open(name,"w")
	writeXMLElement(f,vtufile.xmlroot)
	close(f)
end

function rename!(vtuf::VTUFile,name::String)
	vtuf.name = name
	return nothing
end

function Base.deepcopy(vtuf::VTUFile)
	return VTUFile(vtuf.name,vtuf.xmlroot,vtuf.dataarrays,vtuf.appendeddata,vtuf.headertype,vtuf.offsets,similar(vtuf.data),vtuf.compressed_dat)
end

function Base.similar(vtuf::VTUFile)
	ret = deepcopy(vtuf)
	#foreach(fill_zeros,ret.data.data)
	return ret
end

function Base.fill!(ret::VTUFile, c::Float64)
	fill!(ret.data,c)
	return nothing
end

function Base.zero(vtu::VTUFile)
	ret = similar(vtu)
	fill!(ret,0.0)
	return ret
end

function Base.one(vtu::VTUFile)
	ret = similar(vtu)
	fill!(ret,1.0)
	return ret
end

function Base.empty!(vtu::VTUFile)
	for i = 1:length(vtu.data.data)
		empty!(vtu.data.data[i].dat)
	end
	return nothing
end

function Base.empty(vtu::VTUFile)
	ret = similar(vtu)
	empty!(ret)
	return ret
end

function addPointData!(vtu::VTUFile,name::String,dat,interp_dat) #does only work for scalar fields and last field in result has to be scalar
	pointdata = getElements(vtu.xmlroot,"PointData")
	n = length(vtu.data.idat)+1
	n_pd = length(pointdata[1].content)+1
	apd = deepcopy(pointdata[1].content[end])
	push!(pointdata[1].content,apd)
	setAttribute(apd,"Name",name)
	if hasAttributekey(apd,"NumberOfComponents")
		@assert parse(Int,replace(getAttribute(apd,"NumberOfComponents"),"\""=>"")) == 1
	end
	insert!(vtu.data.data,n,dat)
	off = vtu.offsets[n_pd-1]
	diffoff = vtu.offsets[n_pd]-off
	vtu.appendeddata[1].content[1] = vtu.appendeddata[1].content[1][1:off+1]*vtu.appendeddata[1].content[1][off+2:off+1+diffoff]*vtu.appendeddata[1].content[1][off+2:end];
	insert!(vtu.offsets,n_pd,off)
	vtu.offsets[n_pd:end] .+= diffoff
	insert!(vtu.data.header,n,deepcopy(vtu.data.header[n-1]))
	push!(vtu.data.idat,n)
	push!(vtu.data.interp_data,interp_dat)
	insert!(vtu.data.names,n,name)
	push!(vtukeywords.interpolation_keywords,name)
	push!(vtukeywords.interpolation_keywords,"\""*name*"\"")
	vtu.dataarrays = getElements(vtu.xmlroot, "DataArray")
	return nothing
end

function addIntegrityTemp!(vtu::VTUFile,init=nothing,name::String="temperature_interpolated")
	ind = findall(x->replace(x,"\""=>"")==name,vtu.data.names)[1]
	dat = deepcopy(vtu.data.data[ind])
	interp_dat = deepcopy(vtu.data.interp_data[vtu.data.idat[ind]])
	if init != nothing
		interp_dat.dat .+= init.data.interp_data[ind].dat
	end
	interp_dat.dat ./= 373.15
	addPointData!(vtu,"integrity_temp",dat,interp_dat)
	return nothing
end


function addIntegrityDilat!(vtu::VTUFile,init=nothing,name::String="sigma")
	ind = findall(x->replace(x,"\""=>"")==name,vtu.data.names)[1]
	sigar = deepcopy(vtu.data.interp_data[ind].dat)
	if init != nothing
		sigar .+= init.data.interp_data[ind].dat
	end 
	dat = deepcopy(vtu.data.data[end])
	interp_dat = deepcopy(vtu.data.interp_data[vtu.data.idat[end]])
	for (ig,i) = enumerate(1:4:length(sigar))
		_sig = SMatrix{3,3}(sigar[i], sigar[i+3], 0.0, sigar[i+3], sigar[i+1], 0.0, 0.0, 0.0, sigar[i+2])
		evals = sort(eigvals(_sig))
		r = (evals[end]-evals[1])/2
		phi = 1
		c = 1
		R = c*cos(phi)-(evals[end]+evals[1])/2*sin(phi)
		interp_dat.dat[ig] = r/R
	end
	addPointData!(vtu,"integrity_dilat",dat,interp_dat)
	return nothing
end

function addIntegrityFluid!(vtu::VTUFile,init=nothing,name1::String="sigma",name2::String="pressure_interpolated")
	ind1 = findall(x->replace(x,"\""=>"")==name1,vtu.data.names)[1]
	ind2 = findall(x->replace(x,"\""=>"")==name2,vtu.data.names)[1]
	sigar = deepcopy(vtu.data.interp_data[ind1].dat)
	par = deepcopy(vtu.data.interp_data[ind2].dat)
	if init != nothing
		sigar .+= init.data.interp_data[ind1].dat
		par .+= init.data.interp_data[ind2].dat
	end 
	dat = deepcopy(vtu.data.data[end])
	interp_dat = deepcopy(vtu.data.interp_data[vtu.data.idat[end]])
	for (ig,i) = enumerate(1:4:length(sigar))
		_sig = SMatrix{3,3}(sigar[i], sigar[i+3], 0.0, sigar[i+3], sigar[i+1], 0.0, 0.0, 0.0, sigar[i+2])
		evals = sort(eigvals(_sig))
		p = par[ig]
		interp_dat.dat[ig] = evals[end]+p
	end
	addPointData!(vtu,"integrity_fluid",dat,interp_dat)
	return nothing
end

function addIntegrityChecks!(vtu::VTUFile,init=nothing)
	addIntegrityTemp!(vtu,init)
	addIntegrityDilat!(vtu,init)
	addIntegrityFluid!(vtu,init)
	return nothing
end

function Base.getindex(vtu::VTUFile, str::String)
	ind = findfirst(x->replace(x,"\""=>"")==str,vtu.data.names)
	if ind ∈ vtu.data.idat
		ind = findfirst(x->x==ind,vtu.data.idat)
		return vtu.data.interp_data[ind].dat
	else
		return vtu.data.data[ind].dat
	end
end

