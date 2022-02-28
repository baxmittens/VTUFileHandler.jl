file = joinpath(".","pointheatsource.vtu")
vtu1 = VTUFileHandler.VTUFile(file);
tmp = similar(vtu1.data)
vtu += tmp