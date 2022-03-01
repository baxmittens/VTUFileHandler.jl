---
title: 'VTUFileHandler: A VTU library in the Julia language that implements an algebra for basic mathematical operations on VTU data'
tags:
  - Julia
  - VTK unstructered grid
  - Stochastic/parametric post-processing of simulation results
authors:
  - name: Maximilian Bittens
    orcid: 0000-0001-9954-294X
    affiliation: "1"
affiliations:
 - name: Federal Institute for Geosciences and Natural Resources (BGR)
   index: 1
date: 28 February 2022
bibliography: paper.bib
---

# Abstract

With increasing computing resources, the investigation of uncertainties in simulation results is becoming an increasingly important factor. To analyze those effects, a discrete numerical simulation is computed several times with different realizations of the input parameters to produce different outputs of the same model. The relevant stochastic or parametric output variables, such as mean value, expected value and variance, are often calculated and visualized only at selected individual points of the whole domain. This project aims to provide a simple way to perform stochastic/parametric post-processing of numerical simulations on entire domains, here using the VTK unstructed grid (VTU) file system and the julia language as an example.

# Introduction

Consider a discrete computational model $\mathcal{M}$, providing an output-vector $\mathbf{Y}$ for a given set of inputs $\mathbf{X}$:
\begin{equation}\label{eq:discr}
\mathbf{Y} = \mathcal{M}(\mathbf{X})\;.
\end{equation}
The output $\mathbf{Y}$ can be a scalar, a vector, a matrix, or a finite-element post-processing result, for example. In this case, we consider the output to be a VTU file. The input parameters are considers to be a set of scalars $\mathbf{X}= \{X_1,...,X_N\}$, and for simplicity, the set is reduced to a \textit{singleton} ($N=1$). Equation (\ref{eq:discr}) is called the \textit{deterministic case}. As a next step, we introduce a parametric variation $\mathbf{X}:=\mathbf{X}(\boldsymbol{\xi})$, where $\boldsymbol{\xi}$ maps the inputs from a minimum to a maximum value. Then we refer to as parametric (or if $\xi_i$, $i\in{1,...,N}$ is a random variable with a propability density function, stochastic ) case:
\begin{equation}\label{eq:stoch}
\mathbf{Y}(\boldsymbol{\xi}) = \mathcal{M}(\mathbf{X}(\boldsymbol{\xi}))\;.
\end{equation}
Since $\mathbf{Y}(\boldsymbol{\xi})$ is no longer deterministic, further methods are required to discretize the \textit{sample space} and to post-process and visualize the results. Different methods for uncertainty quantification can be found in @gates2015multilevel or @sudret2017surrogate, for example.
The most prominent method for computing the expected value of the problem described in Equation (\ref{eq:stoch}) is the Monte-Carlo method:
\begin{equation}\label{eq:montecarlo}
\mathbb{E}[\mathbf{Y}(\boldsymbol{\xi})] \approx \tilde{\mathbb{E}}[\mathcal{M}(\mathbf{X}(\boldsymbol{\xi}))] = \frac{1}{M} \sum\limits_{i=1}^M \mathcal{M}(\mathbf{X}(\tilde{\boldsymbol{\xi}}_i))\,,\quad
\tilde{\xi}_{ij} \sim \mathcal{U}(0,1)\,.
\end{equation} 
From (\ref{eq:montecarlo}) we can conlcude that if $\mathbf{Y}(\tilde{\boldsymbol{\xi}}_i)=\mathcal{M}(\mathbf{X}(\tilde{\boldsymbol{\xi}}_i))$ is a deterministic VTU result file at position $\tilde{\boldsymbol{\xi}}_i$ in the sample space, it is sufficient to implement the operators `+(::VTUFile,::VTUFile)` and `/(::VTUFile,::Number)` to compute the expected value on the whole domain by help of the Monte-Carlo method.

# Preliminaries 

The [VTUFileHandler](https://github.com/baxmittens/VTUFileHandler) will eventually be used to perform stochastic post-processing on large VTU result files. Therefore, the following assumptions have to be fulfilled for the software to work properly:

1. The VTU file must be in binary format and, in addition, can be Zlib compressed.
2. Operators can only be applied to VTU files with the same topology. The user must ensure that this condition is met.
3. The data type of numerical fields of the VTU file for which operators should be applied have to be `Float64`.

A three-dimensional cube with dimension $(x,y,z)$ with $0<=x,y,z<=2$ discretized by quadrilian elements with 27 points and 8 cells name `vox8.vtu` with a linear ramp in x-direction ($f(x=0,y,z)=0$, $f(x=2,y,z)=0.8$) as a result field with the named `xramp` will be used as an example (see \autoref{fig:1}).

# Features
The VTUFileHandler implements a basic VTU reader and writer through the functions:
```julia
function VTUFile(file::String) ... end
function Base.write(vtu::VTUFile, add_timestamp=true) ... end
```
By default, a timestamp is added if VTU files are written to disk to not overwrite existing files. Only data fields for which the function 
```julia
function set_uncompress_keywords(uk::Vector{String}) ... end
```
is called before reading the VTU file are uncompressed and can be altered. For applying math operators onto a data field, the field has to be registered by the function 
```julia
function set_interpolation_keywords(ik::Vector{String}) ... end
```
The following math operators are implemented:
```julia 
+(::VTUFile, ::VTUFile),+(::VTUFile, ::Number),
-(::VTUFile, ::VTUFile),-(::VTUFile, ::Number),
*(::VTUFile, ::VTUFile),*(::VTUFile, ::Number),
```

# Example
Thus, for our example cube to work properly following calls have to be made
```julia
set_uncompress_keywords(["xRamp"])
set_interpolation_keywords(["xRamp"])
vtu = VTUFile("vox8.vtu");
```




![Cube with initial result field (left). Cube with manipulated result field (right).\label{fig:1}](xramp1.PNG){ width=100% }

#Conclusion

# References
