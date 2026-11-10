/*
 * sorter_barcode: barcode reader for the sorter images and PDFs (Code 128, Code 39, ITF, DataMatrix, QR, Aztec).
 * https://github.com/TeoPlace/lib_sorter_barcode_windows
 * https://github.com/TeoPlace/lib_sorter_barcode_linux
 *
 * Every read function returns the number of codes found (>= 0), or a negative error:
 *    -1 bad arguments   -2 file cannot be read   -3 'out' too small   -4 out of memory
 * and writes in 'out' (UTF-8, zero terminated) one JSON object per code:
 *
 *     [
 *     {"type":"code128","value":"RB0002627784"}
 *     ]
 *
 * When there is no code the text starts with the line "no 1d or 2d barcodes found".
 * 'needed' (may be NULL) receives the size 'out' must have, terminator included: with -3, call again
 * with a buffer that large.
 * settings: "ALL", "1D" or "2D".  fast: 1 skips the slower retries (faster, may miss hard codes).
 * Thread safe: call from as many threads as you like.
 */
#ifndef SORTER_BARCODE_H
#define SORTER_BARCODE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) && !defined(SB_STATIC)
#define SB_IMPORT __declspec(dllimport)
#else
#define SB_IMPORT
#endif

/* Library version, e.g. "1.2.0". */
SB_IMPORT const char *sb_version(void);

/* A BMP file (1, 4, 8, 16, 24 or 32 bit, uncompressed) or a PDF file; the kind is told by the content, not
 * by the name. Colour images are read as gray. Of a PDF it reads the images of every page and returns
 * their codes together, each code once. PDF images: Flate, LZW, CCITT fax (G3, G4), baseline JPEG,
 * RunLength, ASCIIHex, ASCII85, in gray, RGB, CMYK, Lab, ICC, Indexed or Separation colours.
 * Not read: JBIG2, JPEG 2000, progressive JPEG, encrypted PDFs, and codes drawn as vectors or text. */
SB_IMPORT int sb_read_file(const char *path, const char *settings, int fast, char *out, int out_cap, int *needed);

/* The same as sb_read_file (its name from version 1.1). */
SB_IMPORT int sb_read_bmp_file(const char *path, const char *settings, int fast, char *out, int out_cap, int *needed);

/* The images the reader finds in a file (a BMP: one; a PDF: one per page image), as 8-bit gray, rows top to
 * bottom with no padding. Returns how many images the file has and, when 0 <= index < that number, writes the
 * size of that image in width and height and its pixels in 'pixels' (when not NULL and 'capacity' >= width * height,
 * otherwise -3). Errors: -1 bad arguments, -2 file cannot be read, -4 out of memory. */
SB_IMPORT int sb_file_image(const char *path, int index, uint8_t *pixels, int capacity, int *width, int *height);

/* 8-bit gray pixels already in memory, rows top to bottom; 'stride' is the bytes per row. */
SB_IMPORT int sb_read_gray(const uint8_t *px, int width, int height, int stride, const char *settings, int fast,
                           char *out, int out_cap, int *needed);

#ifdef __cplusplus
}
#endif

#endif
