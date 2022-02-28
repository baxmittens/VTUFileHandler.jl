file = joinpath(".","pointheatsource.vtu")
vtu = VTUFileHandler.VTUFile(file);
tmp = similar(vtu.data)
vtu += tmp