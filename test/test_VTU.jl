include(joinpath("..","src","Ogs6InputFileHandler.jl"))
include(joinpath("..","src","VTUFileHandler.jl"))

file = joinpath(".","Point_injection","square_1e2_lin.prj")
ogs6md = read(Ogs6ModelDef, file)
write(ogs6md)

file1 = joinpath(".","Point_injection","expected_square_1e0_ts_10_t_1000.000000.vtu")
file2 = joinpath(".","Point_injection","expected_square_1e0_lin_ts_10_t_50000.000000.vtu")
file3 = joinpath(".","Point_injection","expected_square_1e0_ts_10_t_50000.000000.vtu")

vtu1 = VTUFile(file1);
vtu2 = VTUFile(file2);
vtu3 = VTUFile(file3);

write(vtu1)

tmp = similar(vtu1.data)