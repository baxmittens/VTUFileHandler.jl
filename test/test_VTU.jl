file = joinpath(".","pointheatsource.vtu")
vtu = VTUFileHandler.VTUFile(file);
tmp = similar(vtu)
vtu += tmp
true
