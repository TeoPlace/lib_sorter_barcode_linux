/* Reads the barcodes of the BMP or PDF files given on the command line.  Usage: leggi <file>... */
#include <stdio.h>
#include <stdlib.h>

#include "sorter_barcode.h"

int main(int argc, char **argv) {
    printf("sorter_barcode %s\n", sb_version());
    int cap = 4096;
    char *out = malloc(cap);
    for (int i = 1; i < argc; i++) {
        int needed = 0;
        int n = sb_read_file(argv[i], "ALL", 0, out, cap, &needed);
        if (n == -3) {
            cap = needed;
            out = realloc(out, cap);
            n = sb_read_file(argv[i], "ALL", 0, out, cap, &needed);
        }
        printf("== %s (%d)\n", argv[i], n);
        if (n >= 0) fputs(out, stdout);
    }
    free(out);
    return 0;
}
