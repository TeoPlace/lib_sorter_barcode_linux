# lib_sorter_barcode (Linux)

Libreria per leggere i barcode dalle immagini del sorter: **Code 128, Code 39, ITF, DataMatrix, QR, Aztec**.
È la stessa libreria usata da SorterNext e SorterBarcode di [teo.place](https://teo.place), e legge gli stessi
codici della versione Windows.

- libreria condivisa `x86_64`, dipende solo da `libc` e `libm`
- funziona con glibc 2.14 o successiva (praticamente ogni distribuzione degli ultimi dieci anni)
- thread safe: si possono leggere più immagini in parallelo
- versione **1.1.1** (le versioni sono i tag `v…` e le [release](https://github.com/TeoPlace/lib_sorter_barcode_linux/releases))

La versione per Windows è in [lib_sorter_barcode_windows](https://github.com/TeoPlace/lib_sorter_barcode_windows).

## Installazione e aggiornamento

**Dal terminale**, per tutto il sistema (`/usr/local`):

```
curl -fsSL https://raw.githubusercontent.com/TeoPlace/lib_sorter_barcode_linux/main/install.sh | sudo sh
```

Senza root, nella propria home:

```
curl -fsSL https://raw.githubusercontent.com/TeoPlace/lib_sorter_barcode_linux/main/install.sh | sh -s -- --prefix ~/.local
```

Installa l'ultima versione. **Per aggiornare si rilancia lo stesso comando**: scarica la versione nuova solo se c'è,
e ne controlla lo SHA-256. Serve `curl` o `wget`.

| opzione | cosa fa |
|---|---|
| `--prefix DIR` | installa in `DIR/lib` e `DIR/include` (predefinito `/usr/local`) |
| `--version 1.1.1` | installa quella versione invece dell'ultima |
| `--check` | dice solo se c'è un aggiornamento |
| `--uninstall` | toglie la libreria, l'header e il file `pkg-config` |

**Con git**, una versione per tag (`v1.1.1`, …):

```
git clone https://github.com/TeoPlace/lib_sorter_barcode_linux.git
cd lib_sorter_barcode_linux
sudo ./install.sh                 # installa la versione del checkout
git pull && sudo ./install.sh     # aggiorna all'ultima
```

**Download diretto** dell'ultima versione:
[lib_sorter_barcode_linux_x86_64.tar.gz](https://github.com/TeoPlace/lib_sorter_barcode_linux/releases/latest/download/lib_sorter_barcode_linux_x86_64.tar.gz)
· tutte le versioni nelle [release](https://github.com/TeoPlace/lib_sorter_barcode_linux/releases).
Dentro c'è anche `install.sh`: `tar -xzf lib_sorter_barcode_linux_x86_64.tar.gz && sudo ./install.sh`.

Lo script copia la libreria in `<prefix>/lib` (con i link `libsorter_barcode.so.1` e `libsorter_barcode.so`),
l'header in `<prefix>/include` e un file `pkg-config` (`sorter_barcode`).
Si può anche non installare nulla e usare direttamente `lib/x86_64/libsorter_barcode.so.1`.

## Le funzioni

```c
const char *sb_version(void);
int sb_read_bmp_file(const char *path, const char *settings, int fast, char *out, int out_cap, int *needed);
int sb_read_gray(const uint8_t *px, int width, int height, int stride, const char *settings, int fast,
                 char *out, int out_cap, int *needed);
```

- `settings`: `"ALL"`, `"1D"` o `"2D"`.
- `fast`: `0` fa tutti i tentativi (consigliato), `1` salta i più lenti e può perdere qualche codice difficile.
- Il risultato è il numero di codici trovati, oppure un errore: `-1` argomenti sbagliati, `-2` immagine illeggibile,
  `-3` `out` troppo piccolo (in `needed` c'è la dimensione giusta: richiamare), `-4` memoria esaurita.
- In `out` c'è un JSON, un oggetto per codice:

```
[
{"type":"code128","value":"RB0002627784"}
]
```

  Se non ci sono codici, prima del JSON c'è la riga `no 1d or 2d barcodes found`.
- `sb_read_bmp_file` legge BMP non compressi a 1, 4, 8, 16, 24 e 32 bit; le immagini a colori sono lette in grigio.
  Per altri formati si decodifica l'immagine in proprio e la si passa in grigio a 8 bit con `sb_read_gray`.

## Esempi

**C**, dopo `install.sh`:

```
gcc -o leggi examples/leggi.c $(pkg-config --cflags --libs sorter_barcode)
./leggi /dati/immagini/lettera.bmp
```

Senza installare:

```
gcc -Iinclude -o leggi examples/leggi.c lib/x86_64/libsorter_barcode.so.1 -Wl,-rpath,'$ORIGIN/lib/x86_64'
```

**Python** (ctypes, nessun pacchetto da installare):

```
python3 examples/leggi.py /dati/immagini/lettera.bmp
```

**C# / .NET su Linux:** `[DllImport("sorter_barcode")]` trova da solo `libsorter_barcode.so` installata.

## Pubblicare una versione nuova

1. Ricostruire la libreria dal sorgente, sostituire i file in `bin/` (o `lib/`) e scrivere la versione in `VERSION`.
2. `git commit`, `git tag v<versione>`, `git push --follow-tags`.
3. Creare la release `v<versione>` con il pacchetto e il suo `.sha256` (stesso nome di file a ogni versione, così
   il link «latest» e lo script di installazione trovano sempre l'ultima).

## Licenza

MIT, vedi [LICENSE](LICENSE).
