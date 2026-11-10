#!/bin/sh
# Installa o aggiorna sorter-barcode: il comando in <prefix>/bin, la libreria in <prefix>/lib,
# l'header in <prefix>/include e un file pkg-config. Prefisso predefinito /usr/local (con sudo);
# senza root: --prefix ~/.local
#
# Dalla rete (ultima release; rilanciato, aggiorna):
#   curl -fsSL https://raw.githubusercontent.com/TeoPlace/lib_sorter_barcode_linux/main/install.sh | sudo sh
#   curl -fsSL https://raw.githubusercontent.com/TeoPlace/lib_sorter_barcode_linux/main/install.sh | sh -s -- --prefix ~/.local
# Da un clone o dal .tar.gz estratto (la versione di quei file):
#   sudo ./install.sh
#
#   install.sh [--prefix DIR] [--version X.Y.Z] [--check] [--uninstall] [--local]
#     --version  installa quella release invece dell'ultima
#     --check    dice solo se c'e' un aggiornamento
#     --local    usa i file accanto allo script (normale quando si lancia da un clone)
set -e

REPO=TeoPlace/lib_sorter_barcode_linux
PREFIX=/usr/local
WANT=""
CHECK=0
UNINSTALL=0
LOCAL=""
while [ $# -gt 0 ]; do
    case "$1" in
        --prefix) PREFIX="$2"; shift 2 ;;
        --prefix=*) PREFIX="${1#--prefix=}"; shift ;;
        --version) WANT="${2#v}"; shift 2 ;;
        --version=*) WANT="${1#--version=}"; WANT="${WANT#v}"; shift ;;
        --check) CHECK=1; shift ;;
        --uninstall) UNINSTALL=1; shift ;;
        --local) LOCAL=1; shift ;;
        *) echo "opzione sconosciuta: $1" >&2; exit 2 ;;
    esac
done

BIN="$PREFIX/bin"
LIB="$PREFIX/lib"
INC="$PREFIX/include"
PC="$LIB/pkgconfig"
ARCH=$(uname -m)

installed() {
    for f in "$LIB"/libsorter_barcode.so.*.*.*; do
        [ -f "$f" ] && { echo "${f##*.so.}"; return 0; }
    done
    return 0
}

if [ "$UNINSTALL" = 1 ]; then
    rm -f "$BIN/sorter-barcode" "$LIB"/libsorter_barcode.so "$LIB"/libsorter_barcode.so.1 "$LIB"/libsorter_barcode.so.*.*.* \
          "$INC/sorter_barcode.h" "$PC/sorter_barcode.pc"
    [ "$(id -u)" = 0 ] && command -v ldconfig >/dev/null && ldconfig || true
    echo "sorter-barcode rimosso da $PREFIX"
    exit 0
fi

fetch() {   # fetch URL [FILE]: senza FILE su stdout
    if command -v curl >/dev/null; then
        if [ -n "$2" ]; then curl -fsSL -o "$2" "$1"; else curl -fsSL "$1"; fi
    elif command -v wget >/dev/null; then
        if [ -n "$2" ]; then wget -q -O "$2" "$1"; else wget -q -O - "$1"; fi
    else
        echo "serve curl o wget" >&2; exit 1
    fi
}

latest() {
    fetch "https://api.github.com/repos/$REPO/releases/latest" | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -1
}

# Da dove vengono i file: accanto allo script (un clone, il .tar.gz) o una release scaricata qui.
HERE=""
case "$0" in
    */install.sh|install.sh) HERE=$(cd "$(dirname "$0")" && pwd) ;;
esac
if [ -z "$LOCAL" ] && [ -n "$HERE" ] && [ -f "$HERE/VERSION" ] && [ -z "$WANT" ] && [ "$CHECK" = 0 ]; then
    LOCAL=1
fi

if [ "$CHECK" = 1 ]; then
    have=$(installed); last=$(latest)
    if [ -z "$have" ]; then echo "sorter-barcode non e' installato in $PREFIX; ultima versione: $last"
    elif [ "$have" = "$last" ]; then echo "sorter-barcode $have: e' l'ultima versione"
    else echo "sorter-barcode $have installato, c'e' la $last: rilancia il comando di installazione per aggiornare"; fi
    exit 0
fi

TMP=""
cleanup() { if [ -n "$TMP" ]; then rm -rf "$TMP"; fi; }
trap cleanup EXIT

if [ "$LOCAL" = 1 ]; then
    SRC="$HERE"
else
    VERSION=${WANT:-$(latest)}
    [ -n "$VERSION" ] || { echo "non trovo l'ultima release di $REPO" >&2; exit 1; }
    have=$(installed)
    if [ "$have" = "$VERSION" ] && [ -x "$BIN/sorter-barcode" ]; then
        echo "sorter-barcode $VERSION e' gia' installato in $PREFIX"
        exit 0
    fi
    ASSET="lib_sorter_barcode_linux_$ARCH.tar.gz"
    BASE="https://github.com/$REPO/releases/download/v$VERSION"
    TMP=$(mktemp -d)
    fetch "$BASE/$ASSET" "$TMP/$ASSET" || { echo "la release v$VERSION non contiene $ASSET" >&2; exit 1; }
    if fetch "$BASE/$ASSET.sha256" "$TMP/$ASSET.sha256" 2>/dev/null; then
        expected=$(cut -d' ' -f1 < "$TMP/$ASSET.sha256")
        actual=$(sha256sum "$TMP/$ASSET" | cut -d' ' -f1)
        [ "$expected" = "$actual" ] || { echo "SHA-256 diverso per $ASSET" >&2; exit 1; }
    fi
    mkdir "$TMP/x"
    tar -xzf "$TMP/$ASSET" -C "$TMP/x"
    SRC="$TMP/x"
fi

VERSION=$(tr -d ' \r\n' < "$SRC/VERSION")
if [ ! -f "$SRC/lib/$ARCH/libsorter_barcode.so.1" ]; then
    echo "nessuna versione per $ARCH (ci sono: $(ls "$SRC/lib" | tr '\n' ' '))" >&2
    exit 1
fi

have=$(installed)
mkdir -p "$BIN" "$LIB" "$INC" "$PC"
if [ -f "$SRC/bin/$ARCH/sorter-barcode" ]; then
    cp "$SRC/bin/$ARCH/sorter-barcode" "$BIN/sorter-barcode"
    chmod 755 "$BIN/sorter-barcode"
fi
rm -f "$LIB"/libsorter_barcode.so.*.*.*
cp "$SRC/lib/$ARCH/libsorter_barcode.so.1" "$LIB/libsorter_barcode.so.$VERSION"
chmod 755 "$LIB/libsorter_barcode.so.$VERSION"
ln -sf "libsorter_barcode.so.$VERSION" "$LIB/libsorter_barcode.so.1"
ln -sf libsorter_barcode.so.1 "$LIB/libsorter_barcode.so"
cp "$SRC/include/sorter_barcode.h" "$INC/"
cat > "$PC/sorter_barcode.pc" <<EOF
prefix=$PREFIX
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: sorter_barcode
Description: Barcode reader for sorter images (Code 128, Code 39, ITF, DataMatrix, QR, Aztec)
Version: $VERSION
Libs: -L\${libdir} -lsorter_barcode
Cflags: -I\${includedir}
EOF

if [ "$(id -u)" = 0 ] && command -v ldconfig >/dev/null; then
    ldconfig
fi
if [ -n "$have" ] && [ "$have" != "$VERSION" ]; then
    echo "sorter-barcode aggiornato dalla $have alla $VERSION in $PREFIX"
else
    echo "sorter-barcode $VERSION installato in $PREFIX"
fi
case ":$PATH:" in
    *":$BIN:"*) echo "Per leggere un'immagine:  sorter-barcode /percorso/immagine.bmp" ;;
    *) echo "Per leggere un'immagine:  $BIN/sorter-barcode /percorso/immagine.bmp   ($BIN non e' nel PATH)" ;;
esac
