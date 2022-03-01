# VTUFileHandler
A VTU library in the Julia language that implements an algebra for basic mathematical operations on VTU data.

## Introduction

With increasing computing resources, investigating uncertainties in simulation results is becoming an increasingly important factor. A discrete numerical simulation is computed several times with different deviations of the input parameters to produce different outputs of the same model to analyze those effects. The relevant stochastic or parametric output variables, such as mean, expected value, and variance, are often calculated and visualized only at selected individual points of the whole domain. This project aims to provide a simple way to perform stochastic/parametric post-processing of numerical simulations on entire domains using the VTK unstructured grid (VTU) file system and the Julia language as an example.

## Install

```julia
import Pkg
Pkg.add(url="https://github.com/baxmittens/XMLParser.git")
Pkg.add(url="https://github.com/baxmittens/VTUFileHandler.git")
```

## Usage

The VTUFileHandler implements a basic VTU reader and writer through the functions:
```julia
function VTUFile(file::String) ... end 
function Base.write(vtu::VTUFile, add_timestamp=true) ... end
```
By default, a timestamp is added if VTU files are written to disk not to overwrite existing files. Only data fields that are registered by the function 
```julia
function set_uncompress_keywords(uk::Vector{String}) ... end
```
before reading the VTU file are uncompressed and can be altered. For applying math operators onto a data field, the associated field has to be registered by the function 
```julia
function set_interpolation_keywords(ik::Vector{String}) ... end
```
The following math operators are implemented:
```julia 
+(::VTUFile, ::VTUFile),+(::VTUFile, ::Number),
-(::VTUFile, ::VTUFile),-(::VTUFile, ::Number),
*(::VTUFile, ::VTUFile),*(::VTUFile, ::Number),
/(::VTUFile, ::VTUFile),/(::VTUFile, ::Number),
^(::VTUFile, ::Number),
```
In-place variations of the operators above are implemented as well.


# Example

A three-dimensional cube with dimension $(x,y,z)$ with $0<=x,y,z<=2$ discretized by quadrilian elements with 27 points and 8 cells named `vox8.vtu` with a linear ramp in x-direction ($f(x=0,y,z)=0$, $f(x=2,y,z)=0.8$) as a result field termed `xramp` will be used as an example (see \autoref{fig:1}). The following set of instructions transform the result field from a linear ramp to a quadratic function in x-direction (displayed as a piecewise linear field due to the discretization):
```julia
set_uncompress_keywords(["xRamp"]) # uncrompress data field xramp
set_interpolation_keywords(["xRamp"]) # apply math operators to xramp
vtu = VTUFile("vox8.vtu"); # read the vtu
vtu += vtu/4; # [0.0,...,0.8] -> [0.0,...,1.0]
vtu *= 4.0; # [0,...,1.0] -> [0.0,...,4.0]
vtu -= 2.0; # [0,...,4.0] -> [-2.0,...,2.0]
vtu ^= 2.0; # [-2.0,...,2.0] -> [4.0,...,0.0,...,4.0]
```

The initial field and the resultant field of the above operations are displayed in figure \autoref{fig:1}.

![Cube with initial result field (left). Cube with manipulated result field (right).\label{fig:1}](xramp1.PNG){ width=100% }

