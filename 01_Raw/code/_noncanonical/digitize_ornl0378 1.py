#!/usr/bin/env python3
"""Gated A/B analysis of the 2-D radial fission-source shape.

Companion to MSRE.Verification.Core2D_RadialSourceSensitivity. Build that model once and run
the SAME executable twice - the second time with -override=useORNLradialShape=true - then point
this script at the two result files. Two runs of one binary make model identity a compile-time
property rather than a diff between independently translated models.

    ./MSRE.Verification.Core2D_RadialSourceSensitivity -r=..._j0.csv
    ./MSRE.Verification.Core2D_RadialSourceSensitivity -r=..._ornl.csv \
        -override=useORNLradialShape=true
    python3 tools/analyze_radial_source_ab.py

Gate order is deliberate: execution, model identity, mass, full first law, terminal steady
state - and only then temperature. Solver completion is NOT accepted as steady state.

Set D below to the directory holding the two result files.
"""

import collections, csv, math, os, sys

D  = "/tmp/claude-0/-home-user-MSRE-TRANSFORM/92e6c8de-4668-5b1c-91ed-e65b3642071c/scratchpad/run/ab_j0"
M  = "MSRE.Verification.Core2D_RadialSourceSensitivity"
NR, NA, NCELL = 15, 20, 302
DT_NOMINAL = 27.8      # K. ASSUMPTION: preregistered nominal core rise (50 F). Scaling only.
E_SRC = 0.11551        # frozen source-space source-model error
STEADY_TOL = 1e-6      # K/s. ASSUMPTION, justified in the report text.
KEEP = 8               # terminal window; result files are ~GB so only the tail is held

def load(tag):
    p = f"{D}/{M}_{tag}.csv"
    if not os.path.exists(p): return None
    rd = csv.reader(open(p)); head = [h.strip('"') for h in next(rd)]
    tail, n = collections.deque(maxlen=KEEP), 0
    for r in rd:
        if r and len(r) == len(head): tail.append(r); n += 1
    if n == 0: return None
    rows = list(tail); idx = {h: i for i, h in enumerate(head)}
    fin = {}
    for h in head:
        v = rows[-1][idx[h]].strip()
        if v:
            try: fin[h] = float(v)
            except ValueError: pass
    return {"head": head, "rows": rows, "idx": idx, "fin": fin, "n": n}

def deriv(d, key, w=5):
    if key not in d["idx"]: return None
    i, t = d["idx"][key], d["idx"]["time"]
    pts = d["rows"][-w:]
    if len(pts) < 2: return None
    dt = float(pts[-1][t]) - float(pts[0][t])
    return None if dt == 0 else (float(pts[-1][i]) - float(pts[0][i])) / dt

def cls(dv, rel, kind):
    a, r = abs(dv), (abs(rel)*100 if rel is not None else 0.0)
    if kind == "global":
        if a < 0.1 and r < 0.1: return "NEGLIGIBLE"
        if a < 1.0 and r < 1.0: return "SMALL"
        if a < 5.0 and r < 5.0: return "MATERIAL"
        return "DOMINANT"
    if a < 0.5 and r < 1.0: return "NEGLIGIBLE"
    if a < 2.0 and r < 5.0: return "SMALL"
    if a < 10.0 and r < 20.0: return "MATERIAL"
    return "DOMINANT"

def corr(x, y):
    n = len(x); mx = sum(x)/n; my = sum(y)/n
    sxy = sum((x[i]-mx)*(y[i]-my) for i in range(n))
    sxx = sum((x[i]-mx)**2 for i in range(n)); syy = sum((y[i]-my)**2 for i in range(n))
    return sxy/math.sqrt(sxx*syy) if sxx > 0 and syy > 0 else float("nan")

J, O = load("j0"), load("ornl")
print("="*100); print("EXECUTION STATUS"); print("="*100)
for tag, d in (("J0", J), ("ORNL", O)):
    if d is None:
        print(f"  CASE {tag:5} : NO RESULT FILE or no data rows")
    else:
        print(f"  CASE {tag:5} : {d['n']} output rows, final time {d['fin']['time']:.1f} s, "
              f"{len(d['head'])} columns")
if J is None or O is None:
    print("\nVERDICT = NOT_ADMISSIBLE  (MODEL_NOT_READY_FOR_COUPLED_SOURCE_SENSITIVITY)")
    sys.exit(1)

# ---- rebuild the source quantities the folding removed -------------------------------------
def qs(d):  return [d["fin"].get(f"core.Qs_core[{i+1}]", 0.0) for i in range(NCELL)]
def vol(d): return [d["fin"].get(f"core.Vs_channelCells[{i+1}]") for i in range(NR*NA)]
QJ, QO = qs(J), qs(O)
def ringQ(Q): return [sum(Q[r*NA + k] for k in range(NA)) for r in range(NR)]
RJ, RO = ringQ(QJ), ringQ(QO)
QtotJ, QtotO = sum(QJ), sum(QO)

print(); print("="*100); print("GATES"); print("="*100)
gates = []
def g(name, val, ok, note=""):
    gates.append((name, val, "PASS" if ok else "FAIL", note)); 

g("G1 both runs reached the same stop time", f"{J['fin']['time']:.1f} / {O['fin']['time']:.1f} s",
  abs(J['fin']['time'] - O['fin']['time']) < 1e-6)
g("G2 identical total imposed power (W)", f"{QtotJ:.6f} / {QtotO:.6f}", abs(QtotJ-QtotO) < 1.0,
  f"difference {QtotO-QtotJ:+.3e} W")
g("G2 identical inlet temperature (K)", f"{J['fin']['T_in']:.6f} / {O['fin']['T_in']:.6f}",
  abs(J['fin']['T_in']-O['fin']['T_in']) < 1e-9)
mfJ = J['fin'].get('core.port_a.m_flow'); mfO = O['fin'].get('core.port_a.m_flow')
if mfJ is not None:
    g("G2 identical inlet mass flow (kg/s)", f"{mfJ:.6f} / {mfO:.6f}", abs(mfJ-mfO) < 1e-6)
g("G2 the source DID change", f"max |dQ_ring| {max(abs(RO[r]-RJ[r]) for r in range(NR))/1e3:.2f} kW",
  max(abs(RO[r]-RJ[r]) for r in range(NR)) > 1e3,
  "guards against the override silently not taking effect")

# Gate 3 - mass
a, b = J['fin'].get('err_mass'), O['fin'].get('err_mass')
if a is not None:
    mn = abs(mfJ) if mfJ else 168.0
    g("G3 mass residual (kg/s)", f"{a:.3e} / {b:.3e}", abs(a) < 1e-6 and abs(b) < 1e-6,
      f"normalized {a/mn:.2e} / {b/mn:.2e}")

# Gate 4 - full first law
for tag, d, Qt in (("J0", J, QtotJ), ("ORNL", O, QtotO)):
    Qb  = d['fin'].get('Q_balance'); Qe = d['fin'].get('Q_enthalpy')
    Qp  = d['fin'].get('Q_potential'); Qk = d['fin'].get('Q_kinetic')
    dEg = sum(d['fin'].get(f"core.channels[{r+1}].der_E_graphite", 0.0) for r in range(NR))
    Eg  = d['fin'].get('core.E_graphite')
    Qgs = d['fin'].get('core.Q_graphite_source_total')
    Qgf = d['fin'].get('core.Q_graphite_to_fuel_total')
    gres = max(abs(d['fin'].get(f"core.channels[{r+1}].graphiteEnergyResidual", 0.0)) for r in range(NR))
    RE = Qt - Qb - dEg
    print(f"  [{tag}] first law: Q_imposed {Qt:.4f} = Q_enthalpy {Qe:.4f} + Q_potential {Qp:.4f}"
          f" + Q_kinetic {Qk:.6f}  -> Q_balance {Qb:.4f}")
    print(f"        graphite: E {Eg:.4f} J, dE/dt {dEg:+.4e} W, source {Qgs:.4e} W, "
          f"to fuel {Qgf:.4e} W, max |sub-balance residual| {gres:.3e} W")
    g(f"G4 first-law residual {tag} (W)", f"{RE:+.5f}", abs(RE) < 1e-3*Qt,
      f"relative {RE/Qt:.3e}; R_E = Q_imposed - Q_balance - dE_graphite/dt. "
      f"Q_graphite_to_fuel is INTERNAL and is already inside Q_enthalpy, so it is NOT added again")

# Gate 5 - steady state over every fuel and graphite node
def cellkeys(kind): return [f"core.channels[{r+1}].Ts_{kind}[{k+1}]" for r in range(NR) for k in range(NA)]
for kind in ("fuel", "graphite"):
    ks = [k for k in cellkeys(kind) if k in J["idx"]]
    if not ks: continue
    rj = [(abs(deriv(J,k) or 0.0), k) for k in ks]; ro = [(abs(deriv(O,k) or 0.0), k) for k in ks]
    mj, kj = max(rj); mo, ko = max(ro)
    g(f"G5 max |dT_{kind}/dt| (K/s)", f"{mj:.3e} / {mo:.3e}", mj < STEADY_TOL and mo < STEADY_TOL,
      f"{len(ks)} nodes; worst J0 {kj}; window = last {5} output points; "
      f"ASSUMPTION tol {STEADY_TOL:g} K/s")

for n,v,s,note in gates:
    print(f"  {n:44} {v:34} {s}")
    if note: print(f"       {note}")
ok = all(s=="PASS" for _,_,s,_ in gates)
print(f"\n  ALL GATES = {'PASS' if ok else 'FAIL'}")
if not ok:
    print("  THERMAL COMPARISON NOT ADMISSIBLE — the differences below are diagnostic only and")
    print("  no physical conclusion about source-shape materiality is drawn from them.")

# ---- fields ---------------------------------------------------------------------------------
def field(d, kind):
    return [[d["fin"].get(f"core.channels[{r+1}].Ts_{kind}[{k+1}]") for k in range(NA)] for r in range(NR)]
Fj, Fo = field(J,"fuel"), field(O,"fuel")
Gj, Go = field(J,"graphite"), field(O,"graphite")
V = vol(J)
def flat(F): return [F[r][k] for r in range(NR) for k in range(NA)]
def vmean(F):
    f = flat(F); return sum(f[i]*V[i] for i in range(len(f)))/sum(V)
def amax(F):
    f = flat(F); v = max(f); i = f.index(v); return v, (i//NA+1, i%NA+1)

print(); print("="*100); print("RING SOURCE FRACTIONS, rebuilt from the model's own core.Qs_core"); print("="*100)
PJ = [RJ[r]/QtotJ for r in range(NR)]; PO = [RO[r]/QtotO for r in range(NR)]
pe_J=[0.107118,0.100511,0.094103,0.087896,0.081888,0.076069,0.070433,0.064986,0.059720,0.054630,0.049712,0.044959,0.040370,0.035948,0.031667]
pe_O=[0.108661,0.111508,0.105510,0.097747,0.089593,0.081321,0.073561,0.065703,0.058071,0.050451,0.042813,0.036020,0.033332,0.026527,0.019190]
print(f"  sum SF: J0 {sum(PJ):.12f}   ORNL {sum(PO):.12f}")
print(f"  max |model - Phase E arithmetic|: J0 {max(abs(PJ[r]-pe_J[r]) for r in range(NR)):.3e}"
      f"   ORNL {max(abs(PO[r]-pe_O[r]) for r in range(NR)):.3e}")
Qred = 0.5*sum(abs(RO[r]-RJ[r]) for r in range(NR))
print(f"  Q_redistributed = 0.5*sum|dQ_ring| = {Qred/1e3:.3f} kW = {Qred/QtotJ*100:.3f} % of total")
print(f"  TOTAL POWER CHANGE = {QtotO-QtotJ:+.3e} W")

print(); print("="*100); print("THERMAL RESULTS"); print("="*100)
mxJ, locJ = amax(Fj); mxO, locO = amax(Fo)
gmxJ, glocJ = amax(Gj); gmxO, glocO = amax(Go)
rows = [("core inlet fuel T", J['fin'].get('T_in'), O['fin'].get('T_in'), "global"),
        ("core outlet fuel T (mixed mean)", J['fin'].get('T_out'), O['fin'].get('T_out'), "global"),
        ("fuel dT across core", J['fin'].get('dT_core'), O['fin'].get('dT_core'), "global"),
        ("volume-mean fuel T", vmean(Fj), vmean(Fo), "global"),
        ("volume-mean graphite T", vmean(Gj), vmean(Go), "global"),
        ("core dp", J['fin'].get('dp_core'), O['fin'].get('dp_core'), "global"),
        ("maximum fuel T", mxJ, mxO, "local"),
        ("maximum graphite T", gmxJ, gmxO, "local"),
        ("hottest-ring outlet T", J['fin'].get('T_out_hottestRing'), O['fin'].get('T_out_hottestRing'), "local"),
        ("hottest-ring rise", J['fin'].get('dT_hottestRing'), O['fin'].get('dT_hottestRing'), "local"),
        ("ring-outlet spread dT_radial", J['fin'].get('dT_radial'), O['fin'].get('dT_radial'), "local")]
print(f"  {'quantity':34} {'J0':>14} {'ORNL-15':>14} {'delta':>12} {'rel %':>9}  class")
for lab,a,b,kind in rows:
    if a is None or b is None: continue
    dv = b-a; rel = dv/a if a else None
    print(f"  {lab:34} {a:14.6f} {b:14.6f} {dv:+12.6f} "
          f"{(rel*100 if rel is not None else float('nan')):+9.4f}  {cls(dv,rel,kind)}")
print(f"  peak fuel cell (ring, axial):     J0 {locJ}   ORNL {locO}   "
      f"{'MIGRATED' if locJ!=locO else 'same cell'}")
print(f"  peak graphite cell (ring, axial): J0 {glocJ}   ORNL {glocO}   "
      f"{'MIGRATED' if glocJ!=glocO else 'same cell'}")
fgJ = max(abs(Fj[r][k]-Gj[r][k]) for r in range(NR) for k in range(NA))
fgO = max(abs(Fo[r][k]-Go[r][k]) for r in range(NR) for k in range(NA))
print(f"  max |T_fuel - T_graphite|: J0 {fgJ:.4e} K, ORNL {fgO:.4e} K")
print(f"    with f_graphiteHeating = 0 the graphite carries no source, so at steady state it")
print(f"    sits at the local fuel temperature and this difference must be ~0. It is a")
print(f"    CONSEQUENCE OF THE PHASE H GATE, not a finding about the source shape.")

print(); print("="*100); print("RING-WISE FIELDS"); print("="*100)
dP = [PO[r]-PJ[r] for r in range(NR)]
dTr, dmr, dTa = [], [], []
print(f"  {'ring':>4} {'dQ(kW)':>9} {'Tout_J0':>11} {'Tout_OR':>11} {'dTout':>9} "
      f"{'Tavg_J0':>11} {'dTavg':>9} {'m_J0':>9} {'dm %':>8}")
for r in range(NR):
    oj, oo = J['fin'].get(f"Ts_out_ring[{r+1}]"), O['fin'].get(f"Ts_out_ring[{r+1}]")
    tj = sum(Fj[r][k]*V[r*NA+k] for k in range(NA))/sum(V[r*NA:(r+1)*NA])
    to = sum(Fo[r][k]*V[r*NA+k] for k in range(NA))/sum(V[r*NA:(r+1)*NA])
    mj, mo = J['fin'].get(f"m_flows[{r+1}]"), O['fin'].get(f"m_flows[{r+1}]")
    dm = ((mo-mj)/mj*100) if (mj not in (None,0) and mo is not None) else float('nan')
    dTr.append(oo-oj); dTa.append(to-tj); dmr.append((mo-mj) if mj is not None else float('nan'))
    print(f"  {r+1:4d} {(RO[r]-RJ[r])/1e3:9.2f} {oj:11.5f} {oo:11.5f} {oo-oj:+9.5f} "
          f"{tj:11.5f} {to-tj:+9.5f} {mj:9.5f} {dm:8.4f}")

print(); print("="*100); print("LOCAL 15x20 FIELD DIFFERENCE"); print("="*100)
aJ, aO = flat(Fj), flat(Fo)
dc = [aO[i]-aJ[i] for i in range(len(aJ))]
E_T = math.sqrt(sum(V[i]*dc[i]**2 for i in range(len(dc)))/sum(V))
im = max(range(len(dc)), key=lambda i: abs(dc[i]))
gJ, gO = flat(Gj), flat(Go)
dg = [gO[i]-gJ[i] for i in range(len(gJ))]
E_G = math.sqrt(sum(V[i]*dg[i]**2 for i in range(len(dg)))/sum(V))
print(f"  fuel     volume-weighted RMS dT = {E_T:.6f} K   max |dT| = {abs(dc[im]):.6f} K "
      f"at (ring {im//NA+1}, axial {im%NA+1})")
print(f"           max positive {max(dc):+.6f} K   max negative {min(dc):+.6f} K")
print(f"  graphite volume-weighted RMS dT = {E_G:.6f} K   max |dT| = {max(abs(x) for x in dg):.6f} K")

print(); print("="*100); print("THERMAL_ATTENUATION_DIAGNOSTIC"); print("="*100)
print("  E_T      = sqrt( sum_c V_c (T_ORNL,c - T_J0,c)^2 / sum_c V_c ) over the 300 channel cells")
print("  E_T_norm = E_T / dT_scale.  E_src is a shape error on a profile of unit volume-mean, so")
print("             the matching temperature scale is the SOURCE-DRIVEN core rise, not an")
print("             absolute temperature (whose datum is arbitrary).")
print("  G_TH     = E_T_norm / E_src.  THERMAL_ATTENUATION_DIAGNOSTIC. NO threshold attached.")
print("  BASELINE (no attenuation, uniform flow, advection only):")
print("    ring-outlet metric  G_TH = 1.00000   (the map from ring power to ring outlet T is")
print("                                          linear and diagonal, so the thermal error is")
print("                                          the source error times the mixed-mean rise)")
print("    300-cell metric     G_TH = 0.59866   (volume-weighted RMS of the axial build-up;")
print("                                          pure geometry, no physics)")
print("  Read the DEPARTURE from these baselines, not the value.")
for lab, sc in (("nominal 27.8 K, preregistered (ASSUMPTION)", DT_NOMINAL),
                ("actual dT_core of CASE J0", J['fin'].get('dT_core'))):
    if sc: print(f"    dT_scale = {sc:9.5f} K  [{lab}]   E_T_norm = {E_T/sc:.6f}   G_TH = {E_T/sc/E_SRC:.6f}")
Tb = sum(aJ[i]*V[i] for i in range(len(aJ)))/sum(V)
den = math.sqrt(sum(V[i]*(aJ[i]-Tb)**2 for i in range(len(aJ)))/sum(V))
print(f"    alternative field-structure normalization: RMS_V(T_J0 - Tbar) = {den:.5f} K,"
      f"  E_T/that = {E_T/den:.6f}")
ip = max(range(NR), key=lambda i: dP[i]); ineg = min(range(NR), key=lambda i: dP[i])
print(f"  largest positive dQ: ring {ip+1} ({(RO[ip]-RJ[ip])/1e3:+.1f} kW) -> dT_out {dTr[ip]:+.5f} K")
print(f"  largest negative dQ: ring {ineg+1} ({(RO[ineg]-RJ[ineg])/1e3:+.1f} kW) -> dT_out {dTr[ineg]:+.5f} K")
print(f"  corr(dQ_j, dT_out_j) = {corr(dP, dTr):.5f}")
if not any(math.isnan(x) for x in dmr):
    print(f"  corr(dQ_j, dm_j)     = {corr(dP, dmr):.5f}")
    rel = [abs(dmr[i])/(J['fin'].get(f'm_flows[{i+1}]') or 1)*100 for i in range(NR)]
    print(f"  max |dm_j|/m_j       = {max(rel):.5f} %  at ring {rel.index(max(rel))+1}")
pos=[i for i in range(NR) if dP[i]>0]; neg=[i for i in range(NR) if dP[i]<0]
print(f"  rings with dQ>0 all hotter: {all(dTr[i]>0 for i in pos)}   {[i+1 for i in pos]}")
print(f"  rings with dQ<0 all cooler: {all(dTr[i]<0 for i in neg)}   {[i+1 for i in neg]}")
