#!/usr/bin/env python3
"""Extract full time histories from an OpenModelica MATLAB v4 result file as CSV.

Usage:  read_omseries.py <result.mat> <out.csv> <name> [name ...]

A companion to read_omres.py, which reports only the final stored sample. This one writes
every sample of the named variables, so a transient can be compared point by point after the
(large) result file has been deleted.

Reading tool only: no interpolation, no smoothing, no unit conversion. Parameters, which are
stored once in data_1, are broadcast to every row so that the CSV is rectangular.
"""
import sys

from read_omres import _read_mat


def series(path, wanted):
    blocks = _read_mat(path)
    nrows, ncols, chars, _ = blocks["name"]
    names = ["".join(chr(chars[c * nrows + r]) for r in range(nrows)).rstrip("\0")
             for c in range(ncols)]
    info = blocks["dataInfo"][2]
    d1 = blocks["data_1"]
    d2 = blocks.get("data_2")
    nsamples = d2[1] if d2 else d1[1]

    out = {}
    for name in wanted:
        i = names.index(name)
        block, index = info[i * 4], info[i * 4 + 1]
        sign = 1 if index > 0 else -1
        var = abs(index) - 1
        if block == 1:                     # a parameter: one stored value, held constant
            values = d1[2]
            out[name] = [sign * values[var]] * nsamples
        else:
            nvars, ns, values, _ = d2
            out[name] = [sign * values[s * nvars + var] for s in range(ns)]
    return nsamples, out


if __name__ == "__main__":
    res, csv, wanted = sys.argv[1], sys.argv[2], sys.argv[3:]
    n, cols = series(res, wanted)
    with open(csv, "w") as f:
        f.write(",".join(wanted) + "\n")
        for s in range(n):
            f.write(",".join("%.10g" % cols[w][s] for w in wanted) + "\n")
    print("%s  %d samples  %d variables" % (csv, n, len(wanted)))
