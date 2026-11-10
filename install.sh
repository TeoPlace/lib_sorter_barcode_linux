#!/bin/sh
# Installs or updates libsorter_barcode: the library in <prefix>/lib, the header in <prefix>/include
# and a pkg-config file. Default prefix /usr/local (run with sudo); without root: --prefix ~/.local
#
# From the network (latest release; running it again updates):
#   curl -fsSL https://raw.githubusercontent.com/TeoPlace/lib_sorter_barcode_linux/main/install.sh | sudo sh
#   curl -fsSL https://raw.githubusercontent.com/TeoPlace/lib_sorter_barcode_linux/main/install.sh | sh -s -- --prefix ~/.local
# From a clone (the version of the checkout; update with git pull, or git checkout v<version>):
#   sudo ./install.sh
#
#   install.sh [--prefix DIR] [--version X.Y.Z] [--check] [--uninstall] [--local]
#     --version  install that release instead of the latest
#     --check    only say whether an update is available
#     --local    use the files next to the script (default when run from a clone)
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
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

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
    rm -f "$LIB"/libsorter_barcode.so "$LIB"/libsorter_barcode.so.1 "$LIB"/libsorter_barcode.so.*.*.* \
          "$INC/sorter_barcode.h" "$PC/sorter_barcode.pc"
    [ "$(id -u)" = 0 ] && command -v ldconfig >/dev/null && ldconfig || true
    echo "libsorter_barcode removed from $PREFIX"
    exit 0
fi

fetch() {   # fetch URL [FILE]: stdout without FILE
    if command -v curl >/dev/null; then
        if [ -n "$2" ]; then curl -fsSL -o "$2" "$1"; else curl -fsSL "$1"; fi
    elif command -v wget >/dev/null; then
        if [ -n "$2" ]; then wget -q -O "$2" "$1"; else wget -q -O - "$1"; fi
    else
        echo "curl or wget is needed" >&2; exit 1
    fi
}

latest() {
    fetch "https://api.github.com/repos/$REPO/releases/latest" | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -1
}

# Where the files come from: next to the script (a clone) or a release downloaded here.
HERE=""
case "$0" in
    */install.sh|install.sh) HERE=$(cd "$(dirname "$0")" && pwd) ;;
esac
if [ -z "$LOCAL" ] && [ -n "$HERE" ] && [ -f "$HERE/VERSION" ] && [ -z "$WANT" ] && [ "$CHECK" = 0 ]; then
    LOCAL=1
fi

if [ "$CHECK" = 1 ]; then
    have=$(installed); last=$(latest)
    if [ -z "$have" ]; then echo "not installed in $PREFIX; latest version: $last"
    elif [ "$have" = "$last" ]; then echo "libsorter_barcode $have: up to date"
    else echo "libsorter_barcode $have installed, $last available: run the installer again to update"; fi
    exit 0
fi

TMP=""
cleanup() { if [ -n "$TMP" ]; then rm -rf "$TMP"; fi; }
trap cleanup EXIT

if [ "$LOCAL" = 1 ]; then
    SRC="$HERE"
else
    VERSION=${WANT:-$(latest)}
    [ -n "$VERSION" ] || { echo "cannot find the latest release of $REPO" >&2; exit 1; }
    have=$(installed)
    if [ "$have" = "$VERSION" ]; then
        echo "libsorter_barcode $VERSION is already installed in $PREFIX"
        exit 0
    fi
    ASSET="lib_sorter_barcode_linux_$ARCH.tar.gz"
    BASE="https://github.com/$REPO/releases/download/v$VERSION"
    TMP=$(mktemp -d)
    fetch "$BASE/$ASSET" "$TMP/$ASSET" || { echo "no $ASSET in release v$VERSION" >&2; exit 1; }
    if fetch "$BASE/$ASSET.sha256" "$TMP/$ASSET.sha256" 2>/dev/null; then
        expected=$(cut -d' ' -f1 < "$TMP/$ASSET.sha256")
        actual=$(sha256sum "$TMP/$ASSET" | cut -d' ' -f1)
        [ "$expected" = "$actual" ] || { echo "SHA-256 mismatch for $ASSET" >&2; exit 1; }
    fi
    mkdir "$TMP/x"
    tar -xzf "$TMP/$ASSET" -C "$TMP/x"
    SRC="$TMP/x"
fi

VERSION=$(tr -d ' \r\n' < "$SRC/VERSION")
if [ ! -f "$SRC/lib/$ARCH/libsorter_barcode.so.1" ]; then
    echo "no build for $ARCH (available: $(ls "$SRC/lib" | tr '\n' ' '))" >&2
    exit 1
fi

have=$(installed)
mkdir -p "$LIB" "$INC" "$PC"
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
else
    echo "note: not root, so ldconfig was not run; programs find the library with"
    echo "      LD_LIBRARY_PATH=$LIB or by linking with -Wl,-rpath,$LIB"
fi
if [ -n "$have" ] && [ "$have" != "$VERSION" ]; then
    echo "libsorter_barcode updated from $have to $VERSION in $PREFIX"
else
    echo "libsorter_barcode $VERSION installed in $PREFIX"
fi
