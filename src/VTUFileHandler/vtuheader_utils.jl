function Base.show(io::IO,hd::VTUHeader{T}) where {T<:Union{UInt32,UInt64}}
	print(io,"VTUHeader{$T}(")
	print(io,Int(hd.num_blocks),", ")
	print(io,Int(hd.blocksize),", ")
	print(io,Int(hd.last_blocksize),", ")
	print(io,"$T[")
	for (i,n) in enumerate(hd.compressed_blocksizes)
		print(io,Int(n))
		i==hd.num_blocks ? nothing : print(io,", ")
	end
	print(io,"])")
end
nbytes(T::Union{Type{UInt32},Type{UInt64}}) = T<:UInt32 ? 4 : 8
nbytes(T::Type{Float64}) =  8
nbytes(T::Type{Int32}) =  4
nbytes(T::Type{Int64}) =  8
nbytes(T::Type{UInt8}) =  1
raw_headerlength(T::Union{Type{UInt32},Type{UInt64}},nblocks) = length(Base64.base64encode(rand(UInt8,3*nbytes(T)+nblocks*nbytes(T))))
headerlength(T::Union{Type{UInt32},Type{UInt64}},nblocks) = 3*nbytes(T)+nblocks*nbytes(T)
bytes(header::VTUHeader) = reinterpret(UInt8,vcat(header.num_blocks,header.blocksize,header.last_blocksize,header.compressed_blocksizes...))
