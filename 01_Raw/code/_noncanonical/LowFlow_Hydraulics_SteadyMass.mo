within MSRE.Verification;
model Core2D_RadialSourceSensitivity
  "A/B on the 2-D radial SOURCE SHAPE alone: production J0 against the ORNL-TM-0378 Fig. 4 profile. NO production change"
  extends MSRE.Verification.Core2D_TH_ZeroPower(
    Q_core=8e6,
    nodalization(f_radial=if useORNLradialShape then f_radial_ORNL else f_radial_J0));

  /* =====================================================================================
     PURPOSE
     ORNL0378 Phase 60 found the production radial source shape and ORNL-TM-0378 Fig. 4 to be
     a BENCHMARK_DIFFERENCE. This model asks whether that difference is thermally material.

     THE ONLY INTENDED DIFFERENCE between the two cases is the radial source shape. Everything
     else is inherited unchanged from Core2D_TH_ZeroPower: total power, axial profile,
     geometry, mass flow, fuel properties, heat-transfer closure, graphite-heating setting,
     inlet temperature, boundary conditions and nodalization.

     The unresolved ORNL absolute specific power does NOT enter. Both cases impose the same
     Q_core and differ only in how a fixed total is allocated across rings; corePowerShape
     renormalizes to sum(SF) = 1 either way, so any common scale on f_radial cancels exactly.
     ===================================================================================== */

  parameter Boolean useORNLradialShape=false
    "=false CASE J0 (production, unchanged). =true CASE ORNL (Fig. 4 on the same rings)";

  parameter Real f_radial_J0[nodalization.nRings]={1.6067,1.5076,1.4115,1.3184,1.2283,1.1410,
      1.0565,0.9748,0.8958,0.8194,0.7456,0.6743,0.6055,0.5392,0.4751}
    "VERBATIM from MSRE.Data.Nodalization.Core2D. Its own documentation calls it an ASSUMPTION:
     a J0 shape with a 25 % reflector saving, standing in for an unpublished Serpent tabulation";

  parameter Real f_radial_ORNL[nodalization.nRings]={1.6299,1.6726,1.5826,1.4662,1.3439,1.2198,
      1.1034,0.9855,0.8711,0.7568,0.6422,0.5403,0.5000,0.3979,0.2878}
    "FIGURE_DERIVED. ORNL-TM-0378 Fig. 4 fuel fission density, machine-digitized by
     tools/digitize_ornl0378.py, VOLUME-averaged over each of these 15 rings and then divided
     by the ring mean so that it carries the same normalization convention as f_radial_J0.
     Because Core2D gives every ring the same channel count, the rings are equal-flow-area
     annuli spanning r = 27.75*sqrt((k-1)/15) .. 27.75*sqrt(k/15) inches, and the average is
     the area-weighted integral (1/V_k) int A(r) 2 pi r dr - NOT a point sample and NOT an
     arithmetic mean over radius. R = 27.75 in is the Table 3 main-core outer radius.
     NO fitted scaling: dividing by the mean is a normalization convention that corePowerShape
     would undo anyway";

  /* ---------------- Phase B: the discrete power identity ------------------------------- */
  final parameter SIadd.NonDim SFs_ring[nodalization.nRings]={sum({SF_core[(r - 1)*
      nodalization.nAxial + k] for k in 1:nodalization.nAxial}) for r in 1:nodalization.nRings}
    "Fraction of the total fission source allocated to each ring";
  final parameter SIadd.NonDim SF_ringSum=sum(SFs_ring) "Must be 1: the plena carry none";
  final parameter SI.Power Qs_ring[nodalization.nRings]={Q_core*SFs_ring[r] for r in 1:
      nodalization.nRings} "Fission power in each ring";
  final parameter SI.Power Q_fromCells=sum({Q_core*SF_core[i] for i in 1:nodalization.nV_core})
    "sum(q''' V) rebuilt from the cell weights; must equal Q_core";
  final parameter SI.Power err_powerIdentity=Q_fromCells - Q_core;

  final parameter SIadd.NonDim radialP2A=max(nodalization.f_radial)/(sum(nodalization.f_radial)
      /nodalization.nRings) "Peak-to-average of whichever profile is active";

  /* ---------------- Phase E/F: per-ring thermal and hydraulic state --------------------- */
  final parameter Integer nR=nodalization.nRings;
  SI.MassFlowRate m_flows[nR]={core.channels[r].m_flow_ring for r in 1:nR};
  SIadd.NonDim fs_flow[nR]={m_flows[r]/noEvent(max(abs(sum(m_flows)), 1e-9)) for r in 1:nR}
    "Fraction of the channel flow carried by each ring";
  SI.Temperature Ts_out_ring[nR]={core.channels[r].Ts_fuel[nodalization.nAxial] for r in 1:nR}
    "Fuel salt temperature leaving each ring";
  SI.Temperature Ts_ring_mean[nR]={sum(core.channels[r].Ts_fuel)/nodalization.nAxial for r in 1:nR};

  SI.Temperature T_fuel_max=max({core.channels[r].Ts_fuel[k] for r in 1:nR, k in 1:
      nodalization.nAxial})
    "Hottest fuel cell anywhere in the core.
     DEFECT FIXED: this was written as max({max(core.channels[r].Ts_fuel) for r in 1:nR}),
     which OpenModelica 1.27 evaluated to the START value 908 K for the whole run instead of
     the true maximum of 941.70 K. The nested max() over a component-array slice inside a
     comprehension does not resolve as intended. A flat two-index comprehension does.
     The published Phase 63 numbers do NOT depend on this variable - the maximum was computed
     from the 300 cell temperatures directly - but the model must not ship a wrong output";
  SI.Temperature T_fuel_mean=sum({core.channels[r].Ts_fuel[k]*core.channels[r].Vs[k] for r in 1:
      nR, k in 1:nodalization.nAxial})/sum({core.channels[r].Vs[k] for r in 1:nR, k in 1:
      nodalization.nAxial})
    "Volume-averaged fuel temperature over the channel cells. Flattened to a two-index
     comprehension for the same reason as T_fuel_max above; this one did evaluate correctly,
     but the two should not differ in form";
  SI.Temperature T_out_hottestRing=max(Ts_out_ring) "Hottest ring outlet temperature";
  SI.TemperatureDifference dT_radial=max(Ts_out_ring) - min(Ts_out_ring)
    "Radial spread of ring outlet temperature - the thermal signature of the radial source";
  SI.TemperatureDifference dT_hottestRing=max(Ts_out_ring) - T_in
    "Temperature rise of the hottest ring";

  /* Hottest-ring identity, as a number so that a change is visible in the result file. */
  Real hottestRingIndex "Index of the ring with the highest outlet temperature";

equation
  hottestRingIndex = sum({(if Ts_out_ring[r] >= max(Ts_out_ring) - 1e-9 then r else 0) for r in 1:nR});

  when terminal() then
    assert(abs(err_powerIdentity) < 1e-6*Q_core, "Discrete power identity failed: the cell
weights sum to " + String(Q_fromCells) + " W against an imposed " + String(Q_core) + " W.
Both cases must impose EXACTLY the same total, or the comparison measures the wrong thing.",
      AssertionLevel.error);

    assert(abs(SF_ringSum - 1) < 1e-10, "The ring source fractions sum to " + String(SF_ringSum)
       + " instead of 1.", AssertionLevel.error);
  end when;

  annotation (
    experiment(StopTime=20000, Tolerance=1e-6),
    Documentation(info="<html>
<h4>SCOPE</h4>
<p><b>Verification only.</b> No production file is modified. <code>f_radial</code> is overridden
here through a parameter modification on the nodalization record, which is exactly what that
record's own documentation invites (<q>Replace them if the Serpent tabulation becomes
available</q>) - and it is done in a test model, not in <code>Core2D</code>.</p>

<h4>Why the absolute-normalization gap does not block this</h4>
<p><code>corePowerShape</code> divides by <code>sum(P)</code>, so <code>sum(SF) = 1</code> for any
radial profile and <code>sum(q''' V) = Q_core</code> identically. The two cases therefore impose
the same total power to machine precision and differ ONLY in radial allocation. The unresolved
ORNL absolute <code>P_f</code> is not used and is not needed.</p>

<h4>REQUIRED RUNTIME FLAG: -noHomotopyOnFirstTry</h4>
<p>On OpenModelica 1.27 this model does <b>not</b> initialize with the default strategy:</p>
<pre>
Solving non-linear system 43325 failed at time=0
Failed to solve the initialization problem with global homotopy with equidistant step size
</pre>
<p>after about ten minutes of CPU. Running the same executable with
<code>-noHomotopyOnFirstTry</code> initializes in seconds
(<code>The initialization finished successfully without homotopy method</code>). The failure is
a property of OM's global homotopy on this system, not of the model: at zero power the fifteen
rings are identical and the parallel momentum balance is trivial, while at 8 MW they carry
different power and therefore different densities, so the flow split makes the fifteen paths one
strongly coupled nonlinear system that the homotopy path does not traverse successfully.</p>
<p>The flag is applied identically to both cases of the A/B, so it cannot bias the comparison.</p>

<h4>What the ring mesh can and cannot show</h4>
<p>ORNL's Fig. 4 peaks at r = 7.0 in, which lands inside <b>ring 1</b> (0 .. 7.165 in), and its
control-rod-thimble depression lies entirely inside that same ring, occupying 21 % of its area.
Volume averaging therefore reduces a 10.6 % central dip in the continuous curve to a 2.55 %
difference between ring 1 and ring 2. This A/B measures the <b>gross radial redistribution</b>,
not the depression - see the Phase D result recorded in docs/PHASE_LOG.md.</p>
</html>"));
end Core2D_RadialSourceSensitivity;
