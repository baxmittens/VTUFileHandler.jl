import Pkg; Pkg.add("Documenter")
push!(LOAD_PATH,"../src/")
using Documenter, VTUFileHandler
makedocs(
	sitename = "VTUFileHandler.jl",
	modules = [VTUFileHandler],
	pages = [
		"Home" => "index.md"
	]
	)
deploydocs(
    repo = "github.com/baxmittens/VTUFileHandler.jl.git"
)