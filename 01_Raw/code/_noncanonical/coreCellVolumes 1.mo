# Phase log

A record of what each development phase decided, measured, and left open.

Git holds *what changed*. This file holds *why*, and — more importantly — what is still
unresolved. Contradictions found and deferred are the entries most worth keeping, because they
do not appear in any diff.

One section per phase, in order, newest at the bottom — this is meant to be read forwards. Do
not rewrite closed sections; if a later phase overturns an earlier finding, add a new entry
that says so and strike the old one through.

---

## Phase 1 — Pump rotor dynamics and per-ring flow resistance

**Branches:** `claude/msre-benchmarking-architecture-i35tb0` (PR #5, merged),
`phase1/pump-init-fix` (PR #7, merged). `phase1/pump-consolidation` (PR #6) was an abandoned
attempt that nevertheless reached `main` and had to be reverted — see decision 5 and the
process note below.
**Status:** implemented, compiles in Dymola. Simulation results not yet recorded.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 1 | Ring flow resistances get a degree of freedom but keep the value 0 | The values would have to come from Kedl, ORNL-TM-3229, which has not been obtained. Fischer et al. (2024) tuned the equivalent coefficients on their three radial groups against that same data. |
| 2 | Fuel properties stay on the existing correlation for now; ORNL-TM-4865 (Compere, 1975) deferred to Phase 2 | Changing the density at the same time as adding the rotor would mix two effects and make the regression unreadable. See the open item below — this is not a free deferral. |
| 3 | Pump rotor parameterized by one constant, `tau_shaft` | With τ_hyd ∝ ω² the rotor equation has closed-form solutions and startup and coastdown follow from the same number. Matches the paper's "typical generic pump parameters". |
| 4 | ~~One pump model with a `use_rotorDynamics` switch, not two model classes~~ | **Reversed.** See entry 5. |
| 5 | The two pump models stay separate classes: `FuelPump` (imposed speed), `FuelPump_Dynamics` (rotor solved), sharing `BaseClasses.PartialFuelPump` | Decision 4 folded both into one class with a Boolean, on the reasoning that keeping a previous state is git's job. That reasoning was about *history*, and it was applied to something that is not only history: which pump drives a given run is a modelling choice a reader has to be able to see. A Boolean buried in a parameter dialog hides it — the rotor disappeared from the package browser and stopped being visible as a thing the model does. Two named classes state the choice where it can be read. The consolidated form is on `phase1/pump-consolidation`, commit `6d19c7d`, if it is ever wanted; do not delete that branch while this reference stands. It was merged to `main` as PR #6 after this decision had already reversed it, and backed out again by PR #8 — see the process note at the end of Phase 1. |

### Numbers established

Pump rotor — only `tau_shaft` is fitted; the rest follows from the rated duty of 3.0 bar at
168 kg/s:

| Quantity | Value | Fixed by |
|---|---|---|
| Rated hydraulic power | 24.4 kW (32.8 hp) | `dp_nominal · V_flow_nominal` |
| `tau_hyd_nominal` | 251 N·m | that power ÷ (ω_n · η) |
| `tau_shaft` | 4.0 s | **fitted** |
| `J` | 8.28 kg·m² | follows from the two above |

At `tau_shaft` = 4.0 s the startup reaches 98.7 % of rated flow in 10 s; the previously fitted
exponential (3.4 s) reached 94.7 %. The paper's halved-inertia sensitivity case is
`tau_shaft` = 2.0.

Core channel hydraulics at rated flow:

| Quantity | Value |
|---|---|
| Total flow area | 0.4469 m² (Mao Table 2: 0.4315 m², −3.4 %) — *superseded in Phase 2, see decision 9* |
| Channel velocity | 0.182 m/s (Engel & Haubenreich quote 0.19 m/s) |
| Channel Reynolds number | **825 — laminar** (855 after Phase 2) |
| Core friction Δp | 243 Pa = 0.081 % of the loop Δp |

Two consequences follow from the Reynolds number, and both are load-bearing:

1. Δp ∝ v, not v². Any later tuning must not assume the turbulent square law.
2. The only mechanism that redistributes flow between rings without a fitted coefficient is the
   viscosity, μ = 8.94e-5·exp(4092/T), giving −0.496 %/K. A ring 10 K hotter draws about 5 %
   more flow on its own.

### Open items

**O-1 — The reported transit times constrain a mass, not a volume. (blocking for Phase 2)**

τ·ṁ contains no density, so what the benchmark actually pins down is the circulating inventory:

| | Mass |
|---|---|
| Core | 1606 kg |
| External loop | 2712 kg |
| Total | 4306 kg |

The volumes in `Data.Geometry` are those masses divided by ρ(908 K) = 2063.1 kg/m³ from the
current correlation. Adopting ORNL-TM-4865 (ρ = 2575 − 0.513·T[°C], giving 2249.3 kg/m³ at
908 K, **+9.03 %**) therefore invalidates the volumes rather than perturbing them:

| | current ρ = 2063.1 | Compere ρ = 2249.3 |
|---|---|---|
| V_core required by τ_C = 9.56 s | 0.77848 m³ | 0.71403 m³ |
| Channel volume (hardware-fixed, 1140 × A × H) | 0.72659 m³ | 0.72659 m³ |
| **Left for the two plenum core nodes** | +0.05189 m³ | **−0.01256 m³ — negative** |
| V_loop required by τ_L = 16.14 s | 1.31430 m³ | 1.20548 m³ (−8.3 %) |

**At the Compere density the channel volume alone exceeds the core volume the reported core
transit time allows.** The channel volume is not adjustable — it is 1140 channels of 1.626 m.
Using Mao's core geometry instead (0.4315 m² × 1.6406 m = 0.70792 m³) leaves +0.00611 m³, i.e.
about 3 litres per plenum node, which fits but is implausibly small.

Three ways out, to be decided at the start of Phase 2:

- **(A)** Adopt Compere ρ *and* Mao's core geometry, accept ~3 L plenum nodes as a stated
  assumption. Both τ_C and τ_L then match MARS.
- **(B)** Adopt Compere ρ, hold the geometry at documented ORNL hardware, and report the
  resulting τ_C shortfall as evidence that MARS is not using the Compere correlation. From a
  code-to-code standpoint this may be the more informative result.
- **(C)** *(chosen for Phase 1)* Defer the density change entirely.

**O-2 — Jeong (2026) publishes no property correlations or values.**

Section 3 says the molten-salt property models were implemented in MARS first and refers to
[18] (KNS spring meeting) and [19] (NET 58(1) 2026, 103898). Neither is in hand. Direct
comparison of the Compere correlation against "the values Jeong used" is therefore **not
possible**; the only route is the inverse one in O-1, backing a density out of the transit times
and the inventory. Obtaining [19] converts this to a direct comparison.

**O-3 — Ring resistance cannot be validated at 100 W.**

At the benchmark power the ring-to-ring temperature spread is at most 0.4 µK, so no setting of
`K_channelInlet` / `K_channelExit` produces an observable difference. Any claim about ring-level
flow distribution needs the full-power (8 MW) or natural-circulation case. Do not present the
15-ring resistance model as validated by the zero-power tests.

**O-4 — Verification models have never been run.**

`Steady_LoopBalance` and `Transient_DriftReactivity` compile but have not been simulated. Their
tolerances are stated acceptance criteria, not observed results. `Steady_LoopBalance` check 6
(delivered flow vs. rated) is the most likely to fail first and is deliberately a warning: the
loop form losses have never been exercised against the pump characteristic in a solver.

**O-5 — TRANSFORM may already ship a Compere-based fuel salt.**

Fischer et al. (2024) state that the LiF-BeF₂-ZrF₄-UF₄ properties they used are included in
TRANSFORM "based on data from Compere (1975)". If so, Phase 2 may be able to use the built-in
medium rather than restating correlations. Not verifiable from this repository — needs the
TRANSFORM library open.

### Process note — an abandoned branch reached `main`

PR #6 carried the consolidation of decision 4. That decision was reversed before the PR was
acted on, and the reversal was pushed to a different branch, but PR #6 stayed open and was
merged anyway. `main` then held the structure the project had just decided against, and the
next two branches — both cut before the merge — could not be merged into it at all: the pump
files were deleted on one side and modified on the other, and `docs/PHASE_LOG.md` existed on
both with different contents.

Backing it out was clean, because the merge was reverted rather than rebased over:
`git revert -m 1 22c846d` (PR #8) restored `main` byte-for-byte to `bb5bb2e`, after which PR #7
and PR #9 merged without conflict. Merge order matters here and was: revert, then Phase 1, then
Phase 2.

The rule this produces: **a branch whose direction has been abandoned must have its PR closed
at the moment of the decision, not left open with a note.** An open PR is an instruction to
merge, whatever the conversation around it says.

### Verification status

| Check | Ran? | Result |
|---|---|---|
| Dymola compilation | yes | passes |
| `Steady_LoopBalance` (7 asserts) | no | — |
| `PumpCoastdown` rotor vs. imposed law | no | — |
| `PumpStartup` rotor vs. imposed law | no | — |
| `Analytic_DriftReactivity` | evaluated outside Modelica | passes with margin |

---

## Phase 2 — Fuel salt density traced to ORNL-TM-4865

**Branch:** `phase2/properties-compere` (PR #9, merged)
**Status:** density replaced. Volumes deliberately not re-derived — see O-6, which is now the
main open item in the library.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 6 | Fuel salt density becomes `2575 − 0.513·T[°C]` (Compere et al., ORNL-TM-4865, 1975) | The previous `2575.3 − 0.5641·T[K]` could not be traced to a source and runs ~9 % low. The new one is independently corroborated: it is Mao et al. Eq. (10), and it is the correlation behind the TRANSFORM medium Fischer et al. (2024) used. |
| 7 | Only the density is traced; cₚ, μ, k are carried over unchanged | Deliberate ordering, not an unfinished job. The density is the property the benchmark is sensitive to — it converts volumes into transit times, and Eq. 8 depends on nothing else. cₚ does not enter the zero-power tests at all; μ and k act only through friction and heat transfer, neither of which matters at 100 W. Trace them before reporting any full-power result. |
| 8 | Geometry left as it is, so the library no longer reproduces the reported transit times | Option B as agreed. The inconsistency is left visible and computable (`Geometry.err_m_core`, `err_m_loop`) rather than absorbed by re-fitting volumes around the new density. |

### The finding, and why it contradicts what option B was chosen to show

Option B was adopted on the expectation that the τ_C deviation would be evidence that **MARS
did not use the Compere density**. The numbers say the opposite, and the reasoning that gets
there does not use any volume this library calibrated.

A transit time times a mass flow rate is a **mass**, with no density in it. The reported
τ_C = 9.56 s at 168 kg/s therefore states that the MARS core holds **1606 kg** of fuel salt,
whatever correlation produced it. The MARS core is its fuel channels plus two small plenum
nodes, and the channel volume is documented hardware. Their ratio is an independent estimate of
the density MARS used:

| Core volume used | Implied density | vs Compere 2249 | vs old correlation 2063 |
|---|---|---|---|
| 1140 channels × 1.626 m (this library) | 2210 kg/m³ | −1.7 % | +7.1 % |
| 0.4315 m² × 1.6406 m (Mao Table 2) | 2269 kg/m³ | **+0.9 %** | +10.0 % |

Both land within ~2 % of Compere and 7–10 % from the correlation the library used before.
**MARS almost certainly did use a Compere-like density; what was wrong was this library's
correlation.** Nothing here is circular — no calibrated volume enters.

Confirming it from the other direction: adopting Mao's published core flow area together with
the Compere density gives τ_C = 9.64 s against the reported 9.56 s, **with nothing fitted.**

### Numbers established

| Quantity | Old (2063 kg/m³) | New (2249 kg/m³) |
|---|---|---|
| ρ at 908 K | 2063.1 | 2249.3 (+9.03 %) |
| ρ at 922 K | 2055.2 | 2242.1 |
| β (thermal expansion) | 2.7448e−4 | 2.2880e−4 |
| τ_C / τ_L / τ_sys at 168 kg/s | 9.56 / 16.14 / 25.70 s | 10.42 / 17.60 / 28.02 s |
| Drift reactivity (Eq. 8) | 228.4 pcm | 218.8 pcm |
| Pump: P_hyd / τ_hyd / J | 24.4 kW / 251 N·m / 8.28 kg·m² | 22.4 kW / 231 N·m / 7.59 kg·m² |

Measured drift reactivity is 227.3 pcm, so with the volumes unchanged the agreement moves from
+0.5 % to −3.7 %. `tau_pump_shaft` is unchanged, so the pump speed histories are identical.

### Open items

**O-6 — The volumes are now inconsistent with the reported transit times. This is the live item.**

Both inventories are 9.0 % high (`Geometry.err_m_core`, `err_m_loop`). Two checks now fail
knowingly and have been downgraded to warnings with the reason stated in the message:
`Steady_LoopBalance` check 2 (τ_sys 28.02 s vs 25.63 s) and `Analytic_DriftReactivity`'s natural
circulation check (0.74 / 5.67 pcm vs 0.9 / 6.7 pcm). They must not be re-tightened by editing
tolerances.

Resolution differs by side. The **core** is close to resolvable from published data: adopting
Mao's core flow area (0.4315 m², 1.6406 m) gives τ_C = 9.64 s unfitted. The **loop** is not —
`V_downcomer` was always the item that absorbed the balance of the inventory, so it has no
independent value and would simply be re-derived from `m_fuel_loop_paper`.

**O-5 is unchanged** — TRANSFORM's built-in medium may already be Compere-based, which would
make `Media.FuelSalt` redundant. Still needs the TRANSFORM library open to check.

---

## Phase 2b — Core volume re-derived from published channel hardware

**Branch:** `phase2/properties-compere` (PR #9, merged — same branch as the section above)
**Status:** implemented and merged. Not yet compiled or simulated.

### Decision

| # | Decision | Rationale |
|---|---|---|
| 9 | Core geometry taken from Mao et al. Table 2: total flow area 0.4315 m², height 1.6406 m | Resolves O-6 on the core side. The library's own 1140 × 3.9198e-4 × 1.626 was not sourced; the Mao figures are published and are the ones that agree with the ORNL-TM-4865 density to within 1 %. |
| 10 | Plena nodalized non-uniformly; the core-boundary node is a thin slice | The node the kinetics counts as core (120-03, 190-01) is 0.86 % of the core volume, not a third of the plenum. `SaltPipe` gained `Vs_nodes`, holding the bore uniform and letting node lengths differ. |
| 11 | `V_downcomer` re-derived from `m_fuel_loop_paper` (0.5869 → 0.4324 m³) | It has always been the item that absorbs the balance of the loop inventory and has no published value to check against. Recorded as arithmetic, not agreement. |

### The result, and what it is worth

| | value | fitted? |
|---|---|---|
| τ_C | **9.5600 s** (reported 9.56) | **no** |
| τ_L | 16.1400 s (reported 16.14) | yes — `V_downcomer` |
| τ_sys | 25.70 s (reported 25.63, measured 25.2) | — |
| Drift reactivity, Eq. 8 | **228.35 pcm** (reported 228.4, measured 227.3) | — |
| β_eff circulating | 0.00450 | — |
| Natural circulation (U-233) | 0.87 / 6.53 pcm (paper 0.9 / 6.7) | — |

**τ_C is a prediction.** Its inputs are a published flow area, a published height and a
published density correlation, none of them adjusted. Since Eq. 8 depends on the transit times
and nothing else, this is the one place the model reproduces the benchmark from independent
data. τ_L is not and must not be presented as if it were.

Both checks downgraded to warnings in Phase 2 now pass again and have been restored to error
level: `Steady_LoopBalance` check 2 (25.70 s vs 25.63) and the natural circulation check in
`Analytic_DriftReactivity` (0.87 / 6.53 vs 0.9 / 6.7).

### Consequential changes

`A_graphite_perChannel` is now derived rather than tabulated: stack area (π/4 × 1.26²) minus
the channel area, shared over 1140 channels, giving 7.153e-4 m² against the previous 7.018e-4.
`r_graphite_inner` 0.014036 → 0.013553 m, `r_graphite_outer` 0.020503 → 0.020282 m,
`V_graphite` 1.3009 → 1.3377 m³. Channel Reynolds number 825 → 855, still laminar.

### Open items

**O-6 is closed on the core side, still open on the loop side.** `V_downcomer` remains
un-checkable. Any statement about loop transit time agreement is circular.

**O-7 — The plenum core-node length does not reconcile with the paper. (new)**

The core node comes out at 3.055 L, which at the assumed plenum bore is an axial length of
12 mm. The paper's core-boundary sensitivity study states Volume 190-01 as 63.5 mm — five times
longer. The transit times depend on volume, not length, so nothing above is affected, but the
plenum bore assumed here is not the one MARS used. Resolving it needs the MARS node dimensions,
which are not published. Note that `corePowerShape` uses the node *length*, so the axial power
shape near the core boundary carries this discrepancy.

**O-8 — `Dh_channel` was not re-derived. (new)**

It stays at 0.01778 m (0.7 in) while the flow area dropped 3.4 %, so the implied wetted
perimeter moved from 0.0882 to 0.0852 m. Both are documented hardware in different sources and
they are no longer mutually consistent. Affects the heat transfer area, not the transit times.

## Toolchain note — MSL 4.1.0 `massFraction` breaks every TRANSFORM medium

**Branch:** `claude/msre-massfraction-errors-erzuuf`
**Status:** implemented. Not yet compiled — the fix has to be confirmed by a Dymola check.

Checking `Verification.Steady_LoopBalance` under Dymola 2026x produced ~120 instances of

> Redeclaration requires a subtype. But missing public function massFraction.

against every `redeclare package Medium` in the loop, plus the same complaint about
`Medium_coolant`, which is a TRANSFORM built-in that this library never touched.

**Cause.** Modelica Standard Library 4.1.0 (2025-05-23) added

```modelica
replaceable partial function massFraction "Return independent mass fractions (if any)"
  input ThermodynamicState state;
  output MassFraction Xi[nXi];
end massFraction;
```

to `Modelica.Media.Interfaces.PartialMedium`. TRANSFORM does not extend that package — it
carries its own copy of the media interfaces
(`TRANSFORM.Media.Interfaces.Fluids.PartialMedium`, which extends only
`Modelica.Media.Interfaces.Types`), so a TRANSFORM medium is a subtype of MSL's `PartialMedium`
only structurally. One added function is enough to break that match, and `PartialMedium` is the
constraining package of every `Medium` in `Modelica.Fluid.Interfaces` and in the TRANSFORM
closure relations. So no TRANSFORM-based medium can be redeclared into any fluid component
under MSL 4.1.0. It is not specific to the fuel salt and not caused by anything in this library.
Comparing the two `PartialMedium` packages class by class, `massFraction` is the only member MSL
has and TRANSFORM lacks.

**Fix.** Declare the function on this library's two media, with the empty body MSL itself uses
in `PartialPureSubstance` (both salts are single substances, so `nXi = 0`):

- `MSRE.Media.FuelSalt` gains `massFraction`, inherited by `FuelSalt_U235` and `FuelSalt_U233`.
- `MSRE.Media.CoolantSalt` changes from an alias of
  `TRANSFORM.Media.Fluids.FLiBe.LinearFLiBe_9999Li7_pT` to a package that extends it and adds
  the same function. Nothing else about the coolant salt changes.

The function is never called by any model here and is inert under MSL 4.0.0, so the fix is
backward compatible. It does not patch TRANSFORM: any *other* TRANSFORM medium redeclared into
a fluid component under MSL 4.1.0 will fail the same way and needs the same three lines.

### Not part of this fix

The same check reported `Class or component 'N_pump_start' not found in PrimarySystem msre`.
`N_pump_start` has been a parameter of `PrimarySystem` since commit d55b826 (PR #7, merged), so
either the working copy under check predates that merge or the message is a knock-on of the
failed medium redeclaration. Re-check after pulling `main`.

---

## Phase 3 — Fuel salt property set replaced with Cantor / ORNL-TM-2316 (INL VTB/SAM basis)

**Scope:** the `MSRE.Media.FuelSalt` medium only. Geometry, pump models, kinetics and transient
test parameters were deliberately not touched.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 10 | All four fuel-salt properties come from S. Cantor, ORNL-TM-2316 (1968), in the form used by the INL MSRE VTB/SAM model | Replaces a mixed set — one traced density (Compere, ORNL-TM-4865) plus three untraced values — with a single self-consistent set from one primary source that a public reference implementation also uses. Closes decision 7 of Phase 2, which deferred cₚ, μ and k. |
| 11 | The density fit is implemented as `2553.3 − 0.562·(T[K] − 273.15)` | The published fit takes **°C**. Implemented against a kelvin argument it gives 2035 kg/m³ at 922 K instead of 2189 — the same class of unit error Phase 2 found in the old `2575.3 − 0.5641·T[K]`. Cross-checked against the INL SAM value 2285.31 kg/m³ at 476.85 °C. |
| 12 | The viscosity fit `8.4e-5·exp(4340/T)` is implemented against **kelvin**, with no conversion | The two fits do not use the same temperature unit; this is stated at every implementation site so it cannot be "tidied up" into consistency. |
| 13 | The superseded values are kept as reference-only functions in `MSRE.Media.MSRE_Properties`, not deleted | `Properties_TransitTime` and `Analytic_DriftReactivity` call `d_Compere` explicitly, and the geometry volumes were derived against it. Active and legacy sets are labelled ACTIVE / REFERENCE ONLY so they cannot be mixed. |
| 14 | Geometry volumes and pump parameters left unchanged, so the reported transit times move by the density ratio | Same policy as Phase 2 option B: the inconsistency stays computable rather than being absorbed by re-fitting volumes around a new density. Mixing a property change with a geometry change makes the regression unreadable. |
| 15 | `T_melt = 722.15 K` recorded as a constant in `MSRE_Properties`, not added to the medium | The TRANSFORM `PartialLinearFluid` interface has no melting-temperature parameter and no model here needs one. Not worth a structural change to the medium interface. |

### Numbers established

| Property | Legacy | Cantor (active) | Δ @ 922 K |
|---|---|---|---|
| ρ | 2575 − 0.513·T[°C] | **2553.3 − 0.562·T[°C]** | 2242.14 → **2188.65** kg/m³ (−2.39 %) |
| μ | 8.94e-5·exp(4092/T) | **8.4e-5·exp(4340/T)** | 7.565e-3 → **9.302e-3** Pa·s (+23.0 %) |
| cₚ | 1967 | **2009.66** J/(kg·K) | +2.17 % |
| k | 1.44 | **1.0** W/(m·K) | −30.6 % |
| T_melt | not represented | **722.15 K** | — |

Over the operating range (core inlet 908 K, average 922 K, outlet 936 K):

| T | ρ [kg/m³] | μ [Pa·s] | cₚ [J/(kg·K)] | k [W/(m·K)] |
|---|---|---|---|---|
| 908 K | 2196.51 | 1.0002e-2 | 2009.66 | 1.0 |
| 922 K | 2188.65 | 9.3019e-3 | 2009.66 | 1.0 |
| 936 K | 2180.78 | 8.6695e-3 | 2009.66 | 1.0 |

All four are strictly positive at all three temperatures.

`beta_const` moved 2.2880e-4 → **2.5678e-4 1/K**. It is not an independent datum: it is
`0.562/2188.65`, the isobaric expansion coefficient of the new density fit at the reference
temperature, and it moves whenever the fit moves.

### Retained assumptions

No new source was established for these, so they keep their existing values —
*retained existing model assumption, not modified in this property update*:

- `FuelSalt.kappa_const = 2.89e-10 1/Pa` (from the TRANSFORM FLiBe model; only sets the stiff
  acoustic time scale, the primary system is essentially incompressible here)
- `FuelSalt.MM_const = 0.0331 kg/mol`
- `FuelSalt.reference_p = 1e5 Pa`, `reference_s = 0`, and the `reference_h` convention
  `cp·(T_ref − 273.15)`
- `Data.Geometry.d_fuel_ref = 2249.3 kg/m³` and `PartialFuelPump.d_nominal = 2242 kg/m³` —
  ORNL-TM-4865 numbers on the geometry/pump side, out of scope for a property-only change

### Consequential changes, and what was left alone

`PrimarySystem.density_ref` is evaluated from the medium, so it — and with it `tau_core`,
`tau_loop`, `tau_system` — falls by 2.39 %. That is the intended visible consequence.
Nothing else was edited: `Data/Geometry.mo`, `PartialFuelPump.mo`, `FuelPump.mo`,
`FuelPump_Dynamics.mo`, the kinetics and the transient test parameters are untouched, and the
two verification models that quote a density call `MSRE_Properties.d_Compere` explicitly rather
than the medium, so their numbers and asserts are unchanged by this commit. They now describe
the *geometry's* reference density rather than the medium's, which is a real divergence and is
recorded as the open item below.

### Open items

- **O-9.** The geometry volumes were derived against the Compere density (Phase 2/2b) and the
  medium now runs on Cantor. `Verification/Properties_TransitTime.mo` and
  `Verification/Analytic_DriftReactivity.mo` still evaluate `d_Compere`. Either the volumes are
  re-derived at the Cantor density or those two models are restated against it — a geometry
  decision, deliberately not taken inside a property-only change.
- **O-10.** The `CoreChannel` documentation quotes the legacy viscosity slope
  (−4092/T² = −0.481 %/K). The Cantor fit gives −4340/T² = −0.511 %/K, so the argument holds in
  substance but the quoted number is now the legacy one.
- **O-11.** The thermal conductivity fell 30 % and the viscosity rose 23 %. Neither reaches the
  zero-power pump tests (100 W), but both act directly on any full-power heat-transfer result.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain (`omc`, Dymola) and no MSL/TRANSFORM installation is
present in this environment, so `checkModel` and the property verification model were not run.
The correlations were verified numerically outside Modelica against the values in the table
above; the edited files were checked for Modelica string/comment balance.

---

## Phase 4 — Core geometry rebuilt from ORNL/INL hardware dimensions

**Scope:** the fuel-channel block of `Data/Geometry.mo` and the matching component defaults.
Plenum, downcomer and external-loop geometry are deliberately left for the next commit.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 16 | The Mao et al. core geometry (`A_core_total = 0.4315 m²`, `H_channels = 1.6406 m`) is retired | It is 32 % larger than the documented channel cross-section of 1140 MSRE channels. It was the quantity that made `tau_core_nominal` land on the reported 9.56 s, so keeping it meant the benchmark was reproduced by an unsourced area. |
| 17 | Core geometry is derived from hardware dimensions, not entered | `w_channel`, `h_channel`, `r_channelCorner`, `H_channels` and `nChannels_total` are the only inputs; `A_channel`, `perimeter_channel`, `Dh_channel`, `A_core_total` and `V_channels` are all `final parameter`. `Dh_channel` in particular was previously a hand-entered 0.7 in that did not follow from any area or perimeter in the record. |
| 18 | Volumes are **not** re-derived from the Cantor density to restore the reported transit times | Doing so makes geometry a function of the property correlation and zeroes `err_m_core`, which is the only indicator that anything disagrees. This is the same option-B policy as Phase 2. |
| 19 | The Mao values are retained as an inert legacy block, labelled *Mao et al. reference geometry — not active* | Provenance change stays a computable comparison (`err_V_channels_Mao`) instead of a remark in a commit message. |
| 20 | `D_graphiteStack` becomes the core container inner diameter, 1.40335 m (55.25 in) | The previous 1.26 m had no stated source. Graphite volume follows from it and the channel area. |
| 21 | INL RZ porous-medium parameters (`core_porosity = 0.2228` and the equivalent-geometry set) are **not** adopted | This baseline is a 1-D channel model, not an RZ multiphysics model. Porosity is an output of the channel geometry here, not an input. |

### Numbers established

| Quantity | Mao (legacy) | ORNL/INL hardware (active) | Δ |
|---|---|---|---|
| `A_channel` | 3.785088e-4 m² | **2.875244e-4 m²** | −24.0 % |
| `perimeter_channel` | 0.085154 m | **0.072559 m** | −14.8 % |
| `Dh_channel` | 0.01778 m (hand-entered) | **0.015851 m** (derived) | −10.9 % |
| `A_core_total` | 0.4315 m² | **0.327778 m²** | −24.0 % |
| `H_channels` | 1.6406 m | **1.6256 m** | −0.9 % |
| `V_channels` | 0.707919 m³ | **0.532836 m³** | −24.7 % |
| `V_graphite` | 1.33774 m³ | **1.98157 m³** | +48.1 % |
| `r_graphite_inner` / `outer` | 0.013553 / 0.020282 m | **0.011548 / 0.021765 m** | — |

Derived at `d_fuel_ref = 2249.3 kg/m³` (unchanged, ORNL-TM-4865 at 908 K):

| | paper | this record | error |
|---|---|---|---|
| core mass | 1606 kg | **1212 kg** | `err_m_core` **−24.5 %** |
| loop mass | 2712 kg | 2712 kg | `err_m_loop` 0.0 % |
| `tau_core_nominal` | 9.56 s | **7.22 s** | −24.5 % |
| `tau_system_nominal` | 25.63 s | **23.36 s** | −8.9 % |

### The finding

**1606 kg of fuel salt does not fit in 1140 channels of documented cross-section.** It would
need 3014 kg/m³, against 2196.5 (Cantor) and 2249.3 (ORNL-TM-4865) — 34 % high. Earlier
revisions of this record read the same comparison in the opposite direction, using an untraced
channel volume of 0.7266 m³ and the Mao area, and concluded the *density* was wrong. With the
channel geometry built from hardware that conclusion no longer follows: the discrepancy points
at **what the MARS core node contains** (plenum, bypass or annulus salt counted as core?)
rather than at any property correlation.

### Consequential assert failures — expected, not fixed

Three asserts now fail, and they fail because they are doing their job. None was relaxed:

| Model | Assert | Value | Limit |
|---|---|---|---|
| `Verification/Steady_LoopBalance.mo:60` | `tau_system_nominal` vs 25.63 s | **23.36 s** | ±0.15 s |
| `Verification/Properties_TransitTime.mo:79` | implied vs Compere density | **+34.0 %** | ±5 % |
| `Verification/Analytic_DriftReactivity.mo:64` | natural-circulation drift | **1.49 / 10.13 pcm** | 0.9 ± 0.2 / 6.7 ± 0.5 pcm |

Forced-circulation drift reactivity (U-235, Eq. 8, Cantor at 908 K) moves from 231.0 pcm to
**277.0 pcm** against the paper's 228.4 pcm — a +48.6 pcm gap, well outside
`Transient_DriftReactivity.tol_rho_pcm = 8`.

### Open items

- **O-12.** Definition of the MARS core node. Blocks any reconciliation of the −24.5 %.
- **O-13.** `d_fuel_ref = 2249.3 kg/m³` is still the ORNL-TM-4865 value while the medium runs on
  Cantor. It cannot simply be switched: `V_flow_pump_nominal`, `P_pump_hydraulic`,
  `tau_pump_hyd_nominal` and `J_pump` are all derived from it, and pump parameters were out of
  scope here. Needs a decision on whether the pump duty follows the medium.
- **O-14.** The three failing asserts need to be restated as reported diagnostics or given
  hardware-based targets. They must not be silently widened.
- **O-15.** `dz_channels = 1.626 m` still differs from `H_channels = 1.6256 m` by 0.4 mm. Left
  alone because the elevation set closes through `dz_downcomer`, which is next-commit scope.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain in this environment. All values above were computed
by hand outside Modelica from the same expressions now in the record; `Data/Geometry.mo` was
checked for Modelica string and comment balance.

---

## Phase 5 — Plenum, downcomer and external-loop geometry

**Scope:** the vessel/downcomer and piping block of `Data/Geometry.mo`. Continues Phase 4 and
closes the deferral noted there. The heat exchanger is **not** included — see below.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 22 | The downcomer becomes the vessel/core-container annulus | `V_downcomer` was never a measurement: it was set to whatever made the loop inventory reproduce the reported loop transit time. Reactor vessel ID 58 in and core container OD 56 in (55.5 in bore + 2 × 0.25 in wall) give a 25.4 mm annular gap, so `A_downcomer` and `Dh_downcomer` now follow from hardware. |
| 23 | `Dh_downcomer = 0.1163 m` is retired | It was not the annulus of any vessel in the record; it travelled with the fitted volume. The hardware value is 0.0508 m. |
| 24 | `D_pipe` 0.1286 → 0.127 m | The 5 in figure the INL MSRE description gives, in place of the 5 in schedule 40 bore. The only piping quantity with a published counterpart. |
| 25 | Unsourced loop quantities keep their values and are labelled as estimates, not replaced by invented ones | Plenum volumes, core-boundary plenum nodes, `V_pumpBowl`, `L_downcomer`, the three pipe lengths and the elevation set have no published counterpart in the ORNL/INL material available. Marked *estimate, no published source* in the record rather than guessed at. |
| 26 | `V_lowerPlenum_core` / `V_upperPlenum_core` are **not** re-derived | Their 3.055 litre value was the remainder of the reported 1606 kg core inventory once the *old* channel volume was removed. That derivation is void after Phase 4, and redoing it would fit geometry to the reported inventory — the practice this whole line of work is removing. Kept as unsourced small nodes. |
| 27 | The heat exchanger is left alone | Its shell-side hydraulic diameter (0.05606 m here vs 0.0209 m in the INL description) feeds `f_shellHT` and `Nu_floor_shell`, which are explicitly calibration parameters and out of scope. Changing the shell geometry without them would silently rescale the full-power duty. Recorded as O-16. |

### Numbers established

| Quantity | fitted / previous | ORNL/INL hardware (active) | Δ |
|---|---|---|---|
| `A_downcomer` | 0.180155 m² (implied) | **0.115529 m²** | −35.9 % |
| `Dh_downcomer` | 0.1163 m | **0.0508 m** | −56.3 % |
| `V_downcomer` | 0.432371 m³ | **0.277270 m³** | −35.9 % |
| `D_pipe` | 0.1286 m | **0.127 m** | −1.2 % (−2.5 % on volume) |
| `V_loop` | 1.205483 m³ | **1.045243 m³** | −13.3 % |
| `V_total` | 1.744429 m³ | **1.584189 m³** | −9.2 % |

At `d_fuel_ref = 2249.3 kg/m³` (unchanged):

| | paper | this record | error |
|---|---|---|---|
| core mass | 1606 kg | 1212 kg | `err_m_core` −24.5 % |
| loop mass | 2712 kg | **2351 kg** | `err_m_loop` **−13.3 %** |
| circulating mass | 4318 kg | **3563 kg** | **−17.5 %** |
| `tau_core_nominal` | 9.56 s | 7.22 s | −24.5 % |
| `tau_loop_nominal` | 16.14 s | **13.99 s** | **−13.3 %** |
| `tau_system_nominal` | 25.63 s | **21.21 s** | −17.2 % |

Forced-circulation drift reactivity (U-235, Eq. 8, Cantor at 908 K): **269.9 pcm** against the
paper's 228.4 pcm, improved from Phase 4's 277.0 pcm because shortening the loop transit time
partly offsets the shortened core transit time. Natural-circulation drift is unchanged at
1.49 / 10.12 pcm.

Hydraulic sanity at rated flow: downcomer 0.65 m/s, Re ≈ 7.4e3; main piping 5.90 m/s,
Re ≈ 1.7e5. Both remain turbulent.

### What the loop error now means

`err_m_loop` used to be exactly 0.0 %, and that was not agreement — it was
`V_downcomer := m_fuel_loop_paper/d_fuel_ref` read back out. It is now −13.3 %, a real
measurement. The missing 0.1603 m³ is 1.39 m of extra downcomer length, or a pump bowl twice
the assumed size, or salt the MARS input counts as loop and this record does not. The available
dimensions cannot distinguish those.

Taken with Phase 4: **the reported circulating inventory is 4318 kg and hardware-based geometry
holds 3563 kg of it, 17.5 % short.** That single number is what any reconciliation now has to
explain, and it is the deliverable of Phases 4–5.

### Open items

- **O-16.** Heat-exchanger shell geometry. INL gives shell diameter 0.41 m and shell-side
  Dh 0.0209 m against 0.05606 m here. Coupled to `f_shellHT` / `Nu_floor_shell`, so it needs to
  move together with the HX calibration, not before it.
- **O-17.** `L_downcomer = 2.40 m`, `V_pumpBowl = 0.150 m³`, the two plenum volumes and the
  three pipe lengths remain unsourced. These are now the entire remaining freedom in the loop
  volume.
- **O-12 / O-13 / O-14 / O-15** from Phase 4 are unchanged and still open. O-14 (three failing
  asserts) is now more pressing: `tau_system_nominal` is 21.21 s against a 25.63 ± 0.15 s
  assert.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain in this environment. All values computed by hand
outside Modelica from the expressions now in the record; `Data/Geometry.mo` checked for
Modelica string and comment balance.

---

## Phase 6 — Geometry provenance cleanup (O-12 + O-17)

**Scope:** provenance classification and documentation only. No active geometry *value* was
changed in this commit; the only new numbers are reference and diagnostic quantities that
nothing depends on.

### O-12 — Jeong core boundary

```
Jeong core boundary confirmed:
120-03 + 300 channel cells + 190-01.
190-01 baseline axial length = 0.0635 m.
Former 0.003055 m3 boundary-node volumes were inventory-derived legacy values
and are no longer accepted as physical provenance.
120-03 physical geometry remains unresolved.
190-01 physical volume remains unresolved unless an independent area source is found.
```

The control-volume **definition** from Jeong et al., *Nuclear Engineering and Technology* 58
(2026) 104438 is confirmed and kept unchanged: `iLP_core = nLP`, `iUP_core = 1`,
`nV_core = nRings*nAxial + 2`, 15 rings × 20 axial nodes, 3 + 3 plenum nodes. No component
architecture was touched.

The boundary-node **volumes** are demoted. `V_lowerPlenum_core` and `V_upperPlenum_core` keep
their 0.003055 m³ — no independently sourced replacement exists and inventing one is exactly
what this work is removing — but they are now tagged **LEGACY / OPEN** in their own description
strings and in the record documentation.

**What the paper's own sensitivity implies.** Lengthening 190-01 by 0.0800 m is reported to
move `tau_core` by +1.11 s and `tau_loop` by −1.11 s. A transit time is a volume over a
volumetric flow, so:

| Diagnostic | Value | Note |
|---|---|---|
| `V_flow_ref` | 0.074690 m³/s | 168 kg/s at `d_fuel_ref` |
| `A_190_01_JeongEq` | **1.0363 m²** | 66 % of the core container bore (1.5608 m²) |
| `V_190_01_JeongEq` | **0.065806 m³** | **21.5×** the legacy 0.003055 m³; **85 %** of the whole assumed upper plenum |
| `V_core_JeongEq` | 0.714035 m³ | from the reported `tau_C`, not used as active |
| `V_120_03_JeongEq` | **0.115393 m³** | **148 %** of the whole assumed lower plenum |

`L_upperPlenum_core` as modelled is **0.0118 m** against the **0.0635 m** the paper states for
190-01 — the clearest single sign that 0.003055 m³ is not the paper's node.

Two readings survive and the data does not choose between them: either the MARS plena are much
larger than the 0.0777 m³ assumed here, or MARS counts as core-boundary nodes a region this
record counts as plenum and downcomer. Both would explain part of the 17.5 % inventory
shortfall. Setting `V_upperPlenum_core := V_190_01_JeongEq` was **not** done: that figure is
derived from a MARS result, not from hardware, and adopting it would reinstate transit-time
fitting. It is reported and left disconnected on purpose.

### O-17 — Loop parameter reclassification

```
Remaining loop-volume uncertainty is no longer absorbed into the downcomer.
Unsourced component dimensions remain explicit assumptions.
No component volume is adjusted to reproduce tau_C, tau_L or total inventory.
```

Six tags, carried in each parameter's own description string so they travel with the value:
**PHYSICAL**, **DERIVED**, **REFERENCE**, **ASSUMPTION**, **LEGACY**, **BENCHMARK-EQUIVALENT**.

| Parameter | Value | Class | Provenance |
|---|---|---|---|
| `V_lowerPlenum_core` (120-03) | 0.003055 m³ | **LEGACY / OPEN** | former paper-inventory balance |
| `V_upperPlenum_core` (190-01) | 0.003055 m³ | **LEGACY / OPEN** | former paper-inventory balance |
| `L_190_01_Jeong` | 0.0635 m | REFERENCE | Jeong 2026 |
| `dL_190_01_Jeong`, `dtau_core_Jeong` | 0.0800 m, 1.11 s | REFERENCE | Jeong 2026 sensitivity |
| `A_190_01_JeongEq`, `V_190_01_JeongEq` | 1.0363 m², 0.065806 m³ | BENCHMARK-EQUIVALENT | not physical |
| `V_core_JeongEq`, `V_120_03_JeongEq` | 0.714035, 0.115393 m³ | BENCHMARK-EQUIVALENT | not physical |
| `V_lowerPlenum`, `V_upperPlenum` | 0.0777 m³ each | ASSUMPTION | no published source |
| `L_lowerPlenum`, `L_upperPlenum` | 0.30 m each | ASSUMPTION | no published source |
| `D_vessel_inner`, `th_vessel`, `D_coreContainer_inner`, `th_coreContainer` | 1.4732, 0.0254, 1.4097, 0.00635 m | PHYSICAL | ORNL/INL hardware |
| `A_downcomer` | 0.115529 m² | DERIVED | vessel/container annulus |
| `Dh_downcomer` | 0.0508 m | DERIVED | vessel/container annulus |
| `V_downcomer` | 0.277270 m³ | DERIVED | hardware area × assumed length |
| `L_downcomer` | 2.40 m | ASSUMPTION | no published source |
| `D_pipe` | 0.127 m | REFERENCE | INL MSRE description, 5 in |
| `L_outletPipe`, `L_pumpToHX`, `L_hxToVessel` | 4.00, 5.00, 7.00 m | ASSUMPTION | none confirmed |
| `V_pumpBowl`, `L_pumpBowl` | 0.150 m³, 0.60 m | ASSUMPTION | no published source |
| `V_hxShell` | 0.266 m³ | ASSUMPTION | frozen with the HX, O-16 |
| `V_downcomer_fitted`, `Dh_downcomer_fitted`, `D_pipe_sch40`, `*_Mao` | — | LEGACY | retired fits, inert |

The core channel set (`nChannels_total`, `H_channels`, `w_channel`, `h_channel`,
`r_channelCorner`, `D_graphiteStack`) is PHYSICAL and everything computed from it
(`A_channel`, `perimeter_channel`, `Dh_channel`, `A_core_total`, `V_channels`) is DERIVED.

`V_core` is tagged **PARTIAL_GEOMETRY_BASELINE**: its channel term is hardware, its two
boundary-node terms are LEGACY/OPEN.

### Inventory and transit times (unchanged by this commit)

| | active | Jeong / MARS | experiment |
|---|---|---|---|
| `V_channels` | 0.532836 m³ | — | — |
| `V_120_03_active` | 0.003055 m³ (LEGACY) | unresolved | — |
| `V_190_01_active` | 0.003055 m³ (LEGACY) | unresolved | — |
| `V_core_active` | 0.538946 m³ | — | — |
| plena (outside core) | 0.074645 m³ × 2 | — | — |
| `V_downcomer` | 0.277270 m³ | — | — |
| `V_pipes` | 0.202683 m³ | — | — |
| `V_pumpBowl` / `V_hxShell` | 0.150 / 0.266 m³ | — | — |
| `V_loop` | 1.045243 m³ | — | — |
| `tau_core` | 7.216 s | 9.56 s | — |
| `tau_loop` | 13.994 s | 16.14 s | — |
| `tau_total` | 21.210 s | 25.63 s | 25.2 s |

Comparison only. No geometry was adjusted toward the right-hand columns.

### Verification asserts

`EXPECTED_MISMATCH_DURING_PARTIAL_GEOMETRY_BASELINE`. The failures listed in Phases 4 and 5
stand unchanged and **no tolerance was widened**: `Steady_LoopBalance` (τ_system 21.21 s vs
25.63 ± 0.15 s), `Properties_TransitTime` (implied density +34.0 % vs ±5 %),
`Analytic_DriftReactivity` (1.49 / 10.12 pcm vs 0.9 ± 0.2 / 6.7 ± 0.5 pcm), and
`Transient_DriftReactivity` (forced-circulation drift 269.9 pcm vs 228.4, `tol_rho_pcm = 8`).
They are the intended output of a hardware baseline that is not fitted to the benchmark.

### Open items

- **O-12** narrowed, not closed: the boundary-node *definition* is settled; the *physical*
  volumes of 120-03 and 190-01 remain OPEN pending an independent flow-area source.
- **O-17** closed as a classification task: every loop parameter now carries a provenance tag.
  The underlying uncertainty is unchanged and is now explicit rather than absorbed.
- **O-13**, **O-14**, **O-15**, **O-16** unchanged.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain in this environment. Diagnostics computed by hand
outside Modelica from the same expressions now in the record; `Data/Geometry.mo` and
`Components/ReactorCore.mo` checked for Modelica string and comment balance.

---

## Phase 7 — O-13: reference-density decoupling

**Scope:** density *roles*, not density *values in geometry*. No physical volume was rescaled.

```
O-13 RESOLUTION:
The geometry/inventory reference density was migrated from the
legacy ORNL-TM-4865/Compere value to the active Cantor property model.
No physical volume was rescaled.
Pump-density dependencies were audited and separated from the geometry
reference density wherever required.
Changes in mass and transit time are derived consequences of the new
property model, not geometry fitting.
Jeong-equivalent O-12 diagnostics were recomputed with the Cantor density
but remain non-physical and inactive.
```

### Dependency graph, audited before any value changed

```
d_fuel_ref  (was 2249.3, ORNL-TM-4865)
 ├─ m_fuel_core_model / m_fuel_loop_model ......... KEEP      (inventory reporting)
 ├─ err_m_core / err_m_loop ....................... KEEP
 ├─ tau_core_nominal / tau_loop_nominal / system .. KEEP
 ├─ V_flow_ref -> A_190_01_JeongEq -> V_190_01_JeongEq ... KEEP (O-12 diagnostics)
 ├─ V_core_JeongEq -> V_120_03_JeongEq ............ KEEP
 ├─ V_flow_pump_nominal ........................... DECOUPLE  -> d_pump_ref
 ├─ P_pump_hydraulic .............................. DECOUPLE  -> d_pump_ref
 ├─ tau_pump_hyd_nominal .......................... DECOUPLE  -> d_pump_ref
 └─ J_pump ........................................ DECOUPLE  -> d_pump_ref

PrimarySystem.density_ref = Medium_fuel.density(p_system, T_start=908 K)
 ├─ pump.d_nominal ................................ ALREADY OVERRIDDEN
 └─ tau_core / tau_loop (reported at run time) .... ALREADY OVERRIDDEN

PartialFuelPump.d_nominal = 2242 ................... LEGACY ONLY (standalone default)
```

**The finding that shaped the fix:** the four pump quantities in `Data/Geometry.mo` are read by
nothing. `FuelPump_Dynamics` computes its own `tau_hyd_nominal` and `J` from the `d_nominal` it
is handed, and `PrimarySystem` hands it `density_ref`, evaluated from `Medium_fuel`. So:

> System-level pump density is already evaluated from Medium_fuel,
> so Geometry.d_fuel_ref is not the active pump density during PrimarySystem simulation.

The coupling was real inside the record and had **zero** effect on any simulation.

### What changed

| | before | after |
|---|---|---|
| `d_fuel_ref` | `2249.3` hard-coded | `MSRE.Media.FuelSalt.Utilities.d_T(T_zeroPower)` = **2196.5143** |
| `d_pump_ref` | did not exist | `MSRE.Media.FuelSalt.Utilities.d_T(T_zeroPower)` = **2196.5143** |
| `d_fuel_ref_legacy_Compere` | did not exist | `2249.3`, LEGACY, connected to nothing |
| `PartialFuelPump.d_nominal` default | 2242 (Compere @ 922 K) | 2188.646 (Cantor @ 922 K) — standalone default only |

`d_fuel_ref` and `d_pump_ref` evaluate to the same number today. **The separation is structural,
not numerical**: a later change to one cannot move the other. Saying otherwise would overstate
what this commit bought.

### Derived changes — inventory and transit time

| Quantity | Before | After Cantor | Δ |
|---|---:|---:|---:|
| `d_fuel_ref` | 2249.3 | **2196.5143** | −2.347 % |
| `m_fuel_core_model` | 1212.25 kg | **1183.80 kg** | −2.35 % |
| `m_fuel_loop_model` | 2351.07 kg | **2295.89 kg** | −2.35 % |
| `m_fuel_total_model` | 3563.32 kg | **3479.69 kg** | −2.35 % |
| `tau_core_nominal` | 7.2158 s | **7.0464 s** | −2.35 % |
| `tau_loop_nominal` | 13.9944 s | **13.6660 s** | −2.35 % |
| `tau_system_nominal` | 21.2102 s | **20.7125 s** | −2.35 % |
| `V_flow_ref` | 0.074690 m³/s | **0.076485 m³/s** | +2.40 % |
| `A_190_01_JeongEq` | 1.036322 m² | **1.061227 m²** | +2.40 % |
| `V_190_01_JeongEq` | 0.065806 m³ | **0.067388 m³** | +2.40 % |
| `V_core_JeongEq` | 0.714035 m³ | **0.731195 m³** | +2.40 % |
| `V_120_03_JeongEq` | 0.115393 m³ | **0.130971 m³** | **+13.50 %** |

`V_120_03_JeongEq` moves furthest because it is a difference of two larger numbers. It is now
**169 %** of the whole assumed lower plenum (was 148 %), and `V_190_01_JeongEq` is **22.1×** the
legacy boundary-node volume (was 21.5×) and 87 % of the assumed upper plenum. Classification
unchanged: REFERENCE / BENCHMARK-EQUIVALENT / NOT PHYSICAL / NOT ACTIVE. Nothing was connected
to `V_*Plenum_core`.

Error metrics against Jeong widen, as they must when the density falls and the volumes do not:

| | paper | active | before | after |
|---|---:|---:|---:|---:|
| `err_m_core` | — | 1184 vs 1606 kg | −24.5 % | **−26.3 %** |
| `err_m_loop` | — | 2296 vs 2712 kg | −13.3 % | **−15.3 %** |
| circulating | 4318 kg | 3480 kg | −17.5 % | **−19.4 %** |
| τ_core / τ_loop / τ_total | 9.56 / 16.14 / 25.63 s | 7.05 / 13.67 / 20.71 s | — | −26.3 / −15.3 / −19.2 % |

Measured system transit time 25.2 s. Comparison only — no geometry was adjusted.

One consistency gain worth noting: the drift-reactivity figures reported in Phases 4–6 were
already computed at the Cantor density, while the record's own `tau_*_nominal` were still at
2249.3. Those two now agree.

### Pump diagnostics — `DERIVED_CHANGE_FROM_DENSITY_ONLY`

| Quantity | Before | After | Effect on the simulation |
|---|---:|---:|---|
| `V_flow_pump_nominal` | 0.074690 m³/s | 0.076485 m³/s | **none** — diagnostic |
| `P_pump_hydraulic` | 22.407 kW | 22.945 kW | **none** — diagnostic |
| `tau_pump_hyd_nominal` | 230.572 N·m | 236.113 N·m | **none** — diagnostic |
| `J_pump` | 7.5924 kg·m² | 7.7749 kg·m² | **none** — diagnostic |

All four move by exactly +2.403 %, the inverse of the density change, and by nothing else. No
pump parameter was retuned to compensate. `tau_pump_shaft = 4.0 s` — the single fitted pump
quantity, and the one that actually sets the transients — is untouched, so every pump speed
history is unchanged.

### Verification asserts

`EXPECTED_MISMATCH_DURING_PARTIAL_GEOMETRY_BASELINE`, **no tolerance modified**:

| Model | Assert | Before | After |
|---|---|---:|---:|
| `Steady_LoopBalance` | τ_system vs 25.63 ± 0.15 s | 21.21 s | **20.71 s** |
| `Properties_TransitTime` | implied vs Compere density, ±5 % | +34.0 % | unchanged (calls `d_Compere` directly) |
| `Analytic_DriftReactivity` | 0.9 ± 0.2 / 6.7 ± 0.5 pcm | 1.49 / 10.12 | unchanged (calls `d_Compere` directly) |
| `Transient_DriftReactivity` | 228.4 pcm, tol 8 | 269.9 pcm | unchanged (already at Cantor) |

### Open items

- **O-13 closed.** Roles separated, active reference on the property model, legacy preserved.
- **O-18 (new).** `Verification/Analytic_DriftReactivity.mo:29` and `Properties_TransitTime.mo`
  still call `MSRE_Properties.d_Compere` directly, so two verification models now run on a
  density the library does not use. Deliberately not touched here — §14 forbade modifying the
  verification models in this commit — but the double standard should be closed next.
- **O-12** (120-03 / 190-01 physical volumes), **O-14** (failing asserts), **O-15**
  (`dz_channels`), **O-16** (HX geometry + calibration), **O-17** (unsourced loop dimensions)
  unchanged.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain, no MSL/TRANSFORM installation. Every number above
was computed by hand outside Modelica from the expressions now in the record. These are hand
calculations, not compile or simulation results. Edited files were checked for Modelica string
and comment balance.

---

## Phase 8 — O-18: verification density baseline unification

```
O-18 RESOLUTION:
Verification density references were aligned with the active Cantor
fuel-salt property model.
Properties_TransitTime now treats Cantor as ACTIVE and Compere/legacy
as reference comparisons.
Analytic_DriftReactivity uses Cantor for the active transit-time and
drift-reactivity calculation.
No geometry, pump, kinetics, experiment input, or assertion tolerance
was modified.
Any remaining benchmark mismatch is therefore no longer attributable
to a Compere-vs-Cantor verification inconsistency.
```

### Which function, and why

Two Cantor implementations exist: `Media.FuelSalt.Utilities.d_T` (the medium's own) and
`Media.MSRE_Properties.d_Cantor` (a restatement for provenance documentation). Both verification
models now call **`FuelSalt.Utilities.d_T`** — same source of truth as the active medium, and as
`Data.Geometry.d_fuel_ref` since O-13. `MSRE_Properties.d_Cantor` duplicates the formula, so
using it would have created a second path that could silently diverge.

### Density dependency, checked against the code rather than assumed

Both models compute `tau = rho*V/m_flow`. The benchmark states a **mass** flow rate (168 kg/s;
1.46 and 4.45 kg/s for natural circulation), so a density is genuinely required and switching
the baseline moves every transit time. Two quantities are density-*free* and did not move:
`d_implied_repo = m_core/V_channels` (reported mass over hardware volume), and the forced-
circulation drift reactivity and `Beta_circulating`, which use the paper's reported transit
times directly.

### Transit-time comparison (active geometry, 908 K)

| Density | rho | tau_core | tau_loop | tau_total | drift |
|---|---:|---:|---:|---:|---:|
| **Cantor (ACTIVE)** | **2196.514** | **7.046 s** | **13.666 s** | **20.713 s** | **269.9 pcm** |
| Compere (reference) | 2249.322 | 7.216 s | 13.995 s | 21.210 s | 267.2 pcm |
| legacy (reference) | 2063.097 | 6.618 s | 12.836 s | 19.454 s | 277.0 pcm |
| *Jeong (MARS)* | *not published* | *9.56 s* | *16.14 s* | *25.63 s* | *228.4 pcm* |

### Drift comparison

| Case | Cantor (ACTIVE) | Compere (reference) | Jeong target |
|---|---:|---:|---:|
| forced circulation (paper τ, density-free) | 228.35 pcm | 228.35 pcm | 228.4 pcm |
| natural circulation, 1.46 kg/s | **1.562 pcm** | 1.492 pcm | 0.9 ± 0.2 pcm |
| natural circulation, 4.45 kg/s | **10.493 pcm** | 10.123 pcm | 6.7 ± 0.5 pcm |

### The point of the exercise

**The benchmark mismatch was never a Compere-versus-Cantor question.** The two correlations
differ by 2.4 %; the core transit time is out by 26 % and the natural-circulation drift by 74 %
and 57 %. Both natural-circulation cases fail at *either* density. Unifying the baseline did not
cause the failures and does not cure them — it removes an explanation that was never doing any
work, so the residual is now unambiguously the `PARTIAL_GEOMETRY_BASELINE`.

### Assertion status — no tolerance touched

| Model | Assert | Before (Compere) | After (Cantor) |
|---|---|---:|---:|
| `Properties_TransitTime` | implied density, ±5 % | +34.0 % FAIL | **+37.2 % FAIL** |
| `Properties_TransitTime` | active closer than legacy | 34.0 < 46.1 PASS | **37.2 < 46.1 PASS** |
| `Analytic_DriftReactivity` | forced drift, 228.4 ± 0.5 pcm | 228.35 PASS | 228.35 PASS (density-free) |
| `Analytic_DriftReactivity` | `Beta_circulating` 0.0045 ± 1e-4 | 0.004497 PASS | 0.004497 PASS (density-free) |
| `Analytic_DriftReactivity` | nat. circ. 0.9 ± 0.2 / 6.7 ± 0.5 | 1.49 / 10.12 FAIL | **1.56 / 10.49 FAIL** |

`EXPECTED_MISMATCH_DURING_PARTIAL_GEOMETRY_BASELINE`. No tolerance was widened, no assertion
deleted or downgraded to a warning. O-14 remains the place where that is decided.

### Repository-wide audit

| Location | Match | Class | Action |
|---|---|---|---|
| `Verification/Properties_TransitTime.mo` | `d_Compere`, `d_legacy` | VERIFICATION | **fixed** — Cantor active, both retained as reference |
| `Verification/Analytic_DriftReactivity.mo` | `d_Compere(922)` | VERIFICATION | **fixed** — Cantor active, Compere kept as diagnostic |
| `Data/Geometry.mo:46` | `d_fuel_ref_legacy_Compere = 2249.3` | LEGACY REFERENCE | correct as is |
| `Media/MSRE_Properties.mo` | `d_Compere`, `d_legacy` functions, `2575 − 0.513` | LEGACY REFERENCE | correct as is — this is the provenance package |
| `Media/FuelSalt/Utilities/d_T.mo` | `2575 − 0.513`, `2242` in prose | DOCUMENTATION | out of scope, not modified |
| `Data/Geometry.mo` prose | `2249.3` in four doc passages | DOCUMENTATION | historical narrative, correct as is |
| `docs/PHASE_LOG.md` | many | DOCUMENTATION | historical record, appended only |
| `Data/PrecursorGroups/U235_6group.mo:18` | `0.5134` | OTHER | false positive — a half-life |

**No ACTIVE MODEL path outside the two verification files still reads a Compere or legacy
density.** No out-of-scope file was modified.

### Open items

- **O-18 closed.**
- **O-14** is now the sharpest one: three assertions fail and their tolerances are untouched by
  policy. They need to be restated as reported diagnostics or given hardware-consistent targets.
- **O-12** (120-03 / 190-01 physical volumes) is the root cause of all three failures.
- **O-15**, **O-16**, **O-17** unchanged.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain, no MSL/TRANSFORM installation. `checkModel` and both
verification models were **not** run. Every number above is a hand calculation performed outside
Modelica from the expressions now in the files; they are not compile or simulation results. Both
edited `.mo` files were checked for Modelica string and comment balance.

---

## Phase 9 — O-12B: physical reconstruction of the core-boundary plenum nodes

```
O-12B — PHYSICAL RECONSTRUCTION OF CORE-BOUNDARY PLENUM NODES
Jeong defines Volumes 120-03 and 190-01 as the lower and upper
boundaries of the reactor core.
The previous 0.003055 m3 values are legacy inventory-derived values
and are not accepted as physical provenance.
ORNL/INL source geometry was reviewed to identify physical regions
corresponding to those MARS control volumes.
No benchmark transit-time fitting was used.
Any active replacement is based only on independently sourced geometry.
```

**Decision: KEEP OPEN. No active geometry value changed. Documentation only.**

### A. Source findings

**Access limitation, stated first because it governs everything below.** Every primary and
secondary PDF host is unreachable from this environment — `info.ornl.gov`,
`publications.anl.gov`, `www.osti.gov`, `mooseframework.inl.gov` and `moltensalt.org` all return
`EGRESS_BLOCKED` to WebFetch and a proxy 403 to curl. ORNL-TM-728, ORNL-TM-730 and ORNL-TM-3229
could **not** be opened. Everything below is as rendered by a search index from the ANL SAM MSRE
model report and the ORNL MSRE TRANSFORM status report: **secondary, unverified, and with no
table, figure or page number attached.**

| Quantity | Reported value | Attributed to | Definition class | Usable as active? |
|---|---|---|---|---|
| core height | 1.6637 m (65.5 in) | ANL SAM MSRE model | code-model 1-D | no |
| lower plenum height | 0.12954 m (5.1 in) | ANL SAM MSRE model | code-model 1-D | no |
| upper plenum height | 0.21336 m (8.4 in) | ANL SAM MSRE model | code-model 1-D | no |
| lower plenum flow area / Dh | 1.71 m² / 1.47 m | ANL SAM MSRE model | code-model, **porosity 1.0** | no |
| upper plenum fluid volume | 11.34 ft³ = 0.32111 m³ | ORNL MSRE TRANSFORM report | unclear | no |
| core radius / porosity | 0.70485 m / 0.225 | ANL SAM MSRE model | R-Z porous equivalent | no — excluded by policy |
| lower plenum internals | 48 anti-swirl vanes, main support grid, horizontal graphite lattice bars; central region has no bars | INL VTB lower-plenum CFD | qualitative | — |
| lattice/stringer detail | 2.642 cm holes housing 2.54 cm dowels at the stringer lower end | INL VTB | hardware | — |

### B. Physical mapping

**120-03** — the top slice of the lower plenum, immediately below the channel entrance. The
physical region is the lower vessel head plus 48 anti-swirl vanes, the main support grid, and
the horizontal graphite lattice bars the stringers dowel into; the salt reaches the channels
through the gaps between those bars, which carry most of the core pressure drop, and the central
lattice has no bars at all. **No axial height, open flow area or fluid volume was found in any
accessible source.** The only area figure available (SAM's 1.71 m², the full vessel bore at
porosity 1.0) explicitly ignores those structures, so it is an upper bound on an open area, not
a fluid volume. **OPEN.**

**190-01** — the bottom slice of the upper plenum, immediately above the channel exit. Its
length is solid (Jeong, 0.0635 m = 2.5 in); the missing piece is an independent flow area.

### C. Derived geometry — candidates evaluated, none adopted

| Candidate area for 190-01 | A | V = A × 0.0635 | Verdict |
|---|---:|---:|---|
| reactor vessel bore (58 in) | 1.70456 m² | 0.108240 m³ | ignores the core container wall |
| core container bore (55.5 in) | 1.56079 m² | 0.099110 m³ | ignores displaced structure |
| SAM upper plenum mean (0.32111/0.21336) | 1.50503 m² | 0.095569 m³ | unverified; plenum is domed, not prismatic |
| *A_190_01_JeongEq* | *1.06123 m²* | *0.067388 m³* | **excluded — derived from a MARS result** |

The three physical candidates span 0.0956–0.1082 m³ and disagree with the Jeong-equivalent
figure by 42–61 %. Picking whichever landed nearest 1.06123 m² would be benchmark fitting with
extra steps. Neither `V_lowerPlenum/3` nor `V_upperPlenum/3` was used: nothing establishes that
the three nodes are equal-volume, and Jeong's own 2.5 in is not one third of the 8.4 in upper
plenum (that would be 2.8 in).

### D. Active-model decision — **KEEP OPEN**

Against the four conditions in the task:

| Condition | 120-03 | 190-01 |
|---|---|---|
| 1. independent source exists | **no** | length yes, area **no** |
| 2. geometry definition unambiguous | **no** | **no** |
| 3. MARS-node ↔ physical-region mapping explicable | qualitative only | partial |
| 4. not a transit-time back-calculation | yes | yes |

Conditions 1–3 fail. `V_lowerPlenum_core` and `V_upperPlenum_core` stay at 0.003055 m³ with
their `LEGACY/OPEN` tag, and their description strings now record that O-12B looked and did not
find. Nothing was connected to `V_190_01_JeongEq`.

### E. Impact — none

No active value changed, so `V_core` 0.538946 m³, `V_loop` 1.045243 m³, core mass 1184 kg, loop
mass 2296 kg, τ_core 7.046 s, τ_loop 13.666 s, τ_system 20.713 s, forced drift 269.9 pcm and
natural-circulation drift 1.562 / 10.493 pcm are all unchanged. No assertion tolerance was
touched and no assertion changed state.

### F. Remaining uncertainty, and the one genuinely new result

The useful output of O-12B is not about the boundary nodes at all. **This record assumes
0.0777 m³ for each plenum total; the reviewed figures put the lower plenum near 0.2215 m³ and
the upper plenum near 0.3211 m³ — 2.9× and 4.1× larger.** Even discounted for the porosity-1.0
treatment, that is independent support for the first of the two readings offered under O-12:
the MARS plena are much larger than assumed here, and the missing circulating inventory is
more likely hiding in `V_lowerPlenum` / `V_upperPlenum` than in the channel geometry. Those are
O-17 scope and were deliberately not touched.

Two definition mismatches recorded alongside: the SAM core height 1.6637 m is 2.34 % longer
than the 1.6256 m used here, and the SAM core salt flow area 0.3512 m² is 7 % larger than the
0.32778 m² that 1140 channels of documented cross-section give. Neither adopted — both are R-Z
porous-medium equivalents, excluded by policy.

**What would close O-12B:** ORNL-TM-728 (reactor vessel, core support structure, flow
distributor), ORNL-TM-730 (core boundary) and ORNL-TM-3229 (core entrance hydraulics) read
directly, or the Jeong MARS input deck. If the PDFs are supplied locally, or egress is opened
to those hosts, the review can be redone against primary text with table and page numbers.

### Open items

- **O-12B** open. **O-12** unchanged and still the root cause of the failing assertions.
- **O-14**, **O-15**, **O-16**, **O-17** unchanged. O-17 gains a concrete lead: the plenum
  totals look far too small.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain. No computation in the library changed, so no
re-evaluation was needed; the candidate arithmetic above was done by hand outside Modelica.
`Data/Geometry.mo` was checked for Modelica string and comment balance.

---

## Phase 10 — O-17: whole-plenum fuel-salt volumes

```
O-17 — WHOLE PLENUM FLUID VOLUMES

Previous active values:
  lower = 0.0777 m3
  upper = 0.0777 m3
  status = unsupported assumptions

Reference:
  ORNL/TM-2019/1359
  Status Report on the MSRE TRANSFORM Model for Thermal-Hydraulic Benchmarking

Reported values:
  lower-plenum fluid volume = 12.24 ft3 = 0.346598 m3
  upper-plenum fluid volume = 11.34 ft3 = 0.321113 m3

The report attributes the MSRE volume information to ORNL-4865.

Decision:
  Promote whole-plenum total volumes to REFERENCE.

Do NOT infer individual Jeong MARS node volumes from these totals.
Volumes 120-03 and 190-01 remain O-12B OPEN.
Whole-plenum axial heights remain assumptions/open.
```

**Decision: CLOSED / REFERENCE for the two volumes. The two plenum heights stay OPEN.**

### A. What changed

| Parameter | Before | After | Class before | Class after |
|---|---:|---:|---|---|
| `V_lowerPlenum` | 0.0777 m³ | **0.346598 m³** (4.46×) | ASSUMPTION | **REFERENCE** |
| `V_upperPlenum` | 0.0777 m³ | **0.321113 m³** (4.13×) | ASSUMPTION | **REFERENCE** |
| `L_lowerPlenum` | 0.30 m | 0.30 m | ASSUMPTION | ASSUMPTION / OPEN |
| `L_upperPlenum` | 0.30 m | 0.30 m | ASSUMPTION | ASSUMPTION / OPEN |

Conversion with the exact factor 1 ft³ = 0.028316846592 m³:
12.24 × 0.028316846592 = 0.34659820 → **0.346598 m³**;
11.34 × 0.028316846592 = 0.32111304 → **0.321113 m³**.

No other active parameter was touched. `L_downcomer`, the three pipe lengths, `V_pumpBowl`,
`V_hxShell`, `V_lowerPlenum_core`, `V_upperPlenum_core`, the density and the mass flow rate are
all unchanged — none of them was allowed to move to absorb the change.

### B. What O-17 explicitly does **not** do

- **O-12B stays OPEN.** `V_lowerPlenum_core` (MARS 120-03) and `V_upperPlenum_core`
  (MARS 190-01) keep 0.003055 m³ with their `LEGACY/OPEN` tag. A whole-plenum total fluid
  volume and a single MARS control volume inside that plenum are not the same quantity, and
  the report gives no nodalization. Nothing was divided by three, and nothing was connected to
  `V_190_01_JeongEq`.
- **O-14 untouched.** No assertion deleted, no tolerance widened, no benchmark target moved.
  The three failing asserts are left exactly as they were, and the effect of O-17 on them is
  reported below rather than engineered away.
- **The plenum heights stay OPEN.** The source gives fluid volumes, not axial extents. The
  `L_*Plenum_core` expressions therefore remain a legacy uniform-bore diagnostic, explicitly
  *not* an independently reconstructed physical MARS-node length; their descriptions now say so.
- The earlier **~0.2215 m³** lower-plenum figure quoted under O-12B was a secondary SAM
  porous-medium estimate (1.71 m² at porosity 1.0 over 0.12954 m). It is neither active nor a
  reference value; O-17 supersedes it with 12.24 ft³ = 0.346598 m³. The O-12B section in
  `Data/Geometry.mo` now says this in place, so the figure cannot be read as an active value.

### C. Derived quantities — recomputed, not fitted

| Quantity | Before | After |
|---|---:|---:|
| `V_core` | 0.538946 m³ | 0.538946 m³ (unchanged) |
| `V_loop` | 1.045243 m³ | **1.557554 m³** (+49.0 %) |
| `V_total` | 1.584189 m³ | **2.096500 m³** (+32.3 %) |
| `tau_core_nominal` | 7.046 s | 7.046 s (unchanged) |
| `tau_loop_nominal` | 13.666 s | **20.364 s** |
| `tau_system_nominal` | 20.713 s | **27.411 s** (paper 25.63 s) |
| `m_fuel_core_model` | 1184 kg | 1184 kg (unchanged) |
| `m_fuel_loop_model` | 2296 kg | **3421 kg** |
| `err_m_core` | −26.29 % | −26.29 % (unchanged) |
| `err_m_loop` | −15.33 % | **+26.17 %** |
| circulating inventory vs 4318 kg | 3480 kg, −19.41 % | **4605 kg, +6.66 %** |
| `L_lowerPlenum_core` (diagnostic) | 0.011795 m | 0.002644 m |
| `L_upperPlenum_core` (diagnostic) | 0.011795 m | 0.002854 m |
| `V_120_03_JeongEq` as a share of the whole lower plenum | 169 % | 37.8 % |
| `V_190_01_JeongEq` as a share of the whole upper plenum | 87 % | 21.0 % |

Delayed-neutron transport quantities, computed from the same expressions the library uses
(paper Eq. 8, `Functions.driftReactivity`):

| Case | Before | After | Paper |
|---|---:|---:|---:|
| natural circulation, 1.46 kg/s | 1.5619 pcm | **1.5619 pcm** | 0.9 pcm |
| natural circulation, 4.45 kg/s | 10.4928 pcm | **10.5004 pcm** | 6.7 pcm |
| forced circulation at this record's own τ | 269.9 pcm | **287.7 pcm** | 228.4 pcm |
| forced circulation at the paper's τ (density- and volume-free) | 228.35 pcm | 228.35 pcm | 228.4 pcm |

The natural-circulation figures barely move because at 1.46 and 4.45 kg/s both transit times
are already long compared with every precursor half-life, so Eq. 8 has saturated.

### D. Assertion status — `EXPECTED_MISMATCH_DURING_PARTIAL_GEOMETRY_BASELINE`

| Model | Assert | Before | After |
|---|---|---:|---:|
| `Steady_LoopBalance` | τ_system vs 25.63 ± 0.15 s | 20.713 s FAIL (−4.92 s) | **27.411 s FAIL (+1.78 s)** |
| `Analytic_DriftReactivity` | nat. circ. 0.9 ± 0.2 / 6.7 ± 0.5 pcm | 1.5619 / 10.4928 FAIL | **1.5619 / 10.5004 FAIL** |
| `Properties_TransitTime` | implied density ±5 % | +37.2 % FAIL | +37.2 % FAIL (unchanged — depends on `V_channels` only) |
| `Properties_TransitTime` | active closer than legacy | PASS | PASS (unchanged) |
| `Analytic_DriftReactivity` | forced drift 228.4 ± 0.5 pcm | PASS | PASS (uses the paper's τ) |
| `Analytic_DriftReactivity` | `Beta_circulating` 0.0045 ± 1e-4 | PASS | PASS |

No tolerance was modified and no assertion was deleted or downgraded. The τ_system assert is
closer to its target than before, but that is a by-product of adopting a sourced volume and not
the reason for adopting it; O-14 remains the place where the three failures are decided.

### E. The substantive result

The old picture was a core 26.3 % short and a loop 15.3 % short, adding to a 19.4 % shortfall.
The new one is a core **26.3 % short** and a loop **26.2 % long** — nearly equal and opposite —
with the total 6.7 % long. That is what a control-volume boundary drawn in a different place
looks like: salt that MARS counts inside its core-boundary nodes and this record counts as
plenum. It is the second of the two readings recorded under O-12, and O-17 is the evidence that
the first one (plena too small) was real and is now spent.

Nothing was moved to make the two sides meet. Settling the remainder needs the MARS node
volumes — O-12B, still OPEN.

### F. Scope

Modified: `Data/Geometry.mo`, `docs/PHASE_LOG.md`.

Not modified: fuel-salt property correlations, pump model, heat exchanger model, kinetics,
experiment inputs, channel geometry, downcomer geometry, pipe lengths, and the O-14 assertion
policy. `Components/ReactorCore.mo` carries `V_lowerPlenum = V_upperPlenum = 0.0777` as
*component defaults*; `Systems/PrimarySystem.mo` overrides both from `Data.Geometry`, so no
active model path reads them. They are out of scope for this commit and are recorded here as a
follow-up.

Two verification documentation tables still quote the pre-O-17 loop figures
(`Properties_TransitTime.mo` line 183: 13.666 s / 20.713 s / 269.9 pcm;
`Analytic_DriftReactivity.mo` line 120: 1.56 / 10.49 pcm). Prose only — no assertion, no active
value — and out of scope here because §8 puts the verification models off limits. Follow-up.

### Open items

- **O-17 closed** for the two whole-plenum volumes; the two plenum **heights** remain OPEN.
- **O-12B** open, unchanged, and now the only route to the remaining ±26 % split.
- **O-14** untouched and still the sharpest item.
- **O-15**, **O-16** unchanged.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain, no MSL/TRANSFORM installation. `checkModel` was not
run and no verification model was simulated. Every number above is a hand calculation performed
outside Modelica from the expressions now in the record. `Data/Geometry.mo` was checked for
Modelica string, comment and HTML-tag balance, and the diff was checked to confirm that the two
plenum volumes are the only active parameters that changed.

---

## Phase 10 — Non-pump baseline: equal-volume plenum nodes and a single Gnielinski closure

**Scope:** fuel-salt property (unchanged), core geometry (unchanged), plenum nodalization, core
and heat-exchanger heat transfer, and the verification/documentation that follows. The pump,
the kinetics, the precursor data, the external-loop pipe lengths and every assertion tolerance
are untouched.

### Decisions taken

| # | Decision | Rationale |
|---|---|---|
| 28 | `V_lowerPlenum_core = V_lowerPlenum/nLP`, `V_upperPlenum_core = V_upperPlenum/nUP` | Replaces the 0.003055 m³ inventory-balance residue with a subdivision of a *referenced* volume. Tagged **ASSUMPTION / DERIVED FROM REFERENCE**, never PHYSICAL: nothing published says the three nodes are equal, and Jeong's 0.0635 m for 190-01 is not one third of any plenum height here. |
| 29 | 0.003055 m³ retired to `V_plenumCore_legacy`, diagnostic only | Its derivation (reported 1606 kg ÷ old density − old channel volume) is benchmark fitting. |
| 30 | `ClosureRelations.Nus_MoltenSalt` becomes **Gnielinski**, used by the core channels and both HX sides | One correlation, no calibration coefficient. `Nu_floor` and `f_enhance` inputs deleted. |
| 31 | `f_shellHT` and `Nu_floor_shell` kept in `Data.Geometry` as **LEGACY/DEPRECATED**, connected to nothing | Deleting them would break nothing but loses the record of what was calibrated. |
| 32 | The shell-side `L_char = D_tube_outer` modifier is removed | Gnielinski is a duct correlation; referring Nu to a different length than Re is formed with was part of the retired cross-flow hybrid. Both HX sides now use Dh consistently. |
| 33 | `Dh_shell = 0.05606 m` tagged **OPEN / TO BE REVIEWED**, not changed | INL gives 0.0209 m. Changing it in the same pass as the closure would confound two effects. O-16. |
| 34 | No sub-transitional correction added | Explicitly out of scope; see the blocker below. |

### B. Parameter changes

```
V_lowerPlenum_core   0.003055        -> 0.1155327 m3   (= 0.346598/3)
V_upperPlenum_core   0.003055        -> 0.1070377 m3   (= 0.321113/3)
L_lowerPlenum_core   0.002644        -> 0.1000000 m
L_upperPlenum_core   0.002854        -> 0.1000000 m
V_plenumCore_legacy  (new)           -> 0.003055 m3, diagnostic only
ReactorCore.V_lowerPlenum default  0.0777 -> 0.346598 m3
ReactorCore.V_upperPlenum default  0.0777 -> 0.321113 m3
Nus_MoltenSalt       Nu_floor + f*0.023*Re^0.8*Pr^0.4  -> Gnielinski
f_shellHT = 3.0, Nu_floor_shell = 10.0   -> LEGACY/DEPRECATED, unused
```

Unchanged as required: `nChannels_total` 1140, `H_channels` 1.6256 m, `w/h/r_channel`,
`A_channel` 2.875244e-4 m², `Dh_channel` 0.015851 m, `V_channels` 0.532836 m², the fuel-salt
correlations, every pump parameter, `f_area_hx` 1.0, and all assertion tolerances.

### C. Derived quantities

| Quantity | Before | After |
|---|---:|---:|
| `V_channels` | 0.532836 m³ | 0.532836 m³ |
| `V_core` | 0.538946 m³ | **0.755406 m³** |
| `V_loop` | 1.557554 m³ | **1.341094 m³** |
| `m_fuel_core_model` | 1184 kg | **1659.3 kg** |
| `m_fuel_loop_model` | 3421 kg | **2945.7 kg** |
| circulating | 4605 kg | 4605 kg (unchanged — salt moved between core and loop) |
| `tau_core_nominal` | 7.046 s | **9.877 s** |
| `tau_loop_nominal` | 20.364 s | **17.534 s** |
| `tau_system_nominal` | 27.411 s | 27.411 s |

### D. Jeong comparison

| | model | Jeong | Δ |
|---|---:|---:|---:|
| τ_core | 9.877 s | 9.56 s | **+3.31 %** |
| τ_loop | 17.534 s | 16.14 s | **+8.64 %** |
| τ_total | 27.411 s | 25.63 s | **+6.95 %** |
| core mass | 1659 kg | 1606 kg | +3.31 % |
| loop mass | 2946 kg | 2712 kg | +8.64 % |
| forced drift | **227.06 pcm** | 228.35 pcm | −1.29 pcm |

**This closeness is not a validation.** It is the consequence of an equal-volume subdivision
assumption meeting a referenced plenum volume; nothing was fitted, and equally nothing was
confirmed. τ_core landing 3 % from 9.56 s must not be reported as agreement.

### E. Heat-transfer implementation

```
Core uses Gnielinski:      YES
HX shell uses Gnielinski:  YES
HX tube uses Gnielinski:   YES
old Nu_floor active:       NO  (input deleted from the model)
old f_shellHT active:      NO  (parameter retained as LEGACY, connected to nothing)
```

### **BLOCKER — the core channels are laminar at rated flow**

At 168 kg/s the MSRE fuel channels run at **Re = 812** (0.233 m/s through a 15.85 mm hydraulic
diameter). Gnielinski is valid for Re ≳ 3000 and its `(Re − 1000)` factor turns negative below
1000, so it returns:

| Location | Re at rated flow | Pr | Gnielinski Nu | retired closure Nu |
|---|---:|---:|---:|---:|
| core fuel channel | **812** | 20.1 | **−3.99** | 20.6 |
| HX shell side | 8637 | 20.1 | 101.6 | 333.0 |
| HX tube side | 10510 | 15.8 | 112.2 | 118.7 |

**A negative Nusselt number is a negative heat transfer coefficient.** This is not confined to
natural circulation — it is the nominal, full-flow condition. As instructed, no low-Re
correction was added, so the core side of the closure is presently unusable for any thermal
result and the §20 steady-state checks (core ΔT, Q_core, Q_HX, energy balance) cannot be
produced from it. Recorded as **O-19**, and it needs a user decision.

The HX is unaffected on the correlation's own terms, but note the shell-side coefficient falls
by a factor of ~12 (22450 → 1812 W/m²K) once `f_enhance = 3` and `L_char = D_tube_outer` are
removed. That is the calibration being withdrawn, not an error.

### F. Remaining OPEN items

- **O-19 (new)** sub-transitional core-channel heat transfer — blocks all thermal results
- **O-12B** physical volume of MARS 120-03 and 190-01
- **O-16** HX shell-side hydraulic geometry (`Dh_shell` 0.05606 vs INL 0.0209 m)
- **O-17** external-loop pipe lengths, `L_downcomer`, `V_pumpBowl`, plenum axial heights
- **O-14** the failing assertions
- **O-15** `dz_channels` 1.626 m vs `H_channels` 1.6256 m
- pump validation (out of scope by instruction)

### G. Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain, no MSL/TRANSFORM installation. `checkModel`,
`translate` and the steady-state run were **not** performed. Every number above is a hand
calculation outside Modelica. Assertion states, with **no tolerance modified**:

| Assert | Value | Limit | State |
|---|---:|---:|---|
| `Steady_LoopBalance` τ_system | 27.411 s | 25.63 ± 0.15 | FAIL |
| `Properties_TransitTime` implied density | +37.2 % | ±5 % | FAIL |
| `Properties_TransitTime` active vs legacy | 37.2 < 46.1 | — | PASS |
| `Analytic_DriftReactivity` forced drift | 228.35 pcm | 228.4 ± 0.5 | PASS |
| `Analytic_DriftReactivity` Beta_circulating | 0.004497 | 0.0045 ± 1e-4 | PASS |
| `Analytic_DriftReactivity` nat. circ. low | 0.818 pcm | 0.9 ± 0.2 | **PASS** (was FAIL) |
| `Analytic_DriftReactivity` nat. circ. high | 6.199 pcm | 6.7 ± 0.5 | FAIL by 0.0009 pcm |

---

## Phase 11 — O-19: core laminar heat-transfer closure

### 1. Re re-verified from the code's own definitions

Nothing was adjusted to move the Reynolds number. Every input below is read from
`Data/Geometry.mo` and `Media/FuelSalt`.

```
A_channel   = w*h - (4-pi)*r^2            = 2.875244e-4 m2
perimeter   = 2(w+h) - 4r(2-pi/2)         = 0.072559 m
Dh_channel  = 4*A/P                       = 0.015851 m
A_flow_tot  = 1140 * A_channel            = 0.327778 m2
rho(908 K)  = 2553.3 - 0.562*(T-273.15)   = 2196.5143 kg/m3
mu(908 K)   = 8.4e-5*exp(4340/T)          = 1.000212e-2 Pa.s
v  = m_flow/(rho*A_flow_tot)              = 0.233343 m/s
Re = rho*v*Dh/mu = m_flow*Dh/(A_tot*mu)   = 812.24
Pr = cp*mu/k                              = 20.101
```

**VERIFIED.** `Dh = 0.015851 m` and `v = 0.2333 m/s` both follow from the geometry as defined;
the density cancels out of `Re` entirely. Reaching Re = 2300 would need 476 kg/s (2.83× rated)
or a viscosity 2.83× lower.

Incidental finding: the corner radius is exactly half the channel depth (0.00508 = 0.01016/2),
so the channel is an **obround/stadium**, not a rounded rectangle — the two short ends are
semicircles. The area and perimeter formulas already in the record are exact for that shape.

### 2. Power deposition path — traced

```
Nuclear/PointKinetics_DNPtransport -> kinetics.Qs
  -> PrimarySystem.mo:131   core.Qs_core = kinetics.Qs
    -> ReactorCore.mo:204   Qs_channels[r,k] = Qs_core[...]*(1 - f_graphiteHeating)
      -> ReactorCore.mo:165 channels[r].Q_gens = Qs_channels[r,:]
        -> CoreChannel.mo:108 pipe.InternalHeatGen = GenericHeatGeneration(Q_gens=Q_gens)
           == VOLUMETRIC HEAT SOURCE in each fuel-salt control volume
    -> ReactorCore.mo:205   Qs_channels_graphite = Qs_core[...]*f_graphiteHeating
      -> CoreChannel.mo:127 graphite.InternalHeatModel = GenericHeatGeneration
  plenum core nodes: ReactorCore.mo:216/221 Qs_LP, Qs_UP -> also volumetric
```

`f_graphiteHeating = 0` by default (`PrimarySystem.mo:42`, `ReactorCore.mo:68`), so **100 % of
the fission power enters the fuel salt as a volumetric source and none of it passes through the
convective closure.** Axial and radial shaping already exists via `SF_core` from
`Functions.corePowerShape`, with `sum(SF_core) = 1` — the structure section 7 of the request
asks for is already present and was not changed.

### 3. Blocker re-adjudicated — **Case A**

`Q_core`, core outlet temperature, core ΔT and the primary energy balance are
`Q = m_flow*cp*ΔT` and do **not** depend on the core Nusselt number. The earlier claim that
O-19 blocked all thermal results was **wrong** and is retracted. O-19 is re-scoped to:

> Core wall/graphite-to-fuel heat-transfer closure undetermined.

It sets the fuel-to-graphite temperature difference and hence the graphite temperature, which
matters for graphite thermal feedback and for the paper's `f_graphiteHeating` sensitivity — not
for bulk temperatures. A negative `h` was still not acceptable: with `q = h(T_w - T_f)` and
`h < 0` the graphite coupling becomes anti-restoring and the graphite temperature diverges.

### 4-6. Closure split

| Component | Closure | Model |
|---|---|---|
| core fuel channels | laminar / blend / Gnielinski | **`ClosureRelations.Nus_Core`** (new) |
| HX shell | Gnielinski | `ClosureRelations.Nus_MoltenSalt` |
| HX tube | Gnielinski | `ClosureRelations.Nus_MoltenSalt` |

```
Re < 2300          Nu = Nu_laminar (4.36)
2300 <= Re < 3000  Nu = (1-w)*Nu_laminar + w*Nu_Gnielinski,  w = x^2(3-2x), x = (Re-2300)/700
Re >= 3000         Nu = Nu_Gnielinski
```

The smoothstep weight and its first derivative vanish at both ends, so Nu is C¹ across the
window. **No multiplier, enhancement factor or Nusselt floor was added anywhere.**

`Nu_laminar = 4.36` (constant heat flux) rather than 3.66 (constant wall temperature), on the
evidence of the model's own boundary condition: the graphite annulus in `CoreChannel` is
adiabatic on its outer radius and both ends, and its only source is the `f_graphiteHeating`
share of fission power, so whatever it generates must leave through the salt interface — the
wall imposes a flux, not a temperature. Tagged:

```
ASSUMPTION / GENERIC LAMINAR CLOSURE
Used only as an interim closure for the 1-D TRANSFORM benchmark model.
Not an experimentally validated MSRE-specific heat-transfer correlation.
```

Deferred, and named as such in the model: obround-duct laminar correlation, MSRE-specific
treatment, Poppendiek effect and graphite–fuel coupling.

### 9. Comparison

| Parameter | Before | After | Reason |
|---|---:|---:|---|
| Core Re | 812 | 812 | unchanged — nothing was adjusted |
| Core Nu | **−3.99** | **4.36** | laminar branch replaces out-of-range Gnielinski |
| Core h [W/m²K] | **−251.8** | **275.1** | `Nu*k/Dh`, k = 1.0, Dh = 0.015851 |
| HX shell Re | 8637 | 8637 | unchanged |
| HX shell Nu | 101.57 | 101.57 | unchanged |
| HX shell h | 1811.7 | 1811.7 | unchanged |
| HX tube Re | 10510 | 10510 | unchanged |
| HX tube Nu | 112.23 | 112.23 | unchanged |
| HX tube h | 11684.3 | 11684.3 | unchanged |

Steady-state bulk energy balance — **hand calculation, not simulation**, and independent of
every Nusselt number above:

```
dT_core = Q_core/(m_flow*cp),  m_flow = 168 kg/s,  cp = 2009.66 J/(kg.K)
  Q = 10 MWth  -> dT = 29.62 K
  Q =  8 MWth  -> dT = 23.70 K
  reported dT = 28 K -> Q = 9.45 MWth
```

`Q_HX`, `Q_core − Q_HX` and the residual fraction need a solved secondary side and are
`BLOCKED_NOT_RUN`.

### O-19 STATUS

```
O-19 STATUS:
Core Re calculation:
  VERIFIED
Core flow regime:
  LAMINAR  (Re = 812 at rated flow; laminar under every simulated condition)
Core power deposition method:
  VOLUMETRIC HEAT SOURCE
  (CoreChannel.pipe.InternalHeatGen; f_graphiteHeating = 0 sends 100 % to the salt)
Is Gnielinski required for core bulk dT?:
  NO
Core thermal closure:
  Nus_Core - generic laminar Nu = 4.36 below Re 2300,
  smoothstep blend to Gnielinski over 2300-3000, Gnielinski above 3000
HX thermal closure:
  Gnielinski (Nus_MoltenSalt), shell and tube
O-19 classification:
  PARTIALLY CLOSED
Remaining limitation:
  The laminar constant is a generic circular-duct value, not an MSRE obround-channel
  correlation, and no entrance-length, Poppendiek or graphite-coupling effect is
  represented. It sets the graphite temperature, not the bulk fuel temperature, so
  it is not on the path to Q_core or core dT.
```

### Not modified

168 kg/s nominal flow, fuel-salt viscosity and density, channel count, channel area, hydraulic
diameter, core power, HX hydraulic diameter (`Dh_shell`, still O-16), `f_area_hx`, every pump
parameter, the kinetics and precursor data, and every assertion tolerance. No transit-time or
inventory value changed, so the assertion states of Phase 10 stand unchanged.

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain, no MSL/TRANSFORM. `checkModel`, `translate` and the
steady-state run were **not** performed. Every number in this entry is a hand calculation
outside Modelica; none is a simulation result. Edited files were checked for Modelica string
and comment balance.

---

## Phase 12 — O-15 closed, and a derived consequence of the plenum subdivision (O-20)

### O-15 — closed

`dz_channels` was a standalone 1.626 m while `H_channels` is 1.6256 m, a 0.4 mm inconsistency
left over from the pre-hardware geometry. It is now `final parameter dz_channels = H_channels`,
which is what `Components/ReactorCore.mo` already did by default. The elevation set still closes
exactly, because `dz_downcomer` is defined as minus the sum of the others; it absorbs the 0.4 mm.

### O-20 (new) — the plenum core nodes now carry 14.8 % of the fission source

`Functions/corePowerShape` applies one cosine over the whole core height and weights each cell
by its **volume**. That was harmless while the two plenum core nodes held 3.055 litres each. At
one third of the referenced plenum totals they hold 0.1155 and 0.1070 m³ — **65 times a channel
cell** — and the source shape moves with them:

| | nodes at 3.055 L | nodes at one third of a plenum |
|---|---:|---:|
| `SF` lower plenum node | 0.00201 | **0.07668** |
| `SF` upper plenum node | 0.00201 | **0.07104** |
| both together | **0.40 %** of core fission | **14.77 %** |
| `phi` at the plenum nodes | 0.355 | 0.501 |
| channel axial peak/average | 1.348 | 1.265 |
| plenum cell / channel cell volume | 1.7× | 65.0× |
| `L_core` seen by the cosine | 1.6311 m | 1.8256 m |

`sum(SF) = 1` and `sum(phi·V)/sum(V) = 1` still hold, so the normalisation is intact; what
changed is where the source sits.

**Nearly a seventh of the fission source is now placed in salt with no graphite around it.**
The plena are unmoderated, so the thermal flux there should be *lower* than in the channels
rather than comparable, and Jeong describes 120-03 and 190-01 as thin slices at the core
boundary — 0.0635 m for 190-01, against the 0.1 m the equal-volume assumption gives.

This is a **consequence of the equal-volume subdivision, surfaced rather than fixed.**
`corePowerShape` was not changed: correcting it means choosing a physical treatment — exclude
the plena from the moderated shape, weight them by a moderator-presence factor, or take the
shape from a transport calculation — and that is a modelling decision, not a cleanup. It also
feeds the kinetics through `phis_core`, so it moves the precursor weighting and the drift
results, not only the thermal field.

O-20 and O-12B are the same question from two sides: what those two nodes physically are.

### Open items

- **O-20 (new)** fission-source treatment of the unmoderated plenum core nodes — needs a decision
- **O-12B** physical volume of MARS 120-03 / 190-01 (blocked on source access)
- **O-19** residual: obround-duct laminar Nusselt number, entrance length, Poppendiek, graphite coupling
- **O-16** HX shell-side hydraulic geometry — the calibration coupling that blocked it is now
  gone, since `f_shellHT` and `Nu_floor_shell` are disconnected, so this is unblocked whenever
  a verified shell geometry is available
- **O-14** the failing assertions
- **O-17** unsourced loop dimensions
- **O-15 closed**

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain. The shape figures above were computed outside
Modelica by re-implementing `corePowerShape` exactly as written, with the record's own
`f_radial`, `A_channel`, `H_channels` and `f_axialExtrapolation = 1.2`. No assertion tolerance
was touched and no assertion changed state: `dz_channels` moves only `dz_downcomer`, and the
shape change affects the kinetics rather than any asserted transit time.

---

## Phase 13 — COMMON baseline consolidation before the benchmark branches

**Scope:** the shared layer only. No benchmark branch was touched, no geometry, property,
inventory or transit-time value moved, no assertion tolerance changed.

### 1-2. The two unmerged commits, reviewed and rebased onto `main`

`820fce9` and `5e18127` were sitting on a branch that `main` had left behind. Both cherry-pick
cleanly onto `dcc3b80`. Reviewed against the acceptance conditions:

| Condition | Status |
|---|---|
| no arbitrary correlation invented to make Nu positive | met — the laminar branch is the classical `Nu = 48/11` analytic constant, no free coefficient |
| correlation source stated | added — analytic circular-duct solution (4.364 uniform flux, 3.657 uniform temperature); Gnielinski, Int. Chem. Eng. 16 (1976) 359 |
| Reynolds range stated | added — laminar `Re < 2300`, Gnielinski `3000 < Re < 5e6`, `0.5 < Pr < 2000` |
| developed vs developing stated | **added, and it is the significant one — see below** |
| transitional handling stated | added — the blend is declared a *numerical interpolation*, not a transition model |
| HX kept on the turbulent correlation | met — `Nus_MoltenSalt` unchanged for both HX sides |
| 14.77 % kept as diagnostic only | met — quoted as error quantification, used nowhere as a factor |

**Thermal entrance length.** `Nu = 4.36` is the *fully developed* value, and the MSRE core is
not thermally developed anywhere along its length:

| Quantity | Value | vs the 1.6256 m channel |
|---|---:|---|
| hydrodynamic entry length `0.05·Re·Dh` | 0.644 m | 2.5 entry lengths — developed |
| thermal entry length `0.05·Re·Pr·Dh` | **12.94 m** | channel is **12.6 %** of it — developing throughout |
| Graetz number `(Dh/L)·Re·Pr` | 159 | entrance-dominated |

So 4.36 is a **baseline fully developed laminar approximation**, and the entry lengths above are
a **screening metric for the thermal-development assumption** based on conventional circular-duct
correlations - not the actual MSRE thermal entrance length. *(Corrected in Phase 39: this
paragraph previously called 4.36 a "lower bound with a known sign" and the "conservative"
choice. Both were withdrawn - the classical entrance result assumes a circular duct with a simple
wall condition and no volumetric heating, while this problem has volumetric heating in both media,
conjugate graphite conduction, and a coupled wall condition, so the direction of the departure is
not established.)* Adding an entrance correction is deferred rather than guessed at.

**Defect found and fixed while rebasing:** `820fce9` added `ClosureRelations/Nus_Core.mo` but
never added it to `ClosureRelations/package.order`, so the class would not have loaded.

### 3-4. O-20 resolved — fission source domain ≠ DNP domain

```
DNP inventory / transport domain : channel cells + both plenum core nodes
fission source domain            : active fuel channel cells only
```

`corePowerShape` gains `plenumFissionSource`, default **false**. The two plenum core nodes get
`SF = 0`, so `Qs = Q_fission·SF = 0` and `mC_sources = β/Λ·N·SF = 0` there, while
`mC_gens = mC_sources − λ·mC` keeps advection and decay running in them.

```
PLENUM_FISSION_SOURCE = 0
ASSUMPTION
```

Not a measurement: fission in the plena is not exactly zero, which is why Jeong counts 120-03
and 190-01 as core at all. No published statement of their source fraction exists, and between
a volume-weighted 14.8 % and zero, zero is the less unphysical. `plenumFissionSource = true`
restores the old treatment for sensitivity.

**Verification of the change (independent calculation, not simulation):**

| | volume-weighted | no plenum source |
|---|---:|---:|
| `sum(SF)` | 1.0000000000 | **1.0000000000** |
| `sum(φ·V)/sum(V)` — the kinetics normalisation | 1.0000000000 | **1.0000000000** |
| `SF` plenum lower / upper | 0.07668 / 0.07104 | **0 / 0** |
| `SF` channel max / min | 0.005776 / 0.000765 | 0.006777 / 0.000897 |
| `φ` channel max | 2.4567 | 2.8825 |
| ring-1 axial peak/average | 1.2654 | 1.2654 |
| fission power in the plena at 8 MW | 1181.8 kW | **0 kW** |

Both normalisations are exactly preserved. `Beta_eff_inst` divides by
`sum(φ_adj·φ·V) = sum(SF)·sum(V) = sum(V)`, which is unchanged, while its numerator
`sum(φ_adj·mC)` still contains the plenum precursor inventory — so the DNP domain keeps the
plena, as intended. `PrimarySystem.T_fuel_effective`, being flux-weighted, now excludes the
plena; that follows from there being no fission there and is the physically consistent result.

### 5. Physical geometry separated from spatial nodalization

New `Data/Nodalization/` with `Core1D` (1 group × 20, `f_radial = {1.0}`) and `Core2D`
(15 × 20, the existing profile). Both take `Data.Geometry` as a component and restate **no**
physical quantity — channel count, `f_axialExtrapolation` and everything else are read from it,
so a 1-D and a 2-D run can only differ in spatial representation.

`f_radial` is tagged **ASSUMPTION** in both places: it is a J0 shape with 25 % reflector saving,
**not** the paper's Serpent tabulation, which is not public. `Core2D` also records that 15 rings
with identical geometry and zero form losses is a radial *discretization*, not yet a radial flow
*model*.

`Data.Geometry` keeps its own nodalization fields, now tagged `NODALIZATION (2-D default)`,
because `PrimarySystem` and `ReactorCore` still read them from there. Removing them and having
the system model take a nodalization record is **O-21**, deliberately left out of this commit.

### 7. Regression audit

Unchanged, verified by independent calculation: `V_core` 0.755406 m³, `V_loop` 1.341094 m³,
τ_core 9.877 s, τ_loop 17.534 s, τ_system 27.411 s, every fuel-salt and coolant property, all
pump parameters, all HX parameters, all precursor data, and every assertion tolerance.

Changed by design: the core heat-transfer closure (`Nu −3.99 → 4.36`, `h −251.8 → 275.1`
W/m²K), the fission source distribution above, `dz_channels` (0.4 mm, into `dz_downcomer`).

`CoreTH_Baseline` is unaffected by all of it: it uses `use_HeatTransfer = false` and supplies
its own uniform `Q_gens`, so it touches neither the closure nor `corePowerShape`.

### Status

| Item | Status |
|---|---|
| `Nus_Core` on the COMMON baseline, provenance complete | **PASS** (code review) |
| `package.order` defect fixed | **PASS** |
| O-20 source domain, normalisations preserved | **PASS** (independent calculation) |
| `PLENUM_FISSION_SOURCE = 0` | **ASSUMPTION** |
| `f_radial` 15-ring profile | **ASSUMPTION** (Serpent tabulation not public) |
| Geometry/Nodalization separated | **PASS**, with **O-21** open |
| Thermal entrance-region treatment | **OPEN** |
| Existing three failing assertions | **EXPECTED_MISMATCH**, untouched |
| Any Modelica run | **BLOCKED_NOT_RUN** |

### Open items

- **O-21 (new)** move `PrimarySystem`/`ReactorCore` onto a nodalization record and delete the
  duplicated fields from `Data.Geometry`
- **O-19 residual** thermal entrance region, obround duct shape, Poppendiek, graphite coupling
- **O-12B** physical volume of MARS 120-03 / 190-01 — same question as O-20 from the other side
- **O-14** the three failing assertions
- **O-16** HX shell geometry — unblocked, awaiting a verified value
- **O-17** unsourced loop dimensions

### Verification status

`BLOCKED_NOT_RUN` — no Modelica toolchain, no MSL/TRANSFORM. `checkModel`, translation and any
simulation were **not** performed. Every number above is an independent calculation outside
Modelica, obtained by re-implementing the model's own expressions. Edited files were checked for
Modelica string and comment balance.

---

## Phase 14 — Stage 2: 1-D core TH verification (zero power and 8 MW)

**Scope:** verification diagnostics only. No property, geometry, pump or HX value changed, no
assertion tolerance relaxed, nothing tuned toward Jeong or toward an experiment.

### A. Changed files

| File | Change | Reason |
|---|---|---|
| `Components/SaltPipe.mo` | added `ds`, `dp_total`, `dp_gravity_local`, `d_bulk`, `dp_gravity_bulk`, `dp_nonstatic`, `G`, `dp_acceleration`, `dp_residual` | Stage 2-4: momentum decomposition with **local** node densities. Purely additive — no equation changed |
| `Verification/CoreTH_Baseline.mo` | `Q_energyNorm` / `Q_norm`; `T_out`, `dT_core`; the five `dp_*` diagnostics; `err_gravityForm`; `tau_core_equivalent` | Stage 2-4/2-7, and a **divide-by-zero defect**: `err_energy = (Q_toFluid − Q_core)/Q_core` is undefined at `Q_core = 0` |
| `Verification/CoreTH_ZeroPower.mo` | new, `extends CoreTH_Baseline(Q_core=0, tol_energy=1e-6)` | Stage 2-1, as a parameterized case rather than a rewrite |
| `Verification/package.order` | registered | class would not load otherwise |

`Q_norm = if abs(Q_core) > 0 then abs(Q_core) else Q_energyNorm`. At 8 MW `err_energy` is
bit-for-bit what it was; `tol_energy` is untouched at 1e-3 there and **tightened** to 1e-6 in the
zero-power case, since no physical power input exists to hide a residual behind.

### Naming

`dp_nonstatic` is used, **not** `dp_irreversible` or `dp_friction`: it is what remains after the
static head and still contains acceleration, friction and form. `dp_residual` isolates
friction+form, but only as a remainder — it is not read out of the TRANSFORM flow model.

### Stage 2-5. TRANSFORM pressure-loss audit — **BLOCKED_NOT_RUN**

`SinglePhase_Developed_2Region_NumStable` could **not** be inspected: no TRANSFORM library and
no MSL exist anywhere on this filesystem (searched; only the repository's own `.mo` files are
present). Its internal friction/form/acceleration split and sign conventions are therefore
**unknown and were not guessed at**. The decomposition above is built only from quantities whose
existence is confirmed in this repository's own code (`pipe.mediums`, already used by
`SaltPipe.Ts`), plus independent formulas. Closing 2-5 needs the TRANSFORM source.

### B. Zero-power results — Q = 0 W

All values are **independent calculation**, not Modelica output.

| Quantity | Modelica | Independent | Difference | Status |
|---|---:|---:|---:|---|
| `m_flow` | BLOCKED_NOT_RUN | 168 kg/s (imposed) | — | BLOCKED_NOT_RUN |
| `Re` | BLOCKED_NOT_RUN | 812.24 | — | BLOCKED_NOT_RUN |
| `T_out − T_in` | BLOCKED_NOT_RUN | 0 K exactly | — | BLOCKED_NOT_RUN |
| `dp_total` | BLOCKED_NOT_RUN | 35 499.39 Pa | — | BLOCKED_NOT_RUN |
| `dp_gravity_local` | BLOCKED_NOT_RUN | 35 016.15 Pa | — | BLOCKED_NOT_RUN |
| `dp_gravity_bulk` | BLOCKED_NOT_RUN | 35 016.15 Pa | 0 (uniform ρ) | BLOCKED_NOT_RUN |
| `dp_acceleration` | BLOCKED_NOT_RUN | 0.0000 Pa | — | BLOCKED_NOT_RUN |
| `dp_nonstatic` | BLOCKED_NOT_RUN | 483.24 Pa | — | BLOCKED_NOT_RUN |

At uniform temperature the local-density and average-density static terms are identical by
construction, which is exactly why this case is run first: it calibrates the diagnostic before
the heated case relies on it.

### C. 8 MW results

| Quantity | Modelica | Independent / reference | Difference | Status |
|---|---:|---:|---:|---|
| `m_flow` | BLOCKED_NOT_RUN | 168 kg/s (imposed) | — | BLOCKED_NOT_RUN |
| `Q_toFluid` | BLOCKED_NOT_RUN | 8.000 MW expected | — | BLOCKED_NOT_RUN |
| `err_energy` | BLOCKED_NOT_RUN | 0 expected, tol 1e-3 | — | BLOCKED_NOT_RUN |
| `T_out` | BLOCKED_NOT_RUN | 931.695 K | — | BLOCKED_NOT_RUN |
| `ΔT` | BLOCKED_NOT_RUN | 23.6951 K | — | BLOCKED_NOT_RUN |
| `dp_total` | BLOCKED_NOT_RUN | 35 366.87 Pa | — | BLOCKED_NOT_RUN |
| `dp_gravity_local` | BLOCKED_NOT_RUN | 34 910.01 Pa | — | BLOCKED_NOT_RUN |
| `dp_acceleration` | BLOCKED_NOT_RUN | 0.7295 Pa | — | BLOCKED_NOT_RUN |

`ΔT = Q/(ṁ·cp)` is a **cross-check only**; the model's own energy balance is on enthalpy,
`Q_toFluid = ṁ(h_out − h_in)`.

### D. Momentum decomposition (independent calculation)

```
                      zero power            8 MW
dp_gravity_local     35016.15 Pa        34910.01 Pa    (local node densities, PRIMARY)
dp_friction            483.24 Pa          456.14 Pa    (laminar 64/Re, local properties)
dp_form                  0.00 Pa            0.00 Pa    (Ks = 0)
dp_acceleration          0.0000 Pa           0.7295 Pa (G^2(1/d_out - 1/d_in), G = 512.542)
                     ------------       ------------
dp_total             35499.39 Pa        35366.87 Pa
```

- gravity is **98.7 %** of the total, so `dp_total` alone verifies almost nothing about the
  friction closure — which is why the decomposition was added.
- heating relieves **106.14 Pa** of static head between the two cases.
- the acceleration term is **0.16 % of `dp_nonstatic`** at 8 MW: small, but **computed rather
  than assumed zero**, as required.
- `dp_gravity_local` and `dp_gravity_bulk` agree to 1e-5 % at 8 MW because the axial temperature
  profile is linear and the density correlation is linear in T. That is a property of this
  case, not a general result, and the local form stays primary.

### E. Status

```
Mass conservation:            BLOCKED_NOT_RUN  (assert present, tolerance unchanged)
Energy conservation:          BLOCKED_NOT_RUN  (enthalpy-based; divide-by-zero defect fixed)
Zero-power isothermal:        BLOCKED_NOT_RUN  (new assert, tol_isothermal = 1e-3 K)
Reynolds number:              PASS  (independent calculation: 812.24 vs 812 reference, +0.03 %)
Gravity pressure term:        PASS  (independent calculation; local and bulk forms agree at uniform T)
Pressure-loss decomposition:  OPEN  (TRANSFORM internal split not inspectable — Stage 2-5 BLOCKED)
Acceleration term:            PASS  (independent calculation: 0 Pa cold, 0.7295 Pa at 8 MW)
Modelica compile:             BLOCKED_NOT_RUN
Modelica simulation:          BLOCKED_NOT_RUN
```

Nothing above is claimed as a Modelica result. The Reynolds, gravity and acceleration rows are
marked PASS as **independent calculations against the stated reference values**, not as
simulation agreement.

### Next blocker

1. No Modelica toolchain — every conservation assert in this stage is unexecuted.
2. Stage 2-5 needs the TRANSFORM source to close the friction/form split.
3. `SaltPipe.pipe.mediums[i].d` is used by the new diagnostics. `pipe.mediums.T` is already used
   by the existing `Ts`, so the access path is sound, but it has not been compiled — first
   `checkModel` should look there.

---

## Phase 15 — Stage 2 executed: OpenModelica obtained, models compiled and simulated

**`BLOCKED_NOT_RUN` is lifted.** Everything below is a **real OpenModelica 1.27.0 simulation**,
not a hand calculation. Hand calculations appear only in the "independent" columns.

### Toolchain

| Component | How | Version |
|---|---|---|
| `omc` | conda-forge via micromamba (`build.openmodelica.org` is blocked; conda-forge is not) | 1.27.0 |
| MSL | `git clone modelica/ModelicaStandardLibrary`, checked out `v4.1.0` | 4.1.0 |
| TRANSFORM | `git clone ORNL-Modelica/TRANSFORM-Library` | targets MSL 4.0.0 |
| `pymoca` | pypi, grammar-level check of all 52 repo files | 0.12.0 — **52/52 parse** |

One sandbox-only workaround was needed and is **not** in the repository: OMC 1.27.0 emits
invalid C for `TRANSFORM.Utilities.Visualizers.IconColorMap.dynColor`
(`real_get` called with an `index_spec_t`). It is a cosmetic icon colour, frozen to a constant
in the sandbox copy of TRANSFORM only. This is an OpenModelica codegen defect, not an MSRE one.

### checkModel

| Model | Result |
|---|---|
| `Verification.CoreTH_ZeroPower` | **PASS** — 6639 equations / 6639 variables |
| `Verification.CoreTH_Baseline` | **PASS** |
| `ClosureRelations.Nus_Core` | **PASS** — 53/53 |
| `ClosureRelations.Nus_MoltenSalt` | **PASS** — 50/50 |
| `Data.Nodalization.Core1D` / `Core2D` | **PASS** |
| `Verification.Properties_TransitTime` | **PASS** |
| `Verification.Analytic_DriftReactivity` | **PASS** |

### The defect the zero-power case was built to find

The base model checked `m_flow*(h_out − h_in)` against `Q_core` and nothing else. The core
climbs 1.6256 m, so at steady state part of the power leaves as **gravitational potential
energy**:

```
m_flow*g*H = 168 * 9.80665 * 1.6256 = 2678.204 W
observed enthalpy deficit             = 2678.2 W
```

At 8 MW that is a relative 3.348e-4 against `tol_energy = 1e-3` — **the heated case had been
passing with a factor of three of margin, for the wrong reason.** At zero power there is no
power to hide it behind and it failed immediately.

The conserved statement is now
`Q_core = m_flow*(h_out − h_in) + Q_potential + Q_kinetic`, with `Q_kinetic` **computed, not
assumed** (8.8e-5 W cold, 0.053 W at 8 MW). **No tolerance was changed.** The residual fell from
3.35e-4 to **9.7e-12** (zero power) and **5.6e-9** (8 MW).

A second, self-inflicted error was found the same way: the zero-power case originally asserted
isothermal behaviour to 1e-3 K, on the premise that only numerical sources remained. That
premise was **wrong** — the salt genuinely cools 1.93 mK doing work against gravity. The
assertion is replaced by the correct and tighter statement that the specific enthalpy given up
must equal `g*H = 15.9417 J/kg`.

### B. Zero-power results (Q = 0 W)

| Quantity | OpenModelica | Independent | Difference | Status |
|---|---:|---:|---:|---|
| `m_flow_in` / `m_flow_out` | 168 / 168 kg/s | 168 | 0.000 % | PASS |
| `err_mass` | **1.42e-10 kg/s** | 0 | tol 1e-6 | **PASS** |
| `Re_channel` | 812.238 | 812.24 | −0.000 % | PASS |
| `dT_core` | −0.0019263 K | — | physical, gravitational | — |
| `dh_actual` | 15.9417 J/kg | `g·H` = 15.9417 | 0.000 % | **PASS** |
| `err_energy` | **9.66e-12** | 0 | tol 1e-6 | **PASS** |
| `dp_total` | 35 500.1 Pa | 35 499.4 | +0.002 % | PASS |
| `dp_gravity_local` | 35 016.8 Pa | 35 016.2 | +0.002 % | PASS |
| `dp_gravity_bulk` | 35 016.8 Pa | identical to local | 0 | PASS |
| `dp_nonstatic` | 483.238 Pa | 483.24 | −0.000 % | PASS |
| `dp_acceleration` | 0.00115 Pa | 0 | negligible, **measured** | PASS |

### C. 8 MW results

| Quantity | OpenModelica | Independent | Difference | Status |
|---|---:|---:|---:|---|
| `m_flow_in` | 168 kg/s | 168 | 0.000 % | PASS |
| `err_mass` | 3.02e-10 kg/s | 0 | tol 1e-6 | **PASS** |
| `Q_toFluid` | 7 997 322 W | 7 997 322 | −0.000 % | PASS |
| `Q_balance` | **8 000 000 W** | 8 000 000 | — | **PASS** |
| `err_energy` | **5.61e-9** | 0 | tol 1e-3 | **PASS** |
| `T_out` | 931.693 K | 931.695 | −0.000 % | PASS |
| `ΔT` | 23.6931 K | 23.6951 | −0.008 % | PASS |
| `dp_total` | 35 366.5 Pa | 35 366.9 | −0.001 % | PASS |
| `dp_gravity_local` | 34 905.4 Pa | 34 910.0 | −0.013 % | PASS |
| `dp_acceleration` | 0.694 Pa | 0.7295 | −4.8 % | see below |
| `dp_residual` (friction+form) | 460.42 Pa | 456.14 | +0.94 % | PASS |

### D. Momentum decomposition — and Stage 2-5, now closed

The TRANSFORM source was obtained, so the split is read from the code rather than inferred.
`PartialMomentumBalance`:

```
Ibs   = I_flows - Fs_p - Fs_fg
Fs_p  = A_avg*(p[i+1] - p[i])
Fs_fg = (dps_fg[i] + firstOrder_dps_K[i].y)*A_avg
dps_K = 0.5*Ks_ab*rho*v^2          (first-order filtered, tau = 0.01 s)
I_flows = A[i]*rho[i]*v[i]^2 - A[i+1]*rho[i+1]*v[i+1]^2   (only if momentumDynamics <> SteadyState)
```

and `dps_fg = dp_DP_staticHead(...)` — **friction and static head combined**, from the MSL
detailed laminar/turbulent correlation. So at steady state

```
p_in - p_out = dp_friction + dp_gravity + dp_form - I_flows/A
```

and for constant area `−I_flows/A = G²(1/ρ_out − 1/ρ_in)`, which is **exactly** the
`dp_acceleration` diagnostic added in Phase 14 — same sign, same form. `use_I_flows` is true
here because `systemTF.momentumDynamics = DynamicFreeInitial`, so TRANSFORM does include the
acceleration term.

```
                        zero power                    8 MW
                    OMC        independent      OMC        independent
dp_gravity_local  35016.8       35016.2       34905.4       34910.0
dp_residual         483.24        483.24        460.42        456.14   (friction + form)
dp_form               0             0             0             0      (Ks = 0)
dp_acceleration       0.00115       0             0.694         0.7295
                  ---------                   ---------
dp_total          35500.1       35499.4       35366.5       35366.9
```

Gravity is **98.7 %** of the total. The 0.94 % gap on `dp_residual` is between TRANSFORM's MSL
detailed correlation and a plain `64/Re` Darcy estimate — good agreement, and it confirms the
core is solved in the laminar branch. The 4.8 % gap on `dp_acceleration` is on a 0.7 Pa term
and comes from TRANSFORM staggering the flow segments against the volumes; my diagnostic uses
first and last node densities.

### E. Status

```
Mass conservation:            PASS   (1.4e-10 / 3.0e-10 kg/s against 1e-6)
Energy conservation:          PASS   (9.7e-12 / 5.6e-9) - after correcting the balance
Zero-power energy path:       PASS   (dh = g*H to 15.9417 J/kg)
Reynolds number:              PASS   (812.238 vs 812.24)
Gravity pressure term:        PASS   (0.002 % / 0.013 %)
Pressure-loss decomposition:  PASS   (Stage 2-5 closed from TRANSFORM source)
Acceleration term:            PASS   (measured, not assumed: 0.00115 / 0.694 Pa)
Modelica compile:             PASS   (checkModel, 7 classes)
Modelica simulation:          PASS   (both cases, 300 s, tol 1e-6)
```

Nothing was tuned. Two model errors were found and corrected, both in the direction of a
**stricter** test, and no tolerance was widened.

### Open items

- **O-22 (new)** every other loop component (`SaltPipe` instances, the plena, the downcomer, the
  HX) has the same enthalpy-only energy accounting; the `m_flow*g*dz` term must be included
  wherever an energy balance is asserted. `Steady_LoopBalance` should be re-examined first.
- OMC 1.27.0 `IconColorMap` codegen defect — worked around in the sandbox only. Dymola is
  unaffected.
- O-12B, O-14, O-16, O-17, O-19 residual, O-20 assumption, O-21 unchanged.

## Phase 16 — O-22 audit, and Stage 3: the 1-D reactor core

### A. O-22 global audit (verification/diagnostic energy accounting only)

The instruction was explicit: audit every energy balance in the model, but **do not touch
TRANSFORM physics** — only the verification and diagnostic accounting. The audit found:

| Location | Asserts an energy balance? | Action |
|---|---|---|
| `Verification/CoreTH_Baseline.mo` | yes, enthalpy-only | **corrected** in Phase 15 |
| `Verification/Steady_LoopBalance.mo` | no — asserts elevation closure, transit time, mass balance, flow split, minimum flow, flow rate, Reynolds | none needed |
| `Verification/Analytic_DriftReactivity.mo`, `Transient_DriftReactivity.mo` | no — reactivity only | none needed |
| `Verification/Properties_TransitTime.mo` | no — property and residence-time values | none needed |
| `Components/PartialFuelPump.mo` | `port_b.h_outflow = inStream(port_a.h_outflow) + dh` | **pump physics, not an assertion — not touched** |

So O-22 was narrower than feared: only one model carried the defective statement. Rather than
repeat the fix per model, the accounting was pushed down into `Components/SaltPipe.mo` as
reusable diagnostics (`Q_enthalpy`, `Q_potential`, `Q_kinetic`, `Q_balance`, `Q_gens_total`,
`err_energy_W`) plus the momentum terms already added in Phase 14. **No equation was changed** —
every addition is an output-only definition. `CoreChannel` and `ReactorCore1D` aggregate them.

Stage 2 was re-run in OpenModelica after the change and reproduced Phase 15 exactly, with the
new component-level residual `core.err_energy_W` = 7.73e-5 W (zero power) and 0.0449 W (8 MW).

### B. Stage 3 structure — reuse, not duplication

`ReactorCore` was checked first and is fully parameterized in `nRings`; it does not use
`f_radial`. So `Components/ReactorCore1D.mo` is

```modelica
extends MSRE.Components.ReactorCore(
  final nRings=1, final nChannels={nChannels_1D}, final nChannels_total=nChannels_1D);
```

with the energy aggregation on top. No core physics is duplicated between the 1-D and 2-D
branches — the 1-D case is the 2-D model with one ring.

`Verification/Core1D_TH_ZeroPower.mo` and `Core1D_TH_Baseline.mo` verify mass, energy
(including the `m_flow*g*dz_core` term), `sum(SF) = 1`, and `SF = 0` in both plenum core nodes
(the O-20 domain split), over the full core: lower plenum + 20 channel cells + upper plenum,
`dz_core = 2.2256 m`.

### C. A second OpenModelica 1.27.0 code-generation defect

`checkModel` passed on both Stage 3 models (13360/13360 and 13359/13359 equations), but the
simulation died at initialization with

```
Dimension 1 has bounds 1..3, got array subscript 4
```

This was **not** a Stage 3 error and **not** an MSRE or TRANSFORM modelling error. Isolation:
a plenum-only probe simulated; a single-`CoreChannel` probe reproduced it. A gdb backtrace
placed the fault in `TRANSFORM.Math.linspace_2Dedge`, called from
`Conduction_2D.Ts_start` for the graphite with `nR = 3, nZ = 20`.

The source of that function ends with

```modelica
for i in 2:n1 - 1 loop
  for j in 2:n2 - 1 loop
    row := linspace(y[i, 1], y[i, n2], n2);
```

OMC inlines the `linspace` reduction as a nested C block that declares **its own**
`modelica_integer _i`, which **shadows the outer loop index of the same name**. The emitted C
reads `real_array_get(_y, 2, _i, 1)` using the *inner* counter, which runs `1..n2 = 1..20`
against a `y[3,20]` array — it trips on the fourth iteration. The defect only fires when
`n1 >= 3` and `n2 > n1`, which is exactly the graphite conduction mesh, and is why the 1-D
plenum probe was unaffected.

Worked around **in the sandbox TRANSFORM copy only** by renaming the loop indices to
`iRow`/`jCol` so the names no longer collide. The mathematics is unchanged, `linspace_2Dedge.mo.orig`
is kept beside it, and **nothing in this repository was modified for it**. Dymola is unaffected.
This is the second OMC 1.27.0 codegen defect met in this work, after `IconColorMap`.

### D. Two more defects of the same family, and what they were hiding

Fixing the OMC codegen bug let initialization run, and immediately exposed three modelling
defects underneath it. All three are the same mistake: **TRANSFORM components do not read the
balance formulation from the `inner SystemTF`.**

`GenericPipe_MultiTransferSurface` declares `outer TRANSFORM.Fluid.SystemTF systemTF` but never
uses it for dynamics. Its own defaults are `energyDynamics = DynamicFreeInitial`,
`massDynamics = energyDynamics`, `momentumDynamics = SteadyState`.
`Conduction_2D` likewise defaults `energyDynamics = DynamicFreeInitial`. So every
`systemTF(energyDynamics = FixedInitial, ...)` in this repository, including the one written for
Stage 2, **has never had any effect on a volume**. That assumption had been carried since Stage 2
and was wrong.

What it produced, each confirmed by running:

1. **Fluid, free initial energy.** At zero power the core is under-determined in temperature, so
   the initialization settled at `T = 4824.79 K`. TRANSFORM's `PartialLinearFluid` density is
   `d = (1 + (p - p_ref)*kappa - (T - T_ref)*beta)*d_ref`, which crosses **zero** at
   `T_ref + 1/beta = 922 + 3894.4 = 4816.4 K`. The solver had parked essentially on the root:
   `division by zero ... divisor is core.upperPlenum.pipe.traceMassTransfer.mediums[2].d`.
2. **Pressure pinned while momentum is algebraic.** With momentum `SteadyState` the flows are
   read straight out of the pressure field, so `massDynamics = FixedInitial` over-specifies the
   network. The plena have almost no resistance - a 1 Pa error across a square metre of flow area
   is worth about 1e5 kg/s - and the core initialized at `-114965 kg/s` out against 168 kg/s in,
   then chattered. `massDynamics` is now `SteadyStateInitial`: `der(p) = 0` lets the pressures
   settle consistently with the flows. No start-value guess could ever have been accurate enough.
3. **Graphite, free initial energy.** Adiabatic on three sides, so at zero power any temperature
   satisfies its steady initial state. The solver went to `-902837 K` and tripped the `Graphite`
   medium's own range assertion.

Energy stays `FixedInitial` throughout - that is what pins the temperature and keeps the solver
off the zero-density root - and is now forwarded to the graphite as well.

### E. Stage 3 executed

The zero-power energy assertion still failed at `StopTime = 600 s` with a 4.31 W residual. Rather
than touch the tolerance, the residual was measured out to 200000 s:

| t (s) | `Q_balance` (W) | `err_mass` | `err_energy` | `dh_actual` (J/kg) |
|---|---|---|---|---|
| 600 | 4.305 | 1.27e-6 | 5.38e-7 | 21.80005 |
| 2000 | 0.1296 | 3.45e-8 | 1.62e-8 | 21.82491 |
| 10000 | 5.98e-4 | 3.73e-8 | 7.48e-11 | 21.825677 |
| 20000 | 2.66e-4 | -1.01e-7 | 3.32e-11 | 21.8256792 |
| 200000 | 2.58e-4 | 8.38e-8 | 3.23e-11 | 21.8256792 |

It is incomplete convergence, not an energy path: the graphite heat structure relaxes far more
slowly than the salt transit time, and the residual plateaus by 20000 s, unchanged out to
200000 s. `StopTime` is now 20000 s. **No tolerance was changed.**

Converged results, all four models, real OpenModelica 1.27.0 runs at `Tolerance = 1e-6`:

| | Stage 2 zero power | Stage 2 8 MW | Stage 3 zero power | Stage 3 8 MW |
|---|---|---|---|---|
| `err_mass` [kg/s] | 1.424e-10 | 3.017e-10 | -9.31e-8 | -5.45e-8 |
| `err_energy` | 9.657e-12 | 5.613e-9 | 3.29e-11 | 1.74e-8 |
| `Q_balance` [W] | 7.73e-5 | 8000000.045 | 2.63e-4 | 8000000.139 |
| `T_out` [K] | 907.998074 | 931.693128 | 907.997543 | 931.692590 |
| `dT_core` [K] | -0.0019263 | 23.693128 | -0.0024573 | 23.692590 |
| `Re_channel` | 812.2384 | 812.2384 | 812.2359 | 815.1165 |
| `dp_core` [Pa] | 35500.08 | 35366.50 | 48424.95 | 48255.87 |
| `dp_gravity_local` [Pa] | 35016.84 | 34905.39 | 47941.46 | 47790.81 |
| `dp_nonstatic` [Pa] | 483.2378 | 461.1129 | 483.4833 | 465.0604 |
| `SF_sum` / `SF_plena` | - | - | 1 / 0 | 1 / 0 |

Stage 3 zero power closes the gravitational statement to
`dh_actual = 21.82567919` against `g*dz_core = 21.82568024 J/kg`, a gap of **1.05e-6 J/kg**
against a 1e-3 tolerance.

**Stage 2 reproduces Phase 15 to every reported digit** despite having originally been run under
the wrong dynamics. That was verified, not assumed: both cases reach steady state, so the
formulation of the initial condition does not move the steady answer.

### F. Independent cross-check of the momentum decomposition

Hand calculation, from `Data/Geometry.mo` and the property model only - no model output used:

```
rho(908 K) = d_ref*(1 + beta*(922 - T)) = 2196.5143 kg/m3
A_channel  = w*h - (4 - pi)*r^2         = 2.87524e-4 m2   ->  A_total = 0.327778 m2
Dh         = 4*A/perimeter              = 0.0158506 m
v          = mdot/(rho*A_total)         = 0.233343 m/s
mu         = 8.4e-5*exp(4340/T)         = 0.0100021 Pa.s
Re         = rho*v*Dh/mu                = 812.2384
f          = 64/Re                      = 0.0787946
dp         = f*(H/Dh)*(rho*v^2/2)       = 483.2364 Pa
```

Model `dp_nonstatic` = 483.2378 Pa. **Agreement to 0.0003 %**, and Re matches to seven digits.
This confirms three things at once: the channel is solved on the laminar branch, `K_channelInlet`
and `K_channelExit` are genuinely zero so `dp_nonstatic` is pure friction, and the momentum
decomposition is arithmetically sound.

The Stage 3 figure is 0.245 Pa higher (483.4833 Pa), which is the two plena. That increment is
**not independently verified** - it is 0.05 % of the total and no hand calculation was done for
it.

### G. Status

```
Stage 2 mass / energy:        PASS  (reproduced Phase 15 exactly)
Stage 3 mass conservation:    PASS  (9.3e-8 / 5.4e-8 against 1e-6)
Stage 3 energy conservation:  PASS  (3.3e-11 / 1.7e-8 against 1e-6 / 1e-3)
Stage 3 zero-power gravity:   PASS  (1.05e-6 J/kg against 1e-3)
Source normalization (O-20):  PASS  (sum(SF) = 1 exactly, SF_plena = 0 exactly)
Friction cross-check:         PASS  (0.0003 % against an independent hand calculation)
Modelica compile:             PASS  (checkModel, 13360/13360 and 13359/13359)
Modelica simulation:          PASS  (all four models, 20000 s, tol 1e-6)
```

Nothing was tuned. Four defects were found and corrected, one of them in OpenModelica itself and
worked around only in the sandbox. No tolerance was widened at any point.

### Open items

- **O-23 (new)** the `SaltPipe` / `CoreChannel` / `ReactorCore` dynamics parameters are now
  explicit, but `PrimarySystem` and the loop-level models have not been re-checked against them.
  Every model that sets `systemTF(energyDynamics = ...)` and expects it to reach the volumes is
  still wrong until it passes the parameter down.
- Stage 3 plenum contribution to `dp_nonstatic` (0.245 Pa) not independently verified.
- OMC 1.27.0 `linspace_2Dedge` and `IconColorMap` codegen defects - sandbox workarounds only.
  Dymola is unaffected by both.
- O-12B, O-14, O-16, O-17, O-19 residual, O-20 assumption, O-21 unchanged.

## Phase 17 — O-23 closed, and the primary loop solved for the first time

**Everything below is a real OpenModelica 1.27.0 run.** Hand calculations appear only in the
columns headed "independent"; they are in `Verification` as models where a Modelica statement
was possible and as standalone arithmetic where it was not.

### A. Toolchain

The container is rebuilt per session, so the toolchain was reinstalled from scratch:

| Component | How | Version |
|---|---|---|
| `omc` | conda-forge via a Miniconda bootstrap (`micro.mamba.pm` is blocked by egress policy, `repo.anaconda.com` and `conda.anaconda.org` are not) | 1.27.0 |
| MSL | `git clone modelica/ModelicaStandardLibrary`, `v4.1.0` | 4.1.0 |
| TRANSFORM | `git clone ORNL-Modelica/TRANSFORM-Library` | targets MSL 4.0.0 |

**Stage 2 and Stage 3 were re-run first and reproduce Phase 16 to every reported digit**
(`Re_channel` 812.2384, `dh_actual` 15.94168986, `dp_nonstatic` 483.2378, `T_out` 907.998074,
and the 8 MW and Stage 3 rows likewise). The toolchain is therefore established as reproducing
the recorded baseline before anything was changed.

### B. O-23: what the audit found

Every fuel-salt component was traced from the `inner SystemTF` down to the TRANSFORM volume
that actually solves the balance.

| Component | energy | mass | momentum | trace |
|---|---|---|---|---|
| `core`, `CoreChannel`, graphite `Conduction_2D` | forwarded (Phase 16) | forwarded | forwarded | **NOT forwarded** |
| the five `SaltPipe` instances | forwarded | forwarded | forwarded | **NOT forwarded** |
| `hx` (`GenericDistributed_HX`) | **NOT forwarded** | **NOT forwarded** | ok by accident | **NOT forwarded** |
| `pump`, `expansionTank` | no volume, nothing to forward | | | |
| `systemTF` | set, read by nothing | not set | **set to `DynamicFreeInitial`, contradicting the `SteadyState` every volume solves** | not set |

Two real defects:

1. **The heat exchanger carried the Phase 16 defect.** `GenericDistributed_HX` defaults
   `energyDynamics[3] = {DynamicFreeInitial, DynamicFreeInitial, DynamicFreeInitial}` on shell,
   tube and wall. At zero power the shell is under-determined in temperature exactly as the core
   was, and the linear-fluid density crosses zero at `T_ref + 1/beta = 4816.4 K`.
2. **`C_start` had never had any effect.** `PartialDistributedVolume` defaults
   `traceDynamics = massDynamics`, which this repository sets to `SteadyStateInitial`. The
   declared precursor initial condition was therefore discarded everywhere in the loop. It is now
   exposed and defaults to `FixedInitial`: trace balances do not enter the momentum equation, so
   unlike mass they cannot over-specify the network, and the circulating equilibrium is reached
   by the null transient — which is the mechanism the paper itself uses for `Beta_eff` (Eq. 6).

The formulation is now stated once, in `PrimarySystem`, and passed explicitly to every component
that holds fuel salt. `systemTF` no longer states a formulation nothing reads.

### C. `Steady_LoopBalance` had never been compiled

It declares `pumpSpeed` and `coolantTemperature` and **never connects them**. The pump would have
received a demand of zero — which `PrimarySystem`'s own documentation warns about. `checkModel`
reported the model two variables short of its equations: exactly those two connectors.

### D. O-21, as far as the loop needs it

`PrimarySystem` read `nRings`, `nAxial`, `nChannels`, `f_radial` and the per-ring form losses out
of `Data.Geometry`, which is meant to be the single source of truth for what the MSRE *is*. It
now takes them from a replaceable nodalization record constrained by a new
`Data.Nodalization.PartialCoreNodalization`. `Core2D` is the default, so the existing 15x20 model
is unchanged, and `Core1D` gives a 1-D loop that differs from it **in spatial representation and
in nothing else** — which is what makes the 1-D/2-D comparison a measurement of the
representation rather than of two models.

### E. The form-loss filter: why the loop would not start

The first attempt at the closed loop initialized and then **died at t = 0.0044 s**. The cause is
in TRANSFORM, and it is worth stating precisely because it will bite every loop model in this
repository.

`PartialMomentumBalance` passes every K form loss through a first-order lag before it enters the
momentum balance:

```modelica
Modelica.Blocks.Continuous.FirstOrder firstOrder_dps_K[nFM](
    each initType = Modelica.Blocks.Types.Init.InitialOutput,
    each y_start  = 0,          // hard-coded
    each T        = taus[1]);   // 0.01 s
```

`y_start` is **unconditionally zero**, so *every form loss in the model is switched off at t = 0*,
whatever the flow is. Initializing this loop at 168 kg/s asserts that it carries rated flow while
three quarters of its resistance does not exist. It does not: the initialization settled at
**257.16 kg/s**, and the missing 216 kPa then had to appear within one 0.01 s time constant
against an algebraic momentum balance. The integrator did not survive it.

Stage 2 and Stage 3 never saw this because `K_channelInlet = K_channelExit = 0` — those models
contain no form loss for the filter to switch off.

**The fix is not a patch and not a tuned time constant.** At zero flow the form losses genuinely
*are* zero, so `y_start = 0` is the correct initial condition there. `Loop_Hydraulics` starts
from rest and lets the pump bring the loop up; the filter charges as the flow builds, and the
inconsistency never exists. A first-order lag has no steady-state effect, so the answer the run
settles at is the same either way.

Two OpenModelica runtime flags were also needed, and both are solver settings rather than model
changes:

```
-noHomotopyOnFirstTry    global homotopy fails on this initialization; the direct solve succeeds
-nlssMaxDensity=0.0      forces the dense NLS; KINSOL/KLU reports "no sparsity pattern available"
```

### F. Two more OpenModelica / TRANSFORM interaction defects

Both are sandbox-only and **nothing in this repository was changed for either**.

- `TRANSFORM.HeatExchangers.GenericDistributed_HX` and its two variants, plus
  `Utilities.Visualizers.IconColorMap_1D`, contain further `scalarToColor` calls. OMC 1.27.0
  emits `real_get(literal, index_spec_t)` for them, which does not compile. Same family as the
  `IconColorMap` defect of Phase 15; frozen to a constant colour in the sandbox copy.
- `GenericHX.mo:72` declares `input SI.Length drs[nR,nV](min=0)` — an array modification without
  `each`. Dymola accepts it, OMC rejects it. Patched to `(each min=0)` in the sandbox copy.

### G. The primary loop, solved

`Verification.Loop_Hydraulics` — new, and the first model in this library that closes the loop
and solves it. Zero fission power, rated pump speed, started from rest, 300 s, tol 1e-6.
**All eight assertions pass.**

Component table, in flow order. Every number is read from the component itself, so this is a
measurement of the assembled model rather than a re-print of its input.

| # | Component | ΔP total [Pa] | ΔP gravity [Pa] | ΔP non-static [Pa] | V [m³] | M [kg] | τ [s] |
|---|---|---:|---:|---:|---:|---:|---:|
| 1 | downcomer | −47 175.467 | −47 940.457 | 764.990 | 0.27727 | 609.03 | 3.6569 |
| 2 | reactor vessel | 48 419.293 | 47 940.573 | 478.720 | 1.20055 | 2637.03 | 15.8340 |
| 3 | outlet riser | 137 946.419 | 47 388.516 | 90 557.904 | 0.05067 | 111.30 | 0.6683 |
| 4 | pump bowl | 2.408 | 0 | 2.408 | 0.15000 | 329.46 | 1.9783 |
| 5 | **pump** | **−301 271.108** | 0 | −301 271.108 | 0 | 0 | 0 |
| 6 | pump discharge | 85 207.205 | −10 770.440 | 95 977.644 | 0.06334 | 139.13 | 0.8354 |
| 7 | HX shell | −31 552.582 | −32 311.286 | 758.704 | 0.26600 | 584.28 | 3.5083 |
| 8 | HX outlet pipe | 108 423.832 | −4 308.106 | 112 731.939 | 0.08867 | 194.77 | 1.1695 |
| | **TOTAL** | **0.000000** | **−1.2007** | 1.201 | **2.09650** | **4605.00** | **27.6507** |

#### Closed-loop balances

```
sum(dz)                    = 0                    exactly, by construction of dz_downcomer
sum(dp_total)              = -0.000000 Pa         the loop returns to the node it started from
dp_pump                    = 301271.108 Pa
sum_passive(dp_nonstatic)  = 301272.309 Pa
sum_passive(dp_gravity)    = -1.2007 Pa
err_dpBalance              = 0.000000 Pa          dp_pump - the two sums above
```

The static heads do **not** cancel to zero, and that is physical rather than numerical. At zero
fission power the pump still delivers `W = 28 554 W` to the salt, which raises it 0.0853 K across
the pump and lowers its density by 0.0479 kg/m³ downstream. Over the loop's elevation that is a
buoyancy head of about 1 Pa, and the measured residual is 1.2007 Pa. The check asserts that the
residual is no larger than the pump heat can account for — not that it is zero, which would be
false, and not a widened version of zero. The loop settles at 908.235 K rather than 908 K for
the same reason; the heat exchanger removes the pumping power.

#### Independent cross-check, component by component

Hand calculation from `Data/Geometry.mo` and the property functions only, using the friction law
TRANSFORM actually solves: 64/Re below Re = 2300, Colebrook–White above it at the default wall
roughness of 2.5e-5 m that `GenericPipe` supplies.

| # | Component | model [Pa] | independent [Pa] | gap | Re |
|---|---|---:|---:|---:|---:|
| 1 | downcomer | 764.990 | 765.222 | −0.03 % | 7 322 |
| 2 | reactor vessel | 478.720 | 479.112 | −0.08 % | 805 |
| 3 | outlet riser | 90 557.904 | 90 561.252 | −0.00 % | 166 931 |
| 4 | pump bowl | 2.408 | 2.409 | −0.02 % | 37 577 |
| 6 | pump discharge | 95 977.644 | 95 988.152 | −0.01 % | 166 931 |
| 7 | HX shell | 758.704 | 758.960 | −0.03 % | 8 562 |
| 8 | HX outlet pipe | 112 731.939 | 112 743.693 | −0.01 % | 166 931 |
| | **TOTAL** | **301 272.309** | **301 298.799** | **−0.01 %** | |

The first attempt at this comparison put the pipes 2.6 to 3.7 % apart. That was **the hand
calculation being wrong, not the model**: it used smooth-pipe Blasius while TRANSFORM solves
Colebrook–White at 2.5e-5 m. Recorded because the failure mode is instructive — a 3 % gap on the
three components that carry 99 % of the loss looked exactly like a modelling defect.

Solving the pump curve against the loop resistance independently gives the operating point

```
independent   m_flow = 166.5414 kg/s     Re_channel = 805.186
model         m_flow = 166.5420 kg/s     Re_channel = 806.178
gap                    3.6e-6 relative                +0.12 %
```

The Reynolds gap is the loop running 0.235 K above 908 K on pump heat, which lowers the
viscosity by 0.124 %. That accounts for it to the third digit.

The loop therefore delivers **166.54 kg/s at rated pump speed, −0.87 % from the nominal 168
kg/s** — the form-loss calibration (`K_pumpInlet`, `K_pumpExit`, `K_loop`) holds, and nothing was
adjusted to make it.

#### Inventory and transit times

| Region | Volume [m³] | Inventory [kg] | Transit time [s] |
|---|---:|---:|---:|
| reactor core (channels + MARS 120-03 + 190-01) | 0.755406 | 1659.265 | 9.9630 |
| external loop (everything else) | 1.341094 | 2945.736 | 17.6876 |
| **circulating total** | **2.096500** | **4605.001** | **27.6507** |

`err_inventory = 0.000000`: the assembled model holds exactly what `Data.Geometry.V_total`
states, measured from node volumes and local node densities rather than restated.

The reactor **vessel** holds 2637.03 kg and has a residence time of 15.83 s. That is **not** the
core transit time — the vessel includes both plena in full, the core only one node of each — and
the two differ by 59 %. `ReactorCore` now reports both, because reporting one under the other's
name would put every transit-time comparison out by that much.

### H. Core nodalization structural verification

`Verification.CoreNodalization_Structure`, run through `Core1D_Structure` and
`Core2D_Structure`. It integrates nothing; it asserts the eight things that must be true of any
core discretization and that are **all invisible in a simulated result**, either because the code
renormalizes them away or because they surface as a plausible-looking few-percent shift somewhere
else.

| Statement | Core1D | Core2D |
|---|---:|---:|
| `sum(nChannels_ring) = 1140` | 0 | 0 |
| `sum(A_flow_ring) = A_core_total` | 0 | 0 |
| `sum(V_ring) = V_channels` | 0 | −4.4e-16 |
| `sum(V_cell) = V_core` | 0 | −1.8e-15 |
| `sum(SF) = 1` | 0.9999999999999998 | 0.9999999999999988 |
| `SF` in both plenum core nodes (O-20) | 0 | 0 |
| channel-weighted mean `f_radial` | **1** | **0.99998** |
| `sum(phi_i*V_i)/sum(V_i) − 1` | 0 | −1.0e-15 |
| `peak_axial` | **1.265426552063129** | **1.265426552063129** |
| `peak_radial` | 1 | 1.606732134642692 |
| `V_cells_sum` [m³] | 0.7554059448251441 | 0.7554059448251428 |

Two things worth keeping:

- **`peak_axial` is identical to fifteen digits.** Collapsing the rings does not touch the axial
  source shape, so any 1-D versus 2-D difference in a global result comes from the hydraulics or
  the radial power spread and never from the axial source. That is what makes the comparison
  interpretable rather than merely different.
- **`f_radial_mean` is 0.99998, not 1.** The 15 radial peaking factors are given to four decimal
  places, and their channel-weighted mean misses unity by 2e-5. `corePowerShape` normalizes the
  result, so this leaves **no trace whatever in any simulated quantity** - which is exactly why it
  is asserted here instead of being left to be noticed. It is table precision, not a modelling
  choice, and the tolerance (1e-4) is set from the table's four decimals rather than from the
  observed residual.

An independent Python reimplementation of `corePowerShape` and `coreCellVolumes` reproduces every
row above to the digits shown.

### I. Independent DNP analysis, before running the model

Two independent calculations were done first, so that the Modelica result has something to be
checked against rather than merely reported.

**Paper Eq. 8 reproduced.** `MSRE.Functions.driftReactivity` at the paper's transit times gives
228.353 pcm against the 228.4 pcm the paper quotes - 0.02 %. `Beta_circulating = 0.0044975`
against the MSRE's well-established 0.0045. Both assertions in `Analytic_DriftReactivity` that
test **Eq. 8 itself** therefore pass.

**A full-loop transport solution, solved by hand.** The same steady problem the Modelica model
solves - production, advection and decay over the 62-node chain that is this nodalization -
closed round the loop analytically rather than integrated:

| grp | λ [1/s] | T½ [s] | λτ_core | λτ_loop | f_core | f_return | (gen−decay)/gen |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0.0125 | 55.45 | 0.1235 | 0.2192 | 0.363 | 0.858 | 1.1e-14 |
| 2 | 0.0318 | 21.80 | 0.3141 | 0.5576 | 0.374 | 0.680 | 1.6e-15 |
| 3 | 0.1090 | 6.36 | 1.077 | 1.911 | 0.468 | 0.276 | 8.0e-16 |
| 4 | 0.3170 | 2.19 | 3.131 | 5.558 | 0.736 | 0.030 | 4.2e-16 |
| 5 | 1.3500 | 0.513 | 13.33 | 23.67 | 0.971 | 1.1e-5 | 1.1e-16 |
| 6 | 8.6400 | 0.080 | 85.33 | 151.5 | 0.999 | 3e-61 | 3.1e-16 |

`f_core` is the fraction of the group's inventory inside the core; `f_return` the fraction of the
core-exit concentration that survives the trip round the loop. The ordering is entirely set by
`λτ_loop`: group 6 is gone before it leaves the vessel and is untouched by circulation, group 1
returns 86 % intact and loses almost all of its worth.

```
Beta_eff_static      = 678.100 pcm
Beta_eff_circulating = 450.846 pcm      (this nodalization, flat importance)
circulation loss     = 227.254 pcm
paper Eq. 8          = 227.066 pcm      at the same transit times
gap                  =   0.188 pcm      (0.08 %)
```

Two completely different routes - a 62-volume transport chain and a two-region closed form -
agree to 0.08 %. **The Core1D and Core2D chains give the same answer to every digit printed**,
which is the analytic prediction for the 1-D/2-D comparison of any precursor quantity: the rings
are hydraulically identical, the importance weighting is flat, and the axial source shape is
identical, so there is nothing left for the radial discretization to change.

### J. DNP full-loop transport, solved

`Verification.DNP_Circulation`. 100 W, rated pump speed, flux servo holding the population
constant, started from rest, tol 1e-6. The six precursor groups are trace substances of the fuel
salt, so TRANSFORM advects them; each fuel-salt volume in the system applies its own decay term
and the fission source goes to the core cells only (the O-20 split).

| grp | λ [1/s] | T½ [s] | mC core | mC external | f_core | λτ_ext | production | decay | residual |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0.0125 | 55.45 | 25.1616 | 44.1337 | 0.36311 | 0.221 | 8.66667e-1 | 8.66191e-1 | 5.49e-4 |
| 2 | 0.0318 | 21.80 | 58.2724 | 97.6497 | 0.37373 | 0.563 | 4.95833 | 4.95832 | 2.31e-6 |
| 3 | 0.1090 | 6.36 | 19.1877 | 21.7144 | 0.46911 | 1.928 | 4.45833 | 4.45833 | 7.46e-7 |
| 4 | 0.3170 | 2.19 | 29.3117 | 10.3834 | 0.73842 | 5.607 | 12.5833 | 12.5833 | 1.71e-7 |
| 5 | 1.3500 | 0.513 | 2.84281 | 0.083114 | 0.97159 | 23.88 | 3.95000 | 3.95000 | 2.49e-9 |
| 6 | 8.6400 | 0.080 | 0.166251 | 1.262e-4 | 0.99924 | 152.8 | 1.43750 | 1.43750 | 2.04e-13 |

`f_core` against the independent chain of section I: 0.36311/0.36307, 0.37373/0.37353,
0.46911/0.46766, 0.73842/0.73599, 0.97159/0.97113, 0.99924/0.99923 — 0.01 to 0.3 %.

#### The conservation residual is the group-1 filling transient, and nothing else

At 600 s the largest residual was 5.4884e-4, against a 1e-4 tolerance. Rather than move the
tolerance the residual was identified:

```
-ln(5.4884e-4)/600 s = 0.012513 1/s        against lambda_1 = 0.0125 1/s
```

The circulating distribution starts empty and fills at the decay rate of the slowest group, so
the residual is `exp(-lambda_1*t)` — and it is that to four digits, with every other group's
residual orders below it and ordered by half-life. 600 s is 10.8 half-lives, which sounds ample
and is not. `t_settle` is now **1500 s**, where `exp(-lambda_1*t) = 7e-9`. **The number was set
from the decay constant and the tolerance; the tolerance was not moved.**

#### Circulation reactivity

```
Beta_eff_static      = 678.100 pcm       (data_PG.Beta = 0.006781)
Beta_eff_circulating = 451.801 pcm       (0.00451801, paper Eq. 6, from the transport)
circulation loss     = 226.299 pcm
paper Eq. 8          = 226.086 pcm       at THIS run's transit times
relative gap         = 9.4e-4  (0.094 %)
```

This is the check worth having. Paper Eq. 8 is the steady-state limit of the same transport, for
a two-region loop with a cosine source and flat importance; evaluating it **at the transit times
this run delivers** rather than at the paper's makes the comparison a code-to-analytic check of
the transport instead of a benchmark comparison mixed with a geometry difference. The two routes
— a distributed transport over some sixty volumes with the reactivity taken from Eq. 7, and a
closed form — agree to 0.094 %. The independent hand chain of section I predicted the same
comparison at 0.08 %.

`Beta_eff_circulating = 0.004518` against the MSRE's well-established 0.0045.

`rho_CR_pcm = 226.299`, identical to the circulation loss, which it must be while `Beta_eff` is
still the static value: `rho_servo = Beta_eff - Beta_eff_inst` is exactly the definition.

Converged at `t_settle = 1500 s`:

| grp | λ [1/s] | T½ [s] | λτ_ext | mC core | mC external | f_core | residual |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0.0125 | 55.45 | 0.221 | 25.1752 | 44.1580 | 0.36310 | 1.47e-6 |
| 2 | 0.0318 | 21.80 | 0.563 | 58.2725 | 97.6499 | 0.37373 | 4.76e-7 |
| 3 | 0.1090 | 6.36 | 1.928 | 19.1876 | 21.7145 | 0.46911 | 1.53e-7 |
| 4 | 0.3170 | 2.19 | 5.607 | 29.3116 | 10.3835 | 0.73842 | 3.52e-8 |
| 5 | 1.3500 | 0.513 | 23.88 | 2.84281 | 0.0831154 | 0.97159 | 5.11e-10 |
| 6 | 8.6400 | 0.080 | 152.8 | 0.166251 | 1.262e-4 | 0.99924 | 4.19e-14 |

`f_core` is ordered entirely by `λτ_external`, which is the whole circulation effect in one
column: group 6 is gone before it leaves the vessel and keeps 99.92 % of its inventory in the
core, so circulation costs it nothing; group 1 circulates almost intact and holds only 36.3 %,
so it loses most of its worth. Nothing about this is fitted — it follows from the decay constants
and the transit time.

`Beta_eff` is frozen at `t_null` at the circulating value 0.00451804, which is paper Eq. 6, and
`rho_CR_pcm` then goes to zero, which is what the servo definition
`rho_servo = Beta_eff − Beta_eff_inst` requires once the two are the same number.

### K. Pump rotor dynamics

The rotor equation as implemented in `FuelPump_Dynamics` is

```
J*der(omega) = tau_motor - tau_hyd_nominal*omega*abs(omega)/omega_nominal^2 - tau_fric
```

which with the default zero friction and `x = omega/omega_nominal`,
`tau_shaft = J*omega_nominal/tau_hyd_nominal` reduces to `dx/dt = (u - x|x|)/tau_shaft`. That has
closed-form solutions and they were reproduced independently: `x = tanh(t/tau_shaft)` for the
start from rest at full torque demand, `x = 1/(1 + t/tau_shaft)` for the trip from rated. The
documented "98.7 % of rated at 10 s" is `tanh(2.5) = 0.98661`.

The documented rotor numbers were stale. They were computed at the retired ORNL-TM-4865 density
and the pump reads `d_nominal` from the medium, so at the active Cantor density they are

| | documented | actual |
|---|---:|---:|
| rated hydraulic power | 22.4 kW | **22.95 kW** (30.8 hp) |
| `tau_hyd_nominal` | 231 N·m | **236.11 N·m** |
| `J` at `tau_shaft = 4 s` | 7.59 kg·m² | **7.775 kg·m²** |

Documentation only — the model was already computing them correctly from the medium.

Quasi-steady flow along the speed locus, from the pump curve crossed with the loop resistance
(independent calculation, the same friction law the model solves):

| t [s] | startup N [rpm] | startup ṁ [kg/s] | ṁ/ṁ_n | coastdown N [rpm] | coastdown ṁ [kg/s] | ṁ/ṁ_n |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | 0 | 0 | 0 | 1160.0 | 166.54 | 0.991 |
| 1 | 284.1 | 39.40 | 0.235 | 928.0 | 132.66 | 0.790 |
| 2 | 536.1 | 75.67 | 0.450 | 773.3 | 110.12 | 0.656 |
| 5 | 984.0 | 140.83 | 0.838 | 515.6 | 72.70 | 0.433 |
| 10 | 1144.5 | 164.27 | 0.978 | 331.4 | 46.17 | 0.275 |
| 20 | 1159.9 | 166.53 | 0.991 | 193.3 | 26.42 | 0.157 |
| 30 | 1160.0 | 166.54 | 0.991 | 136.5 | 18.37 | 0.109 |

This is **quasi-steady**: it neglects the fluid's own inertia, which is legitimate here only
because the loop momentum balance is `SteadyState` in this model — the flow follows the head
algebraically. It is therefore the curve the model must reproduce, not an approximation to it,
and any deviation is a defect rather than a modelling difference.

#### Two diagnostic defects that only a stagnant start could expose

Running the startup from rest surfaced two errors in the diagnostics added earlier in this phase.
Both are output-only and neither touches an equation, but both would have produced wrong numbers
in exactly the regime the natural-circulation stage lives in.

1. **The parallel static head had the wrong weight.** `dp_gravity_channels` averaged the per-ring
   static heads weighted by the *signed* ring flow and divided by its *magnitude*, so it flipped
   sign whenever the loop drifted backwards. At a stagnant start it reported −35 017 Pa instead of
   +35 017. It is now weighted by the flow magnitude, with the plain mean as the zero-flow limit.
2. **Twelve `max(abs(m_flow), eps)` guards were generating state events.** Every residence-time
   and flow-split diagnostic divides by the flow and guards it that way. Each guard is a relational
   expression, so each one is an *event* at |ṁ| = eps — and a startup crosses that threshold
   repeatedly while the loop is deciding which way to drift. The integrator spent minutes of wall
   time reaching t = 7e-6 s. All twelve are now inside `noEvent(...)`.

#### Two further defects the stagnant start exposed, both about zero flow

3. **The pump characteristic has an infinite derivative at zero flow.** At `N = 0` it degenerates
   to `head = -R_pump*V_flow*|V_flow|`, and the solver has to read that the other way round -
   `V_flow = -sign(head)*sqrt(|head|/R_pump)` - because the loop momentum balance is algebraic.
   That derivative is infinite at the origin, and a stagnant start sits exactly there. Regularized
   with `Modelica.Fluid.Utilities.regSquare`, the standard device: the head differs from the exact
   quadratic by `(delta/V_flow)^2/2`, which at the rated flow is 5e-9 and at the 1-3 % of rated
   the natural circulation test runs at is between 6e-5 and 4e-6. **This will matter again in the
   natural circulation stage** and is listed as an open item there.

4. **A stagnant loop is degenerate under an algebraic momentum balance.** With the pump off,
   isothermal and elevation closed, `sum(dp) = 0` holds identically at zero flow, so the flow is
   determined only to the resolution of the friction terms and the solver chases round-off. The
   effective inertia length of the loop is

   ```
   sum(L_i/A_i):  outlet riser 315.8   pump discharge 394.7   HX outlet 552.6
                  downcomer 20.8   HX shell 22.4   core 5.0   plena 0.5   pump bowl 2.4
                  TOTAL 1314.1 1/m
   ```

   so accelerating from rest to 166.5 kg/s under 300 kPa takes `m_flow*L_eff/dp = 0.729 s`. That
   is **not negligible against the 4 s shaft time constant of a 10 s startup**, and the algebraic
   balance discards it. The pump transients therefore solve momentum dynamically. The steady
   models keep `SteadyState`, so nothing in Stage 2, Stage 3 or `Loop_Hydraulics` moves.

#### The blocker, and what it took to isolate it

`PumpStartup` holds the loop **stagnant for 600 s** before starting the pump, purely so that the
stagnant precursor distribution has time to build. **That hold is not integrable.** With the pump
off the loop is isothermal, elevation closed and motionless; the fuel salt is nearly
incompressible (`kappa = 2.89e-10 1/Pa`, about 1255 m/s), the mass balance is dynamic, and there
is no bulk motion for the solver's error test to be dominated by, so the integrator spends
everything on acoustic modes.

Measured: **0.036 s of simulated time per four minutes of wall time.** The 600 s hold is a run of
roughly six weeks.

Four things were tried and none changed the rate by more than a factor of ten:

| Attempt | Result |
|---|---|
| regularize the pump's zero-flow singularity | 400x faster, still 1e-3 s/min |
| dynamic momentum balance | a further 10x, still hopeless |
| force the dense nonlinear solver | no change |
| loosen the tolerance 1e-6 → 1e-4 → 1e-3 | **no change at all** — both reached t = 0.036114 s in the same wall clock |

The last row is the decisive one: if the error test were the limiter, three orders of tolerance
would have moved it. It did not, so the limiter is the stiffness itself.

#### The resolution: state the stagnant distribution instead of simulating it

The stagnant distribution is analytic. With no transport the steady precursor equation in a core
cell is

```
0 = S_ij - lambda_j*mC_ij        S_ij = beta_j/Lambda*N*SF_i
mC_ij = beta_j*N*SF_i/(Lambda*lambda_j)     in the channels, zero everywhere else
```

so `PumpStartup_StagnantStart` imposes it and starts the pump at `t = 0`. The loop never sits
stagnant. Summed over the core that is `mC_j = beta_j*N/(Lambda*lambda_j)`, **independent of the
source shape**, so this initial condition reproduces the static `Beta_eff = 0.006781` exactly —
which is the number the test must start from.

**Setting it at all is only possible because O-23 was closed earlier in this phase.** Before
that, TRANSFORM defaulted `traceDynamics` to `massDynamics` and the declared initial precursor
condition was discarded, so no stated initial distribution could have had any effect.

`PrimarySystem` now takes `C_start` (outside the core) and `C_start_core` (the channels)
separately, because at stagnation the plena hold nothing and the channels hold everything —
`ReactorCore` gained `C_start_channels` for the same reason.

**What is approximated**: only the axial shape inside the channels, which is flat here against
the true cosine, because `SaltPipe` hands TRANSFORM a `C_a_start`/`C_b_start` pair that it
interpolates linearly. The total inventory, the initial `Beta_eff` and the precursor content
outside the core are all exact. The flat shape affects the *timing* of the sweep-out over the
first core transit — about 10 s — and nothing that the asymptotic drift reactivity depends on.
It is an approximation of the **initial condition**, not of the physics, and it is left as an
open item rather than presented as exact.

### L. Pump coastdown, solved

`PumpCoastdown1D_RotorDynamics`, `t_null = 1500 s` (set from `lambda_1` as in section J), motor
trip at 1500 s, `FuelPump_Dynamics` integrating the rotor equation with `tau_shaft = 4.0 s`.

**The coastdown runs and the startup does not, and the reason is exactly the diagnosis above**:
the coastdown starts with the shaft already at rated speed, so the pump has full head from t = 0
and the loop is never near zero flow. The 1500 s null transient at rated flow integrates at
normal speed. It is not the null transient that is fatal — **it is starting the rotor from
zero.**

#### The rotor equation against its closed form

With zero friction the rotor integrates to `omega = omega_0/(1 + t/tau_shaft)` exactly. That is
the case where the analytic answer is known, so any deviation is a defect in the ODE or its
initialization:

| Δt after trip [s] | closed form [rpm] | model [rpm] | gap |
|---:|---:|---:|---:|
| 1.2 | 892.3077 | 892.3080 | +0.0000 % |
| 4.8 | 527.2727 | 527.2730 | +0.0001 % |
| 12.0 | 290.0000 | 290.0000 | +0.0000 % |
| 19.2 | 200.0000 | 200.0060 | +0.0030 % |
| 26.4 | 152.6316 | 152.6450 | +0.0088 % |

`J*der(omega) = tau_motor − tau_hyd − tau_fric` is verified. The drift at late times is solver
accumulation over 26 s, not a modelling difference.

#### Flow against the independent quasi-steady locus

| N [rpm] | model ṁ [kg/s] | independent [kg/s] | gap |
|---:|---:|---:|---:|
| 892.3 | 127.311 | 127.4 | −0.07 % |
| 290.0 | 40.225 | 40.2 | +0.06 % |

The loop flow follows the pump curve crossed with the loop resistance, computed independently.

#### Reactivity: the circulation loss being given back

| Δt [s] | N/N_rated | ṁ/ṁ_rated | Beta_eff_inst | rho_CR [pcm] |
|---:|---:|---:|---:|---:|
| 0 | 1.000 | 0.9913 | 0.0045180 | 0 |
| 1.2 | 0.769 | 0.7578 | 0.0045731 | −5.50 |
| 4.8 | 0.455 | 0.4426 | 0.0049621 | −44.41 |
| 12.0 | 0.250 | 0.2394 | 0.0055426 | −102.46 |
| 19.2 | 0.172 | 0.1629 | 0.0058399 | −132.18 |
| 26.4 | 0.132 | 0.1229 | 0.0060186 | −150.06 |

`Beta_eff` is frozen at the circulating 0.0045180 at the trip, and `Beta_eff_inst` climbs back
toward the static 0.006781 as the precursors stop being swept out of the core. The servo
reactivity `rho_servo = Beta_eff − Beta_eff_inst` is therefore negative and growing: **the
control rods are removing the 226.3 pcm that circulation had cost**, and 150.06 pcm of it —
66 % — is back at 26 s after the trip. The sign, the magnitude and the asymptote are all what
the physics requires, and none of them was fitted.

The run was stopped at t = 1530 s (30 s after the trip) to free the machine for the 15-ring
comparison, not because it failed. It was still progressing, but slowing as the flow decayed —
which is the same low-flow stiffness, approached from the other side. At the stopping point
156.70 pcm of the 226.30 pcm has been recovered, the flow is at 10.9 % of rated and the shaft at
136.5 rpm. **Carrying the coastdown to its asymptote is an open item**, and it will need whatever
resolves the low-flow regime for the startup.

### L2. 1-D versus 2-D, and a second blocker

The comparison is complete at the two levels where it could be measured, and **not measured at
the third**.

**Core structure — exact.** `Core1D_Structure` and `Core2D_Structure` both pass all eight closure
statements, and `peak_axial` is identical to fifteen digits (1.265426552063129). Collapsing
fifteen rings into one does not touch the axial source shape.

**Precursors — analytically identical.** The independent 62-node transport chain of section I run
on both nodalizations gives the same answer to every digit printed, including
`Beta_eff_circulating` and the 227.254 pcm circulation loss. That is the prediction, not a
coincidence: the rings are hydraulically identical (`K_channelInlet = K_channelExit = 0`), the
neutron importance is flat, and the axial source shape is the same, so nothing is left for the
radial discretization to change.

**Loop hydraulics — NOT MEASURED.** `Loop_Hydraulics2D` (188 389 equations) compiles — it took
1897 s of which 1874 s was the OpenModelica backend and C compilation — and then **fails to
initialize**:

```
Using sparse solver kinsol for nonlinear system 785 (48776),
  because size of 10086 exceeds threshold of 1000.
Failed to solve the initialization problem without homotopy method.
Failed to solve the initialization problem with global homotopy with equidistant step size.
```

Fifteen parallel rings under an algebraic momentum balance produce a single coupled nonlinear
initialization system of **10 086 variables**. Tried and failed: `-nlssMinSize=20000` (forces the
dense path — did not finish in 420 s, which is expected for a dense 10 086-square solve),
`-nlsLS=lapack` and `-nlsLS=totalpivot` (both fail to converge), with and without homotopy.

This is a **different blocker from O-24** and it is worth stating separately: O-24 is about the
low-flow regime, this is about the size and conditioning of the 15-ring algebraic initialization
at any flow. **The 15 x 20 loop model is not currently runnable**, which matters for the 2-D
benchmark branch independently of anything to do with natural circulation.

A related symptom appeared in the same log and belongs to O-24's family: `log(Re_eff) was 0` in
the heat exchanger's Gnielinski closure. At zero flow the correlation's logarithm is undefined.
It is survivable in the 1-D run and is one more thing the low-flow regime will have to answer for.

### M0. Core regression after every change of this phase

Stage 2 and Stage 3 were re-run at the end, after the O-23 fix, the nodalization refactor, the
diagnostics added to `SaltPipe` and `ReactorCore`, the `traceDynamics` and `C_start_channels`
changes and the pump regularization. **Every one of them reproduces bit-for-bit**, both against
the run at the start of this phase and against Phase 16:

| | Stage 2 zero | Stage 2 8 MW | Stage 3 zero | Stage 3 8 MW |
|---|---:|---:|---:|---:|
| `err_mass` [kg/s] | 8.532e-11 | 3.016e-10 | 7.171e-8 | −5.448e-8 |
| `err_energy` | 1.886e-11 | 5.613e-9 | 3.291e-11 | 1.740e-8 |
| `Re_channel` | 812.238406 | 812.238406 | 812.235903 | 815.116545 |
| `T_out` [K] | 907.998074 | 931.693128 | 907.997543 | 931.692590 |
| `dh_actual` [J/kg] | 15.94168986 | — | 21.82567919 | — |
| `dp_nonstatic` [Pa] | 483.2378 | 461.1129 | 483.4833 | 465.0604 |
| `Q_balance` [W] | — | 8000000.045 | 2.633e-4 | 8000000.139 |

The diagnostics added this phase are output-only by construction, and this is the measurement
that says so rather than the claim.

### M. Regression matrix

Every model below is a real OpenModelica 1.27.0 run at `Tolerance = 1e-6`. `checkModel` passed
on all of them with balanced equation counts.

| Model | checkModel | equations | simulate | asserts |
|---|---|---:|---|---|
| `Verification.CoreTH_ZeroPower` (Stage 2 zero) | PASS | 6653 | PASS | PASS |
| `Verification.CoreTH_Baseline` (Stage 2, 8 MW) | PASS | 6653 | PASS | PASS |
| `Verification.Core1D_TH_ZeroPower` (Stage 3 zero) | PASS | 13370 | PASS | PASS |
| `Verification.Core1D_TH_Baseline` (Stage 3, 8 MW) | PASS | 13370 | PASS | PASS |
| `Verification.Core1D_Structure` | PASS | — | PASS | PASS (8/8) |
| `Verification.Core2D_Structure` | PASS | — | PASS | PASS (8/8) |
| `Verification.Loop_Hydraulics` (1-D loop) | PASS | 29389 | PASS | PASS (8/8) |
| `Verification.DNP_Circulation` (1-D) | PASS | 29409 | PASS | PASS (2/2) |
| `Experiments.PumpCoastdown1D_RotorDynamics` | PASS | 29326 | PARTIAL (t = 1530 of 1800) | n/a |
| `Experiments.PumpStartup1D_RotorDynamics` | PASS | 29326 | **BLOCKED** | n/a |
| `Experiments.PumpStartup_StagnantStart` | PASS | 29326 | **BLOCKED** | n/a |
| `Systems.PrimarySystem` (15 x 20) | PASS | 188389 | not run standalone | n/a |
| `Verification.Loop_Hydraulics2D` (15 x 20 loop) | PASS | 188389 | **initialization fails** | n/a |
| `Verification.Steady_LoopBalance` | PASS | 188391 | not run | n/a |
| `Verification.Properties_TransitTime` | PASS | — | assertion fails **by design** | see below |
| `Verification.Analytic_DriftReactivity` | PASS | — | assertion fails **by design** | see below |

#### Two assertions that fail deliberately, and were left alone

`Properties_TransitTime` and `Analytic_DriftReactivity` both abort at initialization. Neither is
a defect found in this phase, and **neither was touched**:

- `Properties_TransitTime`: the core density implied by the reported 9.56 s transit time and the
  documented channel volume is **3014.21 kg/m³** against Cantor's 2196.51 — **+37.2 %** against a
  5 % tolerance. The model's own source says "It no longer holds ... The tolerance is deliberately
  left at 5 % — see open item O-14."
- `Analytic_DriftReactivity`: the first two assertions **pass** — Eq. 8 gives 228.353 pcm against
  the paper's 228.4, and `Beta_circulating = 0.0044975` against the MSRE's 0.0045. Only the third
  fails, and by 0.001 pcm out of a 0.5 pcm limit: 6.199 pcm against 6.7 at the high natural
  circulation flow.

Both are **benchmark comparisons left failing on purpose** as markers of O-12B and O-14, by a
deliberate decision recorded in Phase 4 and Phase 10 when the geometry was rebuilt from hardware
and stopped reproducing the reported transit times. Downgrading them, widening them, or tuning
the geometry to satisfy them are all forbidden by the terms of this work, and the first two would
also be dishonest. They are reported here as **KNOWN_FAILING_BY_DESIGN** and escalated as a
decision for the reader, not resolved unilaterally — see the open items.

### N. OpenModelica-specific workarounds

All four are in the **sandbox TRANSFORM copy only**. Nothing in this repository was changed for
any of them, `.orig` files are kept beside each, and Dymola is unaffected.

| # | Where | Defect | Class |
|---|---|---|---|
| 1 | `Utilities/Visualizers/IconColorMap.mo` | `scalarToColor` emits `real_get(literal, index_spec_t)`, invalid C | OMC codegen |
| 2 | `Math/linspace_2Dedge.mo` | inlined `linspace` reduction shadows the outer loop index | OMC codegen |
| 3 | `HeatExchangers/GenericDistributed_HX{,_Rwall,_withMass}.mo`, `Utilities/Visualizers/IconColorMap_1D.mo` | further `scalarToColor` calls, same defect as 1 | OMC codegen |
| 4 | `Fluid/.../HeatExchanger/GenericHX.mo:72` | `input SI.Length drs[nR,nV](min=0)` — array modification without `each`. Dymola accepts it, OMC rejects it | Modelica spec strictness |

1 and 2 were found in Phases 15 and 16; **3 and 4 are new to this phase** and were both needed to
compile anything containing the heat exchanger — which is everything at loop level.

Two OpenModelica **runtime** flags are needed for every loop-level model, and both are solver
settings rather than model changes:

```
-noHomotopyOnFirstTry    global homotopy fails on the loop initialization; the direct solve works
-nlssMaxDensity=0.0      forces the dense NLS; KINSOL/KLU reports "no sparsity pattern available"
```

A third finding is worth recording because it invalidated an experiment before it was caught:
**`-override=stopTime=...` and `-override=tolerance=...` are silently ignored** by the OMC
runtime. A first attempt to measure the tolerance sensitivity of the stalled startup used them,
got identical results, and would have concluded that tolerance was irrelevant for the wrong
reason. Redone by editing the generated `_init.xml`, where the change does take effect, the
conclusion held — but it held on evidence rather than on an artefact.

### O. Status

```
Stage 2 zero power / 8 MW           PASS    reproduces Phase 16 to every reported digit
Stage 3 zero power / 8 MW           PASS    reproduces Phase 16 to every reported digit
O-23 dynamics propagation           CLOSED  heat exchanger and traceDynamics were the gaps
Primary-loop zero-power hydraulics  PASS    8/8 assertions; 0.01 % against an independent
                                            component-by-component hand calculation
Closed-loop pressure balance        PASS    err_dpBalance = 0.000000 Pa
Static-head closure                 PASS    -1.2007 Pa, accounted for by the pump's own heat
Loop inventory                      PASS    err_inventory = 0.000000
Transit times                       PASS    9.9630 s core, 17.6876 s external, 27.6507 s total
DNP full-loop transport             PASS    conservation 1.5e-6; 0.092 % against paper Eq. 8
Circulation reactivity              PASS    226.296 pcm transported, 226.087 pcm closed form
Core1D / Core2D structure           PASS    8/8 each, exact
Pump rotor equation                 PASS    reproduces its closed form to five digits
Pump coastdown                      PARTIAL  runs correctly, stopped at 30 s after the trip
Pump startup                        BLOCKED  cause isolated: starting the rotor from zero
Core1D vs Core2D structure          PASS    identical axial shape to fifteen digits
1-D vs 2-D loop hydraulics          BLOCKED  15-ring initialization does not converge
Natural circulation                 NOT STARTED, as instructed
```

Nothing was tuned at any point. No tolerance was widened. Two assertions that were already
failing by a deliberate earlier decision were left exactly as they were.

### P. Open items

**Blockers for the natural circulation stage**

- **O-24 (new, BLOCKER).** The low-flow regime is not integrable. A loop that is isothermal,
  elevation closed and at rest has no bulk motion to dominate the solver's error test, and with a
  nearly incompressible fluid and a dynamic mass balance the integrator spends everything on
  acoustic modes: 0.036 s of simulated time per four minutes. This blocks the pump startup
  outright and stops the coastdown before its asymptote. **Natural circulation lives entirely in
  this regime**, so it cannot begin until this is resolved. Ruled out as causes: solver tolerance
  (three orders, no effect), the nonlinear solver choice, the homotopy path, the pump's zero-flow
  singularity, and the momentum formulation. The remaining candidates are the mass-balance
  formulation itself (`SteadyState` mass is what an incompressible loop wants, and TRANSFORM
  asserts against it unless the energy balance is also `SteadyState` or the medium is
  single-state) and state scaling.
- **O-25 (new, BLOCKER for accuracy, not for running).** The pump head is regularized with
  `regSquare` at `f_regularization = 1e-4` of the rated flow. The deviation from the exact
  quadratic is 6e-5 to 4e-6 over the 1-3 % of rated the natural circulation test runs at, which
  is harmless, but it grows as `(delta/V_flow)^2` and reaches 41 % at 1e-4 of rated. **A natural
  circulation run must report its sensitivity to `f_regularization` rather than assume it.**

**Non-blockers**

- **O-29 (new, BLOCKER for the 2-D branch).** `Loop_Hydraulics2D` compiles and then fails to
  initialize. Fifteen parallel rings under an algebraic momentum balance give a single coupled
  nonlinear system of 10 086 variables which neither the sparse nor the dense path converges.
  The 15 x 20 loop model is therefore not currently runnable, independently of O-24.
- **O-26 (new).** `PumpStartup_StagnantStart` imposes a **flat** axial precursor profile inside
  the channels against the true cosine, because `SaltPipe` hands TRANSFORM a
  `C_a_start`/`C_b_start` pair that it interpolates linearly. Total inventory, initial
  `Beta_eff` and the precursor content outside the core are all exact; only the timing of the
  sweep-out over the first core transit is affected.
- **O-27 (new).** `Steady_LoopBalance` asserts `tau_system_nominal = 25.63 +- 0.15 s`. The
  geometry delivers **27.41 s**, so this will fail. It is the same stale benchmark assertion as
  O-14 and was not touched; the model has not been simulated.
- **O-28 (new).** The Stage 3 `dp_nonstatic` plenum contribution and now the loop's own
  `dp_gravity` residual are both verified, but the **heat exchanger has had no thermal
  validation at all** — it was treated here as a hydraulic and inventory component only.

**Requires a decision that is not the modeller's to make**

- **O-14 / O-12B (escalated, `USER_DECISION_REQUIRED`).** The repository holds two mutually
  exclusive positions at once. Phase 4 and Phase 10 deliberately rebuilt the core geometry from
  ORNL/INL hardware and the plenum core nodes from referenced plenum totals, accepting that the
  reported transit times are no longer reproduced; but `Properties_TransitTime`,
  `Analytic_DriftReactivity` and `Steady_LoopBalance` still assert the reported values as errors,
  so three verification models abort. The measured gaps are:

  | Quantity | this geometry | Jeong/MARS | difference |
  |---|---:|---:|---:|
  | core transit time | 9.9630 s | 9.56 s | +4.2 % |
  | external loop transit time | 17.6876 s | 16.14 s | +9.6 % |
  | system transit time | 27.6507 s | 25.63 s | +7.9 % |
  | implied core density | 3014.21 kg/m³ | Cantor 2196.51 | +37.2 % |
  | **drift reactivity (Eq. 8)** | **226.09 pcm** | **228.35 pcm** | **−1.0 %** |

  The last row is the one that matters and it is the reassuring one: a 7.9 % transit-time
  difference moves the benchmarked reactivity by 1 %. But the choice between (a) accepting the
  hardware geometry and retiring those three assertions as benchmark comparisons, and
  (b) revisiting the core-boundary node volumes to recover the reported transit times, is a
  physical modelling decision with large consequences and is **not one to take unilaterally**.

## Phase 18 — Transit-time benchmark restructure, and O-24 measured

### A. The O-14 / O-12B decision, taken

Phase 17 escalated this as `USER_DECISION_REQUIRED`: the repository held two mutually exclusive
positions, having rebuilt the geometry from ORNL/INL hardware and the properties from Cantor
while three verification models still asserted the Jeong/MARS transit times as errors. The
decision received is to **keep the hardware geometry and the Cantor property model, and record
the difference against Jeong/MARS as a benchmark difference**.

That is implemented by splitting the *role* of each statement, not by loosening it:

| | Statement | Level |
|---|---|---|
| **Verification criterion** | `tau = rho*V/m_flow`, and `V_core + V_loop = V_total`. No benchmark number appears. | `error` |
| **Benchmark diagnostic** | the Jeong comparison, **original tolerance kept verbatim** | `warning`, tagged `BENCHMARK_DIFFERENCE` |

No Jeong reference value was deleted, no tolerance was widened, and no volume, density or
correlation was touched. New diagnostics: `err_tau_core_pct`, `err_tau_external_pct`,
`err_tau_total_pct`, `err_density_implied_pct`, `err_drho_forced_pct`, `err_drho_lo_pct`,
`err_drho_hi_pct`.

Measured, executed:

| Quantity | This library | Jeong/MARS | Difference |
|---|---:|---:|---:|
| core transit time | 9.8765 s | 9.56 s | +3.31 % |
| external loop transit time | 17.5341 s | 16.14 s | +8.64 % |
| system transit time | 27.4107 s | 25.70 s | +6.66 % |
| implied core density | 3014.21 kg/m3 | 2196.51 (Cantor) | +37.23 % |
| Eq. 8 at the *reported* transit times | 228.353 pcm | 228.4 pcm | -0.02 % |
| `Beta_circulating` | 0.00449747 | ~0.0045 | - |
| **drift reactivity** | **227.065 pcm** | **228.353 pcm** | **-0.56 %** |
| `drho_lo` / `drho_hi` | 0.8183 / 6.1991 pcm | 0.9 / 6.7 | -9.08 % / -7.48 % |

The three identity assertions hold to **exactly zero**. The two assertions that verify paper
Eq. 8 itself - `drho_forced` against 228.4 pcm and `Beta_circulating` against 0.0045 - are
unchanged, remain at `error`, and **pass**: they test the function and the Table 1 data, not the
geometry, so they are verification and not benchmark.

### B. The sandbox workaround set is not durable

Every loop-level model failed to **build**, not to solve, at the start of this phase. The cause
was that sandbox TRANSFORM workarounds 3 and 4 from Phase 17 were **gone** - the container had
been recycled between phases. Re-applied, with `.orig` kept beside each:

| # | File | Change |
|---|---|---|
| 3 | `Utilities/Visualizers/IconColorMap_1D.mo`, `HeatExchangers/GenericDistributed_HX{,_Rwall,_withMass}.mo` | `scalarToColor` frozen to a constant icon colour |
| 4 | `Fluid/.../HeatExchanger/GenericHX.mo:72` | `drs[nR,nV](each min=0)` |

**No Phase 17 loop result is reproducible in a fresh container until these are re-applied.**
Recorded as open item O-30: the workaround set belongs in a script, not in prose.

### C. O-24, measured at the closure level

`Verification/LowFlow_Closure.mo` evaluates `dp_DP_staticHead` - the exact function
`SinglePhase_Developed_2Region_NumStable` calls - at 29 mass flow rates from +168 kg/s through
**exactly zero** to -168 kg/s. No solver is involved, so this separates the mathematics of the
closure from the integrability of the assembled loop.

| Quantity | Measured |
|---|---:|
| `dp` at exactly zero flow | **0.0** |
| `dp` at +1e-3 / -1e-3 kg/s | +1.43820364757002e-4 / -1.4382036475700175e-4 Pa |
| odd-symmetry defect | **1.70e-15** |
| monotonicity violations | **0** of 28 intervals |
| sign errors | **0** of 29 points |
| secant slope, min / max | 163.95521582298198 / 163.95521582298244 Pa/(kg/s) |
| **slope dynamic range** | **1.0000000000000027** |

The slope is constant to fifteen digits across the whole sweep. The reason is physical: the
entire range is laminar - Re runs from 812 downwards - and laminar friction is exactly linear in
mass flow. The regularization band is `m_flow_small = 1.474e-4 kg/s` per channel, so the
+/-1e-3 kg/s points lie inside it; `regFun3` reproduces a linear function exactly, which is why
no kink appears there.

**O-24 classification, from measurement rather than assumption:**

| Candidate | Verdict | Evidence |
|---|---|---|
| `FRICTION_REGULARIZATION` | **ruled out** | slope range 1.0000000000000027 |
| `ZERO_FLOW_SINGULARITY` | **ruled out** | `dp(0) = 0` exactly, slope finite and constant through zero |
| flow reversal well-posedness | **PASS** | odd to 1.7e-15, monotone, sign-consistent |
| `MASS_DYNAMICS` | **standing candidate** | tested by the `LowFlow_Hydraulics` A/B |

This is necessary but not sufficient for natural circulation: a well-posed pressure-loss function
does not make the assembled loop integrable.

### D. Baseline confirmed after the workarounds were restored

`Loop_Hydraulics` reproduces the Phase 17 operating point exactly, which fixes the baseline this
phase builds on:

| Quantity | This run | Phase 17 |
|---|---:|---:|
| loop flow | 166.5420006 kg/s | 166.54 |
| `tau_core` | 9.96304429 s | 9.963 |
| `tau_external` | 17.68764511 s | 17.688 |
| `tau_loop_measured` | 27.6506894 s | 27.651 |
| `err_dpBalance` | 5.82e-11 Pa | 0.000000 |
| `err_inventory` | -8.88e-16 | 0.000000 |
| `dp_pump` | 301271.07 Pa | - |
| `M_loop_measured` | 4605.0011 kg | - |
| `Re_max` | 806.178 | - |

### E. An environment limit, recorded as such

`Steady_LoopBalance` **cannot be compiled in this container**. The OMC frontend reached
4.8 GB resident and was killed by the memory cgroup:

```
Memory cgroup out of memory: Killed process (omc)
total-vm:7393548kB, anon-rss:4800972kB
```

against a 16 GB machine already carrying other work, with the writable disk at 86 %. This is an
**environment limit, not a model defect** - the model translated and generated C in Phase 17.
Consequences: loop-level models must be compiled **one at a time**, and `Steady_LoopBalance`
remains unexecuted in this phase. Recorded as O-31.

The generated build artefacts are also large: the scratch build directory reached 2.6 GB across
a handful of loop models and had to be cleared mid-phase.

### F. Model size, measured (O-29 rung table, partial)

`checkModel` on the assembled models, all balanced:

| Model scope | Equations / variables | Trivial | Rung |
|---|---:|---:|---|
| `Core1D_TH_ZeroPower` — 1 ring + plena | 13 360 | 6 614 | reference |
| `Core2D_TH_ZeroPower` — **15 rings** + plena | **168 240** | 81 959 | 2 |
| `LowFlow_Hydraulics` — 1-D full loop | 29 326 | 14 629 | — |

The 15-ring core alone is **12.6x** the 1-D core and **5.7x the entire 1-D loop**. That is the
scale the O-29 initialization has to cope with, and it is measured rather than inferred.

### G. Two limits that bound what this phase could execute

1. **Memory.** `Steady_LoopBalance` was OOM-killed in the OMC frontend at 4.8 GB resident
   (O-31). Loop-level models must be compiled one at a time.
2. **My own defects.** Two syntax errors in new models - a stale `end` identifier carried over
   from the model one was derived from, and an unescaped quote inside a documentation string -
   broke the entire package load, so nothing compiled until they were fixed. Both were caught by
   the compiler, but they cost a build cycle each, and in a container where a loop build is
   25-40 minutes that is not free. A `checkModel` pass on new files before queueing a long build
   is the cheap guard.

### H. O-24: the A/B experiment, and what it actually showed

The hypothesis carried into this phase was that the mass-balance formulation was the cause and
that `massDynamics = SteadyState` would be the fix. **That is not what the measurement says.**
Both arms fail, in different ways, and the experiment refutes the hypothesis rather than
confirming it.

| Arm | mass / energy balance | Initialization | Integration |
|---|---|---|---|
| **A** baseline | `SteadyStateInitial` / `FixedInitial` | **succeeded** | **timed out at 2700 s** without reaching t = 0.05 s |
| **B** | `SteadyState` / `SteadyState` | **failed** - nonlinear solver assertion, `Division by zero` inside the friction inversion | never reached |

Arm B does not trade a slow run for a fast one; it trades a slow integration for an
initialization that does not converge at all. `MASS_DYNAMICS` is therefore **not** established as
the cause, and `SteadyState` mass is **not** a fix.

Arm A additionally logs trace-substance minimum-constraint violations at
`Cs = -1.5e-30`, physically negligible but not free: each one is solver work.

### I. A real defect, found by reading the source rather than by fitting

`TRANSFORM/Fluid/ClosureRelations/PressureLoss/Functions/TubesAndConduits/SinglePhase/LaminarTurbulent_MSLDetailed/Internal/m_flow_of_dp_fric.mo`

```modelica
line  70:  dRe_ddp := Re/abs(dp_fric)*dy_dx;
line 104:  dRe_ddp := 1/log(10)*(... + 2*2.51/(2*abs(dp_fric)*(2.51/aux2 + 0.27*Delta)));
```

The **inverse** friction law's derivative carries a genuine `1/|dp_fric|` singularity at zero
pressure drop. The returned `m_flow` itself is finite - `Re -> 0` - but the derivative, which is
exactly what a Newton solver asks for, diverges.

This is a different function from the one measured in section C. The **forward** law
`dp(m_flow)` is flawless: odd to 1.7e-15, monotone, slope constant to fifteen digits. The
**inverse** law `m_flow(dp)` is singular at the origin. Which one is used depends on the
`from_dp` switch in `SinglePhase_Developed_2Region_NumStable`, and a steady mass balance pushes
the system towards the `from_dp` direction.

**This matters for natural circulation specifically.** Natural circulation is a `from_dp`
problem by nature: buoyancy sets the pressure difference and the flow follows from it. So the
singular direction is the one the physics selects.

Revised O-24 classification, all of it measured or read from source, none of it inferred:

| Candidate | Verdict | Evidence |
|---|---|---|
| `FRICTION_REGULARIZATION` | **ruled out** | forward slope range 1.0000000000000027 |
| `ZERO_FLOW_SINGULARITY`, forward `dp(m_flow)` | **ruled out** | `dp(0) = 0` exactly, finite constant slope |
| `ZERO_FLOW_SINGULARITY`, inverse `m_flow(dp)` | **PRESENT** | `dRe_ddp ~ 1/abs(dp_fric)` at lines 70 and 104 |
| `MASS_DYNAMICS` | **not established, and not a fix** | arm B fails at initialization |
| `EVENT_CHATTERING` | **present, not yet quantified** | 1.37 GB of output inside a 0.05 s window |
| `ALGEBRAIC_LOOP`, `SOLVER_SCALING` | **open** | arm B's nonlinear failure is consistent with either |

Nothing was added to the model to make any of this pass. No friction multiplier, no artificial
minimum flow, no damping term.

### J. O-24: the dominant cause was ours, and it is fixed

OpenModelica localized the chattering exactly, which is what turned a two-phase-old open item
into a one-line fix:

```
Chattering detected around time 1.45816385667e-11..5.63778083291e-06
(100 state events in a row with a total time delta less than the step size 0.001).
The zero-crossing was: msre.m_flow_pump > 0.0
```

The pump's own equations are smooth: the characteristic is regularized with `regSquare` and
nothing in it branches on flow direction. The crossing comes from **`actualStream`**, which
expands to a conditional on `port.m_flow > 0` and which OpenModelica emits a state event for.

Every `actualStream` in this repository sits in **diagnostic-only** code - `h_a` and `h_b` in
`SaltPipe`, and `Q_enthalpy`, `T_in` and `T_out` in `ReactorCore` - all of it added in Phase 16
for the O-22 energy accounting. **No balance equation reads any of them.** The energy
diagnostics written to observe the loop were perturbing the solver they were meant to observe.

Wrapping them in `noEvent` changes no conserved quantity, no pressure, no flow, and none of
their own values away from the crossing itself.

Measured effect on the loop at rest, `StopTime = 0.05 s`, everything else identical:

| | before | after |
|---|---|---|
| outcome | timed out at 2700 s, then again at 1500 s | **completed, exit 0** |
| wall clock to reach t = 0.05 s | never reached | **235 s** (`timeSimulation` 115.2 s) |
| state events | 100 inside 5.6e-6 s, chattering | **0** |

This is a code defect in this repository, class `MODEL_FORMULATION`, and it is closed. It is not
a tuning change: nothing was fitted, no tolerance moved, no friction multiplier or artificial
minimum flow added.

**It is not the whole of O-24.** The remaining rate is 0.05 s of simulated time in 115 s of
integration, about 2300x slower than real time, against roughly 1.5e-4 s/s measured in Phase 17
- a factor of about three, not a transformation. Whether that residual rate is constant or
improves past the opening transient is the question that decides natural circulation readiness,
and it is measured separately rather than assumed.

A second contributor remains untouched by this fix: the `1/abs(dp_fric)` singularity in the
inverse friction law's derivative (section I), which lives in the `from_dp` direction that
natural circulation inherently selects.

### K. The chattering fix is not the whole of O-24 — correcting section J

Section J reported the `noEvent` fix as making the at-rest loop run. **That reading was too
optimistic and is corrected here.** A longer run fails:

| Run | Output intervals | Outcome | Reached | Integration time |
|---|---|---|---|---:|
| `StopTime = 0.05 s` | 50 | **completed** | 0.05 s | 115 s |
| `StopTime = 0.5 s` | 100 | **failed** | **t = 0.015 s** | 2066 s |

A shorter run completing while a longer one fails *earlier* is not robustness. What the fix
established is narrower than section J implied: the **event chattering is gone** - 0 state
events, measured - but the at-rest loop is still not reliably integrable.

### L. Third contributor: precursor trace states against a min = 0 constraint

The failing run logs 126 assertions of this form before it stops:

```
msre.core.lowerPlenum.pipe.Cs[2,1] >= 0.0  -->  has value: -3.1486e-18
```

`LowFlow_Hydraulics` is a **zero-power hydraulic** model. There is no fission, hence no precursor
source, so the trace states are identically zero as a matter of physics. Numerically they wander
to about 1e-17 and trip the `min = 0` constraint TRANSFORM places on `Cs`, once per group per
node. `LowFlow_Hydraulics_NoTrace` takes those states out of the integration with
`traceDynamics = SteadyState` to establish whether they are a contributor in their own right. No
hydraulic quantity in that model depends on them - not a pressure, not a flow, not an inventory.

That experiment is a **diagnostic on a hydraulic test model**. It is emphatically not a proposal
to run the benchmark without precursor transport, which would be a far larger claim.

### M. O-24 as it now stands

| Contributor | Status | Evidence |
|---|---|---|
| `FRICTION_REGULARIZATION` | **ruled out** | forward slope range 1.0000000000000027 |
| `ZERO_FLOW_SINGULARITY`, forward | **ruled out** | `dp(0) = 0` exactly |
| `EVENT_CHATTERING` (`actualStream` in our own diagnostics) | **FIXED** | 100 events in 5.6 us -> 0 |
| `ZERO_FLOW_SINGULARITY`, inverse | **present, untouched** | `dRe_ddp ~ 1/abs(dp_fric)` |
| Precursor trace states at `min = 0` | **identified, under test** | 126 assertions before failure |
| `MASS_DYNAMICS` | **unsupported as a cause** | `SteadyState` arm fails at initialization |
| `ALGEBRAIC_LOOP`, `SOLVER_SCALING` | **open** | - |

Three named, separable causes, one of them ours and closed. That is a better position than one
vague blocker, but it is **not** a cleared path: on this evidence
`READY_FOR_1D_NATURAL_CIRCULATION = NO`.

### N. A fifth TRANSFORM defect, found by tracing an under-determination

`traceDynamics = SteadyState` does not work in stock TRANSFORM. Setting it left the MSRE primary
loop under-determined:

```
Error: Too few equations, under-determined system.
The model has 28954 equation(s) and 29326 variable(s).
```

372 equations missing, which is exactly `nV * nC` = 62 volumes x 6 precursor groups. The cause is
in `TRANSFORM/Fluid/Pipes/BaseClasses/PartialDistributedVolume.mo`:

```modelica
if traceDynamics == Dynamics.SteadyState then
  for i in 1:nV loop
    zeros(Medium.nC) = mCbs[i, :];                        // only this
  end for;
else
  for i in 1:nV loop
    der(mCs_scaled[i, :]) = mCbs[i, :] ./ Medium.C_nominal;
    mCs[i, :] = mCs_scaled[i, :] .* Medium.C_nominal;     // absent from the branch above
  end for;
end if;
```

`mCs` is already fixed unconditionally by `mCs[i,:] = ms[i].*Cs[i,:]` earlier in the model, so in
the `else` branch the second line is what defines `mCs_scaled`. The `SteadyState` branch omits it
and leaves the scaled variable with no defining equation at all.

Worked around in the **sandbox copy only**, with `.orig` kept beside it, by adding the same
relation rearranged - `mCs_scaled[i,:] = mCs[i,:] ./ Medium.C_nominal` - which defines the
variable and adds no physics. Class: `TRANSFORM`. This is workaround 5; the set is now large
enough that O-30 (put them in a script) is no longer optional.

## Phase 19 — O-24 decomposed

### A. Trace states are not the primary contributor (Case B)

With the TRANSFORM `mCs_scaled` defect patched, `traceDynamics = SteadyState` builds and runs.
The A/B is unambiguous and **negative**:

| | baseline | NoTrace |
|---|---:|---:|
| simulated time reached | 0.015 s | **0.000013 s** |
| wall clock | 2066 s (failed) | 2400 s (timeout) |
| `Cs >= 0` assertions | 126 | **126, unchanged** |

NoTrace is **worse**, and the assertions did not go away. Two consequences:

```
TRACE_STATE_CONSTRAINT = SECONDARY / RULED_OUT_AS_PRIMARY
```

and `traceDynamics = SteadyState` is actively harmful here - it replaces nV*nC states with a
large algebraic system. The `Cs ~ -1e-17` violations are **not** caused by the dynamic trace
states, since removing those states left the count identical.

### B. The inverse closure passes - correcting Phase 18 section I

Phase 18 recorded the `1/abs(dp_fric)` singularity in `Internal.m_flow_of_dp_fric` as
`PRESENT / UNRESOLVED` and argued it sat in the `from_dp` direction natural circulation selects.
**The direction was right and the conclusion was wrong.** The singularity exists in the library
but is **never reached in use**: `dp_MFLOW_staticHead` regularizes with `regFun3` over
`|dp| < dp_small`, evaluating `m_flow_of_dp_fric` only at `+/-dp_small` and interpolating
between them, and carries `smoothOrder = 1`.

`Verification/LowFlow_InverseClosure.mo` measures it over 33 pressure differences from +1000 Pa
through exactly zero to -1000 Pa, including 1e-10 Pa deep inside the regularization band:

| Quantity | Measured |
|---|---:|
| `m_flow` at exactly `dp = 0` | **0** |
| `m_flow(+/-1e-10 Pa)` | +6.099226517e-13 / -6.099226484e-13 kg/s |
| odd-symmetry defect, absolute | **3.32e-21 kg/s** |
| the same, relative to rated per-channel flow | **2.25e-20** |
| monotonicity violations / sign errors | **0 / 0** |
| `dm_flow/ddp`, min / max | 1.052e-3 / 6.099e-3 kg/(s.Pa) |
| slope dynamic range | **5.797** |
| **`dm_flow/ddp` straddling zero** | **6.099e-3 kg/(s.Pa)** - finite, positive, and the largest in the sweep |

```
INVERSE_ZERO_FLOW_CLOSURE   = PASS
INVERSE_JACOBIAN_REGULARITY = PASS
```

A note on the metric, because the first run of this model **failed its own symmetry assertion**
at 5.44e-9. That was a defect in the test, not the closure: normalizing the defect by `|m_plus|`
divides by a quantity that is itself 6e-13, so ordinary double-precision cancellation inside
`regFun3`'s cubic appears as asymmetry. Normalized against **rated** flow - the scale the answer
has to be odd against - the defect is 2.25e-20. The self-relative number is retained as a
reported diagnostic so both remain visible. This is a better-posed metric, **not** a widened
tolerance.

### C. The remaining mechanism is the convection scheme itself

`GenericPipe_MultiTransferSurface`, lines 414-448:

```modelica
H_flows[i]     = semiLinear(m_flows[i], ...)
mXi_flows[i,:] = semiLinear(m_flows[i], ...)
mC_flows[i,:]  = semiLinear(m_flows[i], ...)
```

`semiLinear(x,p,n)` is `if x >= 0 then x*p else x*n` - the donor-cell upwind scheme for convected
enthalpy, species and trace substances. Three zero-crossings per pipe segment, all of which sit
exactly on the operating point a loop at rest occupies. OpenModelica named one directly:

```
Chattering detected ... 100 state events in a row
The zero-crossing was: msre.pumpBowl.pipe.m_flows[2] >= 0.0
```

This is categorically different from the `actualStream` chattering fixed in Phase 18. That was
instrumentation this repository had added. **This is the convection scheme**, in library code.
`semiLinear` is continuous at `x = 0`, so `noEvent` would be mathematically sound, but it is a
physics-path change in TRANSFORM and is recorded as a candidate remedy rather than applied.

### D. O-24 contributor table

| Contributor | Status | Evidence | Blocker? |
|---|---|---|---|
| Forward friction regularization | `RULED_OUT` | forward slope range 1.0000000000000027 | no |
| Forward zero-flow singularity | `RULED_OUT` | `dp(0) = 0` exactly, constant slope | no |
| Diagnostic event chattering (`actualStream`) | **`FIXED`** | 100 events in 5.6 us -> 0 | no |
| Inverse zero-flow singularity | `RULED_OUT` (guarded in use) | `dm/ddp(0) = 6.099e-3`, finite and positive | no |
| Inverse Jacobian regularity | `PASS` | slope range 5.797 | no |
| Trace `min = 0` noise | `SECONDARY` | NoTrace worse, 126 assertions unchanged | no |
| `traceDynamics` TRANSFORM defect | **`FIXED_IN_SANDBOX`** | 372 equations restored | no |
| **`semiLinear` upwind events at zero flow** | **`CONFIRMED_CONTRIBUTOR`** | named zero-crossing, 100 events in a row | **yes** |
| Mass dynamics | `NOT_CONFIRMED` | `SteadyState` arm fails at initialization | unknown |
| Algebraic loop | `OPEN` | - | unknown |
| Solver scaling | `OPEN` | - | unknown |

**No single primary cause is established.** One contributor was ours and is fixed; one is the
convection scheme and is confirmed; three candidates are ruled out by measurement; two remain
open. The forward and inverse closures are both sound, so **the blocker is not the friction
closure in either direction - it is at loop level.**

## Phase 20 — Chasing the zero-flow event source, and three corrections

### A. `semiLinear` is not the event source

`Verification/SemiLinear_ZeroCrossing.mo` measures the donor-cell operator on its own: a flow
`m_amplitude*sin(2*pi*f*t)` crossing zero ten times in 5 s, with **different donors** either side
so the switching is visible, and with the flux integrated so the model has states.

| Quantity | Measured |
|---|---:|
| state events | **0** |
| time events | **0** |
| `timeSimulation` for 5 s and 10 crossings | **0.0176 s** |

OpenModelica handles `semiLinear` specially and does not generate a zero-crossing for it. The
Phase 19 entry recorded `semiLinear` as `CONFIRMED_CONTRIBUTOR` on the strength of OMC naming
`msre.pumpBowl.pipe.m_flows[2] >= 0.0`, and inferred `semiLinear` from the `>= 0` form. **That
inference was wrong** and the status is corrected to `RULED_OUT`.

The first version of this test also had **no state variables**, and reported zero state events
for that reason alone. That number was an artefact of a test that could not fail, and it was
rebuilt with states before being believed.

### B. Two further hypotheses, both killed

- **`allowFlowReversal` assertion.** `PartialDistributedStaggeredFlow.mo:91` reads
  `assert(m_flows[i] > -m_flow_small or allowFlowReversal, ...)`, which would be a live relation
  if the flag were false. `PrimarySystem` sets `allowFlowReversal = true`, so the condition is
  trivially satisfied and optimized away. **Ruled out.**
- **Missing `smoothOrder` on the forward closure.** I recorded that `dp_MFLOW_staticHead` carries
  `annotation(smoothOrder=1)` while its forward sister `dp_DP_staticHead` did not, and proposed
  that as the defect. **That was an artefact of my own truncated `grep | head`**:
  `dp_DP_staticHead` carries the same annotation on its last line. Both functions are annotated.
  **Hypothesis withdrawn.**

### C. What the event source actually is: still open

Searching the generated `_info.json` for relations on `m_flows` finds only min/max constraint
assertions, which are checked at output points and are not zero-crossings. The crossing OMC
named does not appear as an equation, so it is generated inside an inlined function body, which
`_info.json` does not expose.

**I could not identify it.** The remaining candidates are branches inside the inlined closure
chain - `spliceTanh`, `Modelica.Fluid.Utilities.regFun3`, or `dp_MFLOW_staticHead`'s internal
`if dp > dp_zero` - where inlining can defeat a `smoothOrder` declaration. Determining which
requires reading generated C for a loop-scale model, which the container cannot currently
rebuild cheaply. Recorded as **O-32**, and deliberately left as an open question rather than
attributed to the most plausible candidate.

### D. Corrected contributor table

| Contributor | Status | Evidence |
|---|---|---|
| Forward friction regularization | `RULED_OUT` | slope range 1.0000000000000027 |
| Forward zero-flow closure | `PASS` | `dp(0) = 0` exactly |
| Inverse zero-flow closure | `PASS` | `m_flow(0) = 0`, odd to 2.25e-20 of rated |
| Inverse Jacobian regularity | `PASS` | `dm/ddp(0) = 6.099e-3`, finite and positive |
| Diagnostic event chattering (`actualStream`) | **`FIXED`** | 100 events in 5.6 us -> 0 |
| `semiLinear` transport switching | **`RULED_OUT`** (was `CONFIRMED_CONTRIBUTOR`) | 0 state events standalone, with states |
| `allowFlowReversal` assertion | `RULED_OUT` | flag is true; relation optimized away |
| Missing `smoothOrder` on forward closure | `RULED_OUT` | annotation is present; my grep was truncated |
| Trace `min = 0` noise | `SECONDARY` | NoTrace worse, 126 assertions unchanged |
| `traceDynamics` TRANSFORM defect | **`FIXED_IN_SANDBOX`** | 372 equations restored |
| Remaining zero-crossing source | **`OPEN` (O-32)** | not in `_info.json`; inside an inlined function |
| Mass dynamics | `NOT_CONFIRMED` | `SteadyState` arm fails at initialization |
| Algebraic loop / solver scaling | `OPEN` | - |

**No `PRIMARY_CAUSE` is established.** One contributor was ours and is fixed; one library defect
is patched; six candidates are now ruled out by measurement; the actual event source is
identified as existing but not yet located.

`FRICTION_CLOSURE = VERIFIED_THROUGH_ZERO` in both directions.

## Phase 21 — O-32: open chain passes, closed loop does not

### A. The discrimination the ladder was built for

| Model | Scope | Eq/Var | Result | `timeSimulation` | State events |
|---|---|---:|---|---:|---:|
| `O32_SinglePipe` | **open**, two pressure boundaries | 1 227 | **PASS** | 0.53 s | **6** |
| `O32_ReducedLoop` | **closed** circuit, same components | 4 575 | **FAIL at initialization** | - | - |

The open chain sweeps a driving pressure difference from +200 Pa through zero to -200 Pa and
comes out the other side, **with six state events**. So zero-crossing events are not by
themselves fatal, and the transport machinery crosses zero perfectly well when the pressure
level is anchored at both ends.

The closed loop, built from the same `SaltPipe` components, fails **at t = 0** - before the
sweep has even begun, while the drive is a healthy positive value.

### B. Two defects in my own test model, found and recorded rather than quietly fixed

1. **No pressure anchor.** The first version had `massDynamics = SteadyStateInitial` and no
   expansion tank, on the reasoning that dynamic mass makes pressure a state. That is wrong for a
   **closed** loop: `SteadyStateInitial` imposes `der(p) = 0`, a differential condition that
   leaves the absolute level free, so the initialization system is structurally singular. It
   failed with `der(legDown.pipe.flowModel.states[1].p) is inf or nan` - a pressure derivative as
   a diverging iteration variable, which is the signature of exactly that. The full primary loop
   escapes this because its pump bowl anchors the level.
2. **Drive starting at full amplitude.** Momentum is algebraic, so the initial flow is whatever
   the initial drive demands; starting the ramp at +2000 Pa with every `m_flow_a_start = 0` put
   the Newton guess far from the solution. The profile now starts from rest.

Neither failure was evidence about the full loop, and both are recorded because a test that fails
for its own reasons is worse than no test.

### C. What the closed loop actually reports

```
[ 1] legUp.pipe.mediums[1].T  =  288.15   nom = 300
regFun3(): Derivatives at data points do not allow co-monotone interpolation,
as both are non-zero, of opposite sign ... (y0d = 0.00159576, y1d = -114405)
```

The initialization begins with **every medium at 288.15 K**. For this salt that is not a
physically reachable state:

| T | `eta` (Cantor) | |
|---|---:|---|
| 908 K, operating | 0.0100 Pa.s | |
| 722.15 K, melting point | 0.0342 Pa.s | |
| **288.15 K, the start value used** | **292 Pa.s** | **29 198x operating, 434 K below freezing** |

Every closure is therefore evaluated far outside the range its correlation was fitted in, and
`Modelica.Fluid.Utilities.regFun3` fails its own co-monotonicity precondition with endpoint
derivatives of opposite sign.

### D. Where 288.15 K comes from, and why it could not be fixed here

`Media/FuelSalt` sets `T_default = 922.0`, but that is a **constant**: code that writes
`Medium.T_default` gets 922 K, while the inherited `Temperature` **type** from
`Modelica.Media.Interfaces.Types` still carries `start = 288.15`, and a state variable with no
effective start modification uses the type's value.

TRANSFORM does write one - `PartialDistributedVolume` declares
`mediums(..., T(start=Ts_start), ...)` with `Ts_start` built from `T_a_start` - and `SaltPipe`
forwards `T_a_start = 908` correctly. **It does not reach the variable.** A medium-level
`redeclare model extends BaseProperties(T(start=T_default, nominal=T_default), ...)` was tried
and **also did not take effect**: the iteration variable still showed `288.15, nom = 300`. That
change was reverted rather than left in place carrying a justification for an effect it does not
have.

Recorded as **O-33**: start-attribute modifications on medium `BaseProperties` state variables
are not reaching them under OMC 1.27.0. The mechanism is not established, so no class is
assigned yet.

### E. Status

```
O32_EVENT_SOURCE:                 NOT_IDENTIFIED
REDUCED_LOOP_ISOTHERMAL:          FAIL   (at initialization, before the sweep)
REDUCED_LOOP_DYNAMIC_ENERGY:      NOT_RUN (blocked by the isothermal rung)
REDUCED_LOOP_FLOW_THROUGH_ZERO:   NOT_RUN
REDUCED_LOOP_FLOW_REVERSAL:       NOT_RUN
OPEN_CHAIN_FLOW_THROUGH_ZERO:     PASS   (6 state events, reversal reached)
ALGEBRAIC_LOOP:                   OPEN
SOLVER_SCALING:                   OPEN   (O-33 is a scaling/start-value symptom, mechanism unknown)
FULL_LOOP_LOW_FLOW:               FAIL
PUMP_COASTDOWN_TO_LOW_FLOW:       NOT_RUN
READY_FOR_1D_NATURAL_CIRCULATION: NO
```

The one solid causal statement this phase supports: **an open chain of these components crosses
zero flow and reverses cleanly; a closed loop of the same components does not survive
initialization.** That is real discrimination, but it stops short of naming the mechanism,
because the closed-loop model has not yet been made to initialize at all.

### F. The closed loop's blocker, isolated by direct experiment

The 288.15 K start was patched **in the generated `_init.xml`**, not in the model, so the
experiment changes nothing about the physics and tests the causal chain directly.

| | before patch | after patch |
|---|---|---|
| `mediums[i].T` start | 288.15 K | **908 K** |
| `regFun3` co-monotonicity failures | many | **0** |
| nonlinear system 599 | failed | **solves** |
| nonlinear system 3375 | failed | **still fails** |

So the bad temperature start **was** the cause of the `regFun3` failures - that part of the chain
holds - but it was **not** the only blocker. What remains:

```
Solve nonlinear system 3375 at time 0
  [ 1] legUp.port_a.h_outflow                = 1275850.1   nom = 1000000
  [ 3] connBottom.pipe.m_flows[3]            = 0           nom = 1
  [ 4] connBottom.pipe.mediums[2].T          = 908         nom = 300
  [ 6] connBottom.pipe.flowModel.states[1].p = 100000      nom = 100000
  [ 8] legDown.pipe.m_flows[3]               = 0           nom = 1
  [11] legDown.pipe.flowModel.states[1].p    = 100000      nom = 100000
  [14] legUp.pipe.m_flows[2]                 = 0           nom = 1
  [17] connTop.pipe.flowModel.states[1].p    = 100000      nom = 100000
  ...18 variables...
  Solution status: FAILED
  iterations: 9129   function evaluations: 97253
```

**Eighteen variables spanning all four pipes in one system** - stream enthalpies, segment flows,
node temperatures and flow-model pressures coupled together. The open chain has no equivalent:
its pressure boundaries fix `h` and `p` at both ends and break the coupling. This system exists
**because the loop is closed**, and it is the same structure as O-29's 10 086-variable system on
the 15-ring loop, at 1/500 the size.

```
ALGEBRAIC_LOOP = CONFIRMED
```

A scaling observation from the same dump, recorded but not yet tested: every
`flowModel.states[1].p` starts at **100000** with `nom = 100000`, while the loop actually runs at
**150000 Pa**. That is a 50 kPa start error on a pressure that feeds the friction closure, and
the nominal is the medium's default rather than the model's operating pressure. `SOLVER_SCALING`
stays `OPEN` because that has not been varied in isolation.

### G. Corrected status

```
O32_EVENT_SOURCE:                 NOT_IDENTIFIED
OPEN_CHAIN_FLOW_THROUGH_ZERO:     PASS  (6 state events, reversal reached)
REDUCED_LOOP_ISOTHERMAL:          FAIL  (initialization, coupled 18-variable system)
REDUCED_LOOP_DYNAMIC_ENERGY:      NOT_RUN
REDUCED_LOOP_FLOW_THROUGH_ZERO:   NOT_RUN
REDUCED_LOOP_FLOW_REVERSAL:       NOT_RUN
ALGEBRAIC_LOOP:                   CONFIRMED
SOLVER_SCALING:                   OPEN (start p = 1e5 against an operating 1.5e5; not yet varied)
MEDIUM_T_START (O-33):            CONFIRMED as the regFun3 cause; not the whole blocker
FULL_LOOP_LOW_FLOW:               FAIL
PUMP_COASTDOWN_TO_LOW_FLOW:       NOT_RUN
READY_FOR_1D_NATURAL_CIRCULATION: NO
```

## Phase 22 — Pressure start and solver scaling, isolated one variable group at a time

All cases keep the `T(start) = 908 K` patch from Phase 21 and change **one variable group only**,
applied to the generated `_init.xml` so no model equation, parameter or solver option moves.

| Case | `p(start)` | `p(nominal)` | Result | Iterations | Function evals | Jacobian |
|---|---|---|---|---:|---:|---|
| **A** | 100 000 (as generated) | as generated | FAIL | **9 129** | 97 253 | (nearly) singular |
| **B** | **150 000** | as generated | FAIL | **4 417** | 87 570 | (nearly) singular |
| **C** | 150 000 | **150 000** | FAIL | **4 767** | 88 640 | (nearly) singular |

All three fail in the **same** nonlinear system (3375), and all three report:

```
Homotopy solver total pivot: Matrix (nearly) singular at initialization.
```

Residual magnitudes: Case A `-1.89e+22`; Cases B and C `-7.72e+16`.

### Verdicts

- **`PRESSURE_START_MISMATCH = CONTRIBUTING, NOT ROOT CAUSE`.** Correcting the start from
  100 kPa to the operating 150 kPa **halves** the Newton iteration count, 9 129 to 4 417, and cuts
  the worst residual by six orders of magnitude. That is a real and measurable improvement in
  conditioning. It does not change the outcome: the same system still fails and the matrix is
  still singular.
- **`SOLVER_SCALING = REFUTED`** for the `p` nominal. Case C is marginally **worse** than Case B
  (4 767 against 4 417 iterations), which is within run-to-run noise and certainly not an
  improvement. `m_flow` and `h` nominals were not varied, so scaling is refuted only for the
  variable that the evidence actually pointed at.

### Root cause: the initialization system is structurally singular

A singular Jacobian that survives every start-value and nominal change is not a conditioning
problem. Two initial-condition formulations were measured and **both** are singular, for
**opposite** reasons:

| Formulation | Failure | Why |
|---|---|---|
| `SteadyStateInitial`, no anchor | `der(p)` iteration variable goes inf/nan | `der(p) = 0` leaves the absolute pressure level free - **under-determined** |
| `FixedInitial` | matrix nearly singular, 1e16-1e22 residuals | pins `p = ps_start` at **every** volume while the momentum balance also constrains the pressure differences - **over-determined** |

The correct closed-loop formulation is `SteadyStateInitial` for the volumes **plus exactly one
pressure anchor** - which is what `PrimarySystem` has in its pump bowl, and what this reduced
model lacked. Adding a TRANSFORM `ExpansionTank` as that anchor was tried and **still fails**, in
a different system (854 / 3728), so the anchor is necessary but has not by itself been shown
sufficient. That remains open.

### Status

```
REDUCED_LOOP_ISOTHERMAL:   FAIL (initialization; singular Jacobian in the closed-loop system)
PRESSURE_START_MISMATCH:   CONTRIBUTING, NOT ROOT CAUSE  (9129 -> 4417 iterations)
SOLVER_SCALING:            REFUTED for p nominal; m_flow and h nominals not varied
ROOT_CAUSE:                structurally singular closed-loop initialization system
EVIDENCE:                  identical failure and "Matrix (nearly) singular" across A/B/C;
                           under- and over-determined formulations both singular
NEXT_BLOCKER:              find the correct closed-loop initial-condition set - one anchor plus
                           der(p)=0 - that is neither under- nor over-determined
```

## Phase 23 — Structural audit of the closed-loop initialization

### A. The anchor I added in Phase 22 was not an anchor

`ExpansionTank`'s initial equations decide this, and they were read rather than assumed:

```modelica
if massDynamics == Dynamics.FixedInitial then
  level = level_start;          // ABSOLUTE
elseif massDynamics == Dynamics.SteadyStateInitial then
  der(level) = 0;               // DIFFERENTIAL
```

with `port_a.p = p = p_ambient + rho*g*level`. Only the fixed form yields an equation that pins
the loop's absolute pressure. Phase 22 set the tank to `SteadyStateInitial`, so **every** equation
in the loop was differential in pressure and nothing fixed the level. The tank was structurally
inert. Corrected to `FixedInitial`, with the pipes left `SteadyStateInitial`, which is the
intended "der(p)=0 everywhere plus exactly one absolute reference".

### B. Measured effect of the correction

| Case | Configuration | Iterations | Function evals | Worst residual | Singular? |
|---|---|---:|---:|---:|---|
| A | no working anchor, `FixedInitial` volumes | 9 129 | 97 253 | -1.89e+22 | yes |
| B | + `p(start)` 150 kPa | 4 417 | 87 570 | -7.72e+16 | yes |
| **D** | **tank `FixedInitial`** + `T` 908 K + `p(start)` 150 kPa | **366** | **13 078** | ~1e-5 to 0.98 | **yes** |

A **25x** reduction in Newton iterations and a **22 orders of magnitude** reduction in the worst
residual. The anchor fix is real and large.

**It is not sufficient.** `Matrix (nearly) singular at initialization` still appears in Case D.
An earlier draft of this entry claimed the singularity was resolved; that came from grepping the
wrong log file and is corrected here.

### C. The remaining system

`Non-Linear System 3723 (size 40)`, iteration variables include:

```
[1] der(tank.port_a.m_flow)                      nom = 1
[2] der(connTop.port_b.m_flow)                   nom = 1
[3] der(tank.level)                              nom = 100
[4] der(connTop.pipe.flowModel.states[1].p)      nom = 1
[5] der(connBottom.pipe.flowModel.states[1].p)   nom = 1
[6] der(tank.h)                                  nom = 1e+08
```

### D. Redundancy hypothesis, stated but NOT yet confirmed

`massDynamics = SteadyStateInitial` imposes `der(p) = 0` on **every** volume - here 15 across
five pipes. In a **closed** circuit those pressure states are not independent: loop mass
conservation ties them together, so one of the `der(p) = 0` conditions is linearly dependent on
the rest, and the initial system is over-determined by rank 1 no matter how good the start values
are. That would explain a near-singular matrix that survives a correct anchor.

This is a **hypothesis**. It has not been confirmed by inspecting the Jacobian's null space or by
removing one condition and re-running, and it is recorded as a candidate rather than a finding.

### E. Status

```
REDUCED_LOOP_ISOTHERMAL:  FAIL
FAILED_SYSTEM:            3723, size 40 (was 3375 before the anchor; 854/3728 with the inert tank)
SINGULAR_VARIABLES:       der(tank.level), der(tank.h), der(tank.port_a.m_flow),
                          der(connTop.port_b.m_flow),
                          der(connTop|connBottom .pipe.flowModel.states[1].p)
REDUNDANT_EQUATIONS:      candidate - der(p)=0 on all 15 volumes of a closed circuit, one of
                          which loop mass conservation should make dependent. NOT CONFIRMED.
MISSING_EQUATIONS:        none identified
PRESSURE_ANCHOR_COUNT:    1 (tank, FixedInitial -> level = level_start). Verified from source,
                          not inferred.
ROOT_CAUSE:               PARTIALLY CONFIRMED. Missing absolute pressure reference was real and
                          is fixed. A second structural defect remains.
MODEL_FIX:                tank massDynamics SteadyStateInitial -> FixedInitial
EVIDENCE:                 9129 -> 366 iterations; worst residual 1.89e22 -> ~1; singular message
                          persists in all cases
NEXT_STEP:                confirm or refute the rank-1 redundancy by inspecting the null space,
                          or by giving exactly one pipe FixedInitial pressure and re-running
```

Per the standing rule, no advance to dynamic energy, zero-flow crossing, flow reversal, pump
coastdown or natural circulation until `REDUCED_LOOP_ISOTHERMAL` passes.

## Phase 24 — The rank-1 redundancy hypothesis, tested and refuted

### A. Making the experiment controlled

With `nV = 3` per pipe, switching any pipe to `FixedInitial` changes **three** initial equations
at once. The pipes were therefore set to `nV = 1`, at which point the choice of anchor differs by
**exactly one** initial equation, and a `use_tank` switch selects which component supplies it:

| | anchor | absolute pressure equation |
|---|---|---|
| `use_tank = true` | `ExpansionTank` | `level = level_start` |
| `use_tank = false` | `connBottom` | `p = ps_start` on its single volume |

Everything else - `T(start) = 908 K`, operating-point pressure starts, `SteadyStateInitial` on the
remaining pipes, solver options, tolerance, homotopy - is held fixed.

### B. Result

OpenModelica reports the Jacobian rank directly, so nullity is measured rather than inferred:

| Variant | Anchor | Size | Ranks observed | Best-case nullity | Singular msgs | Iterations | Result |
|---|---|---:|---|---:|---:|---:|---|
| **E** | tank | 19 | 17, 18 | **1** | 7 603 | 588 | FAIL |
| **F** | `connBottom` | 14 | 11, 12, 13 | **1** | 1 415 | 591 | FAIL |

Swapping the anchor shrinks the system from 19 to 14 and cuts singular reports by 5.4x, so it is
not a null change. But the **rank deficiency is still there**, and at the best iterate the nullity
is 1 in both.

In variant F the pressure conditions balance exactly: three `der(p) = 0` plus one absolute, for
four pressure states. **The count is right and the matrix is still deficient.**

### C. Verdict

```
RANK_1_REDUNDANCY (as redundant der(p)=0 pressure conditions) = REFUTED
```

The hypothesis was that `der(p) = 0` on every volume of a closed circuit leaves one condition
linearly dependent, so that supplying exactly one absolute pressure equation would restore full
rank. It does not. A deficiency of at least rank 1 survives a correct anchor count, and it
survives the tank being removed entirely, so it is **not** a tank artefact either.

What is now established:

- the deficiency is **rank 1 at the best iterate**, in both anchor configurations;
- it is **not** caused by redundant pressure initial conditions;
- it is **not** caused by the anchor component's own states, since variant F has no tank at all;
- rank **degrades further** as the iterate wanders (17 and 11 at worst), which is why the residuals
  and iteration counts vary so much between configurations while the outcome does not.

### D. Status

```
REDUCED_LOOP_ISOTHERMAL:   FAIL
JACOBIAN_SINGULAR:         YES, in every configuration tested
JACOBIAN_RANK:             E: 17-18 of 19    F: 11-13 of 14
NULLITY:                   1 at the best iterate in both; up to 2 (E) and 3 (F) at worse iterates
DEPENDENT_EQUATION:        NOT IDENTIFIED - the null space was not extracted, only its dimension
DEPENDENT_VARIABLE:        NOT IDENTIFIED
RANK_1_REDUNDANCY:         REFUTED as redundant pressure initial conditions
ROOT_CAUSE:                NOT IDENTIFIED. Two candidates are eliminated, not one confirmed.
MODEL_FIX:                 none this phase. The Phase 23 anchor fix stands and remains a large
                           conditioning improvement (9129 -> 366 iterations).
EVIDENCE:                  measured ranks above; controlled single-equation change; tank present
                           and tank absent both deficient
NEXT_BLOCKER:              extract the actual null vector to name the dependent equation, rather
                           than testing hypotheses about which one it is
READY_FOR_DYNAMIC_ENERGY:  NO
```

Two hypotheses have now been eliminated by controlled experiment rather than by argument. That is
progress of the eliminative kind, and it is not the same as knowing the cause.

## Phase 25 — The null vector, extracted

### A. Method

Variant F unchanged (`nV = 1`, `use_tank = false`, `T(start) = 908 K`, operating-point pressure
starts, stock solver settings). `-lv=LOG_NLS_JAC` dumps the actual numerical Jacobian of the
failing system, and `LOG_NLS_V` gives the column ordering. 1 420 raw `[14x15]` dumps were
captured; the homotopy column was dropped and an SVD taken of each `14x14` Jacobian.

**No model, parameter, solver, tolerance or homotopy setting was changed in this phase.**

### B. Result

| | |
|---|---|
| dumps analysed | 1 420 |
| **rank** | **7 of 14 in 1 411 of them** |
| **nullity** | **7** |
| condition number (first dump) | 5.50e+22 |
| smallest singular values | 5.78e+00, 8.30e-02, 8.14e-05 |

Right null vector, top components by frequency across all deficient dumps:

```
1412x   legDown.pipe.mediums[1].T
1411x   legDown.port_b.h_outflow
   2x   legDown.pipe.flowModel.states[1].p
```

Null-space energy by variable class:

```
  81.66 %   T          temperature
  18.22 %   h          stream enthalpy
   0.12 %   p          pressure
   0.00 %   der(p)     pressure derivatives
```

**The undetermined direction is 99.9 % temperature and enthalpy, and essentially zero pressure.**

### C. Correction to Phase 24

Phase 24 reported `NULLITY: 1`, taken from OpenModelica's own `rank = 11/12/13` messages. Those
refer to a different matrix - scaled or partial - than the raw Jacobian dumped here. The measured
SVD of the actual Jacobian gives **rank 7, nullity 7**. The Phase 24 figure is withdrawn.

This also means Phases 22-24 were chasing the wrong quantity: every hypothesis tested there was
about **pressure** initial conditions, and pressure carries **0.12 %** of the null space. The
pressure anchor work was not wasted - it removed a real and separate defect, and cut iterations
from 9 129 to 366 - but it was never going to resolve this.

### D. Why temperature is undetermined, from the model equations

`energyDynamics = SteadyState` gives, per volume,

```
0 = H_flows[i] - H_flows[i+1] + Q     with   H_flows[i] = semiLinear(m_flows[i], h_upstream, h_downstream)
```

and `semiLinear(0, a, b) = 0` for **any** `a` and `b`. At zero flow every enthalpy flow vanishes
regardless of the enthalpies, so the steady energy balance is satisfied identically and carries
**no information about temperature at all**. In a **closed** loop nothing else constrains it:
there is no boundary imposing an inlet enthalpy. The loop's temperature level is free, exactly as
its pressure level was free before an anchor was added.

This is the same class of defect as the pressure anchor, one level up, and it explains the
open/closed discrimination directly: `O32_SinglePipe` passes because its pressure boundaries also
impose `h` at the inlet, which determines the temperature. The closed loop has no such equation.

### E. Status

```
REDUCED_LOOP_ISOTHERMAL:   FAIL
FAILED_SYSTEM:             1591
SYSTEM_SIZE:               14
JACOBIAN_RANK:             7  (1411 of 1420 dumps)
NULLITY:                   7

RIGHT_NULL_VECTOR_TOP_COMPONENTS:
  1. legDown.pipe.mediums[1].T          coefficient 1.000
  2. legDown.port_b.h_outflow           coefficient 0.473
  3. legDown.pipe.flowModel.states[1].p coefficient 0.0004
  4. (remaining components below 1e-4)
  5. -

LEFT_NULL_VECTOR_TOP_EQUATIONS:
  1. equation row 7    coefficient -1.000
  2. equation row 9    coefficient -0.0003
  3. equation row 3    coefficient +0.0002
  4. (remaining below 1e-4)
  5. -

UNDETERMINED_VARIABLE_COMBINATION:   temperature and stream enthalpy, 99.9 % of the null space
DEPENDENT_EQUATION_COMBINATION:      the steady energy balance rows, degenerate at zero flow

ROOT_CAUSE_HYPOTHESIS:  energyDynamics = SteadyState makes every energy equation identically
                        satisfied at zero flow, because H_flow = semiLinear(m_flow, .., ..) = 0
                        for any enthalpy when m_flow = 0. A closed loop then has no equation
                        determining its temperature level.
CONFIDENCE:             HIGH - the null space is 81.7 % temperature and 18.2 % enthalpy by
                        energy, consistently across 1411 dumps, and the mechanism is visible in
                        the model equations rather than inferred.
DISCRIMINATING_TEST:    change exactly one thing - energyDynamics from SteadyState to
                        FixedInitial, which pins T at t = 0 without altering any equation - and
                        re-measure the rank. Predicted: nullity falls from 7 towards 0.
                        If the rank does not improve, the hypothesis is refuted.

MODEL_CHANGE_THIS_PHASE:  NONE

READY_FOR_DYNAMIC_ENERGY: NO
```

## Phase 26 — The energy initialization degeneracy, confirmed and fixed

### A. The exact equation change, read from source before running anything

Our medium is `pTX`, so `PartialDistributedVolume` generates:

| | balance equation | initial equation |
|---|---|---|
| `SteadyState` (F) | `0 = Ubs[i]` — algebraic, `U` is not a state | **none** |
| `FixedInitial` (G) | `der(Us[i]) = Ubs[i]` — `U` becomes a state | **`mediums.T = Ts_start`** |

At `m_flow = 0` every `H_flows[i] = semiLinear(0, ., .) = 0`, so F's `0 = Ubs[i]` reduces to
`0 = 0` and carries no information about temperature. G adds **4** absolute thermal equations,
one per pipe at `nV = 1`.

### B. Result of changing only `energyDynamics`

| | Variant F | Variant G |
|---|---|---|
| `energyDynamics` | `SteadyState` | `FixedInitial` |
| largest nonlinear system | **1 system of size 14** | **size 6**, then 4s and 1s |
| Jacobian rank / size | **7 of 14** | no failing Jacobian to dump |
| nullity | **7** | - |
| `Matrix (nearly) singular` messages | **1 415** | **0** |
| Newton iterations at the failing system | 591 | **0** (immediate convergence) |
| initialization | **FAIL** | **PASS** |
| simulation | FAIL | **PASS**, `timeSimulation` 0.638 s |

Nothing else changed: `nV = 1`, no tank, one pressure anchor on `connBottom`, `T(start) = 908 K`,
operating-point pressure starts, stock solver, tolerance and homotopy.

### C. The causal chain, measured rather than argued

Variant F's Jacobian column norms, averaged over all 1 420 dumps and normalized to the largest
column:

| variable class | mean relative column norm |
|---|---:|
| **T** | **4.098e-03** |
| **h** | **4.098e-03** |
| `der(p)` | 4.099e-03 |
| **p** | **4.736e-01** |

The temperature and enthalpy columns carry **116x less sensitivity** than the pressure columns.
That is the predicted mechanism seen directly: with a steady energy balance at zero flow the
enthalpy-flow equations have essentially no derivative with respect to `T` or `h`, the
corresponding columns collapse, and the null space is 81.7 % `T` and 18.2 % `h`. Supplying
absolute thermal information restores rank and the degeneracy disappears.

### D. Physical check of the passing run

| quantity | measured |
|---|---|
| `m_flow` at t = 0 | -3.13e-06 kg/s |
| `m_flow` at t = 2 s | +287.609 kg/s |
| **`m_flow` at t = 7 s** | **-9.38e-10 kg/s** (the zero crossing) |
| `m_flow` at t = 12 s | -287.628 kg/s |
| forward / reverse symmetry | 0.007 % |
| `reversed` flag | true |
| T range | 907.989 - 908.005 K |
| density range | 2196.543 - 2196.553 kg/m3 |

The closed loop is driven from rest to forward flow, **through exactly zero**, and into reverse,
with temperature and density physical throughout.

### E. An honest qualification about what "isothermal" now means

`FixedInitial` does not give a steady energy balance with a pinned temperature - it gives a
**dynamic** energy balance whose initial temperature is fixed. So Variant G is already the
dynamic-energy case, and the isothermal/dynamic-energy distinction that the earlier ladder
assumed collapses here: the degenerate formulation was `SteadyState` energy, not dynamic energy.
The measured T range of 16 mK shows the loop stays isothermal in practice, as it must with no
power and no heat transfer, but that is a **result** rather than an imposed constraint.

### F. Status

```
VARIANT_F:
  energyDynamics:  SteadyState
  system size:     14
  rank:            7
  nullity:         7
  result:          FAIL

VARIANT_G:
  energyDynamics:  FixedInitial
  system size:     6 (largest; then 4s and 1s)
  rank:            full - no deficient Jacobian produced
  nullity:         0
  result:          PASS

T_NULLSPACE_BEFORE:   81.66 %
T_NULLSPACE_AFTER:    n/a - no null space
H_NULLSPACE_BEFORE:   18.22 %
H_NULLSPACE_AFTER:    n/a - no null space

ENERGY_INITIALIZATION_DEGENERACY:  CONFIRMED  (Case 1)
ROOT_CAUSE:  energyDynamics = SteadyState leaves the energy balance identically satisfied at
             zero flow, because H_flow = semiLinear(m_flow, .,.) = 0 for any enthalpy when
             m_flow = 0. A closed loop has no boundary enthalpy, so its thermal state is
             undetermined and the Jacobian loses rank in exactly the T and h directions.
EVIDENCE:    rank 7/14 -> full; 1415 singular messages -> 0; T and h column norms 116x below
             the pressure columns in F; null space 81.7 % T and 18.2 % h; single-variable
             controlled change with everything else held fixed
MODEL_FIX_STATUS:  DEMONSTRATED IN THE DIAGNOSTIC MODEL ONLY. Not yet adopted as the library's
             initialization policy - see below.
NEXT_BLOCKER:  none for the reduced isothermal loop
READY_FOR_DYNAMIC_ENERGY:  YES
```

### G. What is deliberately NOT concluded

Per the standing instruction, `FixedInitial` is **not** hereby adopted as the final thermal
initialization policy. What is established is narrower and should stay that way: **a closed loop
being initialized at or near zero flow requires absolute thermal information**, because the
steady energy balance provides none there. Whether an already-circulating loop can still be
initialized with `SteadyStateInitial` thermal states is a separate question with a separate
experiment, and the full `PrimarySystem` has not been touched.

## Phase 27 — Thermal initialization policy, and the reduced-loop coastdown

### A. Tests H and I: does non-zero flow rescue the steady energy balance?

The hypothesis under test was that with `m_flow != 0` the enthalpy flows would regain sensitivity
to `T` and `h`, making `SteadyState` energy admissible for an already-circulating loop. Only
`energyDynamics`, `m_flow_start` and the matched `dp_initial` differ between runs; the pressure
anchor, `T(start)`, `p(start)`, solver, tolerance and homotopy are all held fixed. `dp_initial`
was chosen from the laminar linearity measured in Test H (2000 Pa gives 287.6 kg/s), not fitted.

| Test | `energyDynamics` | `m_flow_start` | Rank | Null space T / h / p | Singular msgs | Result |
|---|---|---:|---|---|---:|---|
| F | `SteadyState` | 0 | **7 of 14** | 81.66 / 18.22 / 0.12 % | 1 415 | FAIL |
| **I** | `SteadyState` | **100 kg/s** | **6 of 14** | **81.65 / 18.29 / 0.06 %** | 1 427 | **FAIL** |
| **H** | `FixedInitial` | 0 | **full** | no null space | **0** | **PASS** |

Mean relative Jacobian column norms: Test I gives `T` 4.067e-03, `h` 4.067e-03, `p` 4.736e-01 -
the same 116x deficit as Test F.

**The hypothesis is REFUTED.** Non-zero flow changes essentially nothing: rank, null-space
composition and column norms are the same to three significant figures.

The reason is visible in the equations. With flow present the steady balance becomes
`0 = m_flow*(h_upstream - h_downstream)`, which forces every temperature to be **equal** but
leaves their common **level** entirely free. Multiplying a degenerate constraint by a non-zero
number does not make it determine anything.

### B. Policy, and an important limit on it

```
zero-flow startup        absolute thermal initialization REQUIRED
already-circulating loop absolute thermal initialization ALSO REQUIRED
```

This is **broader** than the policy split anticipated, and it follows the standing instruction to
re-examine the policy more widely if finite flow also proved singular.

**The limit, stated because it matters more than the result.** This reduced loop is
**adiabatic**: no fission power, no heat exchanger, no wall heat transfer. The real
`PrimarySystem` has a heat exchanger with a prescribed coolant inlet temperature and a fission
source, and **either of those supplies exactly the absolute thermal information this loop
lacks**. So the finding may well not transfer: the full loop could be perfectly well posed with
`SteadyState` energy. That has **not been tested**, `PrimarySystem` has not been touched, and no
library-wide initialization policy is being adopted on this evidence.

### C. Test J: coastdown from rated flow through zero into reversal

Driven from the rated point down to zero and beyond, with `FixedInitial` energy:

| Quantity | Measured |
|---|---|
| initial flow | +287.629 kg/s |
| flow at t = 5.02 s | +129.129 kg/s |
| **zero crossing** | between t = 8.9800 s and t = 8.9897 s, +0.6319 -> **-9.384e-10 kg/s** |
| smallest resolved flow | **9.384e-10 kg/s** |
| samples below 1 kg/s | **410** |
| final flow | -196.107 kg/s |
| temperature range | 907.9892 - 908.0016 K |
| density range | 2196.5456 - 2196.5531 kg/m3 |
| assertions | **0** |
| result | **PASS**, `timeSimulation` 0.288 s |

The loop coasts through the entire low-flow regime, resolves flows down to 1e-9 kg/s, crosses
zero and reverses, with temperature and density physical throughout.

206 state events were logged, about 100 of them chattering at t = 8.99 s on the zero-crossing
`m_flow < -1e-6`. That condition is **the `reversed` diagnostic flag in this test model**, not
model physics - a `when` clause added to record whether reversal occurred. It is an artefact of
the instrument, it did not prevent the run from passing, and it should be removed or wrapped
before this pattern is reused.

### D. Status

```
TEST_H_ZERO_FLOW_FIXEDINITIAL:
  result:   PASS (reproduced)
  rank:     full - no deficient Jacobian produced
  nullity:  0

TEST_I_FINITE_FLOW_STEADYSTATE:
  result:   FAIL
  rank:     6 of 14
  nullity:  8

THERMAL_INITIALIZATION_POLICY:
  zero-flow:    absolute thermal initialization REQUIRED
  finite-flow:  absolute thermal initialization ALSO REQUIRED
                (for an ADIABATIC loop - the full system has an HX and a fission source that
                 may supply it instead; untested)

PUMP_COASTDOWN_TO_LOW_FLOW:  PASS  (287.629 -> 9.4e-10 kg/s, 410 samples below 1 kg/s)
ZERO_FLOW_CROSSING:          PASS  (crossed at 9.384e-10 kg/s)
FLOW_REVERSAL:               PASS  (to -196.107 kg/s, reversed flag set)

ROOT_CAUSE_STATUS:   CONFIRMED for the reduced loop, with the mechanism measured in the Jacobian
MODEL_POLICY_STATUS: NOT GENERALIZED. Demonstrated in the diagnostic model only; PrimarySystem
                     untouched; the adiabatic limitation above is the reason.
NEXT_BLOCKER:        whether the full PrimarySystem needs this at all, given its heat exchanger
                     and fission source already supply absolute thermal information
READY_FOR_1D_NATURAL_CIRCULATION:  NO
```

`READY` stays NO. What has been shown is that a **reduced, adiabatic, prescribed-drive** loop
initializes, coasts through zero and reverses. Natural circulation is a different problem: the
drive is buoyancy, which requires the dynamic energy equation and a real temperature difference,
and none of that has been exercised.

## Phase 28 — Does the reduced-loop thermal defect exist in PrimarySystem?

### A. Equation-level audit, before running anything

`Systems/PrimarySystem.mo:170`:

```modelica
parameter Modelica.Fluid.Types.Dynamics energyDynamics = Modelica.Fluid.Types.Dynamics.FixedInitial
```

**`PrimarySystem` already uses the policy the reduced loop needed.** It has never run with
`SteadyState` energy, so the degeneracy found in Phases 25-27 was never exposed there. That is a
third answer to the question, and neither of the two anticipated cases.

Baseline, measured this session: `Loop_Hydraulics` initializes with **0 singular messages**,
"initialization finished successfully without homotopy", giving 166.5420 kg/s and
`err_dpBalance` 5.8e-11 Pa.

### B. The candidate thermal references, and why none of them is obviously sufficient

| Candidate | Where | Assessment |
|---|---|---|
| `expansionTank`, `Boundary_pT(T = T_start)` | line 309 | connects through a surge line carrying **~zero flow**. With `H_flow = semiLinear(m_flow, ., .)` a zero-flow branch transmits **no** enthalpy information - the same mechanism that caused the reduced-loop degeneracy. Looks like a thermal boundary; may transmit nothing. |
| `coolantInlet`, `MassFlowSource_T(T_coolant_start)` | line 433 | secondary side; reaches the primary only through the HX wall. Plausible reference, but indirect. |
| fission source `Qs_core` | line 230 | a heat **source**, not a reference. Sources fix gradients, not levels. Not counted. |

None of these can be settled by inspection, which is why the counterfactual was run rather than
argued.

### C. The counterfactual could not be executed

`PrimarySystem` with `energyDynamics = SteadyState`, sandbox copy only, everything else
untouched:

```
checkModel   PASS   29 402 equations, 29 402 variables, balanced
buildModel   SEGMENTATION FAULT (exit 139), reproduced twice
```

The OMC **backend** crashes; flattening succeeds and the equation count balances. Memory was not
the cause - 14.9 GB free, and the output file is empty because the crash preceded any flush.

Recorded as **O-34**, class `OPENMODELICA_DEFECT`. The sandbox `PrimarySystem` has been restored
to `FixedInitial`.

Note that `checkModel` passing proves nothing about rank here: the reduced loop also passed
`checkModel` while its initialization Jacobian was rank 7 of 14.

### D. Status

```
PRIMARYSYSTEM_INITIALIZATION:      PASS (as shipped, with energyDynamics = FixedInitial)
FAILED_SYSTEM:                     none - the shipped configuration does not fail
SYSTEM_SIZE:                       n/a
JACOBIAN_RANK:                     n/a - no deficient Jacobian is produced
NULLITY:                           n/a

NULLSPACE_T:                       n/a
NULLSPACE_H:                       n/a
NULLSPACE_P:                       n/a
NULLSPACE_MFLOW:                   n/a

THERMAL_REFERENCE_FROM_HX:         NOT ESTABLISHED - counterfactual blocked by O-34
THERMAL_REFERENCE_FROM_SOURCE:     NOT A REFERENCE - a heat source fixes gradients, not levels
THERMAL_REFERENCE_FROM_BOUNDARY:   NOT ESTABLISHED - the expansion tank is on a zero-flow branch,
                                   which under semiLinear transmits no enthalpy information

SAME_AS_REDUCED_LOOP_ROOT_CAUSE:   NOT APPLICABLE - PrimarySystem never used SteadyState energy,
                                   so the defect was never exposed there
PRIMARYSYSTEM_THERMAL_REFERENCE:   UNKNOWN. The shipped model does not need one, because
                                   FixedInitial supplies the absolute thermal state directly.
                                   Whether the HX and boundaries would suffice on their own is
                                   untested and now blocked.
MODEL_CHANGE_THIS_PHASE:           NONE to PrimarySystem. The only repository change is the
                                   O-32 diagnostic flag, replaced with a continuous tracker.

NEXT_BLOCKER:                      O-34, an OMC backend segfault, blocks the counterfactual.
                                   It does not block natural circulation work, because the
                                   shipped configuration initializes cleanly.
READY_FOR_1D_NATURAL_CIRCULATION:  NO
```

### E. What this does and does not license

The practical position is better than it looks: `PrimarySystem` **initializes cleanly as
shipped**, with dynamic energy and a fixed initial thermal state, which is exactly the
configuration the reduced loop needed to cross zero flow and reverse. The open question is
academic for the benchmark - whether the HX alone *could* have supplied the reference - and it
stays open rather than being answered by assertion.

`READY` remains NO. Nothing here exercises buoyancy, a real temperature difference around the
loop, or the natural circulation drive.

## Phase 29 — Dymola readiness audit (Dymola itself is not available here)

### A. Dymola cannot be run in this environment

No installation, no license, no Python interface:

```
which dymola dsimulate        -> nothing
/opt/dymola*, /usr/local/*    -> nothing
import dymola                 -> not present
DYMOLA / LM_LICENSE env vars  -> unset
```

**No Dymola result is reported in this phase**, and none should be inferred from anything below.
What follows is the preparation that does not require the tool: a tool-neutrality check, an
equation-level audit of the natural circulation prerequisites, and a run script.

### B. The repository is tool-neutral

All five OpenModelica workarounds live in the **sandbox TRANSFORM copy** and are applied by
`tools/apply_sandbox_workarounds.sh`. A grep of the repository for OMC-specific residue returns
only three **comments** explaining why a `noEvent` is there - no code. `tools/dymola_verification.mos`
states explicitly that the workaround script must **not** be applied for a Dymola run, since
Dymola accepts the stock library.

### C. Natural circulation prerequisites, audited at equation level

| # | Prerequisite | Evidence | Status |
|---|---|---|---|
| 1 | elevation closure | `dz_closure` sums all nine rises; **measured `+0` exactly** | PASS |
| 2 | gravity in the momentum path | `flowModel(dheights=dheights)`, and `dp_DP_staticHead` forms `dp_grav = g*dz*IN_var.rho_a` from the **local node density** | PASS |
| 3 | real vertical geometry | `dz_channels +1.6256`, `dz_hxShell -1.5`, `dz_downcomer -2.2256` m | PASS |
| 4 | pump does not obstruct | at `N = 0`, `head = -R_pump*regSquare(V_flow)` - a pure resistance, no imposed head | PASS |
| 5 | exactly one primary pressure anchor | two `Boundary_pT`: `expansionTank` (primary) and `coolantOutlet` (**secondary**) | PASS |
| 6 | HX heat sink present | `coolantInlet` `MassFlowSource_T` + `coolantOutlet`, secondary side | PASS |
| 7 | flow is a result, not an input | `NaturalCirculation.mo` has **no** `MassFlowSource` and no prescribed `m_flow`; `pumpSpeed.y = 0` throughout; `m_flow_start = 1.5` is an iteration guess | PASS |

Point 2 is the one that matters for buoyancy and it is the one most easily assumed: the static
head is built from **each node's own density**, not a loop-average, so a temperature difference
around the loop produces a net head. That is the natural circulation driver and it is present.

Point 7 is the one most easily got wrong: a natural circulation test that prescribes its own flow
proves nothing. This model does not.

### D. What is NOT verified

- Every number in this phase comes from **OpenModelica**. Cross-tool agreement is unverified.
- The buoyancy head has never been **evaluated** - prerequisites 1-7 establish that the terms
  exist and are wired, not that they produce a circulation of the right magnitude.
- `PumpCoastdown_RotorDynamics` and `NaturalCirculation` have not been run in this session in
  either tool.

### E. Status

```
DYMOLA_PRIMARYSYSTEM_INITIALIZATION:  NOT_RUN - Dymola unavailable in this environment
LOW_FLOW:                             NOT_RUN in Dymola
ZERO_FLOW_CROSSING:                   NOT_RUN in Dymola
FLOW_REVERSAL:                        NOT_RUN in Dymola

CORE_DT:            NOT_MEASURED
HX_DT:              NOT_MEASURED
DENSITY_DIFFERENCE: NOT_MEASURED
BUOYANCY_HEAD:      NOT_MEASURED
FRICTION_LOSS:      NOT_MEASURED
PUMP_HEAD:          NOT_MEASURED

NATURAL_CIRCULATION_FLOW:  NOT_MEASURED
PHYSICAL_CONSISTENCY:      NOT_ASSESSED

OPENMODELICA_O34:  recorded as a diagnostic-only OpenModelica backend defect. It blocks the
                   SteadyState-energy counterfactual and nothing else. NOT a PrimarySystem
                   blocker, and explicitly separated from Dymola physical verification.
MODEL_CHANGE:      NONE. Only tools/dymola_verification.mos was added.
NEXT_BLOCKER:      Dymola access. Every prerequisite that can be checked without it passes.
READY_FOR_1D_NATURAL_CIRCULATION:  NO - the gate requires executed results, and none exist yet
                                   in Dymola.
```

For the record, the OpenModelica reference values the Dymola run should be compared against are
carried in `tools/dymola_verification.mos` beside each experiment, so the comparison is set up
before the run rather than rationalized after it.

---

## Phase 30 — OpenModelica pre-verification of the natural circulation chain

Tool roles are now split and fixed (see `docs/DYMOLA_B0_BASELINE.md`): **OpenModelica for
pre-verification and sensitivity, Dymola for final physical confirmation and benchmark
results.** Nothing below is a Dymola result and nothing below replaces one.

### A. Loop_Hydraulics cross-tool comparison — `CROSS_TOOL_MATCH`

Eleven quantities compared against the Dymola B0 baseline. Ten match to between 4e-9 and 1e-5
relative. The one exception is `dp_loop_gravity` (Dymola −1.20131 Pa, OpenModelica −1.199578 Pa,
1.4e-3 relative), which is a residual left after cancelling static heads of order 1e5 Pa: a
1.4e-3 difference on the residual is a ~1e-8 difference on the terms.
`CROSS_TOOL_SMALL_DIFFERENCE`, cause `numerical cancellation`, no action. Full table in
`docs/DYMOLA_B0_BASELINE.md` section K.

### B. `Pump_ZeroSpeed` — PASS

The natural circulation model leaves the pump in the loop at zero speed, so the pump must be a
passive resistance there. Swept over the whole characteristic, 41 points from +168 to −168 kg/s:

| Quantity | Value |
|---|---:|
| `dp` at rated forward flow | −75003.75 Pa |
| `dp` at zero flow | 0 exactly |
| `dp` at rated reverse flow | +75003.75 Pa |
| max power delivered to the stream | 0 |
| anti-symmetry error | 4.85e−16 relative |
| monotonicity violations | 0 of 40 intervals |

**A correction to how this check was first written.** The first version asserted that `dp` is
never positive. That is wrong and it failed on correct behaviour: `dp` is `p_b − p_a` and
`regSquare` is anti-symmetric, so at `N = 0` the head is negative in forward flow and
**positive in reverse flow** — which is exactly what a resistance does, since the pressure falls
in whichever direction the fluid moves. The invariant that holds in both directions is that the
component delivers no power to the stream, `V_flow*dp <= 0`, and that is what is asserted now,
here and in the loop model.

### C. `HX_LowFlow_Closure` — **CONFIRMED DEFECT**, blocks natural circulation

`MSRE.ClosureRelations.Nus_MoltenSalt` (Gnielinski) is used on both sides of the heat exchanger.
Gnielinski carries a factor `(Re − 1000)`. The reproduction of the correlation used here is
verified against the rated point in the closure's own documentation first — 8637.31 / 101.566 /
1811.74 against the stated 8637 / 101.6 / 1812 — so the numbers below are the closure's, not an
approximation of it.

| fuel flow | shell `Re` | shell `Nu` | shell `alpha` [W/(m2.K)] |
|---:|---:|---:|---:|
| 100 % | 8637 | 101.57 | 1811.7 |
| 50 % | 4319 | 49.79 | 888.2 |
| 25 % | 2159 | 19.87 | 354.4 |
| **10 %** | 864 | **−2.85** | **−50.9** |
| **5 %** | 432 | **−14.21** | **−253.4** |
| **2 %** | 173 | **−27.47** | **−490.1** |
| **1 %** | 86 | **−36.86** | **−657.5** |

The shell side Nusselt number **crosses zero at 11.58 % of rated flow** and is negative below it.
A negative Nusselt number is a negative heat transfer coefficient, which reverses the direction
of the heat flow: the heat exchanger would *heat* the fuel salt instead of cooling it, inverting
the very density difference that drives natural circulation. The closure also leaves its stated
validity range (`Re = 3000`) below **34.7 %** of rated flow. `Re_min = 100` guards only the
friction-factor logarithm, so below `Re = 100` it freezes the wrong value rather than fixing it.

**Scope of the defect, measured rather than assumed:**

| Model | Flow range | Sink `dT` | Affected |
|---|---|---|---|
| `Loop_Hydraulics` | rated | 0 K, `Q = 0` | no |
| `PumpStartup` | rated | `T_coolant_start = T_start`, `Q = 100 W` | no |
| `PumpCoastdown` | falls to 5.6 % of rated | `T_coolant_start = T_start`, `Q = 100 W` | no |
| `Experiments.NaturalCirculation` | a few % of rated | 14 K, `Q = 8 kW` | **yes, entirely** |
| `Verification.NaturalCirculation_TH` | a few % of rated | 14 K | **yes, entirely** |

The pump coastdown does fall below 11.58 % of rated (Dymola B0: 15.7 % at 20 s, 10.9 % at 30 s,
5.61 % at 60 s).

**A correction, made in phase 31.** I first wrote here that both pump tests run at 100 W with the
coolant inlet held at the fuel salt temperature, so the heat exchanger transfers essentially
nothing and the sign of `alpha` could not matter. **That was wrong.** `Loop_Hydraulics` reports

```
W_pump = 28554.5 W        at 166.542 kg/s
```

which is 285 times the 100 W fission power. At steady state the heat exchanger must remove that
pump work, so its duty in the pump tests is of order 29 kW, not zero. The claim that the pump
tests are unaffected therefore had no basis and is withdrawn; whether they are affected is a
question for the regression, not for an argument.

**Candidate fix, not applied.** `MSRE.ClosureRelations.Nus_Core` is already in this library, is
already used by the fuel channels, and already has the right structure: a generic fully
developed laminar closure below `Re = 2300`, Gnielinski above `Re = 3000`, smoothstep between.
`HX_LowFlow_Closure` reports what it would give on the shell side, for comparison only.
Adopting it is a physics correction rather than a calibration — nothing in it is fitted — but it
would change the heat exchanger duty at low flow, so under the standing rule it must be measured
against **both** the pump startup and the pump coastdown before it can be called an improvement,
and the Dymola baseline would have to be re-established. Not applied here; the decision is the
user's.

The reasoning in `Nus_Core`'s documentation for leaving the heat exchanger on plain Gnielinski —
"both its sides run at Re of order 1e4" — is correct at rated flow and is exactly the assumption
that natural circulation breaks.

### D. `NaturalCirculation_TH` — initialization, and a correction

The verification model itself: pump left in the loop with its speed driven to exactly zero,
core power held constant by the flux servo so the kinetics cannot influence the flow, one
pressure anchor, gravity on, and nothing prescribed about the flow at any time. It reports
`Q_core -> dT_core -> delta_rho -> dp_buoyancy -> m_flow` as separate quantities so a break can
be located rather than inferred.

**First attempt: start from a stagnant isothermal loop.** Fails at initialization on the
65-unknown loop pressure network, with or without homotopy.

**A correction.** I first attributed that to a donor-cell degeneracy — the upwind weight being
the flow, so a face temperature having no determining equation at exactly zero flow. That
reading was wrong. Running without homotopy and reading the *start values* handed to Newton
shows the actual anomaly:

```
[1] msre.outletPipe.pipe.flowModel.states[5].T = 288.15   nom = 300
[2] msre.pumpBowl.pipe.flowModel.states[1].T   = 288.15   nom = 300
[3] msre.pumpBowl.pipe.flowModel.states[4].p   = 100000   nom = 100000
```

288.15 K and 1 bar are the Modelica defaults, not this model's 908 K and 1.5e5 Pa. All three are
**end-face** states of a pipe (`statesFM[1]` and `statesFM[nFM+1]`), which
`GenericPipe_MultiTransferSurface` declares `protected` with no start attribute. At 288.15 K the
fuel salt is far outside its property range, so the linear-density medium returns a meaningless
density and the KLU setup fails. This is open item **O-33**, and it is an initialization
start-value gap, **not a physics defect and not a zero-flow degeneracy** — the same failure
occurs at 1160 rpm.

That it does not bite `Loop_Hydraulics` is a property of the tearing, not of the model:
`Loop_Hydraulics` was re-run in this same sandbox and still initializes cleanly, so the
regression baseline is intact.

Tested by single-variable override on the built executable, each one at a time:

| Changed | Override applied? | Result |
|---|---|---|
| `Q_core_test` 1e5 -> 0 | yes | still fails - **ruled out** |
| `t_null` 0 -> 300 | yes | still fails - **ruled out** |
| `T_sink` 894 -> 908 | **NO** | verdict withdrawn, see below |
| pump speed source: `Ramp` -> constant rated | n/a, rebuilt | still fails - **ruled out** |

**A correction to my own method.** I first read all three overrides as having applied and
reported `T_sink` as ruled out. It was not. The run log says

```
LOG_STDOUT | warning | It is not possible to override the following quantity: T_sink
```

`T_sink` appears both as a start value and inside a `RealExpression`, so OpenModelica evaluates
it at compile time and `-override` cannot reach it; the run silently continued with 894 K. Only
`Q_core_test` and `t_null` were genuinely varied. The `T_sink` verdict is withdrawn and is being
retested by rebuild. Any override result in this repository is only evidence if the log shows
no "not possible to override" warning for that quantity.

`T_sink` is now the one remaining difference from `Loop_Hydraulics`, which runs with
`T_coolant_start = T_start` and therefore with no temperature difference across the heat
exchanger at t = 0.

**Second attempt: run the physical transient instead.** The model now initializes at rated pump
speed — the operating point `Loop_Hydraulics` proves initializes — and the pump speed is then
ramped to exactly zero. That is the physical natural circulation situation, it prescribes
nothing about the flow, and it carries the loop through the low-flow region as a transient where
the face states are carried by the integrator rather than solved for from nothing.

**A refuted hypothesis.** I first suspected the `Q_hx` diagnostic, which took `actualStream()`
on a connector inside the system model and so added an outside reader to a stream connection
set. Replacing it with a sum of the shell-side wall heat flows **did not change the failure** —
the same system 6803 still fails at t = 0. The hypothesis is refuted and recorded as such. The
replacement was kept anyway, because reading the duty from the wall heat flows is the better
diagnostic on its own merits and it also gives the per-node duty the heat exchanger audit wants.

### E. Independent calculation — what natural circulation flow to expect

Not a simulation result. A closed-form balance of the two terms, to size the run before
spending it:

```
buoyancy      dp_buoy = drho*g*H_thermal,  H_thermal = 2.0628 m,  drho = 0.562*dT_loop
energy        dT_loop = Q/(m*cp),          cp = 2009.66 J/(kg.K)
friction      the quadratic form losses collapse at low flow, leaving roughly the
              27 % of the rated 3.0e5 Pa that is distributed (laminar, linear in m)
```

which gives `m^2 ~ 1.17e-5*Q`, so

| `Q_core` | `m_flow` | fraction of rated | `dT_loop` | loop transit time |
|---:|---:|---:|---:|---:|
| 100 kW | ≈ 1.1 kg/s | ≈ 0.65 % | ≈ 46 K | ≈ 4300 s |
| 1 MW | ≈ 3.4 kg/s | ≈ 2.0 % | ≈ 145 K | ≈ 1400 s |

Two consequences, both of which change the plan:

1. The expected natural circulation flow is **0.5 to 2 % of rated**, which is deep inside the
   region where section C shows the heat exchanger closure returns a negative heat transfer
   coefficient. A converged natural circulation result obtained through the present closure
   would not be interpretable, whatever it came out as.
2. Steady state takes several loop transit times, so a run of order **2e4 s** is needed, not the
   4e3 s first set. Any shorter run reports a transient as a steady state.

### F. Root cause of the `NaturalCirculation_TH` initialization failure — `O-33`, identified

Everything about the operating point and the pump-speed source is now eliminated by controlled
single-variable tests, each verified to have actually taken effect:

| Changed | How tested | Result |
|---|---|---|
| `Q_core_test` 1e5 -> 0 | override, applied | still fails - ruled out |
| `t_null` 0 -> 300 | override, applied | still fails - ruled out |
| `T_sink` 894 -> 908 | **rebuild**, after the override was found not to apply | still fails - ruled out |
| pump speed `Ramp` -> constant rated | rebuild | still fails - ruled out |
| `Q_hx` `actualStream` -> wall heat flows | rebuild | still fails - ruled out |

The seeds handed to the failing Newton system are `288.15 K, nominal 300` and
`100000 Pa, nominal 100000`. Those are not defaults chosen by this model, by TRANSFORM, or by
the pipe. They come from `Modelica.Media.Interfaces.Types`:

```
type Temperature      = SI.Temperature     (min=1, max=1e4, nominal=300,   start=288.15);
type AbsolutePressure = SI.AbsolutePressure(min=0, max=1e8, nominal=1e5,   start=1e5);
```

`ThermodynamicState` is built from those two types, and the pipe end-face states
(`GenericPipe_MultiTransferSurface.statesFM`, declared `protected` with no start attribute)
inherit them. **The start value is hard-coded in the type and is independent of the medium's
`T_default`**, which is 922 K here — so setting `T_default` cannot reach it. That is why the
earlier attempt to fix `O-33` by redeclaring `BaseProperties(T(start=T_default))` had no effect:
it was aimed at the wrong declaration.

At 288.15 K the MSRE fuel salt is roughly 400 K below its melting point and far outside the
range the Cantor correlations are fitted over, so the linear-density medium returns a
meaningless density there and the KLU setup fails.

**Classification: `OPENMODELICA_TOOL_LIMITATION` surfacing an MSL type default. NOT a physics
defect.** Nothing in the momentum, energy or mass balance is implicated, no equation is wrong,
and the same model fails at 1160 rpm as at rest, so it is not a zero-flow degeneracy either.
Whether a given model survives depends only on whether OpenModelica's tearing happens to expose
those variables as iteration variables: `Loop_Hydraulics` was re-run in this same sandbox and
still initializes cleanly, so the regression baseline is intact.

**No in-repo fix is available.** Neither `Temperature` nor `AbsolutePressure` is declared
`replaceable` anywhere in `Modelica.Media.Interfaces.Types` or in TRANSFORM's copy of the media
interfaces, so a medium in this library cannot redeclare them; and `statesFM` is `protected`
inside TRANSFORM, so the pipe cannot be reached either. The remaining options are a sandbox
patch to the library (an `OPENMODELICA_WORKAROUND`, not a model change) or Dymola, whose
initialization and tearing are different and which may not expose these variables at all.

### G. Status after phase 30

```
CROSS_TOOL_LOOP_HYDRAULICS:   CROSS_TOOL_MATCH (dp_loop_gravity CROSS_TOOL_SMALL_DIFFERENCE)
PUMP_ZERO_SPEED:              PASS  (OpenModelica, executed)
HX_LOW_FLOW_CLOSURE:          CONFIRMED_DEFECT - negative Nusselt below 11.58 % of rated flow
NATURAL_CIRCULATION_TH:       BLOCKED_NOT_RUN - two independent blockers, see below

CORE_DT:            NOT_MEASURED
HX_DT:              NOT_MEASURED
DENSITY_DIFFERENCE: NOT_MEASURED
BUOYANCY_HEAD:      NOT_MEASURED
FRICTION_LOSS:      NOT_MEASURED
PUMP_HEAD:          measured statically (Pump_ZeroSpeed), NOT_MEASURED in the loop

NATURAL_CIRCULATION_FLOW:  NOT_MEASURED
PHYSICAL_CONSISTENCY:      NOT_ASSESSED

BLOCKER_1 (physics):  the heat exchanger closure returns a negative heat transfer coefficient
                      throughout the expected natural circulation flow range. A converged
                      result obtained through it would not be interpretable whatever it was.
                      Fix candidate identified (Nus_Core structure), NOT applied - it changes
                      the low-flow duty and must be measured against BOTH pump transients and
                      re-baselined in Dymola first.
BLOCKER_2 (tooling):  O-33, above. OPENMODELICA_TOOL_LIMITATION, no in-repo fix available.

MODEL_CHANGE:      NONE to any physics equation, geometry value or property correlation.
                   Three verification models added; one diagnostic definition changed.
READY_FOR_1D_NATURAL_CIRCULATION:  NO
```

Blocker 1 is the one that matters. Blocker 2 only decides *which tool* can run the check;
blocker 1 decides whether the answer would mean anything, and it must be resolved first.

---

## Phase 31 — HX low-flow closure replaced; system regression blocked by O-33

### A. What the code trace found (STEP 1)

| Item | Value | Source |
|---|---|---|
| shell `Re` | `d*dimensions*abs(v)/mu`, `dimensions` = `Dh_shell` | `PartialSinglePhase.mo:16` |
| shell `Pr` | `mu*cp/lambda` | `PartialSinglePhase.mo:17` |
| `L_char` | defaults to `dimensions` = `Dh_shell` | closure model |
| `alpha` | `Nu*lambda/L_char` | closure model |
| `UA` | `1/(Rs_add + 1/(alpha*A))` | `PartialHeatTransfer_setQ_flows.mo:44` |
| shell arrangement | axial counter-current duct, `StraightPipeHX` | `PrimarySystem.mo:390` |

The `UA` line makes the defect worse than phase 30 reported: at `Re = 1000` exactly, `alpha = 0`
and **`UA` divides by zero**. It is a singularity at 11.58 % of rated flow, not only a sign error
below it.

`Dh_shell = 0.05606` is itself flagged `OPEN / TO BE REVIEWED` (O-16); INL gives 0.0209 m. With
the INL value `Re` is 2.68 times smaller and the singularity moves **up** to about 31 % of rated
flow, so that open item cannot excuse the defect.

### B. `Nus_HX` — why not simply `Nus_Core`

Same three-branch structure, different value, for a stated physical reason:

| | core fuel channel | heat exchanger, both sides |
|---|---|---|
| what sets the wall condition | fission heat in the graphite, independent of the salt | tube wall pinned near the coolant, at rated flow and fixed inlet T |
| idealization | constant heat flux | constant wall temperature |
| fully developed laminar `Nu` | 4.36 | **3.66** |

A duct closure and not `FlowAcrossTubeBundles_Grimison`, because the geometry actually integrated
is `StraightPipeHX` - an axial duct - not a bundle in crossflow. Conservative as well: the shell
thermal entry length is `0.05*Re*Pr*Dh` = 56 m at `Re = 1000`, against `L_shell` = 2.44 m, so the
shell is thermally developing and the true `Nu` is higher than fully developed. Nothing is fitted
to any transient, MARS result or MSRE measurement.

### C. Closure regression (STEP 2) — **PASS**, seven criteria fixed before evaluation

| flow % | `Re` | `Nu_old` | `Nu_new` | `h_old` | `h_new` |
|---:|---:|---:|---:|---:|---:|
| 100 | 8637 | 101.566 | **101.566** | 1811.74 | **1811.74** |
| 50 | 4319 | 49.790 | 49.790 | 888.16 | 888.16 |
| 34.73 | 3000 | 32.124 | 32.124 | 573.03 | 573.03 |
| 26.63 | 2300 | 21.998 | 3.660 | 392.41 | 65.29 |
| 20 | 1728 | 13.054 | 3.660 | 232.86 | 65.29 |
| **11.58** | **1000** | **0.000** | 3.660 | **0.00** | 65.29 |
| 10 | 864 | −2.855 | 3.660 | −50.92 | 65.29 |
| 5 | 432 | −14.207 | 3.660 | −253.43 | 65.29 |
| 1 | 86 | −36.862 | 3.660 | −657.54 | 65.29 |
| 0.1 | 8.6 | −36.862 | 3.660 | −657.54 | 65.29 |

`nNegative = 0` · `UA` bounded, max 43595 W/K, floor 1571 W/K · C0 and C1 residuals **exactly 0**
· monotone · `err_ratedInvariance` **exactly 0** · `Nu(Re -> 0) -> 3.66`.

**Two of my own tests were wrong and were repaired.** The C0 and C1 checks first sampled `Nu` at
`Re +/- 1e-6`; that failed on a *correct* closure, because across a continuous function the two
samples differ by `slope*2*eps` (0.014*2e-6 = 2.8e-8 at the upper boundary - the slope, not a
jump) and the finite-difference derivative on a 1e-6 step is round-off dominated. They are now
exact identities on the blend weight (`w = 0, dw/dx = 0` at the lower end; `w = 1, dw/dx = 0` at
the upper end), asserted at exactly zero, which is stricter. The sweep array was also reordered
to be strictly descending in flow, without which criterion 5 was not testing what it claimed.

### D. System regression (STEP 3) — **BLOCKED by O-33, not by the closure**

`Loop_Hydraulics` rebuilt with `Nus_HX` **fails to initialize**, where the old-closure binary of
the same model initializes cleanly in the same sandbox. The failing system moved from 6802 to
6861, consistent with the blend adding variables per node.

The failure signature is identical to phase 30 section F - the same three variables:

```
[1] msre.outletPipe.pipe.flowModel.states[5].T = 288.15   nom = 300
[2] msre.pumpBowl.pipe.flowModel.states[1].T   = 288.15   nom = 300
[3] msre.pumpBowl.pipe.flowModel.states[4].p   = 100000   nom = 100000
```

**Discriminating test, so that the closure is not blamed by association.** `Nus_HX` was run with
`Re_laminar = 1, Re_turbulent = 2` (overrides verified to have applied - no "not possible to
override" warning). The blend weight is then 1 for every `Re >= 2`, so the model returns
**exactly** the old Gnielinski value while keeping the extra variables in the equation system. It
still fails to initialize. Therefore the laminar branch and every numerical property of the new
correlation are **exonerated**; the cause is the changed tearing tipping the model across the
pre-existing O-33 knife-edge.

This raises O-33 from a curiosity affecting one new model to the blocker on regressing an
ordinary, correct physics change to an established model **in OpenModelica**. It says nothing
about Dymola, whose tearing and initialization are different.

### E. What can still be stated about the closure change without running the system

At the `Loop_Hydraulics` steady state, `m_flow` = 166.542 kg/s, so

```
Re_shell = m_flow*Dh_shell/(A_shell*mu) = 166.542*0.05606/(0.109016*0.0100020) = 8562
```

which is far above `Re_turbulent` = 3000. There the blend weight is exactly 1 and `Nus_HX`
reduces identically to the previous closure, with `err_ratedInvariance` measured at exactly zero.
**The converged steady state of `Loop_Hydraulics` is therefore unchanged by construction** - a
proof, not a simulation. It says nothing about the transient path from rest, which does pass
through `Re < 3000`, nor about the coastdown, which ends at 5.6 % of rated flow. Those need a run.

### F. A correction carried from phase 30

The claim that the pump tests are unaffected because the heat exchanger transfers essentially
nothing is **withdrawn**. `Loop_Hydraulics` reports `W_pump = 28554.5 W`, 285 times the 100 W
fission power, so the heat exchanger duty in those tests is of order 29 kW. Whether the startup
and coastdown results move is a question for the regression, and that regression has not been run.

### G. Status after phase 31

```
HX_LOW_FLOW_CLOSURE:          PASS - 7/7 criteria, executed in OpenModelica
NUS_HX_NUMERICALLY_EXONERATED: PASS - identical-to-old configuration still fails, so the
                              initialization failure is not the correlation's
LOOP_HYDRAULICS_STEADY_STATE: UNCHANGED BY CONSTRUCTION (Re_shell 8562 >> 3000, w = 1 exactly)
LOOP_HYDRAULICS_TRANSIENT:    BLOCKED_NOT_RUN (O-33)
STARTUP_REGRESSION:           BLOCKED_NOT_RUN (Dymola unavailable; OpenModelica blocked by O-33)
COASTDOWN_REGRESSION:         BLOCKED_NOT_RUN (same)
NATURAL_CIRCULATION_TH:       BLOCKED_NOT_RUN (Dymola unavailable)
O-33:                         TOOL_LIMITATION - no workaround applied, none authorized

MODEL_CHANGE: the heat exchanger heat transfer closure, on both sides, from Nus_MoltenSalt to
              Nus_HX. No geometry, material property, pump curve or kinetics parameter touched.
READY_FOR_1D_NATURAL_CIRCULATION: NO
```

**Practical consequence the next session needs to know.** With `Nus_HX` in place, the assembled
system models no longer initialize under OpenModelica in this sandbox. The closure change is
correct and verified, and reverting correct physics to satisfy a solver would be backwards, so it
stays. But it means the OpenModelica precheck route is closed at the system level until O-33 is
addressed, and the remaining verification has to run in Dymola.

---

## Phase 32 — Pump transient: rotor dynamics isolated as the coastdown discrepancy

Natural circulation is on **research priority HOLD**, not failed. `HX_LOWFLOW_CLOSURE: PASS` and
`HX_TRANSIENT_REGRESSION: NOT_RUN` are frozen as of phase 31 and are not revisited here.

### A. Which speed history is actually solved (question 1)

Both a prescribed model and a dynamic model exist, and the benchmark uses the dynamic one.

| | model | pump component | speed |
|---|---|---|---|
| **R0-A** | `Experiments.PumpCoastdown`, `PumpStartup` | `Components.FuelPump` | **prescribed**: `N = N_cmd`, driven by `RealExpression(y = N_rated/(1 + (time-t_null)/tau_coast))` |
| **R0-B** | `Experiments.PumpCoastdown_RotorDynamics`, `PumpStartup_RotorDynamics` | `Components.FuelPump_Dynamics` | **solved**: `omega` is a state with `fixed=true` |

The Dymola B0 baseline used `PumpCoastdown1D_RotorDynamics` / `PumpStartup1D_RotorDynamics`,
which extend the `_RotorDynamics` variants, so **B0 is R0-B and `N(t)` is an ODE result, not an
input**. In R0-B the speed connector is re-read as a *motor torque demand*:

```
u_motor   = min(1, max(0, N_cmd/N_nominal));      // FuelPump_Dynamics.mo
tau_motor = tau_motor_nominal*u_motor;
pumpSpeed(y = if time < t_null then N_rated else 0)   // a torque step, not a speed
```

R0-A remains in the repository and is a reduced-order prescription of the same law. The two must
not be quoted as if they were the same evidence.

### B. The torque terms as the code computes them (question 3)

```
u_motor   = min(1, max(0, N_cmd/N_nominal))
tau_motor = tau_motor_nominal*u_motor
tau_hyd   = tau_hyd_nominal*omega*abs(omega)/omega_nominal^2
tau_fric  = tau_fric_coulomb*tanh(omega/omega_reg) + tau_fric_viscous*omega/omega_nominal
J*der(omega) = tau_motor - tau_hyd - tau_fric
```

with `tau_fric_coulomb = 0` and `tau_fric_viscous = 0` by default, so **`tau_fric` is
identically zero in every benchmark run so far**, and `tau_motor_nominal = tau_hyd_nominal`.

Three properties of this follow directly and matter below:

1. `tau_hyd` depends on **speed alone**, not on the operating point. There is no homologous
   torque characteristic and no flow dependence. The model's own documentation says so.
2. There is no `1/omega` anywhere - the hydraulic torque is not formed as `P_hyd/omega`, so
   there is no zero-speed singularity to regularize. `omega*abs(omega)` also keeps the sign
   right under reverse rotation.
3. With `tau_fric = 0` and `tau_motor = 0`, the coastdown solution is exactly
   `omega = omega_0/(1 + t/tau_shaft)` - a **hyperbola, with an infinite tail**. The shaft never
   stops.

### C. Provenance of the rotor parameters (questions 2 and 6)

| Quantity | Value | Tag |
|---|---:|---|
| `N_pump_nominal` | 1160 rpm | ORNL DESIGN DATA |
| `m_flow_nominal` | 168 kg/s | ORNL DESIGN DATA |
| `dp_pump_nominal` | 3.0e5 Pa (48.5 ft of salt) | ORNL DESIGN DATA |
| `eta_pump` | 0.8 | **ASSUMED** |
| `headRatio_shutoff` | 1.25 | **ASSUMED** |
| `P_pump_hydraulic` | 22.945 kW | DERIVED (`dp*V_flow`) |
| `tau_hyd_nominal` | 236.11 N.m | DERIVED (`P/(omega*eta)`), inherits the assumed `eta` |
| **`tau_shaft`** | **4.0 s** | **CALIBRATED** - the model calls it "the single fitted parameter" |
| **`J`** | **7.775 kg.m2** | **CALIBRATED** - `J = tau_shaft*tau_hyd_nominal/omega_nominal` |
| `tau_fric_coulomb` | 0 | **ASSUMED** |
| `tau_fric_viscous` | 0 | **ASSUMED** |

**`J` is not an MSRE quantity.** It is back-computed from a fitted time constant, so it carries
no independent information about the real rotor; it is a restatement of `tau_shaft`. It is
neither rotor-only nor rotor-plus-motor nor a TRANSFORM default - it is a calibration. No
measured MSRE pump inertia, motor torque-speed characteristic, bearing drag or coastdown time is
present anywhere in this repository, and none was invented here.

### D. Independent calculation from the frozen B0 tables

Not a simulation. The B0 coastdown flow table of section G, read against the analytic rotor
solution.

**Is TRANSFORM's coastdown flow just its speed?**

| t [s] | `N/N0` from the rotor solution [%] | B0 flow [%] | ratio |
|---:|---:|---:|---:|
| 1 | 80.00 | 78.9 | 0.986 |
| 5 | 44.44 | 43.3 | 0.974 |
| 10 | 28.57 | 27.5 | 0.963 |
| 20 | 16.67 | 15.7 | 0.942 |
| 40 | 9.09 | 8.34 | 0.917 |
| 60 | 6.25 | 5.61 | 0.898 |

The ratio stays between 0.90 and 0.99. **The flow is the speed, to within 10 %.** That is
expected rather than surprising: `momentumDynamics = SteadyState`, so the loop momentum balance
is algebraic and the flow carries no inertia of its own - it is slaved to the head. The slow
drift from 0.99 to 0.90 is the laminar part of the loop resistance gaining weight as the flow
falls.

**What decay law is each following?** Fitting a time constant independently at every point:

| t [s] | TRANSFORM, hyperbolic `tau` | MARS, hyperbolic `tau` | MARS, exponential `tau` |
|---:|---:|---:|---:|
| 1 | 3.74 | 4.08 | 4.56 |
| 2 | 3.80 | 2.42 | 3.32 |
| 4 | 3.81 | 1.69 | 3.30 |
| 5 | 3.82 | 1.44 | 3.34 |
| 10 | 3.79 | 0.70 | 3.67 |
| 15 | 3.75 | 0.34 | 3.93 |
| 20 | 3.73 | 0.20 | 4.31 |
| 30 | 3.67 | 0.08 | 5.07 |

TRANSFORM's hyperbolic time constant is **constant at 3.57 to 3.82 s** across the whole
transient - it is a hyperbola, which is exactly the zero-friction rotor solution with
`tau_shaft = 4.0`. MARS's hyperbolic time constant **collapses by a factor of 50**, so MARS is
definitively not hyperbolic; its exponential time constant is roughly constant at 3.3 to 3.9 s
over the well-resolved range.

### E. The structural hypothesis this produces

```
hyperbolic decay   <=>  J*dw/dt = -C*w^2     retarding torque quadratic in speed, infinite tail
exponential decay  <=>  J*dw/dt = -C*w       retarding torque linear in speed, finite settling
```

TRANSFORM carries **only** the quadratic hydraulic term, because both friction coefficients are
zero. MARS behaves as though a term **linear in speed** dominates its coastdown. The discrepancy
is therefore not a wrong value of `J` or of `tau_shaft` - no single `tau_shaft` can turn a
hyperbola into an exponential - but the **absence of a speed-linear retarding torque**, which is
physically the bearing, seal and windage drag that `tau_fric_viscous` exists to carry and that is
currently set to zero.

**Stated caveat.** MARS's speed history is not in the B0 record. It was inferred from MARS's
*flow* using TRANSFORM's own near-identity flow-to-speed mapping. If MARS resolves fluid inertia
- a dynamic momentum equation, which TRANSFORM does not have here - its flow lags its speed and
the inference is biased. This is a hypothesis to be tested by the prescribed-speed case, not a
measurement of the MARS rotor. **No coefficient has been fitted and no parameter changed.**

### F. Answers

1. **Is `N(t)` an input or an ODE result?** In the B0 benchmark (`*_RotorDynamics`), an **ODE
   result**; `omega` is a state and the connector carries motor torque demand. The prescribed
   variants `PumpStartup` / `PumpCoastdown` also exist and must not be conflated with them.
2. **What is `J`?** 7.775 kg.m2, **CALIBRATED**, back-computed from the fitted `tau_shaft = 4.0`
   s. It carries no independent physical information about the MSRE rotor.
3. **How are the torques computed?** Section B above. `tau_fric` is identically zero.
4. **How much does a prescribed benchmark `N(t)` reduce the flow error?** `NOT_RUN` - it needs
   MARS's speed history, which is not in the record, and the system models do not currently
   initialize in OpenModelica (O-33, phase 31).
5. **What fraction of the coastdown error does rotor dynamics explain?** The `N -> m_flow`
   mapping is within 10 % of identity, so it cannot explain the factor of **4.2** at t = 10 s
   (27.5 % against 6.57 %). On the evidence available, **rotor dynamics accounts for essentially
   all of it** - and specifically the decay *law*, not the decay *constant*.
6. **Which generic parameters need MSRE-specific values?** `tau_shaft`/`J` (currently a fit),
   `tau_fric_coulomb` and `tau_fric_viscous` (currently zero by assumption), `eta_pump` (0.8,
   assumed, and it propagates into `tau_hyd_nominal`), `headRatio_shutoff` (1.25, assumed).
7. **`1D_PUMP_TRANSIENT_BASELINE`** - `FAIL` (not yet established; criteria 1, 3, 4, 5 unmet).
8. **`READY_FOR_2D_CORE`** - `NO`.

---

## Phase 33 — O-33 workaround verified; rotor isolation solved analytically

Natural circulation remains on **research priority HOLD**. Phase 32 is frozen as baseline, with
`ROTOR_DECAY_LAW_MISMATCH: STRONG_HYPOTHESIS` - the MARS speed history is not in the record and
is not claimed to be exponential.

### A. `OPENMODELICA_O33_DIAGNOSTIC_WORKAROUND` (STEP A)

Sandbox-only patch to `MSL/Modelica/Media/package.mo`, `Modelica.Media.Interfaces.Types`:

```
type Temperature      ... start=288.15  ->  start=908
type AbsolutePressure ... start=1.e5    ->  start=1.5e5
```

`min`, `max` and `nominal` deliberately untouched - the change is the Newton seed and nothing
else. Recorded as workaround 6 in `tools/apply_sandbox_workarounds.sh`. **Not** a physics
correction, medium property change, calibration, new baseline, or Dymola model change, and never
carried into the repository physics source.

With it, `Loop_Hydraulics` carrying `Nus_HX` initializes (3 homotopy steps) and runs to 300 s,
where before it failed at t = 0.

### B. `O33_WORKAROUND_STEADY_INVARIANCE: PASS` (STEP B)

| quantity | Dymola B0 | OM old closure | OM `Nus_HX` + O-33 | rel. change vs OM old |
|---|---:|---:|---:|---:|
| `m_flow` [kg/s] | 166.542 | 166.5420006 | 166.5420004 | 1.4e−9 |
| `dp_pump` [Pa] | 301271 | 301271.0734 | 301271.0764 | 1.0e−8 |
| `dp_loop_nonstatic` [Pa] | 301272 | 301272.273 | 301272.277 | 1.3e−8 |
| `dp_loop_gravity` [Pa] | −1.20131 | −1.199578 | −1.200512 | 7.8e−4 |
| `V_loop_measured` [m3] | 2.0965 | 2.096499936 | 2.096499936 | 1.5e−10 |
| `M_loop_measured` [kg] | 4605 | 4605.001129 | 4605.001128 | 1.9e−10 |
| `tau_core` [s] | 9.96316 | 9.96304429 | 9.963044209 | 8.1e−9 |
| `tau_external` [s] | 17.6879 | 17.68764511 | 17.68764521 | 5.9e−9 |
| `Re_max` | 806.178 | 806.1779736 | 806.1781379 | 2.0e−7 |

Worst relative change 2.0e−7, excluding `dp_loop_gravity`, which is the known ~1 Pa cancellation
residual and which **moved toward** the Dymola value (gap 0.00173 -> 0.00080 Pa). All eight
`Loop_Hydraulics` terminal verification checks passed; zero `error`-level assertions.

**One thing reported rather than hidden.** The new run emits 15 `LOG_ASSERT | info` min-constraint
notices on precursor concentrations `msre.core.lowerPlenum.pipe.Cs[i,j]`, at values of order
−1e−32. `Loop_Hydraulics` runs at `Q = 0`, where those concentrations are identically zero, so
these are round-off about zero and whether they land marginally negative depends on the exact
arithmetic path, which both the closure change and the new seeds altered. They are informational,
not errors, and no verification check is affected. They are not evidence of a physical change.

### C. The rotor equation is decoupled from the loop (STEP F and I)

Two facts read from the code, not inferred:

1. `momentumDynamics = SteadyState` on **every** fuel-salt component - `PrimarySystem` line 176
   and every component instantiation, with `SaltPipe`, `CoreChannel` and `ReactorCore` all
   defaulting to the same. **There is no fluid inertia anywhere in the loop.**
2. `tau_hyd = tau_hyd_nominal*omega*abs(omega)/omega_nominal^2` reads **only `omega`**. No port
   variable, no flow, no head. `tau_hyd_nominal` is a parameter built from rated constants.

So the rotor is a **standalone scalar ODE**, one-way coupled into the loop. That makes the
inertia and friction studies exactly solvable rather than requiring simulation, and it means
`N(t) -> m_flow(t)` is a pure algebraic map.

`HYDRAULIC_TORQUE_DECOUPLING: CONFIRMED structurally, IMPACT LOW.` Along the operating line
`v = n`, the physical torque reduces algebraically to the current law:

```
head/head_nom = 1.25 n^2 - 0.25 v^2 ,  tau_phys/tau_nom = (head/head_nom)*v/n
with k = v/n :  tau_phys/tau_cur = k*(1.25 - 0.25 k^2) ,  = 1 exactly at k = 1
```

Using the B0 flow/speed ratio, `tau_phys/tau_cur` runs 0.993 at 1 s to 0.941 at 60 s - the
physical torque is up to 5.9 % **smaller**, which would make the coastdown *slower*. **R3 is not
the fix and it points the wrong way.**

### D. Closed form and sensitivities (STEP C, G, H, J)

With `f_v = tau_visc(omega_nom)/tau_hyd_nom`, the coastdown of `J dw/dt = -K1 w - K2 w^2` is

```
n(t) = exp(-t f_v/tau_s) / (1 + (1/f_v)(1 - exp(-t f_v/tau_s)))
  f_v -> 0    n = 1/(1 + t/tau_s)        hyperbola, infinite tail    <- current model
  f_v -> inf  n = exp(-t f_v/tau_s)      exponential, finite settling
```

**`INERTIA_ONLY_FIX: REJECTED`.** `J` enters only through `tau_s`, so it slides the hyperbola
without changing its form. Matching MARS at 10 s needs `tau_s = 0.70 s` (`J/J0` = 0.18), which
then gives 41 % at 1 s against MARS's 80 %. No single `J` fits.

**`VISCOUS_TORQUE_EFFECT: HIGH`.** MARS lies between `f_v` = 0.5 and 1.0, and the tail collapses
as MARS's does.

**A common parameter set exists** (STEP J), which is more than expected:

| `J/J0` | `f_v` | coastdown RMSE vs MARS [%-pts] | startup `t98` |
|---:|---:|---:|---:|
| 1.0 | 0 (current) | 16.81 | 9.19 s (1.00x) |
| 1.0 | 0.5 | 4.59 | 7.06 s (0.77x) |
| 2.0 | 1.5 | **3.70** | 9.70 s (1.06x) |

**Not adopted.** STEP K requires searching for real data first, and there is a physical objection
that matters more than the fit: `f_v` = 1.5 means 354 N.m of drag at rated speed, 1.5 times the
rated hydraulic torque. Real pump bearing and windage losses are a few per cent of shaft torque.
A speed-linear term of that size is not credible **as friction**, so it is most likely standing in
for missing physics - the fluid momentum dynamics this model does not have at all being the
leading candidate. Reporting it as a fitted friction coefficient would be misrepresenting it.

### E. Status

```
O33_WORKAROUND_STEADY_INVARIANCE:  PASS
HYDRAULIC_TORQUE_DECOUPLING:       CONFIRMED structural, IMPACT LOW, wrong direction
INERTIA_ONLY_FIX:                  REJECTED
VISCOUS_TORQUE_EFFECT:             HIGH on shape, magnitude not credible as friction
FLUID_INERTIA_RELEVANCE:           HIGH as a candidate - absent from TRANSFORM entirely
ROTOR_DECAY_LAW_MISMATCH:          STRONG_HYPOTHESIS
ROTOR_DYNAMICS:                    DOMINANT_CANDIDATE
1D_PUMP_TRANSIENT_BASELINE:        FAIL - STEP D, E and K outstanding
READY_FOR_2D_CORE:                 NO
```

---

## Phase 34 — Pump model frozen; 2D-0 nodalization identity

### A. Pump transient closed as `CHARACTERIZED_UNRESOLVED`

Not `PASS`. The discrepancy is characterized, not resolved, and the model is frozen as-is:

| Cause | Verdict |
|---|---|
| rotor decay functional form | **CONFIRMED MODEL DIFFERENCE** |
| `J` value | **CALIBRATED / NOT PHYSICAL** |
| `J`-only correction | **INSUFFICIENT** |
| zero viscous torque | **SHAPE-SENSITIVE, PHYSICAL VALUE UNKNOWN** |
| hydraulic torque decoupling | **STRUCTURAL, LOW IMPACT** |
| fluid momentum dynamics absent | **IMPORTANT UNRESOLVED CANDIDATE** |
| MARS rotor speed history | **NOT AVAILABLE** |

The discrepancy is **not** to be described as a pump rotor ODE error. The accurate statement is:

> The reduced pump/loop transient formulation produces a structurally hyperbolic rotor decay and
> contains no fluid momentum dynamics; the relative contribution of these two simplifications
> cannot be uniquely separated from the available MARS flow data.

`MISSING_FLUID_MOMENTUM_DYNAMICS` is registered as a future work item, deliberately not
implemented now: it is a system-level reformulation of the whole primary loop, not a pump
parameter correction, and with no MARS speed history the rotor and fluid-inertia contributions
cannot be separated anyway.

`PUMP_MODEL_R0_FROZEN_FOR_1D_2D_COMPARISON` - current `J`, current hydraulic torque law,
`tau_fric_coulomb = 0`, `tau_fric_viscous = 0`, current pump curve, current loop momentum
formulation. **Frozen because it must be identical in 1-D and 2-D, not because it is correct.**
No fitting or calibration was applied.

### B. 2D-0 nodalization identity — **PASS**

`MSRE.Verification.Core1D2D_Identity`, parameters only, executed. It instantiates both
nodalization records against one `Geometry` and calls the same `coreCellVolumes` and
`corePowerShape` that `PrimarySystem` calls, so it tests the functions the plant model uses.

| Identity | 1-D | 2-D | relative gap |
|---|---:|---:|---:|
| channels represented | 1140 | 1140 | 0 |
| total flow area [m2] | 0.327777812187 | 0.327777812187 | 0 |
| fuel volume in channels [m3] | 0.532835611492 | 0.532835611492 | 0 |
| graphite volume [m3] | 1.98157134715 | 1.98157134715 | 0 |
| total core cell volume [m3] | 0.755405944825 | 0.755405944825 | −1.8e−15 |
| source fractions sum | 1 | 1 | — |
| channel share of the power | 1 | 1 | −1.0e−15 |
| channel-weighted mean `f_radial` | 1 | 0.99998 | — |
| core cells `nV_core` | 22 | 302 | by design |

Two observations recorded rather than glossed:

1. **The plena receive zero fission source in both.** `corePowerShape` carries
   `plenumFissionSource = false`, an explicit `ASSUMPTION` tied to O-20: the two plenum core
   nodes hold no graphite and so are not treated as an active fuel region. A sensitivity switch
   restores the volume-weighted treatment. It is identical in both nodalizations, so it does not
   affect the identity - it is a pre-existing modelling choice, not a 2-D issue.
2. **`f_radial` has a channel-weighted mean of 0.99998, not exactly 1.** That is the rounding of
   the four-decimal tabulated values. It is absorbed by the normalization inside
   `corePowerShape`, which is why `SF_sum2` is exactly 1, so no power is gained or lost.

### C. Ring grouping provenance (STEP 11)

`Core2D` sets `nChannels = fill(nChannels_total/nRings, nRings)` = 76 channels per ring, so the
rings are **equal-channel-count**, which for a uniform lattice means **equal-area annuli** of
decreasing radial width.

| Item | Tag |
|---|---|
| ring boundaries, 15 rings | `NUMERICAL_NODALIZATION` - the MSRE core has no physical rings |
| 76 channels per ring | `NUMERICAL_NODALIZATION` (derived from the equal-area choice) |
| `nChannels_total` = 1140 | `HARDWARE_GEOMETRY` |
| `f_radial` 15 values | `ASSUMED` - J0 with 25 % reflector saving, standing in for an unpublished Serpent tabulation |
| `K_channelInlet`, `K_channelExit` = 0 | `ASSUMED` |

**The two choices are consistent, which need not have been true.** Evaluating that J0 shape at
the equal-area ring centres `r_i = R*sqrt((i-0.5)/15)` reproduces the tabulated `f_radial` to an
RMS of **0.0000**; evaluating it at equally spaced centres gives RMS **0.0949**. The radial
profile therefore belongs to the equal-area grouping it is used with, and the two are not
independently chosen.

Still open, carried from the `Core2D` record's own documentation: with zero form losses and
geometrically identical rings, the hydraulic flow split will come out near uniform. **Having 15
rings is not by itself a radial flow model**, and 2D-1 has to establish which of the two this is.

---

## Phase 35 — 2D-1 radial hydraulic characterization

### A. Code trace (STEP 1)

In `ReactorCore` the ring array is declared with **every geometric and hydraulic parameter under
`each`**. The only per-ring inputs are the two form losses and the power:

| Quantity | Per ring? | Provenance |
|---|---|---|
| `nChannels` = 76 | same | `NUMERICAL_NODALIZATION`, from the equal-area grouping |
| `crossArea`, `dimension`, `length`, `dheight` | `each` | `HARDWARE_GEOMETRY` |
| roughness | not exposed | TRANSFORM default, **`OPEN`** |
| `K_inlet`, `K_exit` | per ring, both **0** | `ASSUMED` - Kedl ORNL-TM-3229 not extracted |
| `K_distributed` | zeros | `ASSUMED` |
| `Q_gens` | **differs** | `ASSUMED` radial profile |
| inlet / outlet pressure | shared plena | `DERIVED` |

**No geometric or form-loss mechanism can make the rings differ hydraulically.**

### B. Results, executed to 20000 s

| | `Q_core` = 0 | `Q_core` = 8 MW |
|---|---:|---:|
| sum of ring flows | 168.000000 kg/s | 168.000000 kg/s |
| `err_massBalance_rel` | 1.5e−12 | −1.4e−12 |
| `err_sharedDp` | **0** | **0** |
| `eps_max` | **1.77e−12** | **0.129489** |
| `CV_mflow` | 1.07e−12 | 0.078276 |
| `err_mechanism` | 1.78e−12 | **0.033964** |
| `nOrderViolations` | 0 (gated) | **0** |
| `dT_radial` | 0 | 20.85 K |
| `CV_power` | 0.349289 | 0.349289 |

Per-ring at 8 MW, all fifteen rings at an identical `dp_total` = 35369.3 Pa:

| ring | `f_rad` | ṁ [kg/s] | eps % | v [m/s] | `Re` | `dp_fric` [Pa] | `T_out` [K] | rho | predicted ṁ | diff % |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1.607 | 12.6503 | +12.95 | 0.2648 | 922.0 | 510.99 | 941.70 | 2186.6 | 13.0315 | −2.93 |
| 5 | 1.228 | 11.7989 | +5.35 | 0.2467 | 859.2 | 482.39 | 935.63 | 2188.4 | 11.9393 | −1.18 |
| 8 | 0.975 | 11.1818 | −0.16 | 0.2337 | 813.7 | 461.26 | 931.13 | 2189.7 | 11.1637 | +0.16 |
| 11 | 0.746 | 10.5824 | −5.51 | 0.2210 | 769.6 | 440.38 | 926.70 | 2191.0 | 10.4232 | +1.53 |
| 15 | 0.475 | 9.8085 | −12.42 | 0.2047 | 712.7 | 412.89 | 920.85 | 2192.8 | 9.4863 | +3.40 |

### C. The mechanism, and why the split is as large as it is

The rings are parallel paths between two common plena, so `err_sharedDp` is **exactly zero** -
they all see one pressure difference. What differs is how that difference splits between static
head and friction, and the channel is vertical in a dense salt:

```
dp_total = 35369.3 Pa      of which the static head is 98.6 to 98.8 %
dp_fric  = 413 to 511 Pa   the entire budget that drives the flow
```

A 20.85 K radial temperature spread lowers the hottest ring's density by ~6 kg/m3, which lowers
its static head by ~98 Pa - and against a friction budget of only ~460 Pa that is a **24 %
change**. Its viscosity is also 11 % lower. In laminar flow both act linearly, so
`m ~ dp_nonstatic/mu`, and that prediction reproduces the measured split with
`err_mechanism` = **3.4 %** worst ring. The flow ranking follows the power ranking exactly
(`nOrderViolations` = 0).

**The size of the split is a property of the geometry, not a defect.**

### D. Three of my own tests failed on correct behaviour

Recorded because the pattern matters more than the individual fixes: each was sharp about a
*number* where the defensible statement was about a *mechanism*.

| Test | How it failed | Replaced by |
|---|---|---|
| C0/C1 of the HX blend (phase 31) | sampled at `Re +/- 1e-6`; measured `slope*2*eps` and round-off | exact identities on the blend weight, asserted at zero |
| 1 % bound on the ring split | mis-calibrated; the real split is 12.9 % and correct | `m ~ dp_nonstatic/mu` mechanism test |
| strict ring flow ranking | at `Q` = 0 the flows agree to 1e-12, so ordering is round-off | gated on `eps_max` exceeding numerical precision |

### E. Verdict

```
CORE_2D_1_RADIAL_HYDRAULICS:  PASS_UNIFORM          at zero power (eps_max 1.8e-12)
                              PASS_PROPERTY_COUPLED at power (mechanism verified, 3.4 %)

radial power distribution        IMPLEMENTED
radial thermal resolution        IMPLEMENTED
radial hydraulic discretization  IMPLEMENTED
radial hydraulic heterogeneity   PRESENT AT POWER, via buoyancy and viscosity ONLY;
                                 ZERO contribution from geometry or form losses
cross-ring flow redistribution   NOT IMPLEMENTED - the rings are parallel paths between two
                                 common plena and exchange no mass with each other
```

This is **not** "2-D hydraulics complete". The rings redistribute flow only because their own
power changes their own fluid properties; there is no radial momentum coupling, and the measured
MSRE channel flow distribution would still need the Kedl form losses.

### F. O-29 reclassified

The 15-ring model **initializes and runs to 20000 s** under `-noHomotopyOnFirstTry`. Only
OpenModelica's *global homotopy* path fails. **O-29 is not a model defect** - it is the same
class as O-33, an initialization-strategy limitation, and it is cleared by a solver flag rather
than any model change.

### G. Status

```
CORE_2D_0_NODALIZATION_IDENTITY:  PASS
CORE_2D_1_RADIAL_HYDRAULICS:      PASS_UNIFORM / PASS_PROPERTY_COUPLED
O-29:                             OPENMODELICA_TOOL_LIMITATION, cleared by -noHomotopyOnFirstTry
PUMP_MODEL_R0:                    FROZEN, untouched in this phase
NATURAL_CIRCULATION:              HOLD
READY_FOR_PUMP_MODEL_R1:          YES
```

---

## Phase 36 - PUMP_MODEL_R1 dynamic validation

### A. Run validity

| run | samples | t range | post-event | status |
|---|---:|---|---:|---|
| COASTDOWN_R0 | 641 | 0 - 318.53 s | 118.53 s | `PARTIAL_VALID` |
| COASTDOWN_R1 | 658 | 0 - 327.39 s | 127.39 s | `PARTIAL_VALID` |
| STARTUP_R0 | 0 | - | - | `NOT_VALID` - OOM killed, 13.9 GB RSS |
| STARTUP_R1 | 21 | 0 - 9.86 s | none | `NOT_VALID` - DASKR failed at 9.86 s, before the start |

Both coastdowns end with `Integrator failed` at t_rel ~ 120 s, so the requested 300 s point is
`NOT_RUN`. **R0 fails the same way**, so the failure is not caused by R1.

### B. Pre-trip steady, window [150, 200) strictly before the trip

| | R0 | R1 |
|---|---:|---:|
| N mean | 1160.00000 rpm (+0.0000 %) | 1162.61212 rpm (**+0.2252 %**) |
| N relative range | 0.00e+00 | 3.22e-06 |
| m_flow mean | 166.54352 (-0.8670 %) | 166.92541 (-0.6396 %) |
| m_flow relative range | 4.91e-06 | 1.65e-06 |
| tau_hyd mean | 236.10960 | 236.10954 |
| max abs(domega_dt) | 7.31e-15 rad/s2 | 8.90e-06 rad/s2 |

`PRETRIP_STEADY = PASS` for both. `t_null` = 200 s is sufficient for the rotor and the
hydraulics; it is NOT sufficient for precursor equilibrium, which this stage does not test.

**The +0.225 % speed shift is traced, not waved through.** The plant's own steady flow is
166.54 kg/s, 0.87 % below the rated 168 - a pre-existing offset visible in R0. R0's torque cannot
see it: `tau ~ (w/w_n)^2` balances `tau_motor = tau_nominal` at `w = w_nominal` exactly, whatever
the flow is. R1's torque does see it, so the shaft settles 0.225 % higher. R1 is reporting an
off-rated operating point that R0 masks by construction.

### C. Parameter identity, read back from the results

`tau_hyd_nominal` = 236.1096039 N.m and `J` = 7.774760807 kg.m2 are **bit-identical** in every
run. Each R0/R1 pair came from one binary with `use_operatingPointTorque` as the only override,
so the H-Q curve, friction, loop resistance, initial condition, `t_null` and solver settings are
identical by construction.

### D. Coastdown R0 vs R1, t_rel = t - 200 s

| t_rel | N/Nn R0 | N/Nn R1 | diff % | m/mn R0 | m/mn R1 | diff % | dp R0 | dp R1 | tau/tn R0 | tau/tn R1 |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 1.00000 | 1.00225 | +0.225 | 0.99133 | 0.99360 | +0.229 | 301276 | 302629 | 1.0000 | 1.0000 |
| 5 | 0.44445 | 0.44741 | +0.666 | 0.43253 | 0.43548 | +0.683 | 60040 | 60837 | 0.1975 | 0.1973 |
| 10 | 0.28572 | 0.28878 | +1.072 | 0.27482 | 0.27786 | +1.106 | 24947 | 25481 | 0.0816 | 0.0816 |
| 20 | 0.16668 | 0.16966 | +1.792 | 0.15725 | 0.16018 | +1.866 | 8563 | 8870 | 0.0278 | 0.0278 |
| 50 | 0.07410 | 0.07686 | +3.732 | 0.06715 | 0.06982 | +3.977 | 1721 | 1850 | 0.0055 | 0.0055 |
| 100 | 0.03847 | 0.04118 | +7.024 | 0.03329 | 0.03580 | +7.535 | 472 | 540 | 0.0015 | 0.0015 |
| 300 | `NOT_RUN` | `NOT_RUN` | | | | | | | | |

### E. The off-design regime is NOT entered

The static sweep found a torque reaching 7.05x rated with reversed sign. **The actual coastdown
never goes there**, and the reason is that the sweep held the flow at its RATED value while
taking the speed to zero, which the coastdown does not do - the flow decays with the speed.

| | R1 | R0 |
|---|---|---|
| max `tau_hyd/tau_nom` | +1.000000 | +1.000000 |
| min `tau_hyd/tau_nom` | **+0.000917** | +0.001066 |
| time of max abs | t_rel = 0 | t_rel = 0 |
| dp range | **+353.5 to +302629 Pa** | +343.5 to +301276 Pa |
| samples with dp < 0 | **0 / 258** | 0 / 241 |
| samples with tau_hyd < 0 | **0 / 258** | 0 / 241 |
| min abs(omega) | 4.032 rad/s (omega_reg = 1.215) | 3.967 rad/s |
| samples with abs(omega) < omega_reg | **0 / 258** | 0 / 241 |

Regime classification of the R1 trajectory: **A pump-driving 258/258, B turbine-like 0/258,
C low-speed amplification 0/258.** The trajectory is never inside the regularization zone, so
the result is not a regularization artifact.

### F. Dynamic energy consistency

Checked against the relation as IMPLEMENTED, `tau_hyd*w = P_shaft*w^2/(w^2+w_reg^2)`:

```
max ABSOLUTE energy error   5.02e-06 W        at t_rel = 0.500 s
worst point inside regularization zone?       NO
gating threshold                              2.87e-02 W  (1e-6 of the largest reference power)
max GATED RELATIVE error    6.81e-10          at t_rel = 54.0 s
max |P_shaft - branch prediction|  5.00e-06 W
```

`ENERGY_CONSISTENCY = PASS`. Relative error is gated, never evaluated near zero power.

### G. The Q -> tau_hyd -> N feedback is active, and measured

Both relations are recorded inside the R1 run, so they can be compared at ONE identical
operating point with no confounding from the trajectories differing:

| t_rel | N/Nn | phi = (Q/Qn)/(N/Nn) | tau_R0/tn | tau_R1/tn | (R1-R0)/R0 |
|---:|---:|---:|---:|---:|---:|
| 0 | 1.00225 | 0.99137 | 1.004512 | 1.000000 | -0.449 % |
| 5 | 0.44741 | 0.97335 | 0.200172 | 0.197296 | -1.437 % |
| 20 | 0.16966 | 0.94411 | 0.028785 | 0.027818 | -3.363 % |
| 100 | 0.04118 | 0.86938 | 0.001695 | 0.001477 | -12.900 % |
| 127 | 0.03328 | 0.85390 | 0.001108 | 0.000926 | **-16.387 %** |

The flow coefficient falls monotonically from 0.991 to 0.854: the pump leaves its rated
similarity line as it coasts, and R1 returns a torque up to 16.4 % below the speed-only law at
the same point. Less braking torque gives a slower coastdown, which is the +7 % speed and flow
seen at t_rel = 100 s. That is the mechanism the stage set out to test, and it is present.

Ordering could NOT be resolved cleanly: the two runs start from steady states that already
differ by 0.225 %, so the onset of the difference is confounded. The relation comparison above
is the clean statement.

### H. Benchmark comparison, and why it cannot adjudicate

| t_rel | analytic N/Nn | R0 | R1 | R0 dev | R1 dev |
|---:|---:|---:|---:|---:|---:|
| 5 | 0.44444 | 0.44445 | 0.44741 | +0.0003 % | +0.666 % |
| 10 | 0.28571 | 0.28572 | 0.28878 | +0.0009 % | +1.073 % |
| 20 | 0.16667 | 0.16668 | 0.16966 | +0.0059 % | +1.798 % |
| 100 | 0.03846 | 0.03847 | 0.04118 | +0.0310 % | +7.057 % |

RMSE(speed) vs the law: R0 = 1.22e-05, R1 = 2.91e-03.

**This does not show R0 is better.** `N = N0/(1+t/tau_shaft)` is R0's OWN closed-form solution
for zero friction and `tau ~ w^2`; R0 reproducing it to 1e-5 is a self-consistency check, not
independent evidence. **No experimental MSRE coastdown data exists in this repository**, so the
R0/R1 divergence cannot be adjudicated against measurement. Speed and flow are reported
separately and no conclusion is drawn about the rotor from the flow agreement.

Late-time tail, last valid samples: R0 at t_rel 118.53 s, N/Nn 0.032655, m/mn 0.027418;
R1 at t_rel 127.39 s, N/Nn 0.033192, m/mn 0.028180.

### I. New defects and blockers

| id | finding | attribution |
|---|---|---|
| O-34 | coastdown integrator fails at t_rel ~ 120 s | **pre-existing**, occurs in R0 and R1 alike |
| O-35 | startup OOM killed at 13.9 GB RSS | environment resource limit, not the model |
| O-36 | startup DASKR non-convergence at t = 9.86 s in the stagnant phase, before the pump starts | **pre-existing** stagnant-loop regime |
| O-37 | plant steady flow is 166.54 kg/s, 0.87 % below rated; R0 masks it, R1 responds with +0.225 % speed | pre-existing plant offset, newly EXPOSED by R1 |
| A-12 | `eta_is` = 0.8 remains uncited | `ASSUMED`, unchanged, not fitted |

### J. Verdict

```
PUMP_R1_STEADY_INVARIANCE      PASS   (+0.225 % shift, cause traced to O-37)
PUMP_R1_ENERGY_CONSISTENCY     PASS   (6.81e-10 gated relative)
PUMP_R1_LOW_SPEED_REGULARIZATION PASS (trajectory never within omega_reg; 0/258)
PUMP_R1_STARTUP_REGRESSION     NOT_RUN
PUMP_R1_COASTDOWN_REGRESSION   PARTIAL (0 to ~120 s of the requested 300 s)

PUMP_MODEL_R1 = CHARACTERIZED_UNRESOLVED
```

Every mechanism check that was executed passes, and the off-design concern raised by the static
sweep is measured and **NOT realized** on the actual trajectory. The verdict is nevertheless not
`PASS_CANDIDATE`, because that requires all runs valid and the startup regression is `NOT_RUN`;
and it is not `REJECTED`, because none of the rejection triggers is met - the nominal state
holds, energy and sign are consistent, no instability is attributable to R1, and the
regularization does not touch the trajectory.

Note the reason differs from the template's `CHARACTERIZED_UNRESOLVED` rationale: the blocker is
**execution coverage**, not a reverse-torque regime.

### K. GO / NO-GO

```
R1 ADOPTION                      NO-GO for now - not on physics, on coverage
NEXT = EXECUTION_BLOCKER_RESOLUTION   (O-34, O-35, O-36)
   then re-run the startup pair and the full 300 s coastdown, then re-decide R1
HOMOLOGOUS_PUMP_TORQUE_MODEL     NOT indicated - the regime that would motivate it is not entered
FRICTION SENSITIVITY             NOT started, and must not be used to paper over O-34/O-36
2D TRANSIENT BENCHMARK           HOLD - the 1-D startup/coastdown baseline is not re-established
NATURAL CIRCULATION              HOLD
```

R0 stays the default. Nothing in `eta_is`, `J`, `tau_shaft`, friction, the motor model,
`headRatio_shutoff`, the H-Q curve, the loop resistance or the 2-D core was modified in this
phase.

---

## Phase 37 - Graphite heat source: volume weighting and the G1-G4 energy gates

### A. Power provenance, kept separate on purpose

| value | role | literature source |
|---|---|---|
| 10 MW | DESIGN / GRAPHITE REFERENCE CASE - used by this benchmark | **NOT RECORDED** |
| 7.4 MW | ACTUAL FULL-POWER OPERATION CASE - carried, not used here | **NOT RECORDED** |
| 8 MW | independent thermal test condition of `CoreTH_Baseline`, untouched | a test condition, not a claim |

Neither MSRE power is defined as a universal nominal power anywhere. The source for 10 MW and
7.4 MW was not available and **was not guessed**; both are carried as separate parameters with
the provenance recorded as missing, so nothing downstream can silently treat 10 MW as "the"
MSRE power.

### B. The graphite radial source was equal-power, and should not have been

`CoreChannel` fed the graphite `Q_gens_graphite[j]/nR`. TRANSFORM's `Cylinder_2D_r_z` divides
the annulus **uniformly in radius** (`drs = (r_outer - r_inner)/nR`) while the node volume it
computes goes as the difference of squared radii, so the volumes grow with radius:

| node | r_mid [m] | volume fraction | equal 1/nR | power-density error |
|---:|---:|---:|---:|---:|
| 1, facing the fuel | 0.013251 | 0.265178 | 0.333333 | **+25.70 %** |
| 2 | 0.016656 | 0.333333 | 0.333333 | 0.00 % |
| 3, outermost | 0.020062 | 0.401488 | 0.333333 | **-16.98 %** |

Total graphite power was conserved either way, so this was a **distribution** error. It still
mattered: node 1 is the one facing the fuel, so it sets the graphite-to-fuel flux and the peak
graphite temperature. Because the radial thickness is uniform the volume fraction reduces to the
mean radius over the sum of the mean radii, which cannot drift out of step with the geometry
model.

### C. Why the graphite residual is an identity, not a tolerance

Read from the library rather than assumed:

| fact | source |
|---|---|
| `der(Us) = Ubs` | `Dimensions_2/PartialDistributedVolume.mo:58` |
| `port_a1.Q_flow = nParallel*Q_flows_1[1,:]` - a ring total | `Conduction_2D.mo:143` |
| `internalHeatModel.Q_flows` enters divided by `nParallel` - so `Q_gens` is a ring total | `Conduction_2D.mo:137-139` |
| outer, top and bottom boundaries all `Adiabatic` | `CoreChannel.mo` connects |

The internal conduction flows telescope into the boundary ports, so

```
Q_graphite_source - Q_graphite_to_fuel - der(E_graphite)  ==  0
```

structurally. A non-zero value means the source scaling, one of the adiabatic assumptions, or a
sign convention is wrong - it is not something to be given a tolerance.

### D. G1 to G4, measured at 10 MW with f_graphiteHeating = 0.06

| gate | quantity | 2000 s | 8000 s | kind |
|---|---|---:|---:|---|
| G1 | `err_powerSplit` | 2.22e-16 | 2.22e-16 | identity |
| G1 | `err_graphiteFraction` | 0 | 0 | identity |
| G1 | `Q_toFuelDirect` / `Q_toGraphite` | 9.40 / 0.60 MW | same | - |
| G2 | `err_fV` | 0 | 0 | identity |
| G2 | `err_fV_sum` | 0 | - | identity |
| G2 | `fV_vs_equal` | 0.204465 | - | reported |
| G3 | `graphiteResidual` | 1.03e-10 W | -3.79e-11 W | identity |
| G3 | `Q_graphite_to_fuel` | 599984.688 W | 600000.007 W | - |
| G3 | `der_E_graphite` | 15.312 W | -0.0074 W | - |
| G4 | `T_graphite_max` | 949.6925 K | 949.6932 K | **reported only** |
| G4 | `T_graphite_mean` | 939.9687 K | 939.9692 K | **reported only** |
| G4 | `T_fuel_max` | 937.6165 K | 937.6165 K | **reported only** |
| G4 | `dT_graphiteToFuel` | +16.4844 K | +16.4848 K | direction asserted |

### E. The one assertion that fired was not a G-gate, and not a leak

At 2000 s the inherited `Core1D_TH_Baseline` energy balance failed at `err_energy` = -1.576e-06
against the `tol_energy` = 1e-6 this model tightens it to. Arithmetic identified it:

```
Q_toGraphite - Q_graphite_to_fuel = 600000 - 599984.688 = 15.312 W  = der_E_graphite exactly
core energy deficit               = 1e7 * 1.576e-6      = 15.761 W
                                    graphite storage explains 97.2 % of it
```

Activating the graphite source adds a slow thermal mode the zero-power cases never had. **The
response was a longer run, not a looser tolerance**: at 8000 s `err_energy` falls to 1.82e-08 and
`der_E_graphite` to -0.0074 W, and no assertion is violated. The temperatures were already
converged at 2000 s to six figures - only the storage term lagged - which is what confirms the
2000 s failure was convergence rather than a real energy path.

### F. What was deliberately not asserted, and not changed

`T_graphite_max` and `T_graphite_mean` are **reported, never bounded**. There is no accepted MSRE
graphite temperature in this repository; inventing a target would turn G4 into a fit. The only
G4 assertion is the direction - heated graphite must be hotter than the fuel it heats.

Unchanged this phase, as required: `Nus_Core` (Nu = 4.36, recorded as `BASELINE_CLOSURE`;
developing-flow closure is a separate sensitivity phase), the `Graphite_1` property model
(constant-property comparison is a later sensitivity case), `A_HT` and the equivalent graphite
geometry, and `f_graphiteHeating`'s default of 0 - so every result already recorded is unmoved.
The ring-to-ring split in `corePowerShape` was left alone because it is **already**
volume-weighted (`corePowerShape.mo:35-36` carries the cell volume) and changing it would move
`sum(SF) = 1` and with it the Phase 35 results.

### G. Status - gate decision belongs to the user

```
G1 POWER_SPLIT            evidence recorded, identities at 2.2e-16 and 0
G2 RADIAL_VOLUME_WEIGHT   evidence recorded, identities at 0; differs from equal-power by 20.4 %
G3 GRAPHITE_ENERGY_CLOSURE evidence recorded, residual 3.8e-11 W
G4 TEMPERATURES           reported only; direction holds at +16.48 K
POWER_PROVENANCE          10 MW and 7.4 MW separated; BOTH SOURCES NOT RECORDED - open
```

No gate is declared passed here. The numbers above are the evidence for that decision.

---

## Phase 38 - Graphite implementation audit (no code change)

Separates what the implementation demonstrably does from what has literature support. Nothing was
changed, refitted, or relaxed; the audit reads component values, not my own formulae.

### A. Control volumes, from the component rather than from algebra

`Cylinder_2D_r_z` divides uniformly in radius (`drs=(r_outer-r_inner)/nR`) and computes
`Vs = 0.5*((r+dr/2)^2-(r-dr/2)^2)*dtheta*dz`, i.e. `r_i*dr*dtheta*dz`.

| i | rs_i [m] | V_i component [m3] | V_i/sum(V) | fV implemented | abs error |
|---:|---:|---:|---:|---:|---:|
| 1 | 0.013250898 | 4.6093858710e-04 | 0.2651784353 | 0.2651784353 | 0 |
| 2 | 0.016656581 | 5.7940682665e-04 | 0.3333333333 | 0.3333333333 | 5.55e-17 |
| 3 | 0.020062264 | 6.9787506620e-04 | 0.4014882314 | 0.4014882314 | 5.55e-17 |

Max error **5.55e-17**, and the same at every one of the 3x20 cells - not merely `sum(fV)=1`.

### B. Source scaling

`core.Q_imposed` 10000000.000000 W, `Q_toGraphite` 600000.000000 W,
`sum(Q_gens_graphite)` 600000.000000 W (difference **0**), redistribution over cells
600000.000000 W. `nParallel` = 1140, handled once: `Q_gens` and `port_a1.Q_flow` are ring totals,
`Us`/`Ubs` are per channel. **No double counting, no missing equivalent-channel factor.**
Axial shape follows the cosine (17000.772 at both ends, 37962.797 at centre).

### C. Fuel-graphite interface law

Sign convention: `heatPorts[k].Q_flow > 0` into the fluid; `graphite.port_a1[k].Q_flow > 0` into
the graphite. Implemented law is `Q = h*A*(T_wall - T_fluid)*nParallel` with
h = 275.0683 W/m2/K and A = 5.898e-03 m2 per node.

```
eps_HT per node        = 0.000e+00  for all 20 nodes
eps_HT_total           = 0.000e+00 W
sum(Q_port into fluid) = 600000.007433 W = Q_graphite_to_fuel
sum(port_a1.Q_flow)    = -600000.007433 W
```

Verified as an implementation identity. It says the code uses its own `h` consistently; it says
**nothing** about whether that `h` is right - see E.

### D. Graphite properties (`TRANSFORM.Media.Solids.Graphite.Graphite_1`, "fluence = 0.2e25 n/m2")

| T [K] | cp [J/kg/K] | lambda [W/m/K] | density |
|---:|---:|---:|---:|
| 900 | 1712.1115 | 57.85325 | 1776.66 (constant) |
| 950 | 1751.3712 | 56.29782 | 1776.66 |

Declared range 273.15-1773.15 K contains the 900-950 K used here. cp and lambda are cubic in T,
density constant. **No report, table or equation number appears in the TRANSFORM source**:
TRANSFORM DEFAULT, citation `NOT_RECORDED`. The fluence label is a qualifier, not a citation.

By contrast the fuel-salt conductivity IS sourced: `lambda = 1.0 W/m/K` constant, Cantor
ORNL-TM-2316 (1968), as used by the INL MSRE VTB/SAM equation of state. It is the single
first-order input to `h` that has provenance.

### E. Nu = 4.36 applicability - `BASELINE_APPROXIMATION`

| condition Nu=4.36 assumes | measured | met |
|---|---|---|
| laminar | Re 815.9 - 944.6 | yes |
| **thermally developed** | **Lt/L = 7.98** | **no** |
| hydrodynamically developed | Lh/L = 0.43 | no |
| circular duct | stringer groove, D_h = 0.0158506 m equivalent | no |
| axially uniform wall flux | cosine source, node flux ratio 2.129 | no |

Pr = 17.28-20.01 makes the conventional entry-length estimate **eight times the channel length**.
`Lt/L = 7.98` is a **screening metric for the thermal-development assumption**, computed from a
circular-duct correlation, and is **not** the actual MSRE thermal entrance length. *(Corrected in
Phase 39: this paragraph previously asserted that the real Nu exceeds 4.36 and that the value is
therefore conservative. Withdrawn - see Phase 39 A.)* The direction of the departure is **not
established**. Classified `BASELINE_APPROXIMATION`: not `SUPPORTED`, since the stated conditions
are not met, and not `NOT_APPLICABLE`, since the flow is laminar and the value is the correct
order.
Candidate replacements, offered only: Hausen, Sieder-Tate, Shah-London entrance solutions - each
still needing a non-circular shape correction. **Nothing was changed.**

### F. Convergence - a claim of mine that had no basis

An earlier message of mine put the graphite time constant at "tau ~ 190 s". **That number came
from a one-point mental estimate, appears nowhere in the code or logs, and is withdrawn.** Fitted
properly:

```
tau_local(t) = -y/(dy/dt)  over t in [100,2000] s :  174.5, 175.2, 175.7, 175.6, 178.4, 173.9, 171.3 s
log-linear fit  y = A*exp(-t/tau) :  tau = 177.43 s,  A = 1.078e6 W,  R^2(log) = 0.999878
```

But the full record is **not** a single exponential: `der_E_graphite` RISES from 600000 W at t=0
to 999244 W at t=20 s before decaying, and crosses zero once at t = 2400 s
(+0.075 -> -0.193 W) into a small negative tail. Verdict:
**single-time-constant interpretation valid on [100, 2000] s only; rejected for the full record.**

### G. Steady-state criterion - proposed, NOT applied

Both tied to the tolerance the model already runs at, so neither is invented:

```
eps_E = solver_tol * Q_toGraphite = 1e-6 * 600000 = 0.60 W
eps_Q = solver_tol                = 1e-6
```

| t [s] | abs(der_E) [W] | abs(Qgf-QtoG)/QtoG | abs(err_energy) |
|---:|---:|---:|---:|
| 2000 | 15.312052 | 2.552e-05 | 1.576e-06 |
| 2500 | 0.872325 | 1.454e-06 | 1.082e-07 |
| 4000 | 0.214174 | 3.570e-07 | 3.971e-08 |
| 8000 | 0.007433 | 1.233e-08 | 1.820e-08 |

All three first hold at **t = 2360 s**. 8000 s is therefore a
**verified sufficient simulation horizon**, not a physical constant and not a tuned number.

### H. Verdict table

| gate | subject | result |
|---|---|---|
| G1 | power partition implementation | `PASS_IMPLEMENTATION_ONLY` |
| G2 | graphite spatial weighting | `PASS_IMPLEMENTATION_ONLY` |
| G3-A | graphite energy conservation | `PASS_IMPLEMENTATION_ONLY` |
| G3-B | fuel-graphite interface equation | `PASS_IMPLEMENTATION_ONLY` |
| G4 | temperature sanity check | `DIAGNOSTIC_ONLY` |
| P1 | graphite heating fraction 0.06 | `NOT_RECORDED` |
| P2 | graphite material properties | `NOT_RECORDED` |
| P3 | Nu correlation applicability | `BASELINE_APPROXIMATION` |
| P4 | 10 MW provenance | `NOT_RECORDED` |
| P5 | 7.4 MW provenance | `NOT_RECORDED` |

**`graphite physical validation PASS` is NOT claimed and must not be inferred from the above.**
`ReactorCore.f_graphiteHeating` is documented in the code as "0 in the paper"; the 0.06 used here
has no recorded source, and neither do the two powers or the graphite properties. Until P1-P5 are
resolved the temperatures 949.6932 K and 939.9692 K are diagnostics, nothing more.

---

## Phase 39 - Physical-validity audit of the graphite model

Separates code consistency from physical support. Nothing was fitted, no tolerance was relaxed,
`Nu`, `f_graphiteHeating` and `Graphite_1` were not touched.

### A. Corrections to earlier claims of mine

| withdrawn claim | where | replacement |
|---|---|---|
| "4.36 is a lower bound with a known sign" / "the conservative direction" | `Nus_Core.mo`, PHASE_LOG 1634 | **baseline fully developed laminar approximation**; direction of departure NOT established |
| "real Nu in an entrance region exceeds 4.36, so this over-predicts dT" | PHASE_LOG Phase 38 | withdrawn, same reason |
| `Lt/L = 7.98` read as the MSRE thermal entrance length | Phase 38 | **screening metric for the thermal-development assumption** |
| `eps_E = solverTol*Q` as a steady-state criterion | Phase 38 G | **CONFIRMED CIRCULAR**, see F |
| 2360 s as a convergence time | Phase 38 G | **first crossing of provisional numerical criteria** |

The classical entrance result assumes a circular duct, a constant wall temperature or flux, and
no volumetric heating. This problem has volumetric heating in **both** salt and graphite,
conjugate conduction, and a wall condition that is the outcome of the coupled solution, so the
sign of the departure from 4.36 does not follow from it.

### B. P1 - graphite heating fraction, `f_graphiteHeating = 0.06`

Repo evidence: `ReactorCore.mo:69` documents it as "**0 in the paper**". No source for 0.06.

Literature leads found by search, **primary documents NOT retrievable** (egress proxy blocks
osti.gov, info.ornl.gov, virtualtestbed.inl.gov, moltensalt.org), so none is verified to
document + report number + page + table as required:

| lead | value | stated denominator | status |
|---|---:|---|---|
| gamma heating of the graphite moderator | **6.7 %** | thermal output of the MSRE | UNVERIFIED LEAD |
| prompt generation into the graphite | **6.3 %** | core power | UNVERIFIED LEAD |

**Neither lead is 6.0 %**, and the two leads use different denominators from each other. The
value in use is therefore not a citation, and matching it to either lead would be exactly the
"similar number" adoption this audit forbids.

`P1 = NOT_RECORDED`. Resolving it needs ORNL/TM-2019/1359 (the TRANSFORM MSRE status report) or
the MSRE physics reports, fetched outside this container.

### C. P2 - graphite properties

Model uses `TRANSFORM.Media.Solids.Graphite.Graphite_1` ("fluence = 0.2e25 n/m2"), density
1776.66 kg/m3 constant, cp and lambda cubic in T (1712-1751 J/kg/K and 57.9-56.3 W/m/K over
900-950 K). **No report, table or equation number in the TRANSFORM source.**

MSRE actually used **grade CGB** graphite - Union Carbide, petroleum-coke filler with coal-tar
pitch binder, extruded and pitch-densified - and the literature describes it as **highly
anisotropic**. The model's conduction is isotropic. No numerical CGB density, cp or lambda was
retrieved, and none is recorded here.

| property | current model | MSRE reference | difference | source | status |
|---|---:|---|---|---|---|
| grade | generic | **CGB** | not comparable | search lead | `NOT_RECORDED` |
| density | 1776.66 constant | not retrieved | unknown | - | `NOT_RECORDED` |
| cp | cubic in T | not retrieved | unknown | - | `NOT_RECORDED` |
| lambda | cubic in T, isotropic | CGB **anisotropic** | direction unknown | search lead | `NOT_RECORDED` |

**`GENERIC TRANSFORM MATERIAL - MSRE equivalence not established`.**

### D. Equivalent-cylinder geometry - three separate identities

The construction is explicit in `Geometry.mo`: `r_inner = perimeter_channel/(2*pi)` reproduces the
wetted perimeter, `r_outer` reproduces the graphite area per channel. **Both radii are consumed by
those two constraints, so the conduction resistance is whatever they leave.**

| identity | model | reference | result |
|---|---:|---:|---|
| graphite volume | 1.981571 m3 | 1.981571 m3 | **EXACT** (by construction) |
| thermal mass | 3520.58 kg at Graphite_1 density | same volume | **EXACT** for the volume; density is P2 |
| fuel-contact area | 134.464402 m2 | 134.464402 m2 | **EXACT** (by construction) |
| conduction resistance | 9.5159e-07 K/W (annulus) | 1.9160e-06 K/W (slab estimate) | **APPROXIMATION**, ratio 0.4967 |
| heated perimeter | 0.072559 m/channel | same | EXACT |
| nParallel | 1140 | 1140 | EXACT |

**Scale of the mismatch.** Conduction contributes 0.57 K (annulus) or 1.15 K (slab) of the
16.4848 K total, while the convective film contributes **16.2220 K = 98 %**:

```
600 kW / (h*A_HT) = 600000/(275.0683*134.4644) = 16.2220 K   <- set by Nu, i.e. by P3
600 kW * R_cond   = 0.5710 K (annulus) vs 1.1496 K (slab)    <- the unconstrained identity
```

So the geometry approximation is a **second-order** contributor and the unvalidated Nusselt
number is the **dominant** one. Volume equivalence alone would not have shown this.

### E. Heat-transfer problem definition (before any correlation choice)

Traced from the code and confirmed in the results:

| effect | present? | evidence |
|---|---|---|
| laminar internal flow | yes | Re 815.9-944.6 |
| non-circular duct | yes | 1.2 x 0.4 in grooved channel, Dh = 0.0158506 m equivalent |
| hydrodynamic entrance | yes | Lh/L = 0.43 (screening) |
| thermal entrance | yes | Lt/L = 7.98 (screening) |
| fuel volumetric heating | yes | 9.40 MW into the salt |
| graphite volumetric heating | yes | 0.60 MW into the solid |
| axially varying power | yes | cosine, node flux ratio 2.129 |
| conjugate graphite conduction | yes | `Conduction_2D` with 3 radial nodes |
| **constant wall heat flux?** | **NO** | node heat flow 17718.5 - 37723.5 W |
| **constant wall temperature?** | **NO** | `Ts_wall` 919.115 - 948.026 K |

**The wall condition is neither.** Both `q_w(z)` and `T_w(z)` are outputs of the coupled
conjugate solution. `Nu = 4.36` is the fully developed value for a circular duct at **constant
wall heat flux**, so its stated boundary condition is not the one this model solves.

### F. Steady-state criterion - the circularity is demonstrated, not argued

`R_E = |dE_g/dt|/Q_g` and `R_Q = |Q_g - Q_g->f|/Q_g` are **identically equal** by the G3 energy
identity, so proposing both as independent criteria was redundant. `R_T = max_i |dT_g,i/dt|` is
independent and does add information.

Two runs of the same model, differing only in solver tolerance:

| criterion | tol = 1e-6 | tol = 1e-8 | verdict |
|---|---|---|---|
| `eps_E = solverTol*Q` (threshold 0.6 W vs 0.006 W) | crosses at 2360 s | **never crosses in 8000 s** | **CIRCULAR** |
| dimensionless `R_E < 1e-6` | crosses at 2360 s | crosses at 2560 s | stable, a solution property |

Tightening the solver by 100x moved the first threshold by 100x and destroyed the conclusion,
while the dimensionless criterion moved by 8 %. `eps_E = solverTol*Q` is therefore usable only as
a numerical noise floor, never as a physical steady-state criterion.

`R_E` is also **non-monotone**: 6.46e-07 at 2360 s, rising to 2.28e-06 at 3000 s before falling -
consistent with the sign crossing at 2400 s found in Phase 38. 2360 s is a **first crossing of
provisional numerical criteria**, not a convergence time. 8000 s remains a **verified sufficient
simulation horizon**.

### G. Four-level status

```
A. CODE CONSISTENCY VERIFIED      YES  - weighting 5.55e-17, interface residual 0, scaling exact
B. NUMERICAL CONSERVATION VERIFIED YES  - graphite residual ~1e-11 W, an identity not a tolerance
C. PHYSICAL MODEL SUPPORTED        NO   - P1, P2, P3 unresolved; R_cond an APPROXIMATION
D. MSRE VALIDATED                  NO   - no MSRE measurement compared anywhere
```

Level C is blocked on P1 (heating fraction), P2 (CGB vs generic graphite) and P3 (Nusselt
closure, which alone sets 98 % of the graphite-to-fuel temperature difference). No code change is
recommended until those are resolved from primary documents.

---

## Phase 40 - Reduced-order graphite model against the paper's ORNL-referenced steady state

**The paper PDF did not reach this session.** Every value attributed to Amirkhosravi et al. (2026)
below is **as quoted by the user**, not read from the document. Section, table and figure numbers
are recorded as given and are NOT independently verified here. No CFD, RANS, porous k-epsilon,
3-D stringer mesh or solver architecture was reproduced; the model is unchanged from Phase 39.

### A. P1 upgraded - the graphite heating fraction now has a source chain

```
f_graphiteHeating = 0.06
  provenance : Amirkhosravi et al. (2026), Sec. 2.4.2      [user-quoted, not verified here]
  underlying : ORNL-TM-0378 / Engel and Haubenreich         [not retrieved]
  conditions : 0 % fuel permeation; gamma + neutron graphite heating; fuel direct 0.94
  status     : SECONDARY_SOURCE_PROVENANCE
```

This supersedes the Phase 39 `NOT_RECORDED`. It is **not** `SOURCE_CONFIRMED`: the primary ORNL
document was not retrieved, and the Phase 39 search leads (6.7 % gamma heating of thermal output,
6.3 % prompt into core power) still do not equal 6.0 %. The conditions attached to it above are
what make 0.06 a different quantity from those two leads.

### B. Graphite properties - TRANSFORM vs the paper's Table 3 (nothing changed)

| property | TRANSFORM Graphite_1, 900-950 K | at T_g_mean = 939.97 K | paper | rel. error |
|---|---:|---:|---:|---:|
| density [kg/m3] | 1776.66 constant | 1776.66 | 1874 | **-5.19 %** |
| thermal conductivity [W/m/K] | 57.853 - 56.298 | 56.606 | 53 | **+6.80 %** |
| specific heat [J/kg/K] | 1712.1 - 1751.4 | 1743.86 | 1772 | -1.59 % |
| rho*cp [J/m3/K] | - | 3 098 246 | 3 320 728 | **-6.70 %** |

The paper's values are treated as **isotropic modelling values**, a separate question from CGB
validation (Phase 39 C), which remains open.

### C. Inventory

| quantity | model | paper | difference |
|---|---:|---:|---|
| V_graphite | 1.981571 m3 | - | - |
| V_fuel | 0.532836 m3 | - | - |
| graphite fraction | **0.788087** | 0.775 | +1.69 % |
| fuel fraction | **0.211913** | 0.225 | -5.82 % |
| equivalent passages | **1140** | 1140 | **exact** |

### D. Cylinder_2D_r_z against the paper's Eq. (3) - term by term

| paper Eq. (3) term | `Conduction_2D` implementation | verified in |
|---|---|---|
| thermal capacitance | `der(Us[i,j]) = Ubs[i,j]`, `Us = m*u(T)`, so `rho*V*cp*dT/dt` | Phase 38 |
| volumetric source | `internalHeatModel.Q_flows[i,j] = Q_gens_graphite[k]*fV[i]` | Phase 38 §3 |
| internal heat conductance | `Q_flows_1` radial (3 nodes) and `Q_flows_2` axial, telescoping into the ports | Phase 38 §2 |
| graphite-to-fuel exchange | `port_a1.Q_flow = h*A*(T_wall - T_fluid)*nParallel` | Phase 38 §4 |

Same energy physics, **resolved more explicitly**: a lumped graphite node becomes 3 radial nodes
with explicit conduction between them, so the surface temperature that drives the fuel coupling is
computed rather than assumed equal to the mean.

### E. `T_graphite_mean` definition - checked BEFORE comparing

| definition | value |
|---|---:|
| true volume-weighted `sum(T*V)/sum(V)` | 939.969176 K |
| mass-weighted `sum(T*m)/sum(m)` | 939.969176 K |
| naive arithmetic over the 60 cells | 939.948973 K |
| **reported `T_graphite_mean`** | **939.969176 K** |

Reported minus volume-weighted = **-0.000000 K**. The reported value **is** the volume-weighted
mean, so comparing it to an ORNL volume mean is legitimate. (Density is uniform, so mass and
volume weighting coincide; the naive arithmetic mean would have been 0.0202 K off.)

### F. 10 MW steady state, model unchanged

| quantity | model [K] | ORNL-ref [K] | diff [K] | rel |
|---|---:|---:|---:|---:|
| T_fuel_in | 908.0000 | 908.15 | -0.1500 | -0.017 % |
| T_fuel_out | 937.6164 | 935.921 | **+1.6954** | +0.181 % |
| T_graphite_mean | 939.9692 | 936.42 | **+3.5492** | +0.379 % |
| core rise | 29.6164 | 27.7710 | **+1.8454** | +6.6 % |

### G. Cause analysis - the two discrepancies have different owners

Working the §11 order, the first item settled it before reaching the closures.

**(a) The core fuel rise is not a graphite quantity at all.** In steady state every watt reaches
the fuel stream, so `dT = Q/(mdot*cp)` regardless of how the graphite behaves:

```
model fuel cp                        2009.66 J/kg/K   (MSRE.Media.FuelSalt, Cantor ORNL-TM-2316)
cp implied by the model dT           2009.83 J/kg/K   -> self-consistent to 0.01 %
cp implied by the reference dT       2143.38 J/kg/K   -> +6.65 %
mdot implied by the reference dT     179.178 kg/s     vs the model's 168.0
```

The reference rise requires either a fuel `cp` 6.65 % higher or a mass flow 6.7 % higher. **Neither
appears in the §11 cause list, because the list is graphite-focused and this is a fuel-side
difference.** Nu, heat-transfer area, graphite properties and graphite heating distribution cannot
move it: they redistribute temperature between the solid and the fluid, they do not change how much
the fluid heats up for a given power and flow.

**(b) The graphite-to-fuel offset is what the graphite model owns**, and it is the weaker
comparison of the two:

```
model      T_graphite_mean - T_fuel_mean = 939.9692 - 923.5520 = +16.4172 K
reference  936.420 - (908.15+935.921)/2  = 936.420 - 922.0355  = +14.3845 K
difference                                                       +2.0327 K
```

**This comparison is WEAK and is not used as a verdict.** The reference fuel mean is not given, so
`(Tin+Tout)/2` was substituted, which assumes a linear axial profile that a cosine power shape does
not produce. Checked inside the model, that substitution is itself off by 0.7438 K - a third of the
difference being measured. A defensible graphite-offset comparison needs the reference's own
volume-weighted fuel mean.

### H. Gates

| gate | result | basis |
|---|---|---|
| G1 power split | `PASS` | `err_powerSplit` 2.22e-16, 9.40/0.60 MW |
| G2 graphite inventory | `PARTIAL_MATCH` | fraction 0.788087 vs 0.775, +1.69 % |
| G3 1140 channel scaling | `PASS` | nParallel 1140 exact; source 600000.000000 W, no double count |
| G4 graphite energy conservation | `PASS` | residual -3.79e-11 W, a structural identity |
| G5 fuel-graphite interface conservation | `PASS` | per-node `eps_HT` = 0.000e+00, sum = 600000.007 W |
| V1 core T_in | `PASS` | imposed boundary, 908 vs 908.15 K |
| V2 core T_out | `PARTIAL_MATCH` | +1.6954 K; cause is fuel-side cp or mdot, NOT the graphite model |
| V3 graphite mean temperature | `PARTIAL_MATCH` | +3.5492 K, of which +1.52 K is inherited from the fuel offset |
| V4 axial graphite temperature | `NOT_DIRECTLY_COMPARABLE` | Fig. 15 data not available in this session |

Radial comparison (paper Fig. 14) deliberately **not attempted**: the `Cylinder_2D_r_z` radial
coordinate runs through the graphite of a single equivalent channel, not across the reactor core,
so the two radial coordinates are different quantities. Reserved for the Core2D ring model.

### I. Status

```
A. CODE CONSISTENCY VERIFIED       YES
B. NUMERICAL CONSERVATION VERIFIED YES  - G1, G3, G4, G5 all identities
C. PHYSICAL MODEL SUPPORTED        PARTIAL - P1 now secondary-source; P2 and P3 still open
D. MSRE VALIDATED                  NO  - V2/V3 partial, V4 not comparable, and the V2 gap is
                                         fuel-side, so it does not test the graphite model
```

**No parameter was changed and nothing was fitted.** In particular `Nu = 4.36` was left alone: the
paper's `Nu = 0.023*Re^0.8*Pr^0.4` is a turbulent Dittus-Boelter form used with a porous-medium
Reynolds number, while the MSRE channel here runs at Re 816-945, laminar. Copying it would apply a
turbulent correlation to a laminar flow. `P3 = OPEN / BASELINE_APPROXIMATION` stands.

---

## Phase 41 - The paper arrived; Phase 40 verified and one of its conclusions withdrawn

The PDF (Amirkhosravi et al., *Nuclear Engineering and Design* **449** (2026) 114757) reached the
session, so the Phase 40 values recorded as "user-quoted, not verified" are now read directly.
Model still unchanged.

### A. Provenance now confirmed from the document

| item | value | source in the paper | status |
|---|---|---|---|
| **P1** graphite heating | **6 %** | Sec. 2.4.2: "*This calculation assumes that 6% of the reactor power is generated in the graphite in the absence of fuel permeation, based on gamma and neutron heating estimates by C.W. Nestor (Engel and Haubenreich, 1962)*", citing ORNL-TM-0378 | **`SOURCE_CONFIRMED`** |
| **P4** 10 MW | **Design full power 10 MWth** | Table 1 (Bao, 2016) | **`SOURCE_CONFIRMED`** |
| **P5** 7.4 MW | **Actual full power ~7.4 MWth** | Table 1 (Bao, 2016) | **`SOURCE_CONFIRMED`** |
| P2 graphite props | 1874 / 53 / 1772 | Table 3 (Forsberg 2007; Mateusz Pater 2019) | sourced, but **not CGB-specific** |

**The denominator is confirmed to be reactor power**, which is exactly how `f_graphiteHeating` is
defined in `ReactorCore.mo`. The Phase 39 leads (6.7 %, 6.3 %) were different quantities, as
suspected. **P1 is closed.** The design/actual split the user specified is confirmed verbatim.

### B. Withdrawal - the Phase 40 cause analysis was wrong

Phase 40 G(a) concluded that the reference core rise "implies a fuel cp of 2143.38 J/kg/K, +6.65 %
different from the model's, or a mass flow of 179.178 kg/s". **Both figures are withdrawn.**

The paper's own Table 2 (MSRE fuel salt at 922 K, De Wet and Greenwood 2019) gives
**cp = 2 x 10^3 J/(kg.K)**, and Table 1 gives **0.07571 m3/s at 2241 kg/m3 = 169.666 kg/s**:

| quantity | model | paper | difference |
|---|---:|---:|---:|
| fuel cp [J/kg/K] | 2009.66 | **2000** | **+0.48 %** |
| mass flow [kg/s] | 168.0 | **169.666** | -0.98 % |

The inference was wrong because it assumed **both** `Q = 10 MW` **and** `mdot = 168` applied to the
reference pair. Neither is the paper's value, and forcing both into `dT = Q/(mdot*cp)` pushed the
entire residual into `cp`. The real difference in `cp` is half a percent.

### C. What the reference pair actually corresponds to

Running the energy balance on the ORNL-TM-0378 pair with the paper's **own** flow and heat capacity:

```
908.15 -> 935.921  =>  dT = 27.771 K
Q = mdot*cp*dT = 169.666 * 2000 * 27.771 = 9.4236 MW      <- NOT 10 MW, short by 5.76 %

dT that 10 MW gives at the paper's own flow and cp        = 29.4696 K
dT the model gives at 10 MW, mdot 168, cp 2009.66         = 29.6188 K   (+0.51 %)
reference dT                                              = 27.7710 K
```

**The model reproduces the paper's own 10 MW energy balance to 0.51 %.** The remaining 1.85 K gap
to the ORNL pair is a property of the reference data: the quoted inlet/outlet pair does not
correspond to 10 MW at the flow and heat capacity the same paper states. Imposing exactly 10 MW
therefore cannot land on it, and **no graphite-side change can close it** - which is the one part
of the Phase 40 conclusion that survives, now for a documented reason rather than an inferred one.

### D. New conflict found - fuel thermal conductivity, 5.5x

| | model | paper |
|---|---:|---:|
| fuel lambda [W/m/K] | **1.0** (Cantor, ORNL-TM-2316, via INL VTB/SAM) | **5.5** (De Wet and Greenwood, 2019) |
| resulting Pr | 17.28 - 20.01 | **2.93** |
| h at Nu = 4.36 [W/m2/K] | 275.07 | 1512.88 |
| film dT at 600 kW over 134.46 m2 | **16.222 K** | **2.949 K** |

This single property sets the graphite-to-fuel temperature difference almost entirely (Phase 39 D:
the film carries 98 % of it). It is a **direct conflict between two cited sources**, not a gap:
both values have provenance. It is left **unchanged and open** - the model keeps the Cantor value
it cites. Note the paper applies `Nu = 0.023*Re^0.8*Pr^0.4` (Table 6, White 2011), a **turbulent**
Dittus-Boelter form; with its own Pr = 2.93 and the MSRE channel Reynolds number this remains a
turbulent correlation used outside the turbulent regime, so it is still **not** copied here.

### E. Domain mismatch found in V3

The paper's graphite mean is "*the average temperature of the graphite in the reactor vessel,
**excluding the volute***" (Sec. 3). The model's `T_graphite_mean` is over the **active-core channel
graphite only**. These are different domains, so the V3 comparison is weaker than a matching pair
of numbers suggests.

For reference, the paper's own 3-D result against the same ORNL value:

| | paper GeN-Foam | ORNL | deviation |
|---|---:|---:|---:|
| fuel inlet | 908.51 | 908.15 | 0.039 % |
| fuel outlet | 936.003 | 935.921 | 0.008 % |
| graphite mean | **935.61** | **936.42** | 0.08 % |
| this model | **939.97** | 936.42 | 0.379 % |

### F. Gate revisions

| gate | Phase 40 | now | reason |
|---|---|---|---|
| P1 | SECONDARY_SOURCE | **`SOURCE_CONFIRMED`** | Sec. 2.4.2 read; denominator confirmed as reactor power |
| P4, P5 | NOT_RECORDED | **`SOURCE_CONFIRMED`** | Table 1, design 10 MWth / actual ~7.4 MWth |
| V2 core T_out | PARTIAL_MATCH, "cause is fuel cp or mdot" | **`PARTIAL_MATCH`**, cause corrected | model matches the paper's 10 MW balance to 0.51 %; the reference pair itself is a 9.42 MW state |
| V3 graphite mean | PARTIAL_MATCH | **`NOT_DIRECTLY_COMPARABLE`** | different graphite domain (vessel-excluding-volute vs active core) |
| V4 axial | NOT_DIRECTLY_COMPARABLE | unchanged | Fig. 15 is a plot; one tabulated point exists (top of graphite matrix ~167 cm, ORNL 964.4 K) but it lies **above** the model's 162.56 cm active channel |
| P3 Nu | OPEN / BASELINE_APPROXIMATION | unchanged, **and now with a second open input** | the fuel lambda conflict in D feeds straight into h |

### G. Status

```
A. CODE CONSISTENCY VERIFIED       YES
B. NUMERICAL CONSERVATION VERIFIED YES
C. PHYSICAL MODEL SUPPORTED        PARTIAL - P1/P4/P5 confirmed; P2 (CGB) and P3 (Nu, and now
                                             the fuel lambda conflict) still open
D. MSRE VALIDATED                  NO  - V2 explained but not matched, V3 not comparable,
                                         V4 not comparable
```

Nothing was fitted and no parameter was changed in this phase.

---

## Phase 42 - Closure and benchmark-definition audit. NO CODE CHANGED.

Nothing fitted; `Nu`, fuel `k`, graphite properties and every tolerance left as they were.

### A. Phase 41 verdicts downgraded - secondary, not primary

| item | Phase 41 | now | why |
|---|---|---|---|
| P1 6 % graphite heating | `SOURCE_CONFIRMED` | **`SECONDARY_SOURCE_CONFIRMED`** | read in Amirkhosravi Sec. 2.4.2; the underlying **ORNL-TM-0378** was not opened |
| P4 10 MW design | `SOURCE_CONFIRMED` | **`SECONDARY_SOURCE_CONFIRMED`** | Table 1 attributes it to **Bao (2016)**, not to an ORNL primary |
| P5 7.4 MW actual | `SOURCE_CONFIRMED` | **`SECONDARY_SOURCE_CONFIRMED`** | same |

`PRIMARY_SOURCE_CONFIRMED` is not used anywhere and must not be until the ORNL originals are read.

### B. The 9.42 MW arithmetic - wording corrected

The arithmetic stands: 0.07571 m3/s x 2241 kg/m3 x 2000 J/kg/K x 27.771 K = **9.4236 MW**.

The **claim** built on it does not. Phase 41 said "the reference data itself is not 10 MW"; that is
withdrawn. Those numbers are tabulated nominal/design values taken at different reference
temperatures (density at 650 degC, cp at 922 K), are rounded, and are not stated anywhere to form a
closed constant-property set. The paper explicitly identifies the case as the 10 MW reference
condition, and the arithmetic must not be used to contradict it.

Permitted statement only:

> **The tabulated nominal values do not form an exact 10 MW constant-property energy-closure set.**

### C. The 0.51 % agreement - reclassified

| | dT |
|---|---:|
| 10 MW at the paper's nominal flow and cp | 29.4696 K |
| this model at 10 MW | 29.6188 K |
| difference | **0.51 %** |

This is **`GLOBAL ENERGY-EQUATION CONSISTENCY CHECK`**. It confirms only that `Q`, `mdot` and `cp`
are wired together consistently. It is **not** MSRE validation, **not** "the 10 MW benchmark
reproduced", and it is **removed from graphite validation entirely** - it would pass identically
with any graphite model at all, including none.

### D. V1 / V2 reclassified

* **V1 `T_in`** - `T_in_set` is a prescribed Dirichlet boundary. Agreement with 908.15 K is
  **`INPUT_CONDITION_MATCH`**, not a validation PASS. A boundary condition cannot validate itself.
* **V2 `T_out`** - moved out of graphite validation into **`GLOBAL_CORE_TH`** (TH2 below), where it
  belongs: it is the `Q = mdot * integral(cp) * (T_out - T_in)` statement.

### E/F. Fuel thermal conductivity - the top blocker, NOT resolved

| source | composition | T | k [W/m/K] | definition | primary/secondary | remarks |
|---|---|---|---:|---|---|---|
| `MSRE.Media.FuelSalt` (in use) | LiF-BeF2-ZrF4-UF4 65.0-29.17-5.0-0.83 mol% | any (constant) | **1.0** | liquid salt conductivity | secondary (cites Cantor ORNL-TM-2316 via INL VTB/SAM) | argument unused |
| `MSRE_Properties.lambda_legacy` (retired) | same | constant | 1.44 | liquid, 0.83 Btu/(hr.ft.F) | secondary | kept for reference only |
| Amirkhosravi Table 2 | "MSRE fuel salt" | 922 K | **5.5** | **not stated** | secondary, cites **De Wet and Greenwood (2019)** | see below |

**De Wet and Greenwood (2019) is ORNL/TM-2019/1359, *Status Report on the MSRE TRANSFORM Model***
- the same modelling lineage this library descends from. **The document could not be retrieved**
(osti.gov, info.ornl.gov, virtualtestbed.inl.gov and moltensalt.org are all blocked by the egress
proxy), so it is impossible to say from here whether 5.5 is what De Wet and Greenwood state, or
what quantity they attach it to.

**Status: `PAPER_REPORTED_VALUE`.** It is *not* recorded as a peer source conflict, because the two
values are not yet known to be the same quantity.

Possibilities that must be checked against the primary document, **recorded as open questions and
explicitly NOT as a correction**: a typo or decimal-place error; a unit-conversion factor; a
different salt; a citation-propagation error; or an **effective / porous-medium homogenised**
conductivity rather than the liquid value - the paper models the core as a porous zone containing
graphite at k = 53 W/m/K, so a homogenised conductivity would legitimately be far above the salt's.
No evidence for any of these was found here, and none is asserted. **5.5 was not applied.**

### G. P3 split into four independent questions

| id | question | status |
|---|---|---|
| **P3-A** | is `Nu = 4.36` applicable (laminar, developing, non-circular, conjugate, volumetric heating)? | `OPEN / BASELINE_APPROXIMATION` |
| **P3-B** | what is the fuel thermal conductivity, and of what definition? | `OPEN`, blocking |
| **P3-C** | resulting `h` and film resistance | derived from A and B |
| **P3-D** | system-level graphite temperature response | downstream of C |

**Correction carried forward:** Phase 41 said a 5.5x change in `k` gives exactly 5.5x the `h`. That
holds **only** for the present fixed-`Nu` baseline, where `h = Nu*k/Dh`. Under any developing-flow
correlation `Nu = f(Re, Pr, L/D)` with `Pr = mu*cp/k`, changing `k` moves `Nu` as well, so the
proportionality breaks. The statement is valid **only as a fixed-Nu sensitivity**, and is labelled
as such.

### H. Inventory - denominators NOT confirmed equal, so no error is computed

Model, stated as a formula:

```
f_fuel = A_core_total / (pi/4 * D_graphiteStack^2)  over the active height 1.6256 m
       = 0.327778 / 1.546756 = 0.211913        ->  f_graphite = 0.788087
```

The model assigns the **entire** stack cross-section to either channel or graphite: no control-rod
thimbles, no sample basket, no central region, no upper or lower graphite extension, no bypass, no
plena.

The paper states "the **core's** volume fraction is approximately 0.775 for the graphite structure,
with the remaining 0.225 filled by fluid fuel", attributed to **Batara**, with no volume definition
given; and elsewhere notes the sample "basket was not homogenised". **The two denominators are
therefore not established to be the same domain**, and the +1.69 % figure from Phase 40 is
withdrawn as a match quality. Status: **`NOT_CONFIRMED_SAME_DOMAIN`**.

The 1140 parallel-passage scaling remains a separate, exact `PASS` (I3).

### I. Graphite properties - the two differences do different jobs

| | TRANSFORM at 940 K | paper | difference | what it controls |
|---|---:|---:|---:|---|
| `rho*cp` [J/m3/K] | 3 098 246 | 3 320 728 | -6.70 % | **transient only.** Steady state is independent of it. Would move the 177.4 s graphite time constant to about 190.2 s |
| `k` [W/m/K] | 56.606 | 53.0 | +6.80 % | **steady conduction resistance inside the graphite.** Moves the 0.5710 K conduction drop to 0.6099 K, i.e. 0.039 K against a 16.222 K film |

Mixing these into one "property error" would be wrong: at steady state only `k` acts, and its
effect is 0.2 % of the graphite-to-fuel difference. CGB anisotropy stays a separate `OPEN` (P2).

### J/K/L. Graphite temperature comparisons

* **Mean (paper Table 9, 936.42 K)** - stays `NOT_DIRECTLY_COMPARABLE`. The paper averages over
  "the graphite in the reactor vessel, excluding the volute"; the model averages over active-core
  channel graphite. **939.97 - 936.42 = 3.55 K must not be quoted as a validation error.**
* **Axial, Fig. 15** - the PDF is in hand and was read. The body states Figs. 14-16 give the
  distributions "**at the midplane and the hottest radial position**", and Fig. 15 is the axial one.
  It is therefore the axial profile **at the hottest radial position of the reactor core**. The 1-D
  model is a single core-average equivalent channel with **no reactor-radial coordinate**, so it
  cannot produce a "hottest radial position" profile at all. `NOT_DIRECTLY_COMPARABLE` **for a
  definitional reason, not for want of data** - it becomes comparable at the Core2D ring stage,
  where `f_radial` makes ring 1 the hottest. Table 10's "Top of Graphite Matrix (~167 cm), ORNL
  964.4 K" is likewise outside the model's 162.56 m active channel.
* **Radial, Fig. 14** - not attempted. Reactor-core radius is a different coordinate from the
  within-stringer conduction radius of `Cylinder_2D_r_z`.

### M. The 6.7 % / 6.3 % leads - wording corrected

Phase 41 said they "were different quantities, as suspected". Withdrawn. Their numerators,
denominators, deposition definitions and operating conditions have not been read from their own
sources. Status: **`RELATED_VALUES_WITH_DIFFERENT_REPORTED_DEFINITIONS`**.

### N. Gate structure, restated

```
Implementation
  I1 power split bookkeeping ............ PASS   (2.22e-16)
  I2 radial source weighting ............ PASS   (5.55e-17 vs component cell volumes)
  I3 1140 parallel-channel scaling ...... PASS   (exact; 600000.000000 W)
  I4 graphite energy conservation ....... PASS   (-3.79e-11 W, structural identity)
  I5 interface wiring ................... PASS   (per-node eps_HT = 0)

Global core TH
  TH1 prescribed Tin consistency ........ INPUT_CONDITION_MATCH  (not a validation)
  TH2 Q-mdot-cp-Tout energy closure ..... GLOBAL ENERGY-EQUATION CONSISTENCY CHECK (0.51 %)

Graphite physical input
  P1 6 % heating provenance ............. SECONDARY_SOURCE_CONFIRMED
  P2 graphite material properties ....... OPEN   (generic vs CGB; anisotropy)
  P3-A Nu applicability ................. OPEN / BASELINE_APPROXIMATION
  P3-B fuel k provenance ................ OPEN   <-- top blocker, PAPER_REPORTED_VALUE
  P3-C h / film resistance .............. OPEN   (follows A and B)
  P4 equivalent graphite geometry ....... volume EXACT, area EXACT, R_cond APPROXIMATION;
                                          inventory fractions NOT_CONFIRMED_SAME_DOMAIN

Graphite validation
  V1 graphite axial T(z) ................ NOT_DIRECTLY_COMPARABLE (hottest-radial definition)
  V2 graphite local/max T ............... NOT_DIRECTLY_COMPARABLE (definition unmatched)
  V3 graphite mean ...................... NOT_DIRECTLY_COMPARABLE (averaging domain unmatched)
```

Independent levels:

```
A CODE CONSISTENCY .............. VERIFIED
B NUMERICAL CONSERVATION ........ VERIFIED
C GLOBAL CORE TH CONSISTENCY .... VERIFIED (0.51 %, and it says nothing about graphite)
D GRAPHITE PHYSICAL MODEL SUPPORT NOT ESTABLISHED (P2, P3-A, P3-B open)
E MSRE GRAPHITE VALIDATION ...... NOT ESTABLISHED (all three V gates not comparable)
```

### O. Conditions on the next code change

None permitted until P3-B (fuel `k`) and P3-A/C (low-Re closure) are settled from primary
documents. When they are, the baseline is **kept, not replaced**:

```
BASELINE   Cantor k = 1.0 + Nu = 4.36        <- stays runnable, exactly as the R0/R1 pump pair
CANDIDATE  literature-supported k + selected low-Re closure
```

Run both and compare `Nu(z)`, `h(z)`, film resistance, graphite internal resistance, `T_fuel(z)`,
`T_graphite_surface(z)`, `T_graphite_mean(z)`, `T_graphite_max(z)`, `T_out`, graphite stored energy.
No single ORNL temperature may be used as a fitting target.

---

## Phase 43 - Separating the actual-property baseline from the ORNL-TM-0378 historical benchmark

**No code changed. No property package touched. Investigation and case specification only.**

The ORNL-TM-0378 values below were **confirmed externally by the user**, not retrieved in this
container (osti.gov, info.ornl.gov, virtualtestbed.inl.gov and moltensalt.org remain blocked by the
egress proxy). Unit conversions are computed here.

### A. P3-B closed - it was never a physics conflict, it is two vintages

```
1 Btu/(hr.ft.F) = 1.730735 W/(m.K)
```

| id | classification | k [W/m/K] | origin |
|---|---|---:|---|
| **P3-B1** | **`HISTORICAL_ORNL0378_PROPERTY`** | 3.21 Btu/(hr.ft.F) = **5.5557** | ORNL-TM-0378 (1962) graphite-temperature calculation, 10 MW, 0 % permeation, 6 % graphite power |
| **P3-B2** | **`CORRECTED_MSRE_PROPERTY`** | **1.0** | ORNL/TM-2019/1359 later corrected primary-salt correlation; what this library uses |

The `k = 1.0 vs 5.5 unresolved source conflict` framing of Phases 41-42 is **withdrawn**. The two
numbers are the same property at two different states of knowledge, fifty-seven years apart. Neither
is wrong in its own context, and **neither may be substituted for the other**.

### B. Amirkhosravi Table 2 - citation and value do not agree

| | |
|---|---|
| value printed | 5.5 W/(m.K) |
| citation printed | De Wet and Greenwood (2019) |
| what De Wet and Greenwood actually carry | **1.0 W/(m.K)** (the corrected correlation) |
| what 5.5 numerically matches | ORNL-TM-0378's 3.21 Btu/(hr.ft.F) = **5.5557**, agreeing to **1.00 %** |

Recorded as **`CITATION / VALUE PROVENANCE INCONSISTENCY`**.

**"5.5 is confirmed by De Wet 2019" is forbidden** and does not appear anywhere. That the printed
value coincides with the 1962 historical figure is recorded as **a numerical fact only**; whether it
propagated from ORNL-TM-0378 is a hypothesis and is **not** asserted as provenance.

### C. P1 promoted, with its character stated exactly

`P1 = f_graphiteHeating = 0.06` -> **`PRIMARY_SOURCE_CONFIRMED`** (ORNL-TM-0378, user-verified).

Its nature, which the classification alone would mislead about:

> **ORNL-TM-0378 CALCULATION ASSUMPTION** - 6 % of reactor power produced in the graphite in the
> absence of fuel permeation, from a gamma and neutron heating calculation.

**"MEASURED FRACTION" is forbidden.** It was never measured; it was calculated.

### D. Benchmark hierarchy - ORNL-TM-0378 is a calculation, not an experiment

ORNL-TM-0378's graphite temperatures come from a hydraulic model plus a nuclear power distribution
plus a thermal calculation. Calling them "experimental data" would misrepresent the target.

```
A CODE CONSISTENCY ..................... VERIFIED
B NUMERICAL CONSERVATION ............... VERIFIED
C GLOBAL CORE ENERGY CLOSURE ........... VERIFIED   (narrowed, see N)
D PHYSICAL INPUT SUPPORT ............... PARTIAL
E ORNL-TM-0378 CALCULATION BENCHMARK ... NOT ATTEMPTED (Case B not yet specified in full)
F MSRE EXPERIMENTAL VALIDATION ......... NOT ESTABLISHED
```

### E/F. The two cases

**Neither case overwrites the other. The current baseline is Case A and is not modified.**

| property / assumption | **CASE A** actual / corrected | **CASE B** ORNL-TM-0378 historical | source | reason for the split |
|---|---|---|---|---|
| purpose | later-corrected MSRE system TH | reproduce the 1962 thermal calculation | - | physical fidelity is not benchmark reproduction |
| fuel k [W/m/K] | **1.0** | **5.5557** (3.21 Btu/hr/ft/F) | TM-2019/1359 / TM-0378 | P3-B2 vs P3-B1 |
| graphite k [W/m/K] | 56.606 at 940 K (Graphite_1) | **22.4996** (13 Btu/hr/ft/F) | TRANSFORM / TM-0378 | **see the finding below** |
| fuel cp [J/kg/K] | 2009.66 (Cantor) | **NOT YET EXTRACTED** | - | must come from TM-0378 |
| total power | 10 MW | 10 MW | both | same |
| graphite power fraction | 0.06, annotated as a historical assumption | 0.06 | TM-0378 | same number, different standing |
| permeation | n/a | 0 % | TM-0378 | Case B condition |
| T_in | 908 K imposed | **NOT YET EXTRACTED** | - | must come from TM-0378 |
| power profile | cosine, f_ax = 1.2 | **NOT YET EXTRACTED** | - | must come from TM-0378 |
| heat-transfer relation | Nu = 4.36 | **NOT YET EXTRACTED** | - | see G |
| graphite T definition | volume-weighted, active core | **NOT YET EXTRACTED** | - | must match before comparing |

**A first-order finding nobody had flagged:** ORNL-TM-0378's graphite conductivity of
**22.4996 W/(m.K)** is **less than half** the current model's 56.606 and the paper's 53. For Case B
this is a primary input, not a refinement.

### G. One variable at a time is forbidden here

Swapping only fuel `k` from 1.0 to 5.5557 and comparing against ORNL would be meaningless: it would
mix a 1962 transport property into a model carrying modern properties, geometry and closure
everywhere else. **Case B may only be built once the whole input set above is extracted from the
report.** Four rows are still missing, so Case B is `NOT_YET_SPECIFIED`.

Specifically still required from ORNL-TM-0378: the fuel-to-wall heat-transfer relation actually used
- **whether the Poppendiek / Palmer volumetric-heating treatment was applied, and its exact form**.
That question comes **before** choosing any developing-flow correlation: the right first move is to
learn what the reference calculation did, not to pick a modern correlation and hope it matches.

### H. Fixed-Nu sensitivity of the film - bounded claim only

| | fuel k | h at Nu = 4.36 | film dT at 600 kW over 134.46 m2 |
|---|---:|---:|---:|
| Case A | 1.0 | 275.068 | **16.222 K** |
| Case B | 5.5557 | 1528.187 | **2.920 K** |

**Valid only as a fixed-`Nu` sensitivity.** Under any developing-flow closure `Nu = f(Re, Pr, L/D)`
with `Pr = mu*cp/k`, the conductivity enters the Nusselt number too and the proportionality breaks.

A consistency observation, offered as a **hypothesis to test in Case B and not as a conclusion**:
the paper's own graphite mean (935.61 K) sits **below** its fuel outlet (936.003 K), i.e. a small
graphite-to-fuel offset, which is what a high `k` produces; Case A's graphite mean (939.97 K) sits
well **above** its fuel outlet (937.62 K). The domains differ (Phase 42 J), so this is a lead only.

### I. If Case B disagrees, the attribution order is fixed in advance

Not `Nu` first. In order: **1** fuel k basis, **2** graphite k basis, **3** power profile,
**4** fuel volumetric-heating treatment, **5** heat-transfer correlation, **6** equivalent geometry.

### J. Wording corrections carried out

* **`rho*cp`** - "transient-only" is withdrawn. Permitted form: *under the current constant-property,
  volume-source formulation, `rho*cp` directly controls graphite transient storage, while its direct
  contribution vanishes at steady state.*
* **graphite k sensitivity** - the 0.039 K conduction effect is relabelled
  **`CURRENT BASELINE-SPECIFIC SENSITIVITY`**. "Graphite conductivity is negligible" is **not**
  generalisable - and Case B's 22.5 W/(m.K) would roughly double that conduction drop
  (0.5710 -> about 1.44 K on the same fixed-Nu basis). CGB anisotropy stays `OPEN`.
* **Global core TH** - narrowed to **`GLOBAL CORE ENERGY CLOSURE VERIFIED`**. The check is a
  `Q = mdot * dh` statement and must not be read as thermal-hydraulic validation.

### K. Fig. 15 and the Core2D rule

Core1D stays `NOT_DIRECTLY_COMPARABLE`: Fig. 15 is the axial profile **at the hottest reactor radial
position**, and a single core-average equivalent channel has no reactor-radial coordinate.

**Rule recorded for Core2D:** ring 1 must **not** be designated the hottest ring a priori. Solve
`Tg(r,z)`, **locate** the hottest radial position from the result, and compare with Fig. 15 only if
that location corresponds to ORNL's definition. (Phase 35 found the highest-power ring also carries
the highest flow, so the hottest *temperature* ring is not automatic.)

### L. Unchanged

`0.775` graphite fraction stays **`NOT_CONFIRMED_SAME_DOMAIN`**; the 1140 passages stay an
independent `PASS`.

### M. Code-change conditions

Case B may become a **separate verification/sensitivity model** only after its full input set is
extracted from ORNL-TM-0378. The main property package is not to be modified, and **Case B values
must never be written into main as "corrected physical properties"** - they are 1962 historical
inputs whose purpose is reproducing a historical calculation.

---

## Phase 45 - ORNL-TM-0378 read directly. Case B fully specified. NO CODE CHANGED.

The report was uploaded and read **from the page images**, not from the OCR text layer (the 1962
typescript OCRs badly - it renders "sin" as "cos" and mangles subscripts). Report page numbers
equal PDF page numbers. Every item below is `PRIMARY_SOURCE_CONFIRMED` unless stated otherwise.

### A. Temperature boundaries - three distinct definitions, now separated

| quantity | value | SI | source |
|---|---:|---:|---|
| reactor inlet | 1175 F | **908.1500 K** | Table 4, footnote c (p.31) |
| reactor outlet | 1225 F | **935.9278 K** | Table 4, footnote c (p.31) |
| **main-core inlet** | **1177.3 F** | **909.4278 K** | p.33 |
| **main-core mixed-mean outlet** | **1220.8 F** | **933.5944 K** | p.33 |

p.32, verbatim: *"The channel inlet temperature, T_f(z = 0), is assumed constant for all channels and
its value is greater than the reactor inlet temperature **because of the peripheral regions through
which the fuel passes before it reaches the inlet to the main part of the core**."*

p.33, verbatim: *"At the reference conditions the main-core inlet temperature is 1177.3F and the
mixed mean temperature leaving that region is 1220.8F. The additional heat required to raise the
reactor outlet temperature to 1225F is produced in **the peripheral regions above the main part of
the core**."*

```
1175.0 F  reactor in
   +2.3    peripheral regions below/around the main core
1177.3 F  MAIN-CORE IN      <- the boundary a core-only model must use
  +43.5    main core
1220.8 F  MAIN-CORE OUT
   +4.2    peripheral regions above the main core
1225.0 F  reactor out
```

**Consequence for earlier phases.** Amirkhosravi's "ORNL" pair (908.15 / 935.921 K) is the
**reactor-level** 1175/1225 F, **not** the main core. Phases 40-42 compared a channel-only model
against reactor-level boundaries. Case B, being core-only, must use **909.4278 K in** with a target
mixed-mean out of **933.5944 K**, a rise of **24.1667 K**, not 27.7778 K.

### B. Axial power shape - the sin/cos confusion resolved

The report distinguishes two things that the OCR blurs:

* **B(z), the power density shape (Fig. 8)** - p.32 says *"If the **sine** approximation for the
  axial variation of the power density (Fig. 8) is substituted for B(z)"*.
  So **`B(z) = sin[(pi/77.7)(z + 4.36)]`**, z in inches. `PRIMARY_SOURCE_CONFIRMED`.
* **Eq. (4), the fuel temperature** - contains **cosines** because it is the *integral* of B(z):

```
T_f(r,z) = T_f(z=0) + N (A(r)/v(r)) { cos a - cos[ (pi/77.7)(z + 4.36) ] }     (4)
N = (77.7/pi) (Q_f)_m / (rho C_p)_f                                            (5)
a = (pi/77.7)(0 + 4.36)                                                        (6)
```

Phase 44's note that the OCR showed "cos" was reading Eq. (4), not B(z). Both are now recorded.

Domain, p.32 verbatim: *"the lower and upper boundaries of the main part of the core, namely,
**0 <= z <= 64.6 in**"* (inclusive at both ends).

Comparison with the current model, unchanged from Phase 44 and still valid:

| | current `corePowerShape` | ORNL B(z) |
|---|---|---|
| form | `cos(pi(z - Lc/2)/Lext)` | `sin[(pi/77.7)(z + 4.36)]` |
| Lc / span | 1.649190 m = 64.9288 in | 64.6 in |
| Lext / period scale | 1.979028 m = 77.9145 in | **77.7 in** |
| peak | 32.4644 in (geometric mid-core) | 34.4900 in |
| | | **offset +2.0256 in** |
| integral over the channel | 1.211480 | 1.205328 (ratio 0.994922) |
| peak-to-average | 1.3390 | 1.3485 |
| max nodal difference | - | **23.68 %** (inlet -23.7 %, outlet +22.1 %) |

The two are close in integral and peak-to-average but **skewed relative to each other**: ORNL puts
its peak 2.03 in above mid-core. That `Lext` = 77.91 in sits within 0.3 % of ORNL's 77.7 in is
recorded as a numerical observation, not as equivalence.

### C. Eq. (13), Poppendiek - transcribed from the page image

```
                 P_f r_w^2   [  11 ( 1 + (2 q_w)/(P_f r_w) ) - 8  ]
   T_w - T_f'  = --------- * [ ---------------------------------- ]        (13)
                    k_f      [                 48                 ]
```

**`r_w` is defined on p.38, verbatim:** *"circular channels with a diameter such that the **channel
flow area is equal to the actual channel area**. This slightly overestimates the effect."*

So `r_w` is the **equal-flow-area** radius, **not** the hydraulic radius:

| | value | in |
|---|---:|---:|
| current model `Dh = 4A/P` | 0.015850607 m | 0.62404 |
| **ORNL `D_w = sqrt(4A/pi)`** | **0.019133411 m** | **0.75328** |
| **`r_w`** | **0.009566706 m** | **0.37664** |
| ratio | **+20.71 %** | |

Using `Dh` in Eq. (13) would be a **+20.7 % error in the length scale, entering squared**.

Flow regime, p.37 verbatim: *"the flow in the entire core is assumed to be laminar to provide
conservatively pessimistic estimates"*. References: Poppendiek and Palmer, ORNL-1395 (1953) and
ORNL-1701 (1954).

### D. No separate film calculation - Eq. (13) already contains it

p.38, section *Temperature Drop in Fluid Film*, verbatim:

> *"Since the Poppendiek effect in the core is calculated for laminar flow, the temperature drop
> through the fluid immediately adjacent to the channel wall **is included in this effect.
> Therefore, a separate calculation of film temperature drop is not required.**"*

**Case B must therefore REPLACE the convective closure, not supplement it.** Adding `Nus_Core` (or
Dittus-Boelter, Gnielinski, Sieder-Tate) alongside Eq. (13) would count the film resistance twice.
In the present architecture that means the `graphite.port_a1 <-> pipe.heatPorts` convective coupling
in `CoreChannel.mo` is what Eq. (13) stands in place of.

### E. Eqs. (14)-(16), graphite stringer conduction - transcribed

```
   T_g' - T_w = (1/8) * (P_g r_s^2)/k_g                          (14)   cylinder
   T_g' - T_w = (1/3) * (P_g l^2)/k_g                            (15)   slab
   T_g' - T_w = 9.97e-4 * P_g/k_g                                (16)   interpolated
```

Geometry and method, p.39:

| item | value |
|---|---:|
| equivalent cylinder radius `r_s` (equal cross-sectional area) | 0.9935 in |
| cylinder S/V | 2.01 in^-1 |
| **actual fuel-contact S/V** | **1.84 in^-1** |
| slab half-thickness `l` (stringer centre line to channel edge) | 0.8 in |
| slab S/V | 1.25 in^-1 |
| method | **linear interpolation between the two on the basis of surface-to-volume ratio** |

The cylinder **under**estimates and the slab **over**estimates the mean graphite temperature.

**Transcription verified by reconstruction:** interpolating `(1/8)r_s^2 = 8.56808e-4 ft2` and
`(1/3)l^2 = 1.48148e-3 ft2` at a fraction `(2.01-1.84)/(2.01-1.25) = 0.223684` gives
**9.96537e-4 ft2**, against the report's stated **9.97e-4** - agreement to **0.046 %**. The
geometry, both equations and the interpolation rule are therefore transcribed correctly.

SI form: `T_g' - T_w = 9.25813e-05 [m2] * P_g[W/m3] / k_g[W/m/K]`.

### F. Eq. (17)/(18), combined local difference - transcribed

```
              P_g      P_f r_w^2  [ 11 ( 1 + (2 q_w)/(P_f r_w) ) - 8 ]
DT = 9.97e-4 -----  +  --------- [ -------------------------------- ]      (17)
              k_g         k_f     [                48                ]

DT(r,z) = DT_m * P(r,z)/P_m                                                 (18)
```

**Table 5 (p.40) gives a definition-matched Case B target:**

| graphite permeation by fuel (% of graphite volume) | maximum local graphite-fuel dT |
|---:|---:|
| **0** | **62.5 F = 34.7222 K** |
| 0.5 | 65.8 F |
| 2.0 | 75.5 F |

The 0 % row is the Case B condition. This is a **maximum local** difference, not a mean - it must not
be compared against the model's mean `dT_graphiteToFuel`.

### G. Footnote (p.40) - transcribed verbatim

> *"In these calculations, it was assumed that **6% of the reactor power is produced in the graphite
> in the absence of fuel permeation**. This value is based on calculations of gamma and neutron
> heating in the graphite by **C. W. Nestor, (unpublished)**. The thermal conductivities of fuel and
> graphite were assumed to be **3.21 and 13 Btu/hr ft F**, respectively."*

`P1` is now **`PRIMARY_SOURCE_CONFIRMED`**, and its character is fixed by the wording: an
**assumption** based on an **unpublished calculation**. `MEASURED FRACTION` remains forbidden.
`k_f = 5.5557 W/m/K`, `k_g = 22.4996 W/m/K`, both `PRIMARY_SOURCE_CONFIRMED`.

### H. Figs. 13 and 14 - definition confirmed, and my Phase 44 reading corrected

p.41, verbatim: *"**The distributions shown in Figs. 13 and 14 are for the mean temperature within
individual graphite stringers.** The local temperature distributions within the stringers are
superimposed on these in the operating reactor."*

| figure | what it is |
|---|---|
| **Fig. 13** (p.42) | *"Radial Temperature Profiles in MSRE Core Near Midplane"* - **radial**, at the midplane, 10 MW, no fuel soakup |
| **Fig. 14** (p.43) | *"Axial Temperature Profiles in Hottest Channel of MSRE Core (7 in. from Core Center Line)"* - **axial**, at the hottest radial position |

So "7 in. from core center line" is **where the hottest channel is**, and Fig. 14 is the **axial**
profile there - it is not a radial figure. Fig. 13 reads a graphite peak near **1283.5 F** at
r ~ 7 in against a fuel peak near **1220.5 F**, a difference of about 63 F, consistent with
Table 5's 62.5 F.

The **quantity** is now matched to the model: `Ts_graphite[k]`, which is already the mass-average
(= volume-average at uniform density) within a stringer. The **location** still is not: Core1D has
no reactor-radial coordinate. Fig. 13 and Fig. 14 both remain `NOT_DIRECTLY_COMPARABLE` for Core1D,
and the Core2D rule stands - solve `Tg(r,z)`, then **locate** the hottest radial position and check
it against 7 in. before comparing.

### I. Fuel Cp - not found, and not needed

No numerical `Cp` or `rho*Cp` appears anywhere in ORNL-TM-0378. It occurs only as the symbol
`(rho C_p)_f`, stated on p.32 to be *"assumed constant"*.

**More important, the report never needs one.** Appendix Eqs. (a15)-(a16) (p.53) invert the problem:

```
(Q_f)_m = (T_out - T_in) F (rho C_p)_f (2.4) / [ 4 L f R^2 J_1(2.4) ]        (a15)
```

The temperature rise is **prescribed** (1175 -> 1225 F) and the specific power is derived from it, so
`Cp` never has to be evaluated. And Eqs. (13)-(18), which are the whole graphite calculation, depend
only on `P_f`, `P_g`, `r_w`, `k_f`, `k_g`, `q_w` - **no `Cp` at all**.

```
fuel Cp : NOT_FOUND_IN_TM0378   and NOT REQUIRED by the Case B graphite calculation
0.46 Btu/(lb F) : HISTORICAL / DESIGN CANDIDATE from elsewhere, provenance not traced,
                  NOT used, NOT back-derived, NOT promoted
```

This closes the Phase 44 "top blocker" - it was never a blocker for the graphite calculation.

### J. CASE B - `HISTORICAL_ORNL0378_CALCULATION`, fully specified

| parameter / relation | value | original unit | SI | source | page/eq/fig | class | use in Case B | uncertainty |
|---|---|---|---|---|---|---|---|---|
| total power | 10 | MWth | 1e7 W | TM-0378 | Table 4 fn b | PRIMARY | imposed | - |
| main-core inlet T | 1177.3 | F | 909.4278 K | TM-0378 | p.33 | PRIMARY | **boundary** | - |
| main-core mixed-mean outlet T | 1220.8 | F | 933.5944 K | TM-0378 | p.33 | PRIMARY | **target** | - |
| reactor in/out T | 1175 / 1225 | F | 908.150 / 935.928 K | TM-0378 | Table 4 fn c | PRIMARY | context only, NOT the core boundary | - |
| axial power shape | `sin[(pi/77.7)(z+4.36)]` | z in in | - | TM-0378 | Fig. 8, p.32 | PRIMARY | source shape | domain `0<=z<=64.6 in` |
| fuel conductivity `k_f` | 3.21 | Btu/hr ft F | 5.5557 W/m/K | TM-0378 | fn p.40 | PRIMARY | Eq. (13) | 1962 vintage |
| graphite conductivity `k_g` | 13 | Btu/hr ft F | 22.4996 W/m/K | TM-0378 | fn p.40 | PRIMARY | Eq. (16) | 1962 vintage |
| graphite power fraction | 6 | % of reactor power | 0.06 | TM-0378 | fn p.40 | PRIMARY | source split | **assumption**, unpublished Nestor calc |
| permeation | 0 | % graphite volume | - | TM-0378 | Table 5 | PRIMARY | condition | - |
| `r_w` | 0.37664 | in | 0.009566706 m | TM-0378 | p.38 | PRIMARY | Eq. (13) | **equal-flow-area, NOT Dh** |
| `r_s` | 0.9935 | in | 0.02523 m | TM-0378 | p.39 | PRIMARY | Eq. (14) | equal cross-sectional area |
| slab half-thickness `l` | 0.8 | in | 0.02032 m | TM-0378 | p.39 | PRIMARY | Eq. (15) | - |
| Eq. (16) coefficient | 9.97e-4 | ft2 | 9.25813e-5 m2 | TM-0378 | Eq. (16) | PRIMARY | graphite conduction | reconstructed to 0.046 % |
| convective closure | Eq. (13) | - | - | TM-0378 | p.38 | PRIMARY | **REPLACES** Nu closure | film included |
| graphite T definition | stringer mean | - | - | TM-0378 | p.41 | PRIMARY | comparison quantity | matches `Ts_graphite` |
| max local graphite-fuel dT | 62.5 | F | 34.7222 K | TM-0378 | Table 5 | PRIMARY | **benchmark target** | **maximum**, not mean |
| fuel `Cp` | - | - | - | - | - | **NOT_FOUND** | **not required** | see I |

**Checklist - Case B is now `SPECIFIED`:**

```
[x] fuel Cp or rhoCp .................. NOT_FOUND, and NOT REQUIRED (structural, see I)
[x] Tin definition .................... main-core 1177.3 F = 909.4278 K
[x] axial power shape ................. sin[(pi/77.7)(z+4.36)], 0<=z<=64.6 in
[x] fuel conductivity ................. 5.5557 W/m/K
[x] graphite conductivity ............. 22.4996 W/m/K
[x] graphite heating fraction ......... 6 % of reactor power
[x] Poppendiek Eq.13 .................. transcribed, r_w = equal-flow-area radius
[x] graphite conduction Eq.14-16 ...... transcribed, reconstruction agrees to 0.046 %
[x] combined Eq.17-18 ................. transcribed
[x] graphite T benchmark definition ... stringer mean; target 62.5 F max local dT
[x] geometry for the historical eqs ... r_w, r_s, l all extracted
```

### K. The separation that must not be broken

```
CASE A  MODERN BASELINE                 CASE B  HISTORICAL_ORNL0378_CALCULATION
  corrected salt properties (k=1.0)       1962 properties (k_f=5.5557, k_g=22.4996)
  Nus_Core, Nu = 4.36                     Poppendiek Eq. (13) - REPLACES it
  Dh = 4A/P = 0.0158506 m                 r_w = equal-flow-area = 0.0095667 m
  Cylinder_2D_r_z conduction              graphite Eqs. (14)-(16), S/V interpolation
  reactor-level boundaries                main-core boundaries 1177.3 -> 1220.8 F
  purpose: physical fidelity              purpose: reproduce a 1962 calculation
```

**These must never appear in one model.** Mixing them - for instance keeping `Nus_Core` while adding
Eq. (13), or feeding `Dh` into Eq. (13) - produces a configuration that is neither.

Still no code changed. Case B is specified but **not implemented**, awaiting the gate decision.

---

## Phase 46 - ORNL-TM-0378 closure implemented as pure functions. STEP 5 blocked, and why.

New package `Verification/ORNL0378/`. **No production file changed** - the only edit outside it is one
additive line in `Verification/package.order`.

### A. Files added

```
Verification/ORNL0378/package.mo                 REFERENCE / PURPOSE / NOT FOR headers
Verification/ORNL0378/HistoricalData.mo          1962 inputs, every one provenance-tagged
Verification/ORNL0378/axialPowerShape.mo         B(z) = sin[(pi/77.7)(z + 4.36)]
Verification/ORNL0378/poppendiekDeltaT.mo        Eq. (13)
Verification/ORNL0378/graphiteConductionDeltaT.mo Eqs. (14), (15), (16)
Verification/ORNL0378/combinedDeltaT.mo          Eq. (17)/(18)
Verification/ORNL0378/AlgebraicVerification.mo   single-point check
```

### B. Symbol map, from the report's own nomenclature (pp.49-50)

| ORNL symbol | ORNL definition (verbatim) | local/global | implemented as |
|---|---|---|---|
| `P` | **relative** specific power | relative | **see the blocker in F** |
| `Q` | equivalent specific power (**absolute**) | absolute | not needed by Eqs. (13)-(18) |
| `q` | rate of heat transfer per unit area | local | `q_w` |
| `r_w` | equivalent radius of a fuel channel | - | `data.r_w`, **equal FLOW area** |
| `r_s` | equivalent radius of a graphite stringer treated as a cylinder | - | `data.r_s` |
| `l` | equivalent half-thickness of a graphite stringer treated as a slab | - | `data.l_slab` |
| `T'` | **local transverse mean temperature in a single fuel channel or graphite stringer** | local | `T_f_transverseMean`, `T_g_mean` |
| `DT` | local difference between the mean across a stringer and the mean in the adjacent fuel | local | `dT_total` |
| `theta` | fraction of core heat originating in fuel | global | `data.f_fuel` |
| `f` | volume fraction of fuel | - | `data.fuelVolumeFraction_mainCore` = 0.224 |
| subscript `w` | wall, or fuel-graphite interface | - | - |
| subscript `m` | maximum value in reactor | - | `_max` |
| `z` | axial distance from **inlet end of main core** | - | `axialPowerShape` input |

**Two geometry facts that had not surfaced before**, both from Table 2:

* the **main core is 940 fuel channels**, not 1140 - regions 1, 3 and 4 (12, 108, 78) are peripheral;
* the main-core **fuel volume fraction is 0.224**, equivalent outer radius 24.76 in. That 0.224, i.e.
  a graphite fraction of 0.776, is almost certainly the origin of the 0.775/0.225 the 2026 paper
  quotes - and it is **not** the production model's 0.788087, which is computed over a different
  domain.

### C. Equations implemented

All four transcribed in Phase 45 from the page images, now in code, each with its REFERENCE /
PURPOSE / NOT FOR header and an explicit prohibition on being combined with `Nus_Core`.

### D. Unit audit - the Eq. (16) coefficient is an AREA

`9.97e-4` is **not dimensionless**: with `P_g` in Btu/(hr.ft3) and `k_g` in Btu/(hr.ft.F), `P_g/k_g`
is F/ft2, so the coefficient carries **ft2**. Both routes were computed:

| route | value |
|---|---|
| A - SI directly from Eqs. (14), (15) | 9.258134e-05 m2 |
| B - historical ft, then converted | 9.258134e-05 m2 (= 9.965372e-04 ft2) |
| A vs B | **0.000e+00** |

The implementation takes route A and **computes** the interpolation fraction from the three S/V
values rather than carrying any unit-bearing constant across systems.

### E. Eq. (16) reproduction - `PASS`

```
interpolation fraction w = (2.01 - 1.84)/(2.01 - 1.25) = 0.223684    [computed, not hard-coded]
reconstructed coefficient = 9.258134e-05 m2
ORNL Eq. (16), 9.97e-4 ft2 = 9.262433e-05 m2
err_coeff                 = 4.6418e-04   ->  -0.046 %
```

Below the report's own rounding step, so the geometry, both limiting equations and the interpolation
rule are confirmed transcribed correctly. **Asserted** in the model.

### F. Table 5 reproduction - `BLOCKED`, not `FAIL`

Eqs. (13), (16) and (17) need **absolute** specific powers. **ORNL-TM-0378 never states `P_f` or
`P_g` numerically**, and its nomenclature defines `P` as the *relative* specific power - which is
what Eq. (18) uses. So the target cannot be evaluated from report values alone.

The obvious shortcut, which Section 8 of the task prohibited in advance, was evaluated **precisely to
test whether the prohibition was justified**:

```
P_f,max = 0.94 * Q_mainCore / V_fuel     * (pi/2)(2.405/2J1(2.405))  = 62.0593 MW/m3
P_g,max = 0.06 * Q_mainCore / V_graphite * same peaking              =  1.14345 MW/m3
q_w,max = P_g/(S/V)_actual                                           = 15784.6 W/m2

dT_graphiteConduction (Eq 16)  =   4.7051 K
dT_fuelSide           (Eq 13)  =  76.3541 K
dT_total              (Eq 17)  =  81.0591 K
ORNL Table 5 target            =  34.7222 K
error                          = +46.3369 K   (+133.5 %, a factor of 2.33)
```

**The shortcut is wrong by 2.33x.** The prohibition is therefore confirmed empirically rather than
taken on trust. `P_f` and `P_g` are not `0.94Q/V_fuel` and `0.06Q/V_graphite` times a separable
axial-times-radial peaking factor.

`P_f_max` and `P_g_max` are carried in the model **tagged `NOT_SOURCED`**, and the Table 5 target is
**reported, never asserted**. Asserting it would either fail on inputs the report does not supply,
or invite tuning them until it passed.

One quantity **is** derivable from the report: p.39 identifies the fuel-channel surface as the
surface through which *all* heat produced in the graphite must be transferred, so in steady state

```
q_w = P_g / (S/V)_actual        DERIVED FROM THE REPORT, not assumed
```

### G. Term contributions (at the NOT_SOURCED powers, indicative only)

| term | value | share |
|---|---:|---:|
| graphite conduction, Eq. (16) | 4.7051 K | 5.8 % |
| fuel side, Eq. (13) | 76.3541 K | 94.2 % |

The fuel-side Poppendiek term dominates, so the missing `P_f` is the quantity that matters most.

### H. PASS / FAIL

```
Eq. (16) reconstruction ............... PASS   (0.046 %, asserted)
unit audit, method A vs B ............. PASS   (identical)
sign of both Eq. (17) terms ........... PASS   (asserted, p.36)
q_w provenance ........................ DERIVED FROM REPORT (p.39)
symbol/unit map ....................... COMPLETE
T_g_mean / T_wall / T_f' separation ... IMPLEMENTED
main-core Tin = 909.4278 K ............ IMPLEMENTED (reactor 908.15 K NOT used)
Table 5, 34.7222 K .................... BLOCKED - P_f, P_g not stated in the report
tuning ................................ NONE
```

### I. Production regression

`git status` shows only the new directory plus one additive line in `Verification/package.order`.
`checkModel` passes on `Core1D_TH_Baseline` and `Nus_Core`; the whole package still loads, which is
what compiling the new model demonstrates. No production numerical result can move: nothing they
depend on was touched.

### J. Unresolved

1. **`P_f` and `P_g` absolute values** - the blocker. Needs either the report's own specific powers
   or the derivation chain it used. The naive route is ruled out by the 2.33x overshoot.
2. The report's `P` is "relative" in the nomenclature but must be absolute in Eqs. (13)-(17). This
   internal inconsistency is recorded, not resolved.
3. Main core is 940 channels at 0.224 fuel fraction; the production model's 1140 at 0.788087 graphite
   covers a different domain. Not reconciled, and not to be reconciled by changing either one.

### K. Is Phase 47 (axial model) justified?

**Not yet.** The task set Table 5 as the gate before spatial extension, and it is blocked on an input
the report does not supply. Building the axial model now would propagate an unsourced `P_f` through
every axial node and produce a profile whose absolute level is unfounded. The axial *shape* work is
already done and verified; what is missing is the scale.

---

## Phase 46B - The absolute power scale, traced to the one thing the report will not give as a number

No production file touched; only the two files inside `Verification/ORNL0378/`.

### A. P / Q nomenclature - `SOURCE_TEXT_CONFLICT`, but harmless in practice

p.49 defines `P` as **relative** specific power and `Q` as **equivalent specific power (absolute)**.
Eqs. (13), (16) and (17) need an absolute one. No conversion between them appears anywhere in the
report. Recorded as **`SOURCE_TEXT_CONFLICT`**, not as a typo - and it does not block anything,
because Eq. (18) (`DT(r,z) = DT_m P(r,z)/P_m`) is where the *relative* reading applies, while
Eqs. (13)-(17) are evaluated at "the appropriate specific powers" (p.40), i.e. absolute ones.

### B/C. The chain, as Table 3 and p.19 actually define it

p.19, verbatim: *"The reference plane for measurements in the axial direction is the bottom of the
horizontal array of graphite bars at the lower end of the main portion of the core... the top of the
main portion of the core is at 64.59 in."*

So z = 0 is that plane, and the **main core is Table 3's regions N + M + J + L**, not region J alone:

| region | r_in | r_out | z_b | z_t | fuel % | V [in3] | power [kw] |
|---|---:|---:|---:|---:|---:|---:|---:|
| N horizontal stringers | 0 | 27.75 | 0 | 2.00 | 23.7 | 4,838.4 | 68 |
| M core | 2.94 | 27.75 | 2.00 | 5.50 | 22.5 | 8,372.2 | 192 |
| **J core** | 3.00 | 27.75 | 5.50 | 64.59 | **22.5** | 141,281.1 | **8,287** |
| L central region | 0 | 2.94 | 2.00 | 64.59 | 25.6 | 1,699.6 | 159 |

```
V_fuel,mainCore     = 35,253.8 in3 = 0.577707 m3
V_graphite,mainCore = 120,937.6 in3 = 1.981812 m3
Q_mainCore          = 8,706 kw = 87.06 % of the reactor's 10 MW
```

**Region J's 22.5 / 77.5 volume percent is the confirmed origin of the 0.775 / 0.225 the 2026 paper
quotes.** The production model's 0.788087 is over a different domain and neither is to be changed.

**Axial**: B(z) over `0 <= z <= 64.6 in` gives `B(0) = 0.1754`, `B(64.6) = 0.3461`, peak 1.0 at
z = 34.49 in, average 0.736127, so **peak/average = 1.3585**. It is *not* `pi/2`: that belongs to the
idealised uniform core of p.35, whose sine is *"allowed to vanish at the reactor boundaries"*. This
one does not vanish at either end.

**Radial**: `A(r)` is given **only as Fig. 4**, and p.19 states outright that the central flux
distortion *"precludes the use of a simple analytic expression to describe the radial
distribution."* **There is no radial peaking number in the report.**

### D/E. Absolute values

```
P_f,average = 0.94 * 8,706 kw / 0.577707 m3 = 14.1657 MW/m3     DERIVED_FROM_ORNL
P_g/P_f     = (0.06 * V_f)/(0.94 * V_g)     =  0.018607          DERIVED_FROM_ORNL
q_w         = P_g/(S/V)_actual                                   DERIVED_FROM_ORNL (p.39)
radial peak/average                                              NOT AVAILABLE AS A NUMBER
```

### F. Dimensional audit

`[P] = W/m3`, `[r_w^2] = m2`, `[k] = W/m/K`, so `P r_w^2/k` is K. `q_w/(P_f r_w)` is
`(W/m2)/((W/m3)(m))` = dimensionless, as a bracket argument must be. Eq. (16)'s coefficient is an
**area**. All consistent - the only conflict is the wording in A.

### G. Reverse diagnostic - `DIAGNOSTIC_ONLY`

Both Eq. (17) terms are **linear in the power scale**: the bracket argument
`2 q_w/(P_f r_w) = 2 (P_g/P_f)/((S/V)_a r_w) = 0.053697` is **scale-invariant**. So the 2.33x is a
pure scale error, and the required scale can be solved in closed form:

```
P_f,max required = 26.5282 MW/m3      dT_fuelSide  = 32.6910 K  (94.2 %)
P_g,max required =  0.49360 MW/m3     dT_graphite  =  2.0311 K  ( 5.8 %)
q_w      required =  6,813.8 W/m2     dT_total     = 34.7221 K
required total peak/average = 1.8727
  measured axial            = 1.3585
  => implied radial         = 1.3785      <- reverse-derived, NOT provenance
```

### H. The 2.33x decomposed, one correction at a time

| single correction | factor | dT [K] | vs target |
|---|---:|---:|---:|
| A power: region J only -> N+M+J+L (8287 -> 8706 kw) | 1.05056 | 85.158 | 2.453x |
| B fuel volume: R=24.76/f=0.224 -> Table 3 main core | 0.79054 | 64.081 | 1.846x |
| C axial peaking: idealised pi/2 -> measured 1.3585 | 0.86485 | 70.104 | 2.019x |
| **D radial peaking: idealised J0 2.3163 -> 1.3785** | **0.59513** | **48.241** | **1.389x** |
| all four | 0.42746 | 34.650 | 0.998x |

The dominant error was **D**, using the idealised `2.405/(2 J_1(2.405))`. Both idealised factors come
from the uniform cylindrical reactor of p.35, which the report explicitly says has its functions
vanishing at the boundaries and **no peripheral regions**. The MSRE has neither property.

### I. Table 5 reproduction - `NOT REPRODUCED`

The model now returns `dT_total = 34.7221 K` against the target 34.7222 K. **That is not a
reproduction.** The radial factor it uses is the reverse-derived 1.3785, so the agreement is
**circular by construction** and is labelled that way in the code, where `radialPeakToAverage`
carries `NOT_SOURCED AS A NUMBER` and the target remains **reported, never asserted**.

What *is* independently established: the closure equations, the geometry, the volumes, the main-core
power, the axial factor, `P_g/P_f`, and `q_w`. What is missing is one number that the report chose
not to publish in numerical form.

### J. Case B status - downgraded

```
BEFORE (Phase 45):  SPECIFIED
NOW              :  PARTIALLY_SPECIFIED
                    - closure specified and verified
                    - absolute power normalization UNRESOLVED, resting on Fig. 4
```

Per the task's own rule, `SPECIFIED` is not retained by force. The honest label is that the
**closure is specified and the absolute normalization is not**. Calling this
`HISTORICAL_SOURCE_INCOMPLETE` would overstate it - the report is not incomplete, it simply presents
the radial distribution graphically, and digitising Fig. 4 is a legitimate next step rather than a
missing document.

### K. Phase 47 (axial model)

**Justified in shape, not in level.** Everything the axial model needs is now established except the
one multiplicative constant, which affects only the absolute level of `DT(z)` and not its shape -
Eq. (18) makes `DT` proportional to the local power, so the profile is already fully determined up to
that scale. Two options, for the gate decision:

1. **Digitise Fig. 4** to obtain the radial peak/average, converting the last `NOT_SOURCED` into a
   figure-derived value with a stated reading uncertainty. Table 5 then becomes a real test.
2. **Build the axial model normalised to shape only**, comparing `DT(z)/DT_max` against Fig. 14 and
   leaving the absolute level open.

Option 2 needs nothing further and tests something real; option 1 is what would close Table 5.

---

## Phase 46C - Fig. 4 digitized independently. Table 5 is NOT reproduced, and the gap is real.

No production file touched. The radial factor was read from the figure **before** any temperature
was computed, and the reverse-derived 1.3785 of Phase 46B was **not** used as a digitization target.

### A. Fig. 4 - physical definition, from the figure and p.19

| | |
|---|---|
| caption | *Radial Distribution of Slow Flux and Fuel Fission Density in the Plane of Maximum Slow Flux* |
| ordinate | **"FRACTION OF MAX. VALUE"** -> **peak-normalized** |
| abscissa | RADIUS, in., 0 to 30 |
| plane | p.19: *"This plane contains the maximum value of the flux and is 35 in. above the bottom of the main part of the core"* |
| curves | Slow Flux and Fuel Fission Density, essentially coincident; the fission-density curve is the one used |

### B/C. Digitized points and weighting

30 points read against the grid, r = 0 to 27.75 in. Salient features:

```
A(0) = 0.912    dip to 0.885 at r ~ 2.9   <- the control-rod-thimble distortion of p.19
A(7)  = 1.000   PEAK
A(15) = 0.790   A(20) = 0.565   A(25) = 0.315   A(27.75) = 0.135
```

The weighting is **not** a plain 0-to-R cylinder. Using the Table 3 regions,

```
<A> = int A(r) w(r) dr / int w(r) dr ,   w(r) = 2*pi*r * sum_regions( dz * fuel fraction )
  r < 2.94   : N(2.00 x 0.237) + L(62.59 x 0.256)
  2.94-3.00  : N + M            (K is INOR, no fuel)
  r > 3.00   : N + M + J(59.09 x 0.225)
```

### D/E. Radial factor, and the r = 7 in check

```
<A> = 0.593144        radialPeakToAverage = 1.6859        FIGURE_DERIVED
```

**`A_peak` and `A(7 in)` are the same point** - confirmed from the figure, not assumed. That the
digitized peak lands at 7 in independently reproduces p.19's *"a line which passes through the
maximum value, 7 in. from the vertical centerline"* and Fig. 14's *"7 in. from Core Center Line"*.
This is a genuine cross-check on the reading.

### F. Digitization uncertainty

Perturbing the ordinate by +-0.02 (about half a minor division):

| perturbation | 1/<A> |
|---|---:|
| uniform +0.02 | 1.6336 |
| **nominal** | **1.6859** |
| uniform -0.02 | 1.7448 |
| outer half +0.02 / inner -0.02 | 1.6581 |
| outer half -0.02 / inner +0.02 | 1.7176 |

Band taken as **1.634 to 1.745**.

### G/H. Table 5 - `NOT REPRODUCED`

```
P_f,max = 32.4437 MW/m3     P_g,max = 0.60367 MW/m3     q_w,max = 8333.3 W/m2
dT_graphite =  2.4840 K
dT_fuel     = 39.9810 K
dT_total    = 42.4650 K        ORNL Table 5 = 34.7222 K
error       = +7.7427 K  (+22.30 %)
band from the figure reading: 41.148 .. 43.949 K
target 34.7222 K is OUTSIDE the band
```

The Phase 46B agreement was circular, as it was labelled. With the radial factor read
**independently** the closure overshoots by 22 %.

### I. Cause analysis - three candidates tested and ruled out

**1. The radial domain of the fuel.** Ruled out, and it fails in the wrong direction:

| r_outer | basis | radial factor | dT | vs target |
|---:|---|---:|---:|---:|
| 27.75 in | Table 3 region J | 1.6859 | 42.47 K | +22.30 % |
| 26.10 in | Table 2 region 3 | 1.5497 | 44.13 K | +27.08 % |
| 24.76 in | Table 2 region 2 | 1.4601 | 46.20 K | +33.05 % |

Narrowing the domain raises `<A>` but shrinks `V_fuel` more, so **no outer radius brings it down**.

**2. `r_w`.** Now confirmed from the report's own numbers rather than the modern geometry. p.14
(Table 2 text) gives region 2 as *"940 channels, a total cross-sectional area of 1880 in.2, a fuel
fraction of 0.224"*, so the fuel area per channel is `0.224*1880/940 = 0.448 in2` and
`r_w = sqrt(0.448/pi) = 0.37763 in`. Against the 0.37664 in used, that is **0.26 %** - negligible,
and it independently confirms the equal-flow-area reading of p.38.

**3. The 0.94 fission split.** Table 4's region powers are heat *to the fluid*, so the fuel's own
fission is `Q_mainCore` minus the main-core graphite power. Even taking all 600 kw of graphite heat
inside the main core, `8706 - 600 = 8106` against the `0.94 x 8706 = 8184` used - about **1 %**.

**A 17 % inconsistency inside the report itself** was found on the way: Table 2 (hydraulic, 940
channels over an equivalent outer radius of 24.76 in) and Table 3 (neutronic, r = 3.00 to 27.75 in
at 22.5 % fuel) give main-core fuel volumes of 0.443471 and 0.520916 m3. Using the smaller makes the
overshoot worse, so it is not the explanation either, but it is recorded: **the two tables are
different discretizations of the same core and are not interchangeable.**

**The remaining 22 % is unexplained.** A factor of 0.818 on `dT`, i.e. `P_f,max` of 26.53 rather
than 32.44 MW/m3, is required and no input traced so far supplies it.

### J. Case B status - unchanged, deliberately

```
PARTIALLY_SPECIFIED
  closure ............................ specified and verified
  absolute power normalization ....... FIGURE_DERIVED but NOT VALIDATED
```

**Not upgraded.** `SPECIFIED_WITH_FIGURE_DERIVED_RADIAL_NORMALIZATION` would claim the normalization
works, and it does not - it misses the report's own Table 5 by 22 %.
`HISTORICAL_CALCULATION_REPRODUCED` is **not** awarded.

The code now carries `radialPeakToAverage = 1.6859` tagged `FIGURE_DERIVED` with its band, and keeps
1.3785 as `radialPeakToAverage_reverseDerived`, `DIAGNOSTIC ONLY`, unused in the chain, so the gap
stays visible rather than being absorbed.

### K. Phase 47 gate - `NO-GO`

The task's own rule: if Table 5 disagrees, analyse the cause rather than proceeding to the axial
absolute model. It disagrees by 22 %, outside the reading uncertainty, and the cause is not yet
found. Building the absolute axial model now would propagate a 22 % level error through every node.

What remains open, in the order worth attacking:

1. Whether `P_f` in Eq. (13) is the fuel fission density or something else the report computes.
2. How the report forms its own maximum - whether `DT_m` uses the peak of the product `A(r)B(z)` or
   a differently defined maximum.
3. Whether `Q_mainCore` should be built from the Table 2 hydraulic regions rather than the Table 4
   neutronic ones, given the 17 % volume inconsistency between the two tables.

The **shape-normalized** axial model of Phase 46B option 2 remains available and needs none of this:
Eq. (18) makes `DT` proportional to the local power, so `DT(z)/DT_max` is already fully determined
and can be compared against Fig. 14 without the absolute scale.

---

## Phase 46E - Definition chain re-traced. Verdict: `SOURCE_MAPPING_UNRESOLVED`.

No production file touched, no radial factor tuned, no input reverse-derived from Table 5.

### A. Eq. (13)'s `P_f`

p.36 defines the setting: *"it is necessary to consider the core in terms of a number of **unit
cells, each containing graphite and fuel and extending the length of the core**"*, and p.37 adds
that *"the heat generation is uniform in the radial direction over the unit cells"*. So `P_f` and
`P_g` are **local per-unit-cell specific powers, each per its own material volume** - `P_f` per fuel
volume, `P_g` per graphite volume. That much is settled.

What is **not** stated anywhere is a numerical value, or an equation connecting either of them to the
reactor power. The nearest the report comes is p.40's *"applying the appropriate specific powers to
Equation (17)"*, which names no number and no derivation.

Also from p.36: **98.7 %** of the MSRE graphite is in the main part of the core, so treating the
graphite calculation as main-core-only is the report's own choice, not an approximation of mine.

### B. Eq. (18) re-derived - and it clears the double-counting suspicion

Substituting `q_w = P_g/(S/V)_a` and `P_g = rho P_f` into Eq. (17):

```
bracket argument  2 q_w/(P_f r_w) = 2 rho/((S/V)_a r_w) = 0.053697    <- INDEPENDENT of P_f
so the bracket beta = 0.074806 is constant, and
     DT = P_f * [ c rho/k_g + r_w^2 beta/k_f ] = P_f * 1.308881e-06 K/(W/m3)
dividing by the maximum:  DT(r,z)/DT_m = P(r,z)/P_m    <-- exactly Eq. (18)
```

The re-derivation **succeeds**, and it settles three of the questions asked:

* Eq. (18) does **not** absorb the 6 % graphite fraction - `rho` appears in both `DT` and `DT_m` and
  cancels in the ratio.
* Eq. (18) does **not** absorb the fuel/graphite volume ratio, for the same reason.
* Therefore **Phase 46C did not double-count**. The 22.3 % is not a double-counting error.

It also confirms what Phase 46B found empirically: `DT` is exactly linear in the power scale, so the
discrepancy is a pure normalization error and cannot be a shape or closure error.

### C. Table 5's `DT_m`

Eq. (18) makes `DT` proportional to `P`, so `DT_m` is the value at `P_m`. Cross-checked against the
figures rather than assumed: Fig. 13 (radial, near midplane) reads a graphite peak near 1283.5 F
against a fuel peak near 1220.5 F, a difference of about **63 F at r ~ 7 in**, matching Table 5's
**62.5 F**. And the plane of Fig. 4 is 35 in above the core bottom while `B(z)` peaks at 34.49 in -
the same plane. So `DT_m` is the local maximum at the peak of `A(r)B(z)`, which is what was computed.

### D/E/F/G. The mappings that do not close

| item | finding |
|---|---|
| Fig. 4 curves | *Slow Flux* and *Fuel Fission Density*, essentially coincident. The report never states that the **thermal deposition** shape equals the fission shape, so applying the fission-density radial factor to Eq. (13)'s `P_f` is an inference, not a citation |
| Table 4 powers | region powers summing to exactly 10,000 kw at 10 Mw. Nothing in the report links them to Eqs. (13)-(18). Status downgraded to **`DERIVED_BUT_NOT_LINKED_TO_EQ13`** |
| Table 2 vs Table 3 | hydraulic (940 channels, equivalent outer radius 24.76 in) vs neutronic (r = 3.00-27.75 in, 22.5 % fuel): main-core fuel volumes 0.443471 and 0.520916 m3, **17 % apart**. The report never states which geometry the thermal calculation used |
| 940 vs 1140 | 940 is Table 2's region 2 alone; Table 2's four regions total 1138 channels and about 515.9 in2 of fuel area, against 1140 x 0.44566 = 508.0 in2 for the whole core. So **1140 is the whole core and 940 is its main hydraulic region** - not an inconsistency, but two different domains, and which one Eq. (13) belongs to is not stated |

### H. The normalization chain, with the unsupported step marked

```
Q_reactor = 10 MW              Table 4 fn b                       PRIMARY
  -> Q_mainCore = 8.706 MW     Table 4, regions J+L+M+N           DERIVED_BUT_NOT_LINKED_TO_EQ13
  -> fission in fuel = 0.94 x  p.40 footnote (6 % to graphite)    PRIMARY fraction, but the
                                                                   report never applies it per-region
  -> / V_fuel = 0.577707 m3    Table 3 volume percents            DERIVED  ** which geometry? **
  -> x axial 1.3585            B(z), Fig. 8                       PRIMARY shape, DERIVED factor
  -> x radial 1.6859           Fig. 4                             FIGURE_DERIVED  ** fission, not
                                                                   necessarily thermal **
  -> P_f,max = 32.4437 MW/m3
  -> P_g = rho P_f, q_w = P_g/(S/V)_a   p.39                      DERIVED_FROM_ORNL
  -> Eqs. (13),(16),(17)                                          PRIMARY
  -> DT = 42.4650 K            vs Table 5's 34.7222 K             +22.30 %
```

**Two arrows are unsupported by the report**: the one that carries Table 4's regional powers into
Eq. (13), and the one that assumes the fission-density radial shape is also the thermal-deposition
shape. Either could carry the missing factor.

### I/J. The 22.3 % - candidates, and why none is accepted

Required scale correction `S = 34.7222/42.4650 = 0.8177`.

| candidate | value | verdict |
|---|---:|---|
| `0.94 x 0.8706` (fuel fraction x main-core share) | 0.8184 | **within 0.09 % - and REJECTED anyway** |
| `V_fuel(Table 2)/V_fuel(Table 3)` | 0.8513 | rejected, 4 % off and wrong direction when applied |
| main-core graphite share, p.36 | 0.9870 | rejected |
| radial domain, `r_out` 27.75 -> 24.76 in | - | rejected in Phase 46C, moves the wrong way |
| `r_w` | - | rejected, confirmed to 0.26 % from the report's own 1880 in2 and 0.224 |
| fission split | - | rejected, about 1 % |
| Eq. (18) double counting | - | rejected by the re-derivation in B |

**`0.94 x 0.8706 = 0.8184` matches the required correction to 0.09 %, and it is still rejected.** No
equation in the report combines those two factors that way, and this phase's own rule - numerical
proximity is not provenance - applies to convenient coincidences as much as to inconvenient ones.
Recording it as the cause would be exactly the reverse-engineering the task forbids.

### K. Case B - final status

```
CASE B = SOURCE_MAPPING_UNRESOLVED

  closure ...................... SPECIFIED and VERIFIED
                                 Eqs. (13),(14),(15),(16),(17),(18) transcribed; (16) reconstructed
                                 to 0.046 %; (18) re-derived from (13)+(16)+(17)
  geometry ..................... PRIMARY (r_w confirmed to 0.26 % from the report's own numbers)
  historical properties ........ PRIMARY
  shape, axial and radial ...... PRIMARY / FIGURE_DERIVED
  absolute power normalization . UNRESOLVED - the neutronic-to-thermal mapping is not in the report
  Table 5 absolute reproduction  NOT ACHIEVED (+22.30 %, outside the reading band)
```

`RESOLVED` is not claimed. The closure is sound and the shape is established; what the report does
not supply is the step from its regional power tables to the local specific powers of Eq. (13).

### L. Phase 47 gate

```
ABSOLUTE axial model .......... NO-GO
SHAPE-ONLY axial verification . permitted, as a separate phase
```

The shape route needs nothing that is missing: Eq. (18) makes `DT` proportional to the local power,
so `DT(z)/DT_max` is fully determined by `A(r)B(z)` alone. Any such result must be named
**`SHAPE_ONLY_VERIFICATION`** and must not be presented as absolute graphite temperature validation.

---

## Phase 47 - `SHAPE_ONLY_PASS`. The absolute normalization remains unresolved.

New file `Verification/ORNL0378/AxialShapeVerification.mo`. No production file touched, nothing
fitted, no scale factor used.

### Figure correction

The task named Fig. 13 as the axial dataset. It is not: Phase 45 established from the page images
that **Fig. 13 is radial** (*"Radial Temperature Profiles in MSRE Core Near Midplane"*) and
**Fig. 14 is axial** (*"Axial Temperature Profiles in Hottest Channel of MSRE Core (7 in. from Core
Center Line)"*). Fig. 14 is what an axial shape test needs, and it is what was used. Its abscissa,
*"DISTANCE FROM BOTTOM OF CORE (in.)"*, is the same datum p.19 fixes for `B(z)`, so no coordinate
transformation is involved.

### The statement, corrected

Phase 46E said the normalized difference is "determined by `A(r)B(z)`". At a **fixed** radial
station that is looser than it needs to be. With `P(r,z) = A(r)B(z)` (Eq. 2) and Eq. (18):

```
DT(r*,z)/DT(r*,z_peak) = P(r*,z)/P(r*,z_peak) = B(z)/B(z_peak)
```

**`A(r*)` cancels.** So the absolute specific power, the radial amplitude and the thermal
normalization constant are all absent from this test by construction - which is exactly why it can
be run while the normalization is still open.

### Comparison, r* = 7 in

| z [in] | T_g [F] | T_f [F] | dT [F] | dT_norm | B_norm | dev |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | 1188.0 | 1177.5 | 10.5 | 0.1641 | 0.1754 | -0.0113 |
| 10 | 1218.0 | 1187.0 | 31.0 | 0.4844 | 0.5485 | **-0.0642** |
| 15 | 1233.0 | 1191.0 | 42.0 | 0.6562 | 0.7052 | -0.0490 |
| 20 | 1247.0 | 1196.0 | 51.0 | 0.7969 | 0.8332 | -0.0364 |
| 30 | 1274.0 | 1210.0 | 64.0 | 1.0000 | 0.9836 | +0.0164 |
| 35 | 1283.0 | 1219.0 | 64.0 | 1.0000 | 0.9998 | +0.0002 |
| 45 | 1294.0 | 1237.0 | 57.0 | 0.8906 | 0.9111 | -0.0204 |
| 55 | 1295.0 | 1251.0 | 44.0 | 0.6875 | 0.6754 | +0.0121 |
| 60 | 1291.0 | 1256.0 | 35.0 | 0.5469 | 0.5136 | +0.0333 |
| 65 | 1282.0 | 1261.0 | 21.0 | 0.3281 | 0.3309 | -0.0027 |

(14 stations digitized; 10 shown.)

```
normalized RMSE            = 0.0276
max |deviation|            = 0.0642   at z = 10 in
reading band (+-3 F / 64 F) = 0.0469
points inside the band     = 12 / 14
peak of B(z)               = 34.49 in   (analytic, from the report's own 77.7 and 4.36)
peak of the digitized dT   = flat over 30-35 in
```

**The analytic peak falls inside the digitized flat maximum.** That is an independent agreement: the
peak position comes from two constants in Eq. (4)-(6), and the flat maximum comes from subtracting
two curves on a different page.

The two stations outside the band, z = 10 and 15 in, both sit in the steepest part of the rise where
a small reading error in either curve moves the difference most, and both have the digitized `dT`
**below** the source shape. Whether that is a reading artefact or a real entrance effect is not
decided here.

### Verdict

```
PHASE 47 = SHAPE_ONLY_PASS

axial source definition ........ B(z) = sin[(pi/77.7)(z + 4.36)]   ORNL-TM-0378 Fig. 8, p.32
axial coordinate ............... distance from the bottom of the horizontal graphite bars, p.19
calculated peak z .............. 34.49 in  (digitized dT peaks flat over 30-35 in)
source-shape normalization ..... B(z)/B(z_peak), peak-normalized only
comparison dataset ............. Fig. 14, both curves at r* = 7 in, 14 stations
normalized RMSE ................ 0.0276
max normalized deviation ....... 0.0642  (band 0.0469; 12/14 inside)
absolute normalization ......... NOT USED
absolute temperature validation. NOT CLAIMED
```

A cross-check that is **reported and not used as a criterion**: the digitized maximum difference is
64 F against Table 5's 62.5 F. Absolute agreement is not what this test measures.

### What this does not change

```
CASE B = SOURCE_MAPPING_UNRESOLVED        <- UNCHANGED
  absolute power normalization ... still open, still +22.30 % when attempted
```

Phase 46E's verdict stands. The shape test was constructed so that the unresolved quantity cannot
influence it, which means passing it cannot resolve that quantity either. **The normalization
problem has not been bypassed; it has been held apart from a question that does not depend on it.**

---

## Phase 48 - `RADIAL_SHAPE_FAIL`. The failure is informative: Eq. (18)'s `P` is not the fuel fission density.

Phase 47 passed the axial shape test by holding the unresolved absolute normalization apart from a
question that does not depend on it. Phase 48 applies the identical construction in the radial
direction. Same rules: peak-normalized on both sides, no absolute scale anywhere, no fitted
parameter, and the acceptance band declared before the comparison.

### The two datasets, both digitized in this session

`Verification/ORNL0378/data/Fig04_radial_raw.csv` - Fig. 4, printed p.20, *"Radial Distribution of
Slow Flux and Fuel Fission Density in the Plane of Maximum Slow Flux"*. The **fuel fission density**
curve, 30 points, `r = 0 .. 27.75 in`. The ordinate is already *"fraction of max. value"*, so the
file is peak-normalized as printed and nothing is rescaled. Reading uncertainty `+-0.2 in`, `+-0.02`.

`Verification/ORNL0378/data/Fig13_radial_temperature_raw.csv` - Fig. 13, printed p.42, *"Radial
Temperature Profiles in MSRE Core Near Midplane"*. Condition on p.41: **10 Mw, no fuel soakup in the
graphite**, i.e. the 0 % permeation case, the same row of Table 5 that Phase 46C failed to
reproduce. Both plotted curves are transverse means - stringer-mean graphite and adjacent-channel
fuel - which is exactly what `DT` is defined to be (nomenclature p.50). 12 stations, `+-0.3 in`,
`+-1.5 F` on each curve.

Two discontinuities are visible in Fig. 13, at `r ~ 3.3 in` and `r ~ 24.8 in`. The second matches
Table 2 region 2's equivalent outer radius, **24.76 in**, to within the reading uncertainty. They are
region boundaries, not data scatter. Stations inside `r < 4 in` were therefore not read.

### Plane check - the one thing that could have made this a domain mismatch

Fig. 4 is drawn in the plane of maximum slow flux, **35 in**; Fig. 13 is drawn *"near midplane"*, and
the main core's midplane on the report's own axial coordinate is **32.30 in**. Different planes.

But `B(z)` from Phase 47 evaluates to 0.99944 at 35 in and 0.99574 at 32.30 in - a **0.37 %**
difference - and, more decisively, `B(z*)` is a constant of the radial comparison and **cancels
identically** in a peak normalization taken within each plane. The separability that Eq. (18)
asserts, `P(r,z) = P_m A(r) B(z)`, makes the plane offset unobservable in this test. So this is
**not** `DOMAIN_MISMATCH`, and the test is admissible.

### The hypothesis under test, stated before the numbers

```
H1:   [Tg(r) - Tf(r)] / max_r [Tg - Tf]   ==   A(r) / max_r A
```
which is Eq. (18) read literally, with `P(r,z)` taken to be the quantity Fig. 4 plots.

Acceptance band, propagated from the stated reading uncertainties and **declared first**:

```
dT side ... sqrt(2)*sqrt(2)*1.5 F / 63 F = 0.0476     (numerator and peak both uncertain)
A  side ... sqrt(2)*0.02      / 1.00     = 0.0283
combined ................................. 0.0554
```

### Result

```
 r_in   A_norm   dT_norm      dev
  4.0   0.9450   0.9206   -0.0244
  5.0   0.9750   0.9603   -0.0147
  6.0   0.9930   0.9921   -0.0009
  7.0   1.0000   1.0000   +0.0000     <- peak, both
  8.0   0.9980   0.9921   -0.0059
 10.0   0.9650   0.9683   +0.0033
 12.0   0.9050   0.9365   +0.0315
 15.0   0.7900   0.8571   +0.0671
 17.5   0.6775   0.7857   +0.1082
 20.0   0.5650   0.6825   +0.1175     <- max
 22.0   0.4700   0.5714   +0.1014
 24.0   0.3700   0.3651   -0.0049
```

```
peak location .......... r = 7.0 in on BOTH curves, exactly
RMSE ................... 0.0593        band 0.0554
max |deviation| ........ 0.1175        band 0.0554
mean SIGNED deviation .. +0.0315
inside band ............ 8 / 12
```

The peak coincidence is a genuine agreement and is recorded as such. Everything else is not. The
deviation is **not scatter**: it is zero at the peak, rises monotonically outward to +0.1175 at
20 in, and only collapses at 24 in, the region boundary. A mean signed deviation of +0.0315 against
a symmetric band is a **bias**, and a bias is a missing physical term, not reading error.

```
PHASE 48 = RADIAL_SHAPE_FAIL   for H1
```

### Phase 48b - why it fails, algebraically rather than by conjecture

Eq. (18) scales the whole of `DT` by a single scalar `P(r,z)/P_m`. That is exact only if every term
of Eq. (17) is proportional to that same `P`. Expanding Eq. (13) exactly - no approximation, the
identity is verified to machine precision in `scratch/p48b.py`:

```
                r_w^2      [                 q_w ]
  dT_fuel  =  --------- *  [  3 P_f  +  22  ----- ]
              48 * k_f     [                 r_w ]
```

At the Phase 46C operating point (main core, 10 Mw, `f_graphite = 0.06`, radial peak factor 1.6859):

```
fuel fission, via 3*P_f in Eq. (13) ......... 33.404 K   78.7 %
graphite, via q_w in Eq. (13) ................ 6.577 K   15.5 %
graphite conduction, Eq. (16) ................ 2.484 K    5.8 %
                                              --------  -------
total ....................................... 42.465 K  100.0 %
GRAPHITE-DRIVEN SUBTOTAL ..................... 9.061 K   21.3 %
```

**This corrects a statement made earlier in this study.** Phase 46-era notes described the graphite
contribution as *"~6 % of DT"*. That figure is Eq. (16) **alone**. The graphite also enters Eq. (13)
through the wall flux `q_w`, and that path is larger than the conduction path. The correct graphite-
driven share is **21.3 %**, not 6 %. The 6 % number was not wrong about Eq. (16); it was wrong as a
statement about `DT`.

So `DT` is **not** proportional to any single power density. It is a linear combination
`0.787 * (shape of P_f) + 0.213 * (shape of P_g)`. H1 is only correct if `P_g` has the *same radial
shape* as `P_f`. The observed outward bias is precisely what a **flatter** graphite deposition
profile would produce - and gamma heating, which is what the 6 % is (an unpublished Nestor
gamma/neutron calculation, p.40 footnote), has a mean free path of order the core radius and has no
reason to follow the fission density.

### The bounding test - reported, NOT adopted

The extreme opposite assumption, `P_g` radially **uniform**, gives
`dT_norm = 0.787*A_norm + 0.213` with **no free parameter** - the 0.787/0.213 split is the
decomposition above, not a fit.

```
                              all 12        r < 24 only (11)
H1  dT = A                    RMSE 0.0593   RMSE 0.0619
H2  dT = 0.787 A + 0.213      RMSE 0.0448   RMSE 0.0207
```

Both hypotheses are shown under both station sets, chosen symmetrically, because dropping the 24 in
station helps H2 and hurts H1 and reporting only the favourable version of that is exactly the
selective-agreement error this study has forbidden itself. H2 also **overshoots** the ends
(-0.036 at 4 in, -0.139 at 24 in), so fully-flat is too extreme to be the truth.

```
H2 = BOUNDED_HYPOTHESIS.  NOT ADOPTED.  NOT PROVENANCE.
```

The truth lies between H1 and H2, and **the report does not contain the graphite deposition shape**.
That is the finding, and it is a provenance gap, not a modelling choice.

### What this does and does not change

```
CASE B = SOURCE_MAPPING_UNRESOLVED                      <- UNCHANGED
Phase 47 SHAPE_ONLY_PASS (axial)                        <- UNCHANGED, independent test
absolute normalization, +22.30 % against Table 5        <- UNCHANGED
```

No production file was touched. No tolerance was relaxed after seeing a result: the band was fixed
before the comparison and the comparison failed against it.

### Consequence for the phase order

Per the failure rule fixed at the start of this run, `RADIAL_SHAPE_FAIL` raises the priority of the
deposition/domain questions over the pure normalization search. Phase 48b identifies the responsible
quantity by name - the **radial shape of thermal deposition in the graphite**, as distinct from the
neutronic fission density Fig. 4 plots. **Phase 54 (NEUTRONIC -> THERMAL DEPOSITION PROVENANCE) is
therefore pulled ahead of Phases 49-53.**

---

## Phase 49 - Phase 48 REVERSED. The radial shape passes; the failure was my digitization, not the source.

Phase 48 ended with `RADIAL_SHAPE_FAIL` and an explanation: that Eq. (18)'s `P` could not be the
fuel fission density, because the graphite deposition must have a flatter radial shape. Phase 49 set
out to find provenance for that shape. It found the opposite - twice over.

### Finding 1 (provenance): the report states the assumption, verbatim, and it is the one I doubted

Printed p.31, read from the page image, not from OCR:

> *"axial variation of the fission power density. **Since the heat production in the graphite is
> small, no great error is introduced by assigning the same spatial distribution to this term.**
> Then, if axial heat transfer in the graphite is neglected, the net rate of heat addition to the
> fuel has the shape of the fuel power density."*

and printed p.32, immediately after:

> *"It is further assumed that the radial and axial variations in the power-density distribution
> are separable:*  `P(r,z) = A(r) B(z)`  *(2)"*

and printed p.40, introducing Eq. (18):

> *"Since both terms in this equation are directly proportional to the power density, the local
> temperature difference may also be expressed in terms of a maximum value and the local, relative
> power density."*

```
graphite deposition shape ....... SAME AS FUEL FISSION DENSITY   PRIMARY, p.31
separability P = A(r)B(z) ....... EXPLICIT                       PRIMARY, p.32
Eq. (18) single-shape scaling ... EXPLICIT                       PRIMARY, p.40
```

So Phase 48's `NOT_SOURCED` verdict on the graphite deposition shape was **wrong**: the report does
state it. It is an assumption rather than a calculation, and the report says so ("no great error is
introduced by"), but it is stated, and it is exactly `H1`. Phase 48b's `H2` (radially flat graphite
deposition) is therefore **refuted by primary text** and is withdrawn, not merely un-adopted. The
`P_g/P_f` shape identity also retroactively supplies the primary basis for the plane-cancellation
argument both shape tests rest on.

### Finding 2 (the actual defect): the eye reading of Fig. 13 was wrong by up to 7 F

With the source now saying `H1` should hold, the remaining suspect was my own data. Both figures
were re-digitized by machine - `tools/digitize_ornl0378.py`, a curve tracker run on the 300 dpi
page renders, with the axis calibration checked against the printed gridlines (Fig. 4: all 20
vertical majors land within 0.05 in of an integer radius).

```
Fig. 13 graphite curve, T_g (F)      eye      machine    error
  r = 15 in                          1266     1262.19    +3.8
  r = 20 in                          1243     1236.19    +6.8
  r = 22 in                          1231     1223.85    +7.2
```

Seven degrees on a 1280 F ordinate is a small reading error. On a **30 F difference** it is 24 %.
That is the whole of Phase 48's "systematic outward bias". **Reading the difference of two nearly
parallel curves by eye is far less accurate than reading either curve, and its error is systematic
rather than random** - which is precisely why the bias looked like physics.

### The retest, against the band declared BEFORE Phase 48 was run

The acceptance band is **not** re-derived from the better digitization. It stays at 0.0554, the
value propagated from the eye-reading uncertainties in force when the test was first posed. Keeping
the original band is what makes this a pass rather than a re-scored test.

```
MSRE.Verification.ORNL0378.RadialShapeVerification    (new)
  stations ......... 21, r = 4 .. 24 in
  RMSE ............. 0.004759      band 0.0554
  max |deviation| .. 0.010719      band 0.0554
  mean signed ...... -0.001711     assertion: |mean| < 0.25*band
  within band ...... 21 / 21
  VERDICT .......... RADIAL_SHAPE_PASS
```

On the same 12 stations Phase 48 used, the eye reading gave RMSE 0.0593 and the machine reading
gives 0.0062. Nothing about the hypothesis changed between those two numbers.

### The axial test was re-run the same way, because the same error class applies to it

Phase 47 passed on eye-read Fig. 14 values. A test that passed on suspect data is not exonerated by
having passed, so Fig. 14 was re-tracked by the same tool and `AxialShapeVerification` rebuilt on
the machine data.

```
MSRE.Verification.ORNL0378.AxialShapeVerification     (rebuilt)
  stations ......... 15, z = 4 .. 64 in  (z = 20 in absent: the tracker loses the curve at the
                     gridline there, and the gap is left as a gap, not interpolated)
  RMSE ............. 0.004398   was 0.0276 on the eye reading      band 3/64 = 0.046875
  max |deviation| .. 0.007848   was 0.0642
  within band ...... 15 / 15
  VERDICT .......... SHAPE_ONLY_PASS, unchanged and now on better data
```

Phase 47's conclusion survives. Its numbers do not, and are superseded above.

### A cross-check that is reported and NOT used as a criterion

```
Table 5, 0 % permeation, maximum local difference ........ 62.5 F   PRIMARY
Fig. 13 machine max, r = 7.0 in, near midplane ........... 62.44 F  FIGURE_DERIVED
Fig. 14 machine max, z = 36 in, r = 7 in ................. 62.32 F  FIGURE_DERIVED
```

The report's two figures and its table agree with each other to about 0.3 %. This matters for one
reason only: it means the **+22.30 % gap of Phase 46C is a gap against the report as a whole**, not
against one possibly-mistyped table entry. That closes off the cheapest available excuse for the
unresolved normalization. It does not resolve it.

### What Phase 48b keeps

The algebraic decomposition is unaffected by any of this - it is exact expansion of Eq. (13), not
measurement:

```
                r_w^2      [                 q_w ]
  dT_fuel  =  --------- *  [  3 P_f  +  22  ----- ]
              48 * k_f     [                 r_w ]

fuel fission ......... 78.7 %      graphite via q_w ..... 15.5 %
                                   graphite conduction ... 5.8 %   -> graphite-driven 21.3 %
```

The correction of the earlier "~6 %" claim to **21.3 %** stands. What is withdrawn is only the
*inference* built on top of it in Phase 48 - that the two shapes must differ.

### Status ledger

```
Phase 47  SHAPE_ONLY_PASS (axial) ............ CONFIRMED on machine data, numbers superseded
Phase 48  RADIAL_SHAPE_FAIL .................. REVERSED -> RADIAL_SHAPE_PASS
Phase 48b H2 flat graphite deposition ........ REFUTED by p.31, withdrawn
Phase 48b Eq. (13) decomposition ............. STANDS
Phase 54  graphite deposition shape .......... ANSWERED, PRIMARY, p.31 (pulled forward, closed)
CASE B    absolute power normalization ....... SOURCE_MAPPING_UNRESOLVED, UNCHANGED
```

### Incidental fix

`Verification/Graphite_EnergyClosure.mo:141` carried an unescaped `<table border="1">` inside a
documentation string, which made the whole `MSRE` package fail to load. It was masked because no
model in that package had been compiled since the annotation was written. Escaped; the package
loads and both shape models now build and run.

### Method note, recorded so it is not relearned

Any figure comparison in this study that rests on the **difference of two curves** must be machine
digitized. Phase 48 is the demonstration: a defensible eye reading of two curves produced a
confident, well-argued, physically plausible and entirely spurious conclusion about the source.

---

## Phase 50 - The absolute normalization, cornered. The overshoot is not where anyone thought.

With both shape questions closed, the +22.30 % overshoot of Phase 46C had nowhere left to hide
except in the absolute peak specific power. Phase 50 attacks that directly, by building a **second
route to the same quantity that shares no intermediate step with the first**. Model:
`MSRE.Verification.ORNL0378.AbsoluteNormalizationAudit`.

### Two new primary transcriptions

**Table 2** (printed p.14, *"Core Regions Used to Calculate Temperature Distributions in the MSRE"*):

```
Region  channels   total x-sec area   fuel frac   eff. outer r   eff. velocity   Re    flow
                        (in2)                         (in.)         (ft/s)             (gpm)
  1        12 *         45.00          0.256          3.78           1.99        3150    72
  2       940         1880.            0.224         24.76           0.60         945   791
  3       108          216.0           0.224         26.10           1.49        2360   224
  4        78          245.9           0.142         27.58           0.82        1300    89
  5         0 **        29.55          1.000         27.75           0.26         421    24
                                                                                       ----
                                                                                       1200
* plus 3 control-rod-thimble annuli.   ** annulus between graphite and core shell.
```

**Table 3** (printed p.17, the 19-region EQUIPOISE model), the four main-core rows:

```
Region   r_in    r_out    z_bot   z_top    fuel%   graphite%   represented
  J      3.00    27.75     5.50   64.59     22.5      77.5     Core
  L      0       2.94      2.00   64.59     25.6      74.4     Central region
  M      2.94    27.75     2.00    5.50     22.5      77.5     Core
  N      0       27.75     0       2.00     23.7      76.3     Horizontal stringers
```

Three things fall out immediately, and all three are checks that pass:

```
Table 3 volumes reproduce V_fuel = 35 253.8 in3 and V_graphite = 120 937.6 in3 EXACTLY
Table 4 regional powers sum to EXACTLY 10 000 kw
Table 2's stated areas match pi(r_out^2 - r_in^2) from its own radii to 0.2 .. 1.5 %
```

### The domain trap, walked into and then out of

**Table 2 and Table 3 are different regionalizations of the same core.** Table 2's region 2 ends at
an *effective outer radius* of 24.76 in; Table 3's region J ends at 27.75 in. `V_fuel_mainCore` is
built from Table 3, so the radial peaking factor that multiplies it must be integrated over
**27.75 in**, not 24.76 in.

Integrating to 24.76 in instead gives a radial factor of 1.4725 and cuts the overshoot from
+22.3 % to **+6.8 %** - by far the most favourable number this study has produced. It is
**REJECTED**, because pairing one table's radius with another table's volume is exactly the
domain splice these rules forbid, and a number does not become permissible by being convenient.

```
radial peak-to-average, machine digitization, area-weighted
  0 .. 27.75 in   (Table 3, matches V_fuel_mainCore) ....... 1.6997    USED
  3 .. 27.75 in   (region J alone)  ........................ 1.7100    variant
  0 .. 24.76 in   (Table 2 region 2) ....................... 1.4725    REJECTED, domain splice
```

Across every domain-consistent variant the overshoot is **+22.3 % to +24.4 %**. It is not sensitive
to the choice.

### rho*Cp, which the report never states, derived from the report

The report gives no heat capacity and no density - Phase 45 recorded that as a gap. It is not one:
a power, a volumetric flow and a temperature rise determine `rho*Cp`, and Table 4 supplies all
three, twice.

```
whole reactor   10 000 kw / 1200 gpm / 1175 -> 1225 F .... rho*Cp = 4.7551e6 J/(m3.K)
region J         8 287 kw / 1157 gpm / 43 F ............... rho*Cp = 4.7523e6 J/(m3.K)
                                                            agreement 0.06 %
```

Two independent rows agreeing to 0.06 % is what turns this from an inference into a derivation.
Table 4 is a single-`rho*Cp` construction.

### r_w, cross-checked against the report instead of against MSRE hardware

`data.r_w` was taken from MSRE channel geometry, not from this report - a weak point, since `r_w`
enters Eq. (13) **squared**. Table 2 closes it:

```
1880.0 in2 / 940 channels = 2.0000 in2 per cell   EXACTLY
x 0.224 fuel fraction     = 0.4480 in2 flow area per channel
r_w = sqrt(0.4480/pi)     = 0.37762 in = 0.0095916 m
data.r_w                  = 0.37664 in = 0.0095667 m     +0.26 %
```

Confirmed from the report alone, and 0.26 % is three orders too small to be the answer. (It also
points the wrong way: the report's own value makes the overshoot slightly *worse*.)

### ROUTE 2 - the report's own channel equation, inverted

Eqs. (4) and (5), p.32:

```
  T_f(r,z) = T_f(0) + X * A(r)/u(r) * { cos a - cos[ (pi/77.7)(z + 4.36) ] }      (4)
  X        = (77.7/pi) * (Q_f)_m / (rho Cp)_f                                     (5)
```

At `r = 7 in`, `A(r) = 1` by construction of Fig. 4. Fig. 14 gives that channel's rise, Table 2
gives its velocity, Table 4 gives `rho*Cp`. **No peaking factor, no Table 3 volume, no region
power enters.**

```
{cos a - cos b} across 0 <= z <= 64.59 in ......... 1.92257
dT_f(r=7) = 1261.7 - 1177.3 F .................... 84.4 F  (Fig. 14, p.33 inlet)
u(r=7) = 0.60 ft/s ............................... Table 2, region 2
X ................................................ 4.4602 K.m/s
(Q_f)_m .......................................... 3.3760e7 W/m3
P_f_max = 0.94 (Q_f)_m ........................... 3.1735e7 W/m3
```

### The result

```
ROUTE 1  power/volume x peaking ............. P_f_max = 3.2709e7 W/m3
ROUTE 2  Eq. (3)-(5) inverted ............... P_f_max = 3.1735e7 W/m3
                                              agree to  3.07 %
Table 5's 62.5 F REQUIRES ................... P_f_max = 2.6528e7 W/m3
                                              lower by 19.6 % (route 2) / 23.3 % (route 1)
```

Two routes that share no intermediate quantity land within 3 % of each other and both miss what
Table 5 needs by about 20 %.

### A third corroboration, with no free parameter

Eq. (3) makes the channel rise proportional to `A(r)/u(r)`, so the hot channel's rise relative to
the mixed mean is `(A(7)/<A>_flowarea) * (<u>/u(7))`. Every factor comes from a different place:

```
A(7)/<A>_flowarea   from Fig. 4 weighted by Table 2's five flow areas ....... 1.709
<u>/u(7)            Table 2's own total flow / total area, over its 0.60 .... 1.176
predicted ratio ............................................................. 2.010
observed, Fig. 14 with the p.33 boundaries: 84.4 F / 43.5 F ................. 1.940
                                                                             +3.6 %
```

This independently **rules out** the radial peaking of 1.3785 that would close Table 5: it is 24 %
below the value three separate parts of the report agree on.

### Elimination table

```
graphite deposition shape differs .............. REFUTED   p.31, p.38, p.40
radial shape of DT wrong ....................... REFUTED   Phase 49, RMSE 0.0048
radial peaking factor wrong .................... REFUTED   corroborated to 3.1 % and 3.6 %
r_w wrong ...................................... REFUTED   Table 2 gives it to 0.26 %
Table 3 volumes wrong .......................... REFUTED   reproduced exactly
Table 4 powers / domain mismatch ............... REFUTED   sum to 10 000 kw; rho*Cp closes twice
Table 5 mistyped ............................... REFUTED   Figs. 13 and 14 give 62.44, 62.32 F
Table 2 radius + Table 3 volume ................ REJECTED  +6.8 %, but a domain splice
```

### What is left, and why the audit stops here

One link. p.40: *"The maximum values of the local graphite-fuel temperature difference may be
obtained by applying the appropriate specific powers to Equation (17)."* **The report states no
numerical specific power anywhere** - its own nomenclature (p.49) defines `P` as the *relative*
power density. That sentence is the only step in the chain that cannot be checked, and it is
precisely the step where the factor of 1.20 would have to live.

```
PHASE 50 = ABSOLUTE_NORMALIZATION_UNRESOLVED, LOCALIZED

  the overshoot is NOT in any transcribed quantity
  the overshoot IS in the one step the report leaves unstated
  CASE B remains SOURCE_MAPPING_UNRESOLVED
```

The audit model encodes this as an assertion at `AssertionLevel.warning` that is **expected to
fire**. Widening its bound to make it pass would be the fitting these rules forbid; leaving it
firing is the finding, in executable form.

---

## Phase 51 - One coincidence, recorded and REJECTED, because a later reader will find it

Phase 50 localized the overshoot to the unstated step "applying the appropriate specific powers to
Equation (17)". Before closing, the obvious question was asked: **is there a sub-expression of
Eq. (17) that does land on 62.5 F?**

```
                                      route 1 P_f      route 2 P_f
  full Eq. (17)                     77.06 F  +23.30%   74.77 F  +19.63%
  Eq. (13) WITHOUT the q_w term     65.13 F   +4.20%   63.19 F   +1.10%   <-- lands on it
  Eq. (13) fission term alone       60.62 F   -3.01%   58.81 F   -5.90%
```

Table 5's 62.5 F sits **between** "Eq. (13) fission term alone" and "that plus Eq. (16)", and the
second of those is within 1.1 % of it on the better-sourced route.

```
STATUS = REJECTED as provenance.  RECORDED as an observation.
```

Rejected because there is no reading of the report that omits `q_w`. p.38 states the opposite in
so many words: *"the rate of heat transfer from graphite to fuel, q_w, is directly proportional to
the graphite specific power"*, and Eq. (13) carries the term explicitly. Adopting a sub-expression
because it hits the target is the inverse fitting these rules forbid, and a 1.1 % match is not
even a strong coincidence when the two routes themselves differ by 3.1 %.

It is written down anyway, with its rejection, because it is the first thing anyone re-deriving
this will stumble on, and finding it undocumented would look like an oversight rather than a
decision. What it legitimately narrows: **62.5 F is consistent with an evaluation of Eq. (17) in
which the wall-flux contribution is absent or much smaller than the 15.5 % this study computes** -
which is a statement about the unstated step, not a licence to change the equation.

### Regression

```
MSRE.Verification.ORNL0378.AlgebraicVerification ...... checkModel OK, simulates, verdict unchanged
MSRE.Verification.ORNL0378.AxialShapeVerification ..... PASS on machine data
MSRE.Verification.ORNL0378.RadialShapeVerification .... PASS on machine data
MSRE.Verification.ORNL0378.AbsoluteNormalizationAudit . 3 hard assertions PASS, the expected
                                                        warning fires as designed
```

---

## Phase 57 - Reference recovery. Every citation traced; the one that matters does not exist as a document.

The complete citation apparatus of ORNL-TM-0378, read off the page images rather than the OCR:

```
 #  author                    title                                        number        date        status
 1  E. S. Bettis et al.       Internal Correspondence                      (none)        (none)      UNPUBLISHED
 2  T. B. Fowler, M. L. Tobias EQUIPOISE-3: A Two-Dimensional, Two-Group   ORNL-3199     1962-02-07  published
                              Neutron Diffusion Code for the IBM-7090
 3  C. W. Nestor, Jr.         EQUIPOISE-3A                                 ORNL-3199 Add 1962-06-06  published
 4  B. E. Prince, J. R. Engel Temperature and Reactivity Coefficient       ORNL TM-379   1962-10-15  published
                              Averaging in the MSRE
 5  H. F. Poppendiek,         Forced Convection Heat Transfer in Pipes     ORNL-1395     1953-11-05  published
    L. D. Palmer             with Volume Heat Sources Within the Fluids
 6  H. F. Poppendiek,         Forced Convection Heat Transfer Between      ORNL-1701     1954-05-11  published
    L. D. Palmer             Parallel Plates and in Annuli with Volume
                              Heat Sources Within the Fluids
 7  = 4 (re-cited on p.45)
 -  C. W. Nestor             gamma and neutron heating in the graphite     (none)        (none)      UNPUBLISHED
                              (cited only in the p.40 footnote)
```

### Which reference feeds which quantity

```
quantity              fed by                                    linkage evidence
A(r)                  EQUIPOISE-3A run for the MSRE             p.15 "the neutronic calculations upon
B(z)                  same                                      which the temperature distributions are
regional power        same (Table 4)                            based were made with Equipoise 3A"
u(r), Table 2 vel.    ref 1, Bettis et al.                      p.12, named
Eq. (13) form         refs 5, 6                                 p.37, superscript 5,6
Eq. (19)-(22)         ref 4                                     p.45, superscript 7
f_graphite = 0.06     Nestor, unpublished                       p.40 footnote, named
P_f  (numerical)      NOTHING                                   no citation anywhere
P_g  (numerical)      NOTHING                                   no citation anywhere
```

Refs 2 and 3 document the **code**, not the MSRE run. The MSRE EQUIPOISE-3A calculation itself is
not a cited document; it is unpublished work internal to this report. So the two candidate carriers
of the absolute specific power - the MSRE EQUIPOISE run and the Nestor heating calculation - are
**both unpublished and neither has a report number**.

### Two further primary statements recovered along the way

p.15: *"Regions J, L, M, and N comprise the main portion of the core. This portion contains 98.7 %
of the graphite and **produces 87 % of the total power**."* - confirms `Q_mainCore` in words, not
only by summing Table 4.

p.15: *"the reactor model used for this calculation **differed somewhat from the hydraulic
model**"* - the report states outright that Table 2 and Table 3 are different regionalizations.
Phase 50's rejection of the 24.76 in / 27.75 in splice is now source-backed rather than inferred.

p.37: the graphite-fuel difference is broken into **three** parts - Poppendiek effect, the drop
across the graphite-fuel interface, and stringer-mean minus interface - while Eq. (17) has two
terms. p.38 reconciles them: the interface film drop is *inside* the Poppendiek term. No missing
term.

## Phase 57D/E - Local and external search. The documents exist; this session cannot reach them.

Local: the only documents available are the two identical ORNL-TM-0378 scans and the 2026
Amirkhosravi paper. The paper cites the 6 % figure as *"gamma and neutron heating estimates by
C.W. Nestor (Engel and Haubenreich, 1962)"* - i.e. **through TM-0378 itself**. A secondary source
reproducing the same gap is not independent provenance.

External: search identifies the documents; **every document host is blocked by this session's
egress proxy** (`moltensalt.org`, `osti.gov`, `info.ornl.gov`, `digital.library.unt.edu`,
`inis.iaea.org`, `nrc.gov`, `arxiv.org` - all refused at CONNECT). Only the search index itself is
reachable. Recorded so a session with network access can go straight to them:

```
ORNL-TM-0379   Prince & Engel, companion report           OSTI 4768339   moltensalt.org PDF exists
ORNL-3199      Fowler & Tobias, EQUIPOISE-3 manual        OSTI 4792940
ORNL-TM-0730   MSRE Design & Operations Report Part III   OSTI 4114686
ORNL-CF-61-4-62 MSRE Preliminary Physics Report           OSTI 4007873
(1960)         Nestor, Reactor Physics Calculations       OSTI 4155392   1960-07-26
               for the MSRE
ORNL/TM-2019/1359  Status Report on the MSRE TRANSFORM Model            - direct ancestor of this repo
```

One search snippet is worth recording **as a snippet and nothing more**: the 1960 Nestor report is
summarized as giving, at 10 Mw, a homogeneous peak power density of 10 W/cm3 and an average of
4 W/cm3, i.e. a peak-to-average of **2.5**. That is the same order as the 2.31 this study computes
and nowhere near the 1.87 Table 5 needs. It describes a 54 in x 66 in core at 8 vol % fuel - **not
the MSRE final design** - and it has not been page-verified.

```
STATUS = SEARCH_SNIPPET_ONLY, NOT PAGE-VERIFIED, NOT USED AS PROVENANCE
```

## Phase 57G - Energy-partition audit. The partition cannot be the explanation, in either direction.

Both routes fix the **total** peak heat per unit fuel volume; `f_graphite` only splits it. Sweeping
that split across its entire physical range:

```
             route 1                    route 2
 f_graphite  dT (F)   vs 62.5 F         dT (F)   vs 62.5 F
   0.00       64.49    +3.18 %           62.57    +0.11 %
   0.02       68.68    +9.89 %           66.63    +6.61 %
   0.06       77.06   +23.30 %           74.77   +19.63 %      <- the report's value
   0.20      106.40   +70.24 %          103.23   +65.17 %
```

`dT` is **monotonically increasing** in `f_graphite`, so its minimum over the whole range [0,1] is
at zero - and at zero it is still at or above 62.5 F. **No energy partition reproduces Table 5 from
a lower value; more graphite heating only makes the overshoot worse.**

Double-counting check: `Q_mainCore` is total regional power (Table 4 sums to 10 000 kw and closes
on one `rho*Cp` twice), and `f_fuel` is applied to it exactly once; route 2's `(Q_f)_m` is the
*equivalent* specific power including graphite heat by the report's own definition (p.32), and
`f_fuel` is likewise applied once. **No double counting found.**

That route 2 at `f_graphite = 0` lands 0.11 % from 62.5 F belongs with the Phase 51 coincidence and
carries the same verdict: `REJECTED as provenance, RECORDED as observation`. Two different
reductions land near the target because they are numerically similar reductions, not because either
is documented.

## Phase 57I - Route-independence audit. The honest classification.

```
                        route 1                       route 2
f_fuel = 0.94           multiplicative                multiplicative      SHARED
Table 4                 regional powers (J,L,M,N)     rho*Cp (2 rows)     SHARED SOURCE, disjoint use
B(z) parameters         axial average                 the cos-cos bracket SHARED SOURCE, disjoint use
A(r)                    full radial integral          only A(7) = 1       nearly disjoint
Table 3 volumes         V_fuel_mainCore               not used            route 1 only
Table 2                 not used                      u(r=7)              route 2 only
Fig. 14                 not used                      dT_f(7)             route 2 only
```

```
CLASSIFICATION = ALGEBRAICALLY_INDEPENDENT
             NOT FULLY_INDEPENDENT, and NOT independent physical measurements
```

Both are arithmetic on one 1962 document. Their agreement to 3.07 % shows the *report is
self-consistent on the fuel side*; it is not evidence from two measurements. The single input that
would move them together is `f_fuel`, and Phase 57G has just shown no value of it closes the gap.

## Phase 57J - Discrepancy convention, fixed

```
                                   route 1     route 2
(predicted - Table5implied)/Table5implied   +23.30 %    +19.63 %
(Table5implied - predicted)/predicted       -18.90 %    -16.41 %
EFFECTIVE_NORMALIZATION_DISCREPANCY ratio    0.8110      0.8359
```

These are the same fact under two denominators. **0.81 / 0.84 is an
`EFFECTIVE_NORMALIZATION_DISCREPANCY`, not a `MISSING_CORRECTION_FACTOR`** - nothing in the report
authorises a multiplier, and none is introduced anywhere in this repository.

The earlier phrasing *"the factor of 1.20 has to live in the p.40 sentence"* is **withdrawn**. The
correct statement: *the remaining discrepancy is localized to the mapping that supplies the
"appropriate specific powers" to Eq. (17), or to definitions implicitly embedded in those specific
powers.*

## Phase 58 / 56 - NOT ENTERED

```
PROVENANCE GATE NOT SATISFIED.
No source normalization was recovered, so no reconstruction and no absolute Table 5 retest was run.
```

## Phase 59 / 60 / O - TRANSFORM implementation boundary and production source audit

Model: `MSRE.Verification.ORNL0378.ProductionShapeComparison`. **No production file was modified.**

### O. Source integral, verified numerically against the production construction

`corePowerShape` normalizes `SF` so that `sum(SF) = 1`, and the kinetics sets `Qs = Q_fission*SF`.
Power conservation is therefore an identity of the construction, for any radial profile:

```
plenumFissionSource = false    sum(SF) = 1 - 6e-16    sum(q''' V) - Q = +9.3e-9 W on 10 MW
plenumFissionSource = true     sum(SF) = 1            sum(q''' V) - Q =  0
```

The plenum-node issue is closed and stays closed: at `false` both plenum cells carry `SF = 0`; at
`true` they take **13.05 %** of the source between them while holding 65x a channel cell's volume.
(The function's own documentation quotes 14.77 % for that case - a stale figure from an earlier
geometry vintage. `DOCUMENTATION_DRIFT`, not a behaviour defect, since the default path never
evaluates it.) All 15 rings carry the same channel count, so every channel cell has the same volume
(1.7761e-3 m3) and there is no volume-weighting artefact inside the channel domain.

### 60. Mapping, ORNL concept -> production implementation

```
ORNL concept          provenance          TRANSFORM variable            same domain?  class
B(z) sin, 77.7 in     Fig. 8, PRIMARY     corePowerShape cosine,        yes           NO_ISSUE
                                          f_axialExtrapolation = 1.2
  axial peak/average  1.3584              1.3552                                      0.24 % apart
  extrapolation       1.20297 (77.7/64.59) 1.2 (rule of thumb)          -             NO_ISSUE, unrelated
                                                                                       provenance
  peak elevation      34.49 in            32.295 in (midplane)          -             MODEL_ASSUMPTION
                                                                                       offset 2.195 in = 3.40 %
A(r) Fig. 4           FIGURE_DERIVED      Core2D f_radial (J0 + 25 %)   yes, r<=27.75 BENCHMARK_DIFFERENCE
  radial peak/average 1.6726 on 15 rings  1.6067                        -             3.9 % apart
  shape               peak on RING 2,     monotone from ring 1          -             BENCHMARK_DIFFERENCE
                      central depression
  normalized RMSE     -                   0.1155, max 0.187             -
combined peak/average 2.272 (ring-avg)    2.177                         -             4.2 % apart
                      2.309 (continuous)                                              discretization 1.6 %
Q_total -> Q_f, Q_g   f_graphite = 0.06   f_graphiteHeating = 0         -             MODEL_ASSUMPTION
                      p.40, unpublished   (locked by user decision)                     (user-fixed gate)
  partition algebra   Q_f + Q_g = Q       Qs*(1-f) + Qs*f = Qs          -             NO_ISSUE, no double count
channel count         1138 + 3 annuli     nChannels_total = 1140        yes           NO_ISSUE (0.18 %)
channel flow area     0.4480 in2 (Tab.2)  0.44565 in2                   yes           NO_ISSUE (0.53 %)
active height         64.59 in            64.00 in (1.6256 m)           -             MODEL_ASSUMPTION (0.9 %)
total core flow area  545.49 in2 (Tab.2,  508.0 in2                     NO - Table 2  BENCHMARK_DIFFERENCE
                      all 5 regions)                                   includes the
                      515.94 in2 (1-4)                                 channel-free    (1.5 % against
                                                                       annulus         regions 1-4)
power conservation    -                   sum(SF) = 1, exact            -             NO_ISSUE
```

### The one structural difference worth naming

ORNL's Fig. 4 is **not monotone**: three control-rod thimbles depress the flux inside r ~ 3.3 in and
put the maximum at r = 7 in, on ring 2. The production J0 profile decreases monotonically from ring
1 and cannot represent that at all. Whether it should is a modelling-policy question about which
reference case the 2-D model serves - the paper benchmark's Serpent tabulation is unpublished, so
substituting a 1962 figure would swap one unsourced profile for a differently-sourced one and
silently change the benchmark. **This audit does not make that call, and nothing was changed.**

### Explicitly NOT claimed

A power-conserving TRANSFORM normalization - `q'''(r,z) = Q_total A(r)B(z) / integral(A B dV)` - is
valid on its own terms and is what the production model already implements. **It is not, and must
not be presented as, a reproduction of ORNL Eq. (13)'s absolute specific power.** The first
conserves a total; the second requires an absolute local value that this study has not recovered.

---

## Phase 61 - 2-D RADIAL SOURCE SENSITIVITY. Pre-registration, written and committed BEFORE any run.

### Status carried in, frozen

```
GOVERNING   CASE 2 = ABSOLUTE_PROVENANCE_NOT_RECOVERED
ADDITIONAL  CASE 3 = UNRESOLVED CROSS-CHAIN NORMALIZATION INCONSISTENCY
            EQUIPOISE absolute normalization MECHANISM ......... SOURCED
            actual MSRE EQUIPOISE normalization INPUT .......... UNRESOLVED
            P_f/P_g mapping into Eq. (17) ..................... UNRESOLVED
```

Phase 57G's verdict is **narrowed** as instructed. It read `POWER PARTITION = ELIMINATED`; that
was too broad. What the monotonicity argument actually establishes is:

```
GRAPHITE-HEATING-FRACTION-AS-SOLE-CAUSE = REJECTED
```

The general upstream fuel/graphite absolute partition remains inside the unresolved `P_f`/`P_g`
provenance, not outside it. The 0.8110-0.8359 discrepancy is not reopened here, and no factor is
hunted.

### Phase A - source shape freeze

```
CASE J0    MSRE.Data.Nodalization.Core2D f_radial, VERBATIM, unchanged
CASE ORNL  ORNL-TM-0378 Fig. 4, machine-digitized, ring-volume-averaged
```

Both run in `MSRE.Verification.Core2D_RadialSourceSensitivity`, which extends the existing
`Core2D_TH_ZeroPower` at `Q_core = 8 MW` - **the repository's own established verification
operating point** (`CoreTH_Baseline`, `Core1D_TH_Baseline`), not a new one. Everything except
`f_radial` is inherited: total power, B(z), geometry, mass flow, fuel properties, heat-transfer
closure, `f_graphiteHeating = 0`, inlet temperature, boundary conditions, 15x20 nodalization.
**No production file is modified.**

### Phase B - discrete power normalization

`corePowerShape` divides by `sum(P)`, so `sum(SF) = 1` and `sum(q''' V) = Q_core` hold
identically for **any** radial profile. Both cases therefore impose the same total to machine
precision, and any common scale on `f_radial` cancels exactly. The model asserts both identities.

Interpolation and averaging, documented as required:

```
source curve ........ Verification/ORNL0378/data/Fig04_radial.csv (machine-tracked, 0.5 in
                      spacing to r = 24.5 in) spliced with the four eye-read points beyond it
interpolation ....... piecewise linear in r
ring definition ..... Core2D gives every ring the same channel count, hence equal FLOW AREA,
                      hence equal-area annuli: r_k = 27.75*sqrt(k/15) in
                      R = 27.75 in is Table 3's main-core outer radius
ring average ........ A_k = (1/V_k) int_ring A(r) 2 pi r dr, midpoint rule, 20 000 intervals
                      NOT a point sample at the centroid, NOT an arithmetic mean over radius
post-normalization .. divided by the 15-ring mean 0.58763, so it carries the same convention as
                      f_radial_J0 (whose mean is 1.00000). This is a convention, not a fit -
                      corePowerShape would undo any scale anyway
```

```
ring   r0      r1      r_centroid   V_frac    A_ring(pre)   f_radial_ORNL   f_radial_J0
  1   0.000   7.165      4.777      0.06667     0.9578         1.6299         1.6067
  2   7.165  10.133      8.734      0.06667     0.9829         1.6726         1.5076
  3  10.133  12.410     11.310      0.06667     0.9300         1.5826         1.4115
  4  12.410  14.330     13.393      0.06667     0.8616         1.4662         1.3184
  5  14.330  16.021     15.191      0.06667     0.7897         1.3439         1.2283
  6  16.021  17.551     16.798      0.06667     0.7168         1.2198         1.1410
  7  17.551  18.957     18.263      0.06667     0.6484         1.1034         1.0565
  8  18.957  20.266     19.619      0.06667     0.5791         0.9855         0.9748
  9  20.266  21.495     20.886      0.06667     0.5119         0.8711         0.8958
 10  21.495  22.658     22.082      0.06667     0.4447         0.7568         0.8194
 11  22.658  23.764     23.215      0.06667     0.3774         0.6422         0.7456
 12  23.764  24.820     24.296      0.06667     0.3175         0.5403         0.6743
 13  24.820  25.834     25.330      0.06667     0.2938         0.5000         0.6055
 14  25.834  26.809     26.324      0.06667     0.2338         0.3979         0.5392
 15  26.809  27.750     27.282      0.06667     0.1691         0.2878         0.4751
```

All 15 ring volumes are identical (1140/15 = 76 channels each, 20 cells of 1.7761e-3 m3).

### Phase C - can this mesh represent the central depression? No.

```
ORNL continuous peak ......... A = 0.9988 at r = 7.00 in
that radius falls in .......... RING 1  (0.000 .. 7.165 in)
central depression ............ minimum A = 0.8812 at r = 2.50 in, a 10.6 % dip
depression region r < 3.3 in .. 21.2 % of ring 1's AREA, so 21.2 % of its volume weight
ring carrying the largest volume-averaged source ... RING 2
trace of the depression that survives ... ring1 0.9578 vs ring2 0.9829, a 2.55 % dip
```

The production 2-D model has **no radial coordinate at all**: the 15 rings are geometrically
identical parallel channel groups distinguished only by `f_radial`. "Equal-area annuli" is the
mapping this audit imposes to put the two profiles on one axis, and it is stated as such.

### Phase D - nodalization sensitivity, before attributing anything to physics

```
                       continuous        15-ring volume-averaged
<A> .................. 0.5876            0.5876          (identical by construction)
peak ................. 0.9988            0.9829          98.41 % retained
peak/average ......... 1.6997            1.6726          98.41 % retained
peak location ........ r = 7.00 in       ring 2, centroid 8.73 in
area-weighted RMSE ... -                 0.0208
max |error| .......... -                 0.0766          (at the peak/depression)
```

```
NODALIZATION_PARTIAL_LIMITATION
  gross profile and peak/average: PRESERVED to 1.6 %
  central thimble depression:     NOT RESOLVED - it lies entirely inside ring 1
```

So this A/B measures the **gross radial redistribution** and nothing about the depression. Any
verdict below is bounded by that, and a `J0_THERMALLY_EQUIVALENT` outcome would NOT license the
statement that the thimble depression is thermally unimportant - only that this mesh cannot see it.

### Phase G - engineering thresholds, DECLARED BEFORE THE RUN

Anchored on the physics, not on any result: the MSRE core temperature rise at the reference
condition is 50 F = 27.8 K, and the local graphite-fuel difference is of order 35 K. A shift of
1 K is 3.6 % of the core rise - the level at which a benchmark comparison would notice it.

```
GLOBAL   (mixed-mean outlet T, core dT, dp_core, energy balance)
  NEGLIGIBLE  |dT| < 0.1 K   or  |rel| < 0.1 %
  SMALL       0.1 .. 1 K     or  0.1 .. 1 %
  MATERIAL    1 .. 5 K       or  1 .. 5 %
  DOMINANT    > 5 K          or  > 5 %

LOCAL HOTSPOT   (max fuel T, hottest-ring outlet T, radial spread, ring flow split)
  NEGLIGIBLE  |dT| < 0.5 K   or  |rel| < 1 %
  SMALL       0.5 .. 2 K     or  1 .. 5 %
  MATERIAL    2 .. 10 K      or  5 .. 20 %
  DOMINANT    > 10 K         or  > 20 %
  a CHANGE OF HOTTEST-RING IDENTITY is MATERIAL regardless of magnitude
```

### Phase H - graphite-heating gate

`f_graphiteHeating = 0` is held for the primary comparison, per the standing user decision, so
that radial source shape is the only variable. No secondary 0.06 sensitivity is combined with it.

---

## Phase 61 (item 11) - Nodalization error vs source-model error, separated exactly. SOURCE DOMINATES.

Computed on the **source distribution** while the two thermal builds run, because it needs no
simulation and it bounds how the thermal comparison may be read.

Metric: the volume-weighted L2 norm over `0 <= r <= 27.75 in` with weight `2 pi r dr`, each profile
first normalized to unit volume-average so that only shape is compared.

**The projection and the norm use the SAME measure.** Over a fixed axial extent the annular volume
element is `dV = 2 pi r dr H`, so `dV` is proportional to `r dr`; the ring average
`A_k = (1/V_k) int_ring A(r) 2 pi r dr` is the orthogonal projection onto piecewise-constant
functions *in exactly the inner product the norm below uses*. That identity of measure is what makes
the decomposition exact rather than merely a triangle inequality - if the ring average had been an
arithmetic mean over `r`, or the norm unweighted, the cross term would not vanish.

```
E_nod   continuous ORNL  ->  15-ring ORNL   =  0.03542
E_src   15-ring ORNL     ->  15-ring J0     =  0.11551
E_tot   continuous ORNL  ->  15-ring J0     =  0.12082
```

The decomposition is **exact, not approximate**. The ring average is precisely the L2 projection of
the continuous profile onto the space of piecewise-constant functions on those rings, so the two
errors are orthogonal:

```
sqrt(E_nod^2 + E_src^2) = 0.12082      residual +1.25e-06   (quadrature only)
```

```
variance share    nodalization  8.6 %      source model  91.4 %
ratio             E_src / E_nod = 3.26
```

Same split on peak-to-average:

```
continuous ORNL ....... 1.6997
15-ring ORNL .......... 1.6726     nodalization loss  0.0270
15-ring J0 ............ 1.6067     source-model loss  0.0659      ratio 2.44
```

```
ITEM 11 VERDICT (source distribution) = SOURCE-MODEL ERROR DOMINATES
  it is 3.26x the nodalization error in norm and 2.44x on peak/average
  CASE D (NODALIZATION_DOMINATED) is therefore NOT satisfied on the source side
```

Note on units: Phase D reported this reconstruction error as 0.0208 in raw `A` units, whose volume
mean is 0.58763. `0.0208/0.58763 = 0.0354` - the same number in the mean-normalized metric used
here. Phase D's frozen statement is unchanged; only its expression is made comparable.

**What this does not settle.** It is a statement about the *source field*, not about temperature. A
thermal system low-pass filters its source, so a source-side ratio of 3.26 does not transfer to the
thermal metrics. Whether CASE D applies *thermally* still needs the runs.

---

## Phase 62 - Gates 1 and 2 of the 2-D radial source A/B. Model identity proved at compile time.

### Gate 1 - translation, code generation, compilation

Both cases were translated by omc 1.27.0 from the same library load. Staging, recorded because a
45-minute wall-clock ceiling was in play and a bare "timeout" would have been an uninformative
verdict:

```
stage                       CASE J0            CASE ORNL          note
library load + instantiate  PASS               PASS               ~1 min
symbolic backend            PASS, ~30 min      PASS, ~30 min       10086-variable coupled system;
                                                                   4.0-5.4 GB resident each, plateaued
code generation             PASS, 261 .c       PASS, 261 .c        makefile, _init.xml, _info.json all
                                                                   written -> codegen COMPLETE
C compilation               finished by make   finished by make    see below
```

The two backends behaved **identically** - same duration, same memory plateau, same file count - so
the cost is a property of the 2-D model, not of either source shape. Nothing stalled: the long
phase was symbolic processing, and code generation was entered and completed by both.

One intervention is recorded because it changed the process: a memory watchdog killed the CASE ORNL
`omc` at 1748 MB free to keep the machine from OOM-killing both. **Code generation for that case had
already completed**, so nothing was lost; the remaining C compilation was finished with `make`
against the makefile omc had already written. Running two 4-5 GB backends on a 15 GB machine was
the mistake, not the model.

### Gate 2 - model identity, and a stronger result than a diff

All 8545 parameters of the two compiled models were compared from their `_init.xml`:

```
parameters compared ............ 8545
identical ...................... 8544
differ, ALLOWED (source chain) . 1     useORNLradialShape:  false / true
differ, NOT ALLOWED ............ 0
present in only one model ...... 0
GATE 2 = PASS
```

That single boolean is the *only* difference in the entire parameter set - geometry, ring count,
axial discretization, properties, mass flow, inlet temperature, hydraulic BCs, heat-transfer
correlations, graphite conductivity, heat capacities, initialization, solver, tolerances, duration
and total fission power are all bit-identical.

The generated C shows exactly what that boolean does, and nothing else:

```c
nodalization.f_radial[j] = if useORNLradialShape then f_radial_ORNL[j] else f_radial_J0[j]
SF_core = MSRE.Functions.corePowerShape(15, 20, {76 x 15}, nodalization.f_radial, ...)
```

Both statements sit in the **bound-parameter section**, evaluated at initialization from a runtime
boolean. So the two cases are not merely "the same model with one input changed" - they are the
same executable code path with one branch selected.

**A methodological correction follows.** `SF_core` is a `final parameter` and I expected it to be
constant-folded, which is why two separate builds were made. It is not: omc keeps the
`corePowerShape` call as a runtime bound-parameter evaluation. A single build with
`-override=useORNLradialShape=true` would therefore have been sufficient, and would have made model
identity a compile-time certainty rather than a diff. Both builds are kept - the second is now an
independent cross-check that the override and the recompile agree - but the second was avoidable
work.

```
GATE 2 = PASS
  permitted difference: radial fission source distribution ONLY
  CASE A = 15-ring projected ORNL source     CASE B = J0 source
  total fission power: 8 MW in both, exactly
```

### Power accounting, with the definition pinned down

```
sum_i Q_i          CASE J0   8 000 000.000000000 W    residual 0.000e+00 W
                   CASE ORNL 8 000 000.000000000 W    residual 0.000e+00 W
TOTAL POWER CHANGE                          -1.5e-10 W
```

Redistribution, using the non-double-counting definition:

```
Q_redistributed = 0.5 * sum_i |Q_J0,i - Q_ORNL,i| = 404.744 kW = 5.059 % of 8 MW
  sum of positive deltas  +404.744 kW
  sum of negative deltas  -404.744 kW
  sum |delta|              809.488 kW   <- DOUBLE COUNTS, not used
```

The earlier "~0.4 MW" figure is traced: it was the positive-side sum, which equals
`0.5*sum|delta|` to 5.8e-11 W. **The earlier number already used the correct definition; no
correction is needed.** It remains a redistribution, not a power increase.

---

## Phase 62b - Analytic prediction, recorded BEFORE the thermal runs returned.

Written so that whatever the simulation gives cannot be rationalised afterwards. A ring is a
parallel path with imposed inlet temperature; if flow were uniform its outlet rise is
`dT_ring = Q_ring / (m_ring cp)`.

```
m_total = 168 kg/s (Data.Geometry.m_flow_nominal), m_ring = 11.200 kg/s
cp = 2000 J/(kg.K)   ASSUMPTION, order-of-magnitude only, for the prediction alone -
                     the simulation uses the real MSRE.Media.FuelSalt property model

 ring   dQ (kW)   predicted dT_out (K)
   1     +12.34         +0.551
   2     +87.98         +3.927
   3     +91.26         +4.074      <- largest positive
   4     +78.81         +3.518
   5     +61.64         +2.752
   8      +5.74         +0.256
  11     -55.19         -2.464
  13     -56.30         -2.514
  15     -99.82         -4.456      <- largest negative

predicted max |dT_out| ............ 4.456 K
predicted RMS over rings .......... 2.750 K
predicted mixed-mean outlet change  -4.8e-05 K, i.e. zero by construction
```

```
PREDICTED CLASS = BULK_ATTENUATED_LOCAL_EFFECT_PERSISTS
  local ring outlets move by up to ~4.5 K -> MATERIAL on the preregistered local band (2-10 K)
  mixed-mean outlet moves by nothing      -> NEGLIGIBLE on the global band, BY CONSTRUCTION
```

This is exactly the trap the instructions warn about: equal total power and equal total flow force
the mixed-mean rise to agree, so **global agreement here carries no information about source
fidelity**. If the simulation reproduces this pattern, the correct reading is that the bulk is
constrained, not that the two sources are equivalent.

### Build-process note

The `omc` driver for CASE J0 hit its 2700 s wall clock during C compilation, having reached 253 of
261 objects; the compilation was finished from omc's own makefile. Four `cc1` processes on the
`_02nls_part*.c` files were holding 1.5-3.3 GB each - the nonlinear-system code for a
10086-variable system - which drove the machine to 1.7 GB free and one compiler into
uninterruptible IO. The redundant CASE ORNL compile chain was dropped at that point, since Gate 2
had already shown a single executable with `-override=useORNLradialShape=true` is sufficient and
strictly better evidence. `RESOURCE_LIMITATION`, not a model defect.

### Phase 62b (sharpened) - the prediction re-run with the model's own heat capacity

The first prediction used `cp = 2000 J/(kg.K)` as a round number. The model's actual value is
`cp = 2009.66 J/(kg.K)`, constant (`Media/FuelSalt/Utilities/cp_T.mo`), so the prediction can be
made exact rather than order-of-magnitude. Still uniform flow per ring, which the simulation will
relax.

```
mixed-mean core rise = Q/(m cp) = 8e6/(168 x 2009.66) = 23.6951 K
  -> the ACTUAL dT_core scale is 23.70 K, not the 27.8 K nominal. Both are reported for E_T_norm.

 ring  dT_out (K)   rise_J0   rise_ORNL
   1     +0.5484     38.073     38.621
   2     +3.9086     35.724     39.633     <- overtakes ring 1 under the ORNL source
   3     +4.0543     33.447     37.501
   4     +3.5013     31.241     34.742
  12     -3.1772     15.980     12.802
  14     -3.3485     12.777      9.428
  15     -4.4347     11.255      6.821     <- largest drop

max |dT_out| = 4.4347 K      RMS over rings = 2.7368 K
```

```
FALSIFIABLE PREDICTION: the hottest ring MIGRATES, ring 1 -> ring 2.
  J0:   ring 1 rises 38.07 K, ring 2 rises 35.72 K  -> hottest is ring 1
  ORNL: ring 1 rises 38.62 K, ring 2 rises 39.63 K  -> hottest is ring 2
```

That is a **topological** change, and the preregistered rule makes any change of hottest-ring
identity MATERIAL regardless of magnitude. It is also physically legible: ORNL's Fig. 4 peaks at
r = 7.0 in, on the ring-1/ring-2 boundary, whereas the J0 profile is monotone from ring 1. If the
simulation reproduces it, the migration is the single clearest signature that the two source
shapes are not interchangeable at this resolution - and it will have been predicted, not observed
and then explained.

`TOPOLOGICAL_MATERIALITY` and `THERMAL_MAGNITUDE` stay separate: a migration of a few tenths of a
kelvin between two nearly-equal rings is topologically material and thermally small, and both must
be reported.

### Phase 62c - G_TH has a geometric baseline. Stated before any result, because it changes how G_TH must be read.

`G_TH = E_T_norm / E_src` was accepted as a diagnostic without asking what value it takes when
**nothing** attenuates. It is not 1 in general, and the baseline depends on which temperature field
the norm is taken over.

Under the uniform-flow, purely-advective idealization the map from ring power to ring outlet
temperature is **linear and diagonal**:

```
dT_out(r) = [A(r)/<A>] * Q/(m_tot cp)
```

so the ring-outlet temperature field *is* the normalized source profile times the mixed-mean rise.
Consequently:

```
dT_mixed = Q/(m_tot cp) = 8e6/(168 x 2009.66) = 23.69508 K
E_T_src (ring outlet) = dT_mixed * E_src = 2.73702 K   (the ring sweep gives 2.7368 K - agrees)
E_T_nod (ring outlet) = dT_mixed * E_nod = 0.83928 K
ratio 3.2612, identical to source space BY CONSTRUCTION of the linear map
```

```
G_TH baseline, ring-outlet metric, uniform flow ....... 1.00000
G_TH baseline, 300-cell metric,  uniform flow ........ 0.59866
```

The 0.599 is the volume-weighted RMS of the axial build-up `int_0^z B dz' / int_0^H B dz'` - the
fuel is at inlet temperature at `z = 0` and only reaches its full difference at the outlet, so
averaging over the whole channel dilutes the difference by that factor and by nothing else. (A
purely linear build-up would give `sqrt(1/3) = 0.577`; the cosine source gives 0.599.)

```
A simulated G_TH below 1 on the 300-cell metric is NOT evidence of thermal attenuation
until the 0.599 geometric factor is accounted for. What measures physics - radial flow
redistribution, property coupling - is the DEPARTURE from these baselines, not the value itself.
```

This does **not** propagate the 91.4/8.6 source-space split into thermal space. It says something
narrower and checkable: *if* the flow stayed uniform and the only mechanism were advection, the
thermal decomposition would inherit the source one exactly, because the map is diagonal. The
simulation exists to test whether that idealization holds. Any measured departure is the coupled
effect, and that is the quantity of interest.

---

## Phase 63 - CASE J0 executed and fully gated. The coupled chain is strongly measurable.

### Execution

The un-ramped model does **not** initialize at full power with OpenModelica's default strategy:

```
Solving non-linear system 43325 failed at time=0
Failed to solve the initialization problem with global homotopy with equidistant step size
```

after about ten minutes of CPU. With `-noHomotopyOnFirstTry` the same executable reports
*"The initialization finished successfully without homotopy method"* in seconds and the whole
20 000 s run completes in 93 s. The failure is a property of OM's global homotopy path on this
system, not of the model: at zero power the fifteen rings are identical and the parallel momentum
balance is trivial, while at 8 MW they carry different power, hence different densities, hence a
buoyancy-driven flow split - one strongly coupled nonlinear system that the homotopy does not
traverse. **The flag is applied identically to both cases and cannot bias the A/B.**

### Gates, CASE J0

```
G1 simulation                LOG_SUCCESS, exit 0, 504 output rows, t = 20 000 s      PASS
G3 mass residual             err_mass = -4.517e-08 kg/s  (tol 1e-6)                  PASS
                             normalized -2.69e-10 of the 168 kg/s inlet flow
G4 first law                 Q_imposed  8 000 000.0000 W
                             Q_enthalpy 7 996 333.372 W
                             Q_potential    3 666.714 W
                             Q_kinetic          0.0579 W
                             Q_balance  8 000 000.1444 W
                             dE_graphite/dt  -6.90e-06 W
                             R_E = Q_imposed - Q_balance - dE_g/dt = -0.14443 W
                             relative -1.805e-08                                     PASS
G5 terminal steady state     max |dT_fuel/dt|     = 7.579e-15 K/s
                             max |dT_graphite/dt| = 1.942e-13 K/s
                             over all 300 fuel and 300 graphite nodes, last 5 output
                             points; ASSUMPTION tol 1e-6 K/s                         PASS
                             -> converged by nine orders of magnitude, not marginally
```

`Q_graphite_to_fuel_total = 6.9e-06 W` and `Q_graphite_source_total = 0` confirm the Phase H gate:
with `f_graphiteHeating = 0` the graphite carries no source and exchanges no net heat at steady
state. It is **not** isothermal with the fuel, though - `max |T_fuel - T_graphite| = 0.433 K` -
because the 2-D graphite conducts axially from the hot top toward the cooler bottom. That is
physical and small, and it is a consequence of the gate, not a result about the source shape.

### The 1-D-per-ring energy balance is exact

```
ring   Q_ring (kW)   m (kg/s)   T_out (K)   rise (K)   Q/(m cp) (K)   ratio
  1      856.924     12.6503    941.7047    33.7047      33.7070      0.9999
  5      655.106     11.7989    935.6257    27.6257      27.6280      0.9999
 10      437.022     10.7804    928.1697    20.1697      20.1719      0.9999
 15      253.392      9.8085    920.8525    12.8525      12.8548      0.9998
```

Every ring's outlet rise equals `Q_ring/(m_ring cp)` to one part in 10^4. The analytic framework
used for the predictions is therefore not an approximation of this model - it is this model,
provided the ring flows are taken from the simulation rather than assumed uniform.

### The coupled chain, quantified

```
sum m = 168.000000 kg/s exactly
ring flows            12.6503 (ring 1)  ->  9.8085 kg/s (ring 15)
flow spread           25.37 % of the mean ring flow
core.err_flowSplit    0.129489  - the same 12.95 % Phase 35 measured
```

Fitting the measured flows against ring power fraction:

```
m_ring = 8.69275 + 37.60880 * Qfrac      max residual 0.0754 kg/s
```

```
source -> temperature -> density -> hydraulic resistance -> ring mass flow
IS MEASURABLE, and it is LINEAR over this range:
a ring carrying one percentage point more of the power carries 0.376 kg/s more flow,
3.36 % of the mean ring flow.
```

This is a **self-limiting** coupling: the hotter ring is also the better-cooled one. Under uniform
flow the predicted ring-outlet RMS difference between the two sources was 2.737 K; propagating the
measured coupling forward gives 2.290 K - the flow redistribution absorbs **16 %** of the
source-shape difference before it reaches temperature. That is real attenuation, distinct from the
0.599 geometric factor of Phase 62c.

### Forward prediction of CASE ORNL from the J0-measured coupling

```
ring   m_pred    rise_pred   rise_J0    d rise
  1   12.7793     33.8480    33.7047    +0.1433
  2   12.8864     34.4462    32.1751    +2.2711   <- new maximum
  3   12.6608     33.1741    30.6515    +2.5226
 12   10.0474     14.2711    17.2274    -2.9563
 15    9.4144      8.1142    12.8525    -4.7383   <- largest drop

predicted hottest ring: ORNL ring 2  vs  J0 ring 1   -> MIGRATION
predicted max |d rise| = 4.7383 K     predicted RMS over rings = 2.2898 K
```

Recorded before the ORNL run returned, and now including the measured flow coupling rather than
assuming uniform flow.

### A defect found in this study's own verification model

`T_fuel_max` reported **908.0 K** - its start value - for the entire run, while the true maximum
computed from the 300 cell temperatures is **941.7047 K** at (ring 1, axial node 20). The
declaration was

```modelica
SI.Temperature T_fuel_max = max({max(core.channels[r].Ts_fuel) for r in 1:nR});
```

and OpenModelica 1.27 does not evaluate the nested `max()` over a component-array slice inside a
comprehension as intended. Flattening it to a two-index comprehension fixes it. **No published
number depends on the broken variable** - every maximum in this phase is computed from the cell
field directly - but the model must not ship a wrong output, so it is corrected.
`T_out_hottestRing`, `dT_hottestRing`, `dT_radial` and `hottestRingIndex` were checked against the
cell field and are correct.

### Phase 63b - Thermal-space error decomposition, using the coupling measured on CASE J0

Item 11 asked for the nodalization-vs-source split "on thermal metrics if technically feasible".
It is feasible without a finer-mesh simulation, because CASE J0 measured both halves of the map:

```
per-ring energy balance   rise = Q_ring/(m_ring cp)   exact to 1 part in 10^4 in the simulation
flow-power coupling       m/<m> = 0.77607 + 0.22393 Q/<Q>   fit residual 0.075 kg/s
```

Written mesh-independently, the ring-outlet rise is

```
rise(r) = dT_mixed * f(A(r)/<A>),      f(x) = x / (0.77607 + 0.22393 x),   f(1) = 1
dT_mixed = 23.69508 K
```

```
ASSUMPTION: the coupling measured on CASE J0 carries over to a different radial profile and to a
finer mesh. The energy balance it multiplies is not an assumption - it is exact in the simulation.
```

```
E_T_nod   continuous ORNL -> 15-ring ORNL  = 0.64943 K
E_T_src   15-ring ORNL    -> 15-ring J0    = 2.27287 K
E_T_tot   continuous ORNL -> 15-ring J0    = 2.36539 K
sqrt(nod^2 + src^2) = 2.36384 K            departure from orthogonality -0.00155 K (0.07 %),
                                            entirely from the nonlinearity of f
error-energy share:  nodalization 7.5 %,   source model 92.3 %
ratio E_T_src/E_T_nod = 3.50               (source space gave 3.26)
```

The conclusion transfers, and it is now **derived in thermal space rather than propagated from
source space**. The flow coupling slightly *raises* the source dominance (3.50 against 3.26),
because `f` is concave: it compresses the large positive excursions of the source-model error less
than it compresses the fine-scale excursions the nodalization error is made of.

### Attenuation, separated into its two mechanisms

```
ring-outlet metric, uniform flow, no coupling ..... E_T_src = 2.73705 K
ring-outlet metric, measured coupling ............ E_T_src = 2.27287 K   -> coupling absorbs 16.96 %
300-cell metric additionally carries the axial build-up factor of Phase 62c, 0.599
```

So of the two things that make a simulated `G_TH` fall below 1, only one is physics:

```
0.599  axial build-up          GEOMETRY   - present even with no coupling at all
0.830  flow redistribution     PHYSICS    - the hotter ring is also the better-cooled ring
```

Reporting `G_TH` without separating these would attribute a factor of 0.599 of pure geometry to
thermal attenuation.

### Phase 63c - Every ORNL-case number predicted, before the simulation returned

```
E_T (ring-outlet metric) ....... 2.27287 K
E_T (300-cell metric) .......... 1.36061 K   = ring value x the 0.59866 axial factor
G_TH (ring metric) ............. 0.83039     baseline 1.00000  -> pure coupling
G_TH (300-cell metric) ......... 0.49711     baseline 0.59866
   decomposition: 0.59866 geometry x 0.83039 coupling = 0.49712
max |dT_out| over rings ........ 4.7383 K at ring 15
hottest ring ................... J0 = 1, ORNL = 2   MIGRATION
mixed-mean outlet change ....... ~0, by construction (same Q, same m_flow)
```

All of it follows from CASE J0 plus the frozen source-space numbers; none of it uses the ORNL
simulation. Whatever the ORNL run returns is a test of this chain, not an input to it.

---

## Phase 64 - CASE ORNL will not initialize. A source-shape continuation gets the answer anyway.

### The blocker, and five routes tried

CASE J0 initializes and runs in 93 s. **CASE ORNL does not initialize at all** on this toolchain.
Every route was tried and recorded, because "it failed" is not a diagnosis:

```
route                                    outcome
default (symbolic + global homotopy)     FAILED after ~10 min CPU:
                                         "Solving non-linear system 43325 failed at time=0"
                                         "Failed to solve the initialization problem with global
                                          homotopy with equidistant step size"
-noHomotopyOnFirstTry                    WORKS FOR J0 (seconds). For ORNL: plain Newton fails,
                                         falls back to homotopy, still running past 24 min
-iim=numeric                             NOT A VALID VALUE in OM 1.27 - only none | symbolic
-iim=none                                initializes, but from an unphysical state
                                         (m_flow_out = -114 965 kg/s violates its own min/max)
                                         and then crawls. REJECTED as a starting point
-iif warm start from the J0 steady state BLOCKED: the model was built with outputFormat="csv",
                                         so -r=x.mat still writes CSV and -iif rejects it
                                         ("Matrix uses imaginary numbers")
-nls=newton                              header only after 200 s; no better
```

De-risking the warm start by testing it on CASE J0 first is what caught the `.mat` problem - had it
been used blind on ORNL, the failure would have looked like another initialization failure.

### The diagnosis, and the route that works

The difficulty scales with how far the radial profile departs from uniform. Interpolating the
source shape,

```
f_radial(lambda) = f_radial_J0 + lambda * (f_radial_ORNL - f_radial_J0)
```

`f_radial_ORNL[1..15]` survives into the compiled parameter set, so every `lambda` is reachable by
`-override` on the **same executable** - model identity is preserved exactly as in the A/B.

```
lambda = 0.5   INITIALIZES IN SECONDS and runs to 20 000 s
```

That confirms the diagnosis - it is profile severity, not a defect - and it yields a measured point
on the path from J0 to ORNL.

### CASE lambda = 0.5, gated

```
                  sum Q (W)        err_mass        R_E (W)          max|dTf/dt|   max|dTg/dt|
CASE J0        8 000 000.0000     -4.52e-08      -0.1444 (-1.8e-08)   7.58e-15     1.94e-13
CASE lam=0.5   8 000 000.0000     -6.85e-08      -0.1455 (-1.8e-08)   2.84e-15     8.91e-14
total power difference between the two cases: +1.68e-08 W
ALL GATES PASS
```

### Result

```
ring   dQ (kW)   Tout_J0     Tout_lam.5    dTout      m_J0      m_lam.5     dm %
  1      +6.18   941.70467   941.84126   +0.13659   12.65028   12.69006   +0.3145
  3     +45.62   938.65149   939.97111   +1.31962   12.22029   12.42590   +1.6825
  8      +2.85   931.13365   931.20022   +0.06656   11.18184   11.21084   +0.2594
 12     -35.74   925.22742   923.77800   -1.44942   10.38628   10.21336   -1.6648
 15     -49.95   920.85254   918.61351   -2.23903    9.80852    9.53598   -2.7786

max |dT_out| = 2.23903 K      RMS over rings = 1.12367 K
hottest ring: 1 in both (the migration has not happened yet at half the shape change)
```

**The mixed-mean outlet temperature is identical to six decimal places** - 931.692591 K in both
cases, `dT_core = 23.692591 K` in both. Exactly the constraint predicted: equal total power and
equal total flow fix the bulk, so bulk agreement carries no information about source fidelity.
Every rings-level quantity moves.

### The prediction, tested

Extrapolating the measured `lambda = 0.5` differences linearly to `lambda = 1`:

```
                        measured at 0.5   x2 -> lambda=1    Phase 63c prediction   agreement
max |dT_out| over rings      2.23903         4.47805              4.7383              5.5 %
RMS over rings               1.12367         2.24734              2.2729              1.1 %
```

The prediction chain - CASE J0's measured per-ring energy balance and flow-power coupling, applied
to the frozen source-space profiles - is confirmed to **1.1 % on the RMS** by an independent
simulated point that was not used to build it. The 5.5 % on the maximum is the expected signature
of the coupling's mild nonlinearity, which a two-point linear extrapolation cannot capture.

### Phase 64b - The predicted migration is OBSERVED, not extrapolated

Continuing the sweep to `lambda = 0.75`:

```
                  sum Q (W)        err_mass       R_E (W)            max|dTf/dt|   T_out (K)
lambda = 0.00   8 000 000.0000    -4.52e-08     -0.1444 (-1.8e-08)    7.58e-15    931.692591
lambda = 0.50   8 000 000.0000    -6.85e-08     -0.1455 (-1.8e-08)    2.84e-15    931.692591
lambda = 0.75   8 000 000.0000    -7.12e-08     -0.1462 (-1.8e-08)    9.47e-16    931.692591
ALL GATES PASS AT EVERY POINT
```

**`T_out` is 931.692591 K at all three - identical to six decimal places.** The mixed-mean outlet
is fixed by equal power and equal flow and says nothing whatever about the source shape. That is
the constraint the instructions warned about, now demonstrated rather than argued.

```
ring     T@0        T@0.5      T@0.75    T@1 (quad)   dT@1
  1   941.70467  941.84126  941.90655   941.96983   +0.26516
  2   940.17509  941.41169  942.01627   942.61170   +2.43661   <- overtakes ring 1
  3   938.65149  939.97111  940.61561   941.24990   +2.59841
 12   925.22742  923.77800  923.03566   922.28155   -2.94587
 15   920.85254  918.61351  917.44894   916.25433   -4.59821
```

```
MEASURED hottest ring:  lambda = 0.00 -> ring 1   (941.70467 vs 940.17509)
                        lambda = 0.50 -> ring 1   (941.84126 vs 941.41169)
                        lambda = 0.75 -> RING 2   (941.90655 vs 942.01627)
```

The hottest-ring migration predicted in Phase 62b from the source shape alone, and again in Phase 63
with the measured flow coupling, **happens in the simulation between lambda = 0.5 and 0.75**. It is
observed, not inferred.

Extrapolating to `lambda = 1` with the exact quadratic through the three simulated points:

```
                          extrapolated   Phase 63c prediction   agreement
max |dT_out| over rings      4.59821 K          4.7383 K          3.0 %
RMS over rings               2.26753 K          2.2729 K          0.24 %
ring 2 minus ring 1          +0.64187 K
```

A prediction built entirely from CASE J0 and the frozen source-space profiles, tested against three
simulated points that were not used to build it, and correct to **0.24 % on the RMS**.

### Phase 64c - Where the initialization actually breaks

Continuing the sweep bounds the toolchain limit rather than just reporting it:

```
lambda    initialization                                   run
0.00      succeeds in seconds (plain Newton)               complete, gated
0.50      succeeds in seconds (plain Newton)               complete, gated
0.75      succeeds in seconds (plain Newton)               complete, gated
0.85      plain Newton FAILS -> falls back to homotopy     no data
0.90      plain Newton FAILS -> falls back to homotopy     killed at 900 s, header only
1.00      plain Newton FAILS -> homotopy ran 28 minutes    no data
```

```
THE INITIALIZATION THRESHOLD LIES BETWEEN lambda = 0.75 AND lambda = 0.85
```

That is a quantitative statement about the solver, not a vague "it did not converge". The
transition is exactly where the plain Newton stops converging from a uniform-temperature guess; the
homotopy fallback does not recover it in any time budget tried, up to 28 minutes.

`RESOURCE / TOOLCHAIN LIMITATION`, not a model defect: the model equations are identical at every
`lambda`, and three of the six points solve in seconds.

---

## Phase 65 - FINAL. Source space and thermal space, separated.

All quantities at `lambda = 1` come from the exact quadratic through the three **simulated and
gated** points `lambda = 0, 0.5, 0.75`. Nothing is fitted; the polynomial is determined.

### 15 x 20 local field

```
fuel     volume-weighted RMS dT = 1.392832 K      (Phase 63c predicted 1.36068 K, 2.4 %)
         max |dT| = 4.598206 K at (ring 15, axial node 20)
         max positive +2.598410 K   max negative -4.598206 K
graphite volume-weighted RMS dT = 1.388459 K      max |dT| = 4.549621 K
```

### Peak migration, in the cell field

```
max fuel T      J0  941.70467 K at (ring 1, axial 20)
              ORNL  942.61170 K at (ring 2, axial 20)   +0.90703 K   PEAK CELL MIGRATED
max graphite T  J0  941.35043 K at (ring 1, axial 20)
              ORNL  942.24807 K at (ring 2, axial 20)   +0.89764 K
```

### Global versus local, against the preregistered bands

```
quantity                        J0            ORNL          delta      class
core outlet T (mixed mean)  931.692591    931.692591     +0.000000    NEGLIGIBLE  (identical)
fuel dT across core          23.692591     23.692591     +0.000000    NEGLIGIBLE  (identical)
volume-mean fuel T          920.176879    919.977956     -0.198923    SMALL
volume-mean graphite T      920.176874    919.977951     -0.198923    SMALL
maximum fuel T              941.70467     942.61170      +0.90703     SMALL (magnitude)
                                                                       MATERIAL (topological)
hottest ring                     1             2                      MATERIAL, observed at 0.75
max |dT| over the 300 cells                                4.598206   MATERIAL
ring-outlet spread                                      up to 4.6 K   MATERIAL
```

`TOPOLOGICAL_MATERIALITY` and `THERMAL_MAGNITUDE` are reported separately, as required: the hottest
ring changes identity (material by the preregistered rule) while the hotspot temperature itself
moves only **+0.907 K** (SMALL). Both are true and neither is the whole story.

### THERMAL_ATTENUATION_DIAGNOSTIC

```
metric              E_T (K)     E_T_norm    G_TH      baseline with NO attenuation
ring outlet         2.267529    0.095707    0.828554  1.00000
300 cells           1.392832    0.058788    0.508940  0.59866
(E_T_norm uses dT_scale = 23.69259 K, the actual dT_core; on the preregistered 27.8 K
 nominal the cell-metric numbers are E_T_norm 0.050102 and G_TH 0.433745)
```

The two factors, separated and both measured:

```
measured axial dilution  E_T(cell)/E_T(ring) = 0.61425    geometric prediction 0.59866   (2.6 %)
measured flow coupling   G_TH(ring)          = 0.82855    predicted 0.83039              (0.22 %)
```

**Only the second is physics.** Quoting `G_TH = 0.509` as "thermal attenuation" would credit a
factor of 0.614 of pure axial geometry to a physical mechanism. The physical attenuation is
**17 %**, and it is the self-limiting flow redistribution: the ring that receives more power also
draws more flow.

### Verdicts, separated

```
SOURCE_SPACE_VERDICT = SOURCE_MODEL_ERROR_DOMINANT          (frozen, unchanged)
  E_nod 0.03542   E_src 0.11551   E_tot 0.12082   ratio 3.26
  error-energy share: nodalization 8.6 %, source model 91.4 %

THERMAL_SPACE_VERDICT = BULK_ATTENUATED_LOCAL_EFFECT_PERSISTS
  bulk    core outlet and core dT identical to 1e-6 K - and that is FORCED by equal power and
          equal flow, so it is not evidence of source equivalence
  local   max |dT| 4.60 K, ring-outlet RMS 2.27 K, cell RMS 1.39 K, hottest ring migrates 1 -> 2,
          hotspot +0.91 K
  chain   source -> temperature -> density -> resistance -> ring flow is measurable and linear:
          +1 percentage point of power draws +0.376 kg/s, and absorbs 17 % of the source difference
```

This is the CASE C the instructions singled out as the one to be careful with: **bulk agreement is
perfect and carries no information; the local field is where the two source models differ.**

### Bounded by the mesh

```
CENTRAL_THIMBLE_THERMAL_EFFECT = NOT RESOLVED BY THIS MESH   (unchanged from Phase C/D)
```

ORNL's Fig. 4 peaks at r = 7.0 in, inside ring 1, and its thimble depression occupies 21 % of that
ring's area. The strongest permitted statement remains
`J0_GROSS_PROFILE_DIFFERS_MATERIALLY_AT_15_RING_RESOLUTION` - and the migration to ring 2 is
precisely the coarse footprint of a peak the mesh cannot resolve.

### PRODUCTION CHANGE

```
NOT MADE. Nothing in production was modified at any point in Phases 61-65.
```

The finding does not license replacing `f_radial`: the production 2-D nodalization serves the paper
benchmark, whose radial tabulation is unpublished, and substituting a 1962 figure would swap one
unsourced profile for a differently-sourced one and silently change the benchmark. What is now
established is that the choice **matters locally** - which is the input a decision needs, not the
decision.

---

## Phase 66 (user "Phase 48") - Inner-region radial mesh convergence. Source space first.

### A prerequisite that turned out to be recoverable: the continuous parent of the J0 profile

Mesh convergence needs each profile as a **function**, not as fifteen numbers, or the comparison
across meshes is between two different profiles rather than one profile at two resolutions. The
ORNL side already had that (the digitized Fig. 4). The production side did not - `Core2D` gives
fifteen tabulated values and calls them "a J0 shape with a 25 % reflector saving".

Fitting a Bessel `J0` with one free parameter, the extrapolated radius, recovers it exactly:

```
f_radial_J0(r)  proportional to  J0(2.404826 * r / 34.684 in)
extrapolated radius 34.684 in   ->  saving (Re - R)/R = 24.99 %
reproduces all fifteen published Core2D values with RMS 3.2e-05, max |diff| 5e-05
```

The docstring's "25 % reflector saving" is therefore literal, and the production profile is now
projectable onto any mesh. `DERIVED, exact to 5e-05` - not an assumption.

### Source projection error against mesh family and resolution

`E_nod` is the volume-weighted L2 distance between the continuous profile and its piecewise-constant
ring projection, both normalized to unit volume mean - the same norm and the same measure as
Phase 61.

```
profile  mesh          N    ring1 outer   E_nod     peak ring   peak/avg   rings inside r=7in
ORNL     equal-area   15      7.165 in   0.03542        2        1.6726          0
ORNL     equal-area   30      5.066      0.01845        3        1.6889          1
ORNL     equal-area   60      3.583      0.00881        4        1.6987          3
ORNL     equal-area  120      2.533      0.00470        8        1.6997          7
ORNL     equal-dr     15      1.850      0.04303        4        1.6944          3
ORNL     equal-dr     30      0.925      0.02221        8        1.6996          7
ORNL     equal-dr     60      0.463      0.01132       16        1.6997         15
J0       equal-area   15      7.165      0.02359        1        1.6067          -
J0       equal-area   60      3.583      0.00590        1        1.6446          -
J0       equal-dr     15      1.850      0.03048        1        1.6539          -
J0       equal-dr     60      0.463      0.00763        1        1.6571          -
continuous limits                                                J0 1.6573, ORNL 1.6997
```

`E_nod` halves as `N` doubles on every family - clean first-order convergence for a
piecewise-constant projection, which is the expected order and confirms the projection is being
computed correctly.

### Two findings that change how the mesh question must be posed

**1. Equal-area refinement does not refine where the structure is.** Equal-area rings cluster at
large radius. Going from 15 to 120 equal-area rings still leaves only 7 rings inside r = 7 in,
while 15 equal-**dr** rings already put 3 there. For a feature at r < 7 in, adding equal-area rings
is close to the least efficient thing one can do.

**2. A single error norm does not decide which mesh is better.** Equal-dr at N=15 is **worse** in
whole-domain L2 (0.04303 against 0.03542) because it under-resolves the outer region where most of
the volume lives, and **better** where the structure is - it keeps 99.7 % of the ORNL peak-to-average
against 98.4 %. Both statements are true of the same pair of meshes.

### Does the central depression resolve?

```
equal-area, N = 15   ring 1 spans 0 .. 7.165 in
                     the dip at 2.5 in and the peak at 7.0 in are in the SAME ring
                     -> f_radial ring1 1.6299, ring2 1.6726: a 2.6 % artefact of averaging

equal-dr,  N = 15    ring 1 spans 0 .. 1.850 in, ring 4 spans 5.55 .. 7.40 in and holds the peak
                     f_radial  1.5195, 1.5262, 1.6379, 1.6944 across rings 1-4
                     -> a 10.3 % rise from the depression to the peak, RESOLVED
```

```
CENTRAL_THIMBLE_EFFECT, SOURCE SPACE = RESOLVED at equal-dr N=15
                                        NOT RESOLVED at equal-area N=15 (the production mesh)
```

The thermal half of that question needs the run.

### Why a rebuild is required, and what was checked before concluding so

The radial profile can be changed on the existing executable - `f_radial_ORNL[1..15]` are settable
runtime parameters, which is how the lambda continuation of Phase 64 was done. The **mesh** cannot:
the generated code contains

```c
core.channels[1].nParallel = 76.0;
```

as a folded literal in the bound-parameter section, not as a reference to the overridable
`core.nChannels[1]`. Overriding `core.nChannels` would therefore change the source weighting
without changing the geometry it must stay consistent with - a half-changed model that would still
run and would give a plausible wrong answer. That is exactly the failure mode this study exists to
avoid, so the mesh study is done by rebuilding.

`MSRE.Verification.BaseClasses.Core2D_EqualDr` and
`MSRE.Verification.Core2D_RadialSourceSensitivity_EqualDr` are verification-only; no production
nodalization was touched. The build uses `outputFormat="mat"`, which also secures the
warm-start/continuation path that the CSV build blocked in Phase 64.

### Phase 66b - The equal-dr result, predicted before its build finished

The flow-power coupling measured on the equal-area CASE J0 can be written **per channel**, which
makes it mesh-independent:

```
m_ring = 8.69275 + 37.6088 Qfrac,  Qfrac = f/15,  76 channels per ring
  -> per channel   w(f) = (168/1140) * (0.77613 + 0.22387 f)
  -> ring flow     m_k  = n_k w(f_k)
  -> ring rise     rise_k = Q_tot f_k / (sum_j n_j f_j * w(f_k) * cp)      depends only on f_k
```

The total-flow constraint closes exactly on any mesh: `sum n_k w(f_k) = 168.000 kg/s` for all three
cases below, because the volume-weighted mean of `f` is 1 by construction.

Self-check on the mesh it was fitted to: it predicts ring 1 of the equal-area J0 case at
941.5190 K against the simulated **941.70467 K** - 0.19 K, or 0.55 % of that ring's rise. That is
the linearization residual and it bounds how much of the equal-dr prediction below to trust.

```
PREDICTED, equal-dr mesh                       measured/extrapolated, equal-area mesh
max |dT_out| over rings   4.0220 K             4.5982 K
RMS over rings            2.0803 K             2.2675 K
hottest ring J0 -> ORNL   1 -> 4               1 -> 2
peak T_out change         +0.5621 K            +0.9070 K
```

The interesting line is the third. On the equal-area mesh the hotspot moves to ring 2, whose volume
centroid is at **8.73 in**. On the equal-dr mesh it moves to ring 4, spanning 5.55 to 7.40 in with
centroid **6.49 in** - which brackets the true ORNL peak at **7.0 in**. The coarse mesh gets the
*existence* of the migration right and puts it in the wrong place; the finer inner mesh puts it
where the source peak actually is.

If the run reproduces this, the verdict is `MESH_SENSITIVE` on magnitude and location, with the
migration itself robust across both meshes.
