#!/bin/sh
# Installs libsorter_barcode: the library in <prefix>/lib, the header in <prefix>/include and a
# pkg-config file. Default prefix /usr/local (run with sudo); without root: ./install.sh --prefix ~/.local
#   ./install.sh [--prefix DIR]
#   ./install.sh --uninstall [--prefix DIR]
set -e

VERSION=1.1.1
PREFIX=/usr/local
UNINSTALL=0
while [ $# -gt 0 ]; do
    case "$1" in
        --prefix) PREFIX="$2"; shift 2 ;;
        --prefix=*) PREFIX="${1#--prefix=}"; shift ;;
        --uninstall) UNINSTALL=1; shift ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

HERE=$(cd "$(dirname "$0")" && pwd)
LIB="$PREFIX/lib"
INC="$PREFIX/include"
PC="$LIB/pkgconfig"

if [ "$UNINSTALL" = 1 ]; then
    rm -f "$LIB/libsorter_barcode.so" "$LIB/libsorter_barcode.so.1" "$LIB/libsorter_barcode.so.$VERSION" \
          "$INC/sorter_barcode.h" "$PC/sorter_barcode.pc"
    [ "$(id -u)" = 0 ] && command -v ldconfig >/dev/null && ldconfig || true
    echo "libsorter_barcode removed from $PREFIX"
    exit 0
fi

ARCH=$(uname -m)
if [ ! -f "$HERE/lib/$ARCH/libsorter_barcode.so.1" ]; then
    echo "no build for $ARCH (available: $(ls "$HERE/lib" | tr '\n' ' '))" >&2
    exit 1
fi

mkdir -p "$LIB" "$INC" "$PC"
cp "$HERE/lib/$ARCH/libsorter_barcode.so.1" "$LIB/libsorter_barcode.so.$VERSION"
chmod 755 "$LIB/libsorter_barcode.so.$VERSION"
ln -sf "libsorter_barcode.so.$VERSION" "$LIB/libsorter_barcode.so.1"
ln -sf libsorter_barcode.so.1 "$LIB/libsorter_barcode.so"
cp "$HERE/include/sorter_barcode.h" "$INC/"
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
else
    echo "note: not root, so ldconfig was not run; programs find the library with"
    echo "      LD_LIBRARY_PATH=$LIB or by linking with -Wl,-rpath,$LIB"
fi
echo "libsorter_barcode $VERSION installed in $PREFIX"
