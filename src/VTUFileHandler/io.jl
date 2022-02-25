function read_compressed(dat,headertype,type)
	a = reinterpret(headertype,dat[1:8])[1]
	vtuheader = VTUHeader(headertype,dat[1:headerlength(headertype,a)])
	if !isempty(vtuheader.compressed_blocksizes)
		decompr_dat = transcode(ZlibDecompressor, dat[headerlength(headertype,a)+1:end])		 
	 	interpr_dat = reinterpret(type,decompr_dat)
	 	dat = VTUDataField(interpr_dat)
	 	#return vtuheader,interpr_dat
	 	return vtuheader,dat
	else
		#return vtuheader,type[]
		return vtuheader,VTUDataField(type)
	end
end

function read_uncompressed(dat,headertype,type)
	header = reinterpret(headertype,dat[1:sizeof(headertype)])
	datalength = reinterpret(headertype,header)
	println(Int(header[1]))
	println(Int(datalength[1]))
	println("$(map(x->Int(x),datalength)) == $(length(dat)-sizeof(headertype)) = $(length(dat))-$(sizeof(headertype))")
	println()
	#@assert datalength[1] == (length(dat)-sizeof(headertype)) "$(map(x->Int(x),datalength)) == $(length(dat)-sizeof(headertype)) = $(length(dat))-$(sizeof(headertype))"
	@assert datalength[1] == length(dat)-sizeof(headertype) "$(map(x->Int(x),datalength)) == $(length(dat)-sizeof(headertype)) = $(length(dat))-$(sizeof(headertype))"
	interpr_dat = reinterpret(type,dat[sizeof(headertype)+1:end])
	dat = VTUDataField(interpr_dat)	
	return VTUHeader(headertype),dat
end

function readappendeddata!(data,i,appendeddata,offsets,type,headertype,compressed_dat)
	@assert length(appendeddata) == 1 && length(appendeddata[1].content) == 1 "length(appendeddata) = $(length(appendeddata)) && length(appendeddata[1].content) = $(length(appendeddata[1].content))"
	offset = offsets[i]
	rawdat = appendeddata[1].content[1]
	next_offset = i < length(offsets) ? offsets[i+1] : length(rawdat)-1
	dat = Base64.base64decode(rawdat[offset+2:next_offset+1])
	#println(i)
	if compressed_dat
		vtuheader,dat = read_compressed(dat,headertype,type)
		push!(data,dat)
	else
		vtuheader,dat = read_uncompressed(dat,headertype,type)
		push!(data,dat)
	end
	#println()
	#a = reinterpret(headertype,dat[1:8])[1]
	#vtuheader = VTUHeader(headertype,dat[1:headerlength(headertype,a)])
	#if !isempty(vtuheader.compressed_blocksizes)
	#	decompr_dat = transcode(ZlibDecompressor, dat[headerlength(headertype,a)+1:end])		 
	# 	interpr_dat = reinterpret(type,decompr_dat)	
	# 	push!(data,interpr_dat)
	#else
	#	push!(data,type[])
	#end
	return vtuheader
end

function readdataarray!(data,el,type,headertype,compressed_dat)
	rawdat = el.content[1]
	dat = Base64.base64decode(rawdat);
	if compressed_dat
		vtuheader,dat = read_compressed(dat,headertype,type)
		push!(data,dat)
	else
		vtuheader,dat = read_uncompressed(dat,headertype,type)
		push!(data,dat)
	end
	return vtuheader	
end
 
#function readdataarray!(data,el,type,headertype,compressed_dat)
#	rawdat = el.content[1]
#	dat = Base64.base64decode(rawdat);
#	a = reinterpret(UInt32,dat[1:4])[1]
#	vtuheader = VTUHeader(UInt32,dat[1:headerlength(headertype,a)])
#	if !isempty(vtuheader.compressed_blocksizes)
#		decompr_dat = transcode(ZlibDecompressor, dat[headerlength(headertype,a)+1:end])
#	 	interpr_dat = reinterpret(type,decompr_dat)
#	 	push!(data,interpr_dat)
#	else
#		push!(data,type[])
#	end
#	return vtuheader	
#end 


