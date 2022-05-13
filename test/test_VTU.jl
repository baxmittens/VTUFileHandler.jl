using VTUFileHandler
using Test

@testset "VTUFileHandler test" begin
    file = joinpath(".","pointheatsource.vtu")
    tempfieldstr = "temperature_interpolated"
    set_interpolation_keywords([tempfieldstr])
	vtu = VTUFileHandler.VTUFile(file);
	tmp = zero(vtu)
	tmp += vtu
	vtu += tmp
    @test all(vtu[tempfieldstr] .== 2.0*tmp[tempfieldstr])
    vtu -= tmp
    @test all(vtu[tempfieldstr] .== tmp[tempfieldstr])
end 