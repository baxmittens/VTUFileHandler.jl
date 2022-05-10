# Library

## Contents 

```@contents
Pages = ["lib.md"]
Depth = 4
```

## Functions

### Index

```@index
Pages = ["public.md"]
```

### General functions

```@docs
VTUHeader
VTUFileHandler.VTUDataField
VTUFileHandler.VTUData
VTUFile
```

### VTU Keywords

```@docs
VTUFileHandler.VTUKeyWords
set_uncompress_keywords
add_uncompress_keywords
set_interpolation_keywords
add_interpolation_keywords
```

### IO-Functions

```@docs
write(::VTUFile, ::Bool)
```