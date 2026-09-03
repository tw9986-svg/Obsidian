#!/usr/bin/env python3
"""Read an OpenModelica MATLAB v4 result file and print the final value of named variables.

Usage:  read_omres.py <result.mat> [name ...]
With no names, lists every variable in the file.

This is a reading tool only. It performs no interpolation, no smoothing and no unit
conversion: it reports the last stored sample of each requested variable exactly as the
solver wrote it, or the stored value for a parameter.
"""
import struct
import sys


def _read_mat(path):
    """Return {name: (nrows, ncols, values, is_text)} for a MATLAB level-4 file."""
    blocks = {}
    with open(path, "rb") as f:
        while True:
            header = f.read(20)
            if len(header) < 20:
                break
            mopt, nrows, ncols, imagf, namelen = struct.unpack("<5i", header)
            name = f.read(namelen).decode("latin-1").rstrip("\0")
            # MOPT = 1000*M + 100*O + 10*P + T
            precision = (mopt // 10) % 10
            is_text = (mopt % 10) == 1
            fmt, size = {0: ("d", 8), 1: ("f", 4), 2: ("i", 4),
                         3: ("h", 2), 4: ("H", 2), 5: ("B", 1)}[precision]
            count = nrows * ncols
            values = struct.unpack("<%d%s" % (count, fmt), f.read(count * size))
            blocks[name] = (nrows, ncols, values, is_text)
    return blocks


def load(path):
    """Return (names, getter). getter(name) is the final stored value of that variable."""
    blocks = _read_mat(path)
    nrows, ncols, chars, _ = blocks["name"]
    names = ["".join(chr(chars[c * nrows + r]) for r in range(nrows)).rstrip("\0")
             for c in range(ncols)]
    info = blocks["dataInfo"][2]          # 4 x nVars, column major
    d1 = blocks["data_1"]
    d2 = blocks.get("data_2")

    # Both data blocks are stored transposed and column major: nrows = number of variables
    # in the block, ncols = number of samples, so variable v at sample s is at s*nrows + v.
    def getter(name):
        i = names.index(name)
        block, index = info[i * 4], info[i * 4 + 1]
        sign = 1 if index > 0 else -1
        var = abs(index) - 1
        nvars, nsamples, values, _ = d1 if block == 1 else d2
        return sign * values[(nsamples - 1) * nvars + var]

    return names, getter


if __name__ == "__main__":
    names, get = load(sys.argv[1])
    wanted = sys.argv[2:]
    if not wanted:
        for n in names:
            print(n)
        sys.exit(0)
    for n in wanted:
        try:
            print("%-38s %.12g" % (n, get(n)))
        except ValueError:
            print("%-38s NOT IN RESULT FILE" % n)
