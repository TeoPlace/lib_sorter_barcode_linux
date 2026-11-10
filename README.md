# sorter-barcode per Linux

Legge i barcode dalle immagini BMP del sorter: **Code 128, Code 39, ITF, DataMatrix, QR, Aztec**.
C'è un comando da usare nel terminale e una libreria per chi scrive programmi. È lo stesso lettore di
SorterNext e SorterBarcode di [teo.place](https://sorterbarcode.teo.place/), e legge gli stessi codici della
versione per Windows. Per Linux a 64 bit (x86_64), qualunque distribuzione.

La versione per Windows è in [lib_sorter_barcode_windows](https://github.com/TeoPlace/lib_sorter_barcode_windows).

## Installare

```
curl -fsSL https://raw.githubusercontent.com/TeoPlace/lib_sorter_barcode_linux/main/install.sh | sudo sh
```

Senza root, nella propria home:

```
curl -fsSL https://raw.githubusercontent.com/TeoPlace/lib_sorter_barcode_linux/main/install.sh | sh -s -- --prefix ~/.local
```

## Leggere un file

```
sorter-barcode /dati/immagini/lettera.bmp
```

Risponde con i codici trovati:

```
[
{"type":"code128","value":"RB0002627784"},
{"type":"data-matrix","value":"RB0002627784-BACK"}
]
```

Se non trova niente scrive `no 1d or 2d barcodes found`.

| per | scrivi |
|---|---|
| più file insieme (un blocco per file, nello stesso ordine) | `sorter-barcode a.bmp b.bmp` |
| tutti i BMP di una cartella | `for f in /dati/immagini/*.bmp; do echo "$f"; sorter-barcode "$f"; done` |
| solo i codici a barre lineari, o solo DataMatrix/QR/Aztec | `sorter-barcode 1D lettera.bmp`, `sorter-barcode 2D lettera.bmp` |
| andare più veloce (può perdere i codici più difficili) | `sorter-barcode --fast lettera.bmp` |
| sapere la versione | `sorter-barcode --version` |

## Aggiornare

Si rilancia lo stesso comando di installazione: scarica la versione nuova solo se c'è.
Per sapere soltanto se c'è un aggiornamento:

```
curl -fsSL https://raw.githubusercontent.com/TeoPlace/lib_sorter_barcode_linux/main/install.sh | sh -s -- --check
```

Al posto di `--check`: `--uninstall` per disinstallare, `--version 1.1.2` per una versione precisa
(con `--prefix ~/.local` se l'hai installato lì; con `sudo sh` se è in /usr/local).

## Scaricare senza installare

[lib_sorter_barcode_linux_x86_64.tar.gz](https://github.com/TeoPlace/lib_sorter_barcode_linux/releases/latest/download/lib_sorter_barcode_linux_x86_64.tar.gz)
è sempre l'ultima versione. Si estrae dove si vuole e si usa `bin/x86_64/sorter-barcode`
(oppure `sudo ./install.sh` dalla cartella estratta). Le versioni precedenti sono nelle
[release](https://github.com/TeoPlace/lib_sorter_barcode_linux/releases).

## Per chi scrive programmi

L'installazione mette anche la libreria (`libsorter_barcode.so`), l'header `sorter_barcode.h` e il file
`pkg-config`. La funzione da chiamare è una:

```c
int sb_read_bmp_file(const char *path, const char *settings, int fast, char *out, int out_cap, int *needed);
```

Legge il file e scrive in `out` lo stesso testo del comando; restituisce quanti codici ha trovato, o un numero
negativo se qualcosa non va. `settings` è `"ALL"`, `"1D"` o `"2D"`, `fast` è 0 o 1. Il resto è spiegato in
[include/sorter_barcode.h](include/sorter_barcode.h); in [examples](examples) c'è un esempio in C e uno in Python.
Per compilare: `gcc programma.c $(pkg-config --cflags --libs sorter_barcode)`.

Con git ogni versione è un tag (`v1.1.2`, …): `git clone` di questo repository, `sudo ./install.sh`,
e poi `git pull && sudo ./install.sh` per aggiornare.

## Licenza

MIT, vedi [LICENSE](LICENSE).
