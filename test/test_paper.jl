import VTUFileHandler
import VTUFileHandler: set_uncompress_keywords, set_interpolation_keywords, VTUFile

set_uncompress_keywords(["xRamp"])
set_interpolation_keywords(["xRamp"])
vtu = VTUFile("vox8.vtu");
tmp = deepcopy(vtu)/4.0;
vtu += tmp;
vtu *= 4.0;
vtu -= 2.0;
vtu ^= 2.0;

write(vtu)

