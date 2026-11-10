"""Reads the barcodes of the BMP files given on the command line, through ctypes.

    python leggi.py <image.bmp>...

Windows: looks for bin/x64 (or bin/x86) next to this folder. Linux: the installed library
(install.sh), or lib/<arch> next to this folder.
"""
import ctypes
import json
import os
import platform
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def load():
    if sys.platform == 'win32':
        arch = 'x64' if struct.calcsize('P') == 8 else 'x86'
        return ctypes.CDLL(os.path.join(ROOT, 'bin', arch, 'sorter_barcode.dll'))
    local = os.path.join(ROOT, 'lib', platform.machine(), 'libsorter_barcode.so.1')
    return ctypes.CDLL(local if os.path.exists(local) else 'libsorter_barcode.so.1')


lib = load()
lib.sb_version.restype = ctypes.c_char_p
lib.sb_read_bmp_file.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_int,
                                 ctypes.c_char_p, ctypes.c_int, ctypes.POINTER(ctypes.c_int)]


def read_bmp(path, settings='ALL', fast=False):
    """List of (type, value). Raises OSError when the image cannot be read."""
    cap = 4096
    while True:
        out = ctypes.create_string_buffer(cap)
        needed = ctypes.c_int(0)
        # the DLL opens the file with fopen: on Windows the path goes in the ANSI code page
        name = os.fsdecode(path).encode('mbcs') if sys.platform == 'win32' else os.fsencode(path)
        n = lib.sb_read_bmp_file(name, settings.encode(), int(fast), out, cap, ctypes.byref(needed))
        if n == -3:
            cap = needed.value
            continue
        if n < 0:
            raise OSError(f'sorter_barcode error {n} on {path}')
        text = out.value.decode('utf-8')
        codes = json.loads(text[text.index('['):])
        return [(c['type'], c['value']) for c in codes]


if __name__ == '__main__':
    print('sorter_barcode', lib.sb_version().decode())
    for p in sys.argv[1:]:
        print(p, read_bmp(p))
