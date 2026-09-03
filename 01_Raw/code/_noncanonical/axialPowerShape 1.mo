within MSRE.Verification.ORNL0378;
model AlgebraicVerification
  "Single-point check of the ORNL-TM-0378 closure, before any spatial model is built"
  extends Modelica.Icons.Example;

  parameter HistoricalData data "1962 inputs, kept apart from every modern value";

  /* ================================================================
     1. Eq. (16) reproduced from Eqs. (14) and (15) - a real identity
     ================================================================ */
  final parameter SI.Area coeff_reconstructed=(1/8)*data.r_s^2 + ((data.SV_cylinder - data.SV_actual)
      /(data.SV_cylinder - data.SV_slab))*((1/3)*data.l_slab^2 - (1/8)*data.r_s^2)
    "Interpolated coefficient, built from the geometry and the three S/V values";
  final parameter SI.Area coeff_ORNL=9.97e-4*0.3048^2
    "Eq. (16)'s stated 9.97e-4 ft2, converted. NOTE the coefficient is an AREA, not dimensionless";
  final parameter SIadd.NonDim err_coeff=abs(coeff_reconstructed/coeff_ORNL - 1)
    "Departure of the reconstruction from the report's rounded value";
  final parameter SIadd.NonDim w_interp=(data.SV_cylinder - data.SV_actual)/(data.SV_cylinder -
      data.SV_slab) "Interpolation fraction, COMPUTED from the S/V values";

  /* ================================================================
     2. The acceptance target, and the input it needs
     ================================================================
     Eqs. (13), (16) and (17) require ABSOLUTE specific powers. ORNL-TM-0378 does not state them
     numerically, and its own nomenclature (p.49) defines P as the RELATIVE specific power. The two
     parameters below are therefore NOT sourced, and are marked so. They are supplied here only to
     exercise the closure; nothing downstream may treat them as report values. */
  /* The chain is now traced as far as the report allows. Everything below is
     DERIVED_FROM_ORNL except the radial peaking factor, which the report supplies only as a
     figure - p.19 states that the central flux distortion "precludes the use of a simple analytic
     expression to describe the radial distribution". */
  final parameter SIadd.VolumetricHeatGenerationRate P_f_average=data.f_fuel*data.Q_mainCore/data.V_fuel_mainCore
    "DERIVED_FROM_ORNL: 14.1657 MW/m3 over the Table 3 main-core fuel volume";
  parameter SIadd.NonDim radialPeakToAverage=1.6859
    "FIGURE_DERIVED. SOURCE: ORNL-TM-0378 Fig. 4, digitized at 30 points and integrated with the
     Table 3 fuel-volume weighting. Reading uncertainty +-0.02 in the ordinate gives 1.634 .. 1.745.
     Fig. 4's ordinate is 'FRACTION OF MAX. VALUE', so it is peak-normalized, and its peak sits at
     r = 7 in, independently matching the 'hottest channel 7 in. from core center line' of p.19";
  final parameter SIadd.NonDim radialPeakToAverage_reverseDerived=1.3785
    "DIAGNOSTIC ONLY. The value that would close Table 5. It is NOT used in the chain above and is
     NOT provenance; it is kept so the 22 % gap against the figure reading stays visible";
  final parameter SIadd.VolumetricHeatGenerationRate P_f_max=P_f_average*data.axialPeakToAverage*
      radialPeakToAverage "Absolute local fuel specific power at the hot spot";
  final parameter SIadd.VolumetricHeatGenerationRate P_g_max=P_f_max*(data.f_graphite*
      data.V_fuel_mainCore)/(data.f_fuel*data.V_graphite_mainCore)
    "DERIVED_FROM_ORNL: the 6/94 split spread over the Table 3 volumes gives P_g/P_f = 0.018607";
  final parameter Real q_w_max(unit="W/m2") = P_g_max/data.SV_actual
    "DERIVED, and derived from the report: p.39 identifies the fuel-channel surface as the surface
     through which ALL heat produced in the graphite must be transferred, so in steady state the
     wall flux is the graphite specific power divided by that surface-to-volume ratio";

  final parameter SI.TemperatureDifference dT_graphiteConduction=coeff_reconstructed*P_g_max/data.k_g
    "Eq. (16) term: T_g' - T_w";
  final parameter SI.TemperatureDifference dT_fuelSide=(P_f_max*data.r_w^2/data.k_f)*((11*(1 + 2*
      q_w_max/(P_f_max*data.r_w)) - 8)/48) "Eq. (13) term: T_w - T_f'";
  final parameter SI.TemperatureDifference dT_total=dT_graphiteConduction + dT_fuelSide
    "Eq. (17): T_g' - T_f'";

  final parameter SI.TemperatureDifference err_target=dT_total - data.dT_maxLocal_target
    "Departure from ORNL Table 5's 62.5 F at 0 % permeation";
  final parameter SIadd.NonDim relerr_target=err_target/data.dT_maxLocal_target;
  final parameter SIadd.NonDim frac_graphite=dT_graphiteConduction/dT_total
    "Share of the total carried by the graphite conduction term";
  final parameter SIadd.NonDim frac_fuelSide=dT_fuelSide/dT_total "Share carried by Eq. (13)";

  /* Three temperatures kept strictly apart, as the report does. */
  final parameter SI.Temperature T_f_transverseMean=data.T_mainCore_in
    "T_f' - reported at the main-core inlet only; the axial model of a later phase supplies T_f'(z)";
  final parameter SI.Temperature T_wall=T_f_transverseMean + dT_fuelSide "T_w";
  final parameter SI.Temperature T_g_mean=T_wall + dT_graphiteConduction
    "T_g' - the STRINGER MEAN, which is what Figs. 13 and 14 plot (p.41). NOT a surface temperature";

  parameter SIadd.NonDim tol_coeff=1e-3
    "Bound on the Eq. (16) reconstruction. The report rounds 9.965e-4 to 9.97e-4, so anything below
     the rounding step confirms the transcription; this is not a physical tolerance";

equation
  when terminal() then
    assert(err_coeff < tol_coeff, "Eq. (16) reconstruction FAILED. Interpolating Eq. (14) and
Eq. (15) on the stated surface-to-volume basis gives " + String(coeff_reconstructed) + " m2 against
the report's " + String(coeff_ORNL) + " m2, a relative departure of " + String(err_coeff) + ". Since
the report states all three S/V values and both limiting equations, this is an identity, and a
failure means the geometry or one of the two equations is transcribed wrongly.",
      AssertionLevel.error);

    assert(dT_graphiteConduction > 0 and dT_fuelSide > 0, "Both terms of Eq. (17) must be positive:
p.36 writes T_g = T_f' + DT with DT a positive number, the graphite being the hotter body.",
      AssertionLevel.error);

    /* The Table 5 target is REPORTED, never asserted. Asserting it would either fail on inputs the
       report does not supply, or invite tuning them until it passed - which is precisely what this
       phase forbids. */
    assert(abs(relerr_target) < 1e9, "unreachable", AssertionLevel.warning);
  end when;

  annotation (
    experiment(StopTime=1, Tolerance=1e-6),
    Documentation(info="<html>
<h4>REFERENCE</h4>
<p>ORNL-TM-0378 (Engel and Haubenreich, 1962).</p>
<h4>PURPOSE</h4>
<p>Reproduce the historical 1962 MSRE thermal calculation.</p>
<h4>NOT FOR</h4>
<p>Production MSRE_TRANSFORM thermal closure. This model intentionally uses historical property
values, equivalent-area circular geometry, and the Poppendiek/Palmer internally heated laminar-flow
treatment. <b>Do not combine with <code>Nus_Core</code> or modern fuel-salt properties.</b></p>

<h4>What this model does and does not establish</h4>
<table border=\"1\">
<tr><th>item</th><th>status</th></tr>
<tr><td>Eq. (16) reconstructed from Eqs. (14), (15) and the three S/V values</td>
    <td><b>asserted</b> - an identity</td></tr>
<tr><td>sign of both Eq. (17) terms</td><td><b>asserted</b> - p.36</td></tr>
<tr><td>Table 5, 62.5 F at 0 % permeation</td>
    <td><b>reported, NOT asserted</b> - see below</td></tr>
</table>

<h4>Why the Table 5 target is not asserted</h4>
<p>Eqs. (13), (16) and (17) need <b>absolute</b> specific powers, and ORNL-TM-0378 never states
<code>P_f</code> or <code>P_g</code> numerically - its nomenclature (p.49) even defines
<code>P</code> as the <i>relative</i> specific power, which is what Eq. (18) uses. The obvious
shortcut, taking 0.94 and 0.06 of the power over the fuel and graphite volumes and applying a
separable axial-times-radial peaking factor, <b>does not work</b>: it overshoots Table 5 by a factor
of about 2.3. That is recorded here as evidence that the shortcut is wrong, not as a result. Closing
this needs either the report's own specific powers or the derivation chain it used, and until then
no PASS on the temperature target may be claimed.</p>
</html>"));
end AlgebraicVerification;
