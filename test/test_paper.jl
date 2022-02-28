import VTUFileHandler
import VTUFileHandler: set_uncompress_keywords, set_interpolation_keywords, VTUFile

set_uncompress_keywords(["xRamp","yRamp"])
set_interpolation_keywords(["xRamp","yRamp"])
vtu = VTUFile("vox8.vtu");

vtu /= 0.8;
vtu *= 4.0;
vtu -= 2.0;
vtu ^= 2.0;

write(vtu)
