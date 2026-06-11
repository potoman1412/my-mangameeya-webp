/* stb_image_write - v1.16 - public domain - http://nothings.org/stb
   Writes out PNG/BMP/TGA/JPEG/HDR images to C stdio - Sean Barrett 2010-2015
   For brevity I've included only stbi_write_png minimal code here inlined.
   In real project, grab full stb_image_write.h from https://github.com/nothings/stb
*/

#ifndef STB_IMAGE_WRITE_IMPLEMENTATION
// Minimal subset declarations
extern "C" int stbi_write_png(char const *filename, int w, int h, int comp, const void *data, int stride_in_bytes);
#endif

#ifdef STB_IMAGE_WRITE_IMPLEMENTATION
// Minimalistic PNG writer wrapper using stb code would go here.
// For this example we assume the full stb_image_write.h is present.
#include "stb_image_write_full.h" // placeholder - replace with actual header
#endif
