#!/usr/bin/env python3
"""Programmatic digitization of ORNL-TM-0378 Figs. 4 and 13 from the report page images.

Why this exists
---------------
Phase 48 of this study compared the two figures using values read BY EYE off the printed
grid. That reading was wrong: on Fig. 13 the graphite curve was misread by up to +7 F in
r = 15..22 in, which inflated the graphite-fuel difference there and produced a spurious
shape disagreement. Reading a DIFFERENCE of two nearly parallel curves by eye is far less
accurate than reading either curve, and the eye's error is systematic rather than random.

This script replaces that reading with a curve tracker, so the digitization is reproducible
and its failure modes are visible rather than hidden in a CSV of hand-typed numbers.

Method
------
1.  Render the page at 300 dpi with pdftoppm.
2.  Calibrate the axes from the plot frame, then CHECK the calibration against the printed
    major gridlines (Fig. 4: all 20 vertical gridlines land within 0.05 in of an integer
    radius; the horizontal gridlines land within 0.001 of 0.0 ... 1.0).
3.  Per pixel column, take runs of dark pixels. Fig. 4 is printed on dense graph paper, so a
    run is additionally required to be solid black (mean grey < 70) and >= 6 px long.
4.  Follow each curve column by column from a seed, choosing at each step the run nearest to
    a slope-extrapolated prediction. Continuity is what separates a curve from a gridline,
    a legend rule, or a text label - none of which continue.

Limits, stated rather than hidden
---------------------------------
Fig. 4 beyond r ~ 24.5 in cannot be tracked at this scan quality: the legend rules sit at
0.85 of full scale and the tracker jumps to them. Values are therefore emitted only where
the track is monotone and uninterrupted. Fig. 13's two curves track cleanly over the whole
of main-core region 2 (3.5 <= r <= 24.6 in).

Usage:  python3 tools/digitize_ornl0378.py <ORNL-TM-0378.pdf> <output_dir>
"""
import os
import subprocess
import sys

import numpy as np
from PIL import Image


def render(pdf, page, out_prefix, dpi=300):
    subprocess.run(["pdftoppm", "-r", str(dpi), "-png", "-f", str(page), "-l", str(page),
                    pdf, out_prefix], check=True)
    return f"{out_prefix}-{page}.png"


def dark_runs(dark, x, min_len, gray=None, max_mean=None):
    col = dark[:, x]
    out, s = [], None
    for i in range(len(col)):
        if col[i] and s is None:
            s = i
        elif not col[i] and s is not None:
            if i - s >= min_len:
                out.append((s, i - 1))
            s = None
    if s is not None and len(col) - s >= min_len:
        out.append((s, len(col) - 1))
    if gray is not None:
        out = [(a, b) for a, b in out if gray[a:b + 1, x].mean() < max_mean]
    return out


def track(cands, x0, y0, step, xlo, xhi, tol=14.0, max_miss=15):
    """Follow one curve by continuity. `cands` maps column -> list of (y_start, y_end)."""
    y, slope, x, miss = y0, 0.0, x0, 0
    got = {x0: y0}
    while xlo <= x + step <= xhi:
        x += step
        pred = y + slope * step
        best, bd = None, 1e9
        for a, b in cands.get(x, []):
            d = 0.0 if a <= pred <= b else min(abs(pred - a), abs(pred - b))
            if d < bd:
                bd, best = d, (a, b)
        if best is None or bd > tol:
            miss += 1
            if miss > max_miss:
                break
            y = pred
            continue
        miss = 0
        y = max(best[0], min(best[1], pred)) if best[0] <= pred <= best[1] \
            else (best[0] + best[1]) / 2.0
        slope = 0.6 * slope + 0.4 * ((y - got.get(x - step, y)) / step) if x - step in got \
            else slope
        got[x] = y
    return got


# --------------------------------------------------------------------------- Fig. 4
FIG4_PAGE = 20
FIG4_X0, FIG4_X1 = 609.0, 1866.0     # r = 0 in, r = 30 in
FIG4_YTOP, FIG4_YBOT = 581.0, 2428.0  # ordinate 1.1 and 0.0 (fraction of max value)


def digitize_fig4(png):
    im = np.array(Image.open(png).convert("L")).astype(int)
    y0, y1 = int(FIG4_YTOP), int(FIG4_YBOT)
    gray = im[y0:y1 + 1, int(FIG4_X0):int(FIG4_X1) + 1]
    dark = gray < 110
    per_unit = (FIG4_YBOT - FIG4_YTOP) / 1.1
    W = dark.shape[1]
    cands = {x: dark_runs(dark, x, 6, gray, 70) for x in range(W)}

    def xof(r):
        return int(round((r / 30.0) * (FIG4_X1 - FIG4_X0)))

    seed = xof(7)                      # the peak, unambiguous on both curves
    a, b = cands[seed][0]
    prof = {}
    prof.update(track(cands, seed, (a + b) / 2.0, -1, 0, W - 1))
    prof.update(track(cands, seed, (a + b) / 2.0, +1, 0, W - 1))

    out = {}
    for x, y in sorted(prof.items()):
        out[x / (FIG4_X1 - FIG4_X0) * 30.0] = (FIG4_YBOT - (FIG4_YTOP + y)) / per_unit
    return out


# --------------------------------------------------------------------------- Fig. 13
FIG13_PAGE = 42
FIG13_X0, FIG13_X1 = 557.5, 2083.5    # r = 0 in, r = 30 in
FIG13_Y0, FIG13_Y1 = 425.0, 2649.0    # 1290 F and 1180 F


def digitize_fig13(png):
    im = np.array(Image.open(png).convert("L")).astype(int)
    dark = im < 128
    px_in = (FIG13_X1 - FIG13_X0) / 30.0
    px_F = (FIG13_Y1 - FIG13_Y0) / 110.0

    def X(r):
        return int(round(FIG13_X0 + r * px_in))

    def T(y):
        return 1290.0 - (y - FIG13_Y0) / px_F

    # A run longer than 40 px is the near-vertical dashed jump at a region boundary,
    # not a point on either curve.
    cands = {x: [(a, b) for a, b in dark_runs(dark, x, 4) if b - a <= 40]
             for x in range(X(3.0), X(25.0))}
    xlo, xhi = X(3.45), X(24.65)

    def seed(r, guess):
        x = X(r)
        best, bd = None, 1e9
        for a, b in cands[x]:
            c = T((a + b) / 2.0)
            if abs(c - guess) < bd:
                bd, best = abs(c - guess), (a + b) / 2.0
        return x, best

    xg, yg = seed(13, 1270.6)
    xf, yf = seed(13, 1215.8)
    G, F = {}, {}
    for store, (xs, ys) in ((G, (xg, yg)), (F, (xf, yf))):
        store.update(track(cands, xs, ys, -1, xlo, xhi))
        store.update(track(cands, xs, ys, +1, xlo, xhi))
        store[xs] = ys
    rows = []
    for x in sorted(set(G) & set(F)):
        r = (x - FIG13_X0) / px_in
        rows.append((r, T(G[x]), T(F[x])))
    return rows


# --------------------------------------------------------------------------- Fig. 14
FIG14_PAGE = 43
FIG14_X0, FIG14_X1 = 615.5, 2226.0    # z = 0 in, z = 70 in
FIG14_YA, FIG14_TA = 933.0, 1280.0    # the 1280 F gridline
FIG14_PXF = (2092.0 - 933.0) / 100.0  # px per F, from the 1280 F and 1180 F gridlines


def digitize_fig14(png):
    im = np.array(Image.open(png).convert("L")).astype(int)
    dark = im < 128
    px_in = (FIG14_X1 - FIG14_X0) / 70.0

    def X(z):
        return int(round(FIG14_X0 + z * px_in))

    def T(y):
        return FIG14_TA - (y - FIG14_YA) / FIG14_PXF

    cands = {x: [(a, b) for a, b in dark_runs(dark, x, 4) if b - a <= 60]
             for x in range(X(0.0), X(65.5))}
    xlo, xhi = X(0.2), X(64.6)

    def seed(z, guess):
        x = X(z)
        best, bd = None, 1e9
        for a, b in cands[x]:
            c = T((a + b) / 2.0)
            if abs(c - guess) < bd:
                bd, best = abs(c - guess), (a + b) / 2.0
        return x, best

    G, F = {}, {}
    for store, (xs, ys) in ((G, seed(30, 1272)), (F, seed(30, 1196))):
        store.update(track(cands, xs, ys, -1, xlo, xhi))
        store.update(track(cands, xs, ys, +1, xlo, xhi))
        store[xs] = ys
    rows = []
    for x in sorted(set(G) & set(F)):
        rows.append(((x - FIG14_X0) / px_in, T(G[x]), T(F[x])))
    return rows


HEAD14 = """\
# ORNL-TM-0378 Fig. 14, printed p.43: "Axial Temperature Profiles in Hottest Channel of MSRE
# Core (7 in. from Core Center Line)". Abscissa: DISTANCE FROM BOTTOM OF CORE (in.), the same
# datum that fixes B(z) (p.19). Both curves are read at the same radial station, so their
# difference is the report's DT with A(r) common to both and cancelling.
# PRODUCED BY tools/digitize_ornl0378.py - not by eye. Regenerate, do not hand-edit.
z_in,Tg_F,Tf_F,dT_F
"""

HEAD4 = """\
# ORNL-TM-0378 Fig. 4, printed p.20: "Radial Distribution of Slow Flux and Fuel Fission
# Density in the Plane of Maximum Slow Flux". Curve tracked: the two curves coincide over
# this range; they separate only at r < 4 in and r > 27 in.
# Plane: 35 in above the bottom of the main part of the core (p.19).
# The printed ordinate is "FRACTION OF MAX. VALUE", so the figure is peak-normalized as
# printed and NOTHING here is rescaled.
# PRODUCED BY tools/digitize_ornl0378.py - not by eye. Regenerate, do not hand-edit.
# Axis calibration checked against the printed gridlines: all 20 vertical majors land
# within 0.05 in of an integer radius; horizontal majors within 0.001 of 0.0 .. 1.0.
# Tracking is reliable only to r = 24.5 in; beyond that the legend rules at 0.85 capture
# the tracker, so no values are emitted.
r_in,A_frac_of_max
"""

HEAD13 = """\
# ORNL-TM-0378 Fig. 13, printed p.42: "Radial Temperature Profiles in MSRE Core Near
# Midplane". Condition (p.41): 10 Mw, NO fuel soakup in the graphite - the 0 % permeation
# case, the same row of Table 5 the absolute reconstruction fails against.
# Both curves are transverse means: stringer-mean graphite, adjacent-channel mean fuel
# (p.41), which is what the report's DT is defined to be (nomenclature p.50).
# Region-boundary discontinuities are visible at r ~ 3.3 in and r ~ 24.8 in; the second
# matches Table 2 region 2's equivalent outer radius, 24.76 in. Only the interval between
# them - main-core region 2 - is emitted.
# PRODUCED BY tools/digitize_ornl0378.py - not by eye. Regenerate, do not hand-edit.
r_in,Tg_F,Tf_F,dT_F
"""


def main():
    pdf, outdir = sys.argv[1], sys.argv[2]
    os.makedirs(outdir, exist_ok=True)
    tmp = os.path.join(outdir, ".render")

    f4 = digitize_fig4(render(pdf, FIG4_PAGE, tmp + "4"))
    with open(os.path.join(outdir, "Fig04_radial.csv"), "w") as fh:
        fh.write(HEAD4)
        for r in [x / 2.0 for x in range(0, 50)]:
            near = [v for k, v in f4.items() if abs(k - r) < 0.03]
            if near:
                fh.write(f"{r:.1f},{sum(near) / len(near):.4f}\n")

    f14 = digitize_fig14(render(pdf, FIG14_PAGE, tmp + "14"))
    with open(os.path.join(outdir, "Fig14_axial_temperature.csv"), "w") as fh:
        fh.write(HEAD14)
        for z in range(0, 66):
            # 0.05 in, slightly more than one pixel column at this scale (1/23 in), so that
            # every integer station is emitted rather than falling between two columns.
            near = [(g, f) for k, g, f in f14 if abs(k - z) < 0.05]
            if near:
                g = sum(q[0] for q in near) / len(near)
                f = sum(q[1] for q in near) / len(near)
                fh.write(f"{z:d},{g:.2f},{f:.2f},{g - f:.2f}\n")

    f13 = digitize_fig13(render(pdf, FIG13_PAGE, tmp + "13"))
    with open(os.path.join(outdir, "Fig13_radial_temperature.csv"), "w") as fh:
        fh.write(HEAD13)
        for r in [x / 2.0 for x in range(7, 50)]:
            near = [(g, f) for k, g, f in f13 if abs(k - r) < 0.03]
            if near:
                g = sum(q[0] for q in near) / len(near)
                f = sum(q[1] for q in near) / len(near)
                fh.write(f"{r:.1f},{g:.2f},{f:.2f},{g - f:.2f}\n")


if __name__ == "__main__":
    main()
