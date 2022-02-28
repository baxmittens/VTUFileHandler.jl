file = joinpath(".","pointheatsource.vtu")
vtu = VTUFileHandler.VTUFile(file);
tmp = similar(vtu1.data)
vtu += tmp