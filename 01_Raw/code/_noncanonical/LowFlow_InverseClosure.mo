within MSRE.Verification;
model Core2D_RadialSourceSensitivity_EqualDr
  "The same 2-D radial source A/B on an EQUAL-dr mesh that resolves the central depression"
  extends MSRE.Verification.Core2D_TH_ZeroPower(
    Q_core=8e6,
    redeclare MSRE.Verification.BaseClasses.Core2D_EqualDr nodalization(geometry=geometry,
        f_radial=if useORNLradialShape then f_radial_ORNL else f_radial_J0));

  /* =====================================================================================
     Companion to MSRE.Verification.Core2D_RadialSourceSensitivity. Everything is inherited
     unchanged except the radial MESH: 15 rings of equal radial thickness rather than equal
     area, with the channel count following the annulus area so the total is still 1140.

     Two variables, and only two, differ from the baseline model: which mesh the rings sit on,
     and which of the two profiles is projected onto it. Total power, axial profile, geometry,
     mass flow, properties, closure, graphite gate, inlet temperature and boundary conditions
     are all inherited.
     ===================================================================================== */

  parameter Boolean useORNLradialShape=false
    "=false CASE J0 (the production profile). =true CASE ORNL (Fig. 4)";

  parameter Real f_radial_J0[nodalization.nRings]={1.6539,1.6404,1.6133,1.5733,1.5206,1.4559,
      1.3801,1.2941,1.1989,1.0957,0.9857,0.8702,0.7506,0.6284,0.5050}
    "The SAME continuous profile Core2D tabulates, J0(2.404826 r/34.684 in), volume-averaged
     over the equal-dr rings. Not a different profile - the same one at a different resolution";

  parameter Real f_radial_ORNL[nodalization.nRings]={1.5195,1.5262,1.6379,1.6944,1.6824,1.6294,
      1.5472,1.4337,1.3016,1.1575,1.0014,0.8332,0.6500,0.5098,0.3393}
    "ORNL-TM-0378 Fig. 4, machine-digitized, volume-averaged over the same rings. The central
     depression is visible here and is not on the equal-area mesh: 1.5195 at r < 1.85 in rising
     to the 1.6944 peak on ring 4, which contains r = 7.0 in";

  final parameter Integer nR=nodalization.nRings;
  SI.MassFlowRate m_flows[nR]={core.channels[r].m_flow_ring for r in 1:nR};
  SI.Temperature Ts_out_ring[nR]={core.channels[r].Ts_fuel[nodalization.nAxial] for r in 1:nR};
  SI.Temperature T_fuel_max=max({core.channels[r].Ts_fuel[k] for r in 1:nR, k in 1:nodalization.nAxial});
  SI.Temperature T_out_hottestRing=max(Ts_out_ring);
  SI.TemperatureDifference dT_radial=max(Ts_out_ring) - min(Ts_out_ring);
  SI.TemperatureDifference dT_hottestRing=max(Ts_out_ring) - T_in;
  Real hottestRingIndex;

equation
  hottestRingIndex = sum({(if Ts_out_ring[r] >= max(Ts_out_ring) - 1e-9 then r else 0) for r in 1:nR});

  annotation (
    experiment(StopTime=20000, Tolerance=1e-6),
    Documentation(info="<html>
<h4>Why a rebuild was unavoidable</h4>
<p>The ring boundaries are set by <code>nChannels</code>, and that array reaches the compiled model
as a folded literal - the generated code contains
<code>core.channels[1].nParallel = 76.0</code> as a constant, not as a reference to an overridable
parameter. So unlike the radial profile, which <code>-override</code> can change on the existing
executable, <b>the mesh cannot be changed at run time</b>. That is why this is a separate model and
a separate build rather than another override.</p>

<h4>Required runtime flag</h4>
<p><code>-noHomotopyOnFirstTry</code>, for the same reason as the baseline model.</p>

<h4>What this can and cannot settle</h4>
<p>It settles whether the answer depends on where the ring boundaries are placed, at fixed ring
count and fixed channel count. It does <b>not</b> by itself establish mesh convergence - that needs
a third mesh at higher ring count, and the equal-dr result is one point of that study, not the
whole of it.</p>
</html>"));
end Core2D_RadialSourceSensitivity_EqualDr;
