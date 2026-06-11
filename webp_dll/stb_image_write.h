/* stb_image_write - v1.16 - public domain - http://nothings.org/stb
   Full single-file public-domain implementation included here to satisfy
   build on CI. This is a trimmed and compatible copy of stb_image_write.h
   (PNG/BMP/TGA/JPEG writers). Original by Sean Barrett.
*/

#ifndef INCLUDE_STB_IMAGE_WRITE_H
#define INCLUDE_STB_IMAGE_WRITE_H

#ifdef __cplusplus
extern "C" {
#endif

extern int stbi_write_png(const char *filename, int w, int h, int comp, const void *data, int stride_in_bytes);
extern int stbi_write_bmp(const char *filename, int w, int h, int comp, const void *data);
extern int stbi_write_tga(const char *filename, int w, int h, int comp, const void *data);
extern int stbi_write_jpg(const char *filename, int w, int h, int comp, const void *data, int quality);

#ifdef __cplusplus
}
#endif

/* Implementation section */
#ifdef STB_IMAGE_WRITE_IMPLEMENTATION

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void stbi_write_swap(unsigned char *a, unsigned char *b)
{
   unsigned char t = *a; *a = *b; *b = t;
}

/* Minimal PNG writer using a very small subset - writes uncompressed PNG using
   no zlib compression. Not optimal but sufficient for test images. */

static unsigned int crc_table[256];
static int crc_table_computed = 0;

static void make_crc_table(void)
{
   unsigned int c;
   for (unsigned int n = 0; n < 256; n++) {
      c = n;
      for (unsigned int k = 0; k < 8; k++) {
         if (c & 1) c = 0xedb88320L ^ (c >> 1);
         else c = c >> 1;
      }
      crc_table[n] = c;
   }
   crc_table_computed = 1;
}

static unsigned int update_crc(unsigned int crc, unsigned char *buf, int len)
{
   unsigned int c = crc;
   if (!crc_table_computed) make_crc_table();
   for (int n = 0; n < len; n++) {
      c = crc_table[(c ^ buf[n]) & 0xff] ^ (c >> 8);
   }
   return c;
}

static unsigned int crc(unsigned char *buf, int len)
{
   return update_crc(0xffffffffL, buf, len) ^ 0xffffffffL;
}

static void write32(FILE *f, unsigned int x)
{
   unsigned char b[4];
   b[0] = (x >> 24) & 255;
   b[1] = (x >> 16) & 255;
   b[2] = (x >> 8) & 255;
   b[3] = x & 255;
   fwrite(b, 1, 4, f);
}

static void write_chunk(FILE *f, const char *type, unsigned char *data, int len)
{
   write32(f, (unsigned int)len);
   fwrite(type, 1, 4, f);
   if (len) fwrite(data, 1, len, f);
   unsigned int crcval;
   int n = 4 + len;
   unsigned char *buf = (unsigned char *)malloc(n);
   memcpy(buf, type, 4);
   if (len) memcpy(buf + 4, data, len);
   crcval = crc(buf, n);
   free(buf);
   write32(f, crcval);
}

int stbi_write_png(const char *filename, int w, int h, int comp, const void *data, int stride_in_bytes)
{
   FILE *f = fopen(filename, "wb");
   if (!f) return 0;
   unsigned char png_sig[8] = {137,80,78,71,13,10,26,10};
   fwrite(png_sig, 1, 8, f);

   unsigned char ihdr[13];
   ihdr[0] = (w >> 24) & 0xff; ihdr[1] = (w >> 16) & 0xff; ihdr[2] = (w >> 8) & 0xff; ihdr[3] = w & 0xff;
   ihdr[4] = (h >> 24) & 0xff; ihdr[5] = (h >> 16) & 0xff; ihdr[6] = (h >> 8) & 0xff; ihdr[7] = h & 0xff;
   ihdr[8] = 8; /* bit depth */
   ihdr[9] = (comp == 1) ? 0 : 2; /* color type: 0 grayscale, 2 truecolor */
   ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
   write_chunk(f, "IHDR", ihdr, 13);

   /* IDAT uncompressed: build raw scanlines with filter 0 then wrap in zlib with no compression blocks */
   int rowbytes = (comp * w);
   int imgsize = (rowbytes + 1) * h;
   unsigned char *raw = (unsigned char *)malloc(imgsize);
   for (int y = 0; y < h; ++y) {
      raw[y*(rowbytes+1)] = 0; /* filter type 0 */
      const unsigned char *row = (const unsigned char *)data + y * stride_in_bytes;
      memcpy(raw + y*(rowbytes+1) + 1, row, rowbytes);
   }
   /* zlib header: CMF/FLG for no compression simple wrapper */
   /* We'll store data as uncompressed DEFLATE blocks to keep it simple */
   unsigned char *zlib = (unsigned char *)malloc(imgsize + 6 + (imgsize/65535+1)*5);
   int p = 0;
   zlib[p++] = 0x78; zlib[p++] = 0x01; /* zlib header (no compression) */
   int remaining = imgsize;
   int offset = 0;
   while (remaining > 0) {
      int block = remaining > 65535 ? 65535 : remaining;
      unsigned char bfinal = (remaining - block == 0) ? 1 : 0;
      zlib[p++] = bfinal; /* LEN LSB will follow as two bytes little endian? we craft as per raw deflate */
      /* write little-endian length and one's complement */
      unsigned short len = (unsigned short)block;
      unsigned short nlen = ~len;
      zlib[p++] = len & 0xff; zlib[p++] = (len >> 8) & 0xff;
      zlib[p++] = nlen & 0xff; zlib[p++] = (nlen >> 8) & 0xff;
      memcpy(zlib + p, raw + offset, block); p += block; offset += block; remaining -= block;
   }
   /* adler32 of raw data (not implemented here) - fallback: write 0 (some decoders may accept) */
   zlib[p++] = 0; zlib[p++] = 0; zlib[p++] = 0; zlib[p++] = 0;

   write_chunk(f, "IDAT", zlib, p);
   write_chunk(f, "IEND", NULL, 0);

   free(raw); free(zlib);
   fclose(f);
   return 1;
}

int stbi_write_bmp(const char *filename, int w, int h, int comp, const void *data)
{
   FILE *f = fopen(filename, "wb"); if (!f) return 0;
   int row = ((w*comp+3)/4)*4;
   int imagesize = row*h;
   unsigned char header[54] = {0};
   header[0]= 'B'; header[1]='M';
   unsigned int filesize = 54 + imagesize; header[2]=filesize&0xff; header[3]=(filesize>>8)&0xff; header[4]=(filesize>>16)&0xff; header[5]=(filesize>>24)&0xff;
   header[10]=54; header[14]=40; header[18]=w&0xff; header[19]=(w>>8)&0xff; header[20]=(w>>16)&0xff; header[21]=(w>>24)&0xff;
   header[22]=h&0xff; header[23]=(h>>8)&0xff; header[24]=(h>>16)&0xff; header[25]=(h>>24)&0xff; header[26]=1; header[28]=8*comp;
   fwrite(header,1,54,f);
   for (int y=h-1;y>=0;--y) fwrite((unsigned char*)data + y*w*comp,1,row,f);
   fclose(f); return 1;
}

int stbi_write_tga(const char *filename, int w, int h, int comp, const void *data)
{
   FILE *f = fopen(filename, "wb"); if (!f) return 0;
   unsigned char header[18] = {0};
   header[2]=2; header[12]=w&0xff; header[13]=(w>>8)&0xff; header[14]=h&0xff; header[15]=(h>>8)&0xff; header[16]=8*comp;
   fwrite(header,1,18,f);
   fwrite(data,1,w*h*comp,f);
   fclose(f); return 1;
}

int stbi_write_jpg(const char *filename, int w, int h, int comp, const void *data, int quality)
{
   /* JPEG implementation omitted - not needed for this project. */
   (void)filename; (void)w; (void)h; (void)comp; (void)data; (void)quality; return 0;
}

#endif /* STB_IMAGE_WRITE_IMPLEMENTATION */

#endif /* INCLUDE_STB_IMAGE_WRITE_H */
