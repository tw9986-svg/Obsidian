within MSRE.Verification.ORNL0378;
model AbsoluteNormalizationAudit
  "Two INDEPENDENT source-internal routes to the peak fuel specific power, against the value Table 5 requires"
  extends Modelica.Icons.Example;

  parameter HistoricalData data;
  constant Real IN=0.0254 "m per in";
  constant Real GAL=0.00378541 "m3 per US gallon";
  constant Real FT_S=0.3048 "m per ft";

  /* =====================================================================================
     PURPOSE
     Phases 46B-46E left one number unexplained: reconstructing Table 5's 62.5 F from
     Eq. (17) overshoots by +22.30 %. Phase 49 removed the two explanations that had been
     offered for it (a differing graphite deposition shape - refuted by p.31; a bad radial
     shape - refuted by the machine digitization). This model asks the remaining question
     directly: is the peak fuel specific power the report implies ANYWHERE NEAR the value
     Table 5 needs?

     Nothing here is fitted. Every input is a page-image transcription or an exact
     consequence of one, and the two routes share no intermediate quantity except the
     figure-derived radial shape A(r), which enters route 2 only through A(7) = 1.
     ===================================================================================== */

  /* ---------------- rho*Cp, derived from Table 4 without assuming a density -------------
     The report gives no Cp and no density. It does not need to: Table 4 pairs a power, a
     volumetric flow and a temperature rise for every region, and their ratio IS rho*Cp.
     Two independent rows are computed below; that they agree to 0.06 % is what makes this
     a derivation rather than an inference. */
  final parameter Real rhoCp_reactor(unit="J/(m3.K)") = 10.0e6/((1200*GAL/60)*(50.0*5/9))
    "DERIVED_FROM_ORNL: Table 4 footnotes b and c - 10 Mw, 1200 gpm, 1175 to 1225 F";
  final parameter Real rhoCp_regionJ(unit="J/(m3.K)") = 8.287e6/((1157*GAL/60)*(43.0*5/9))
    "DERIVED_FROM_ORNL: Table 4 row J - 8287 kw, 1157 gpm, 43 F";
  final parameter SIadd.NonDim rhoCp_consistency=rhoCp_regionJ/rhoCp_reactor - 1
    "Table 4 is a single-rho*Cp construction if this is ~0";

  /* ---------------- Table 2, transcribed. It is a closed geometric set -----------------
     "Core Regions Used to Calculate Temperature Distributions in the MSRE", printed p.14. */
  final parameter Real nChannels_region2=940 "Table 2, region 2";
  final parameter Real A_cell_region2_in2=1880.0/940.0
    "2.0000 in2 per channel EXACTLY - total cross-sectional area over channel count";
  final parameter Real A_flow_channel_in2=A_cell_region2_in2*0.224
    "0.4480 in2. Table 2's fuel fraction for region 2";
  final parameter SI.Radius r_w_fromTable2=sqrt(A_flow_channel_in2/Modelica.Constants.pi)*IN
    "0.37762 in = 0.0095916 m. The equal-FLOW-AREA channel radius of p.38, obtained from
     Table 2 ALONE. It is a cross-check on data.r_w, which was taken from MSRE channel
     geometry rather than from this report";
  final parameter SIadd.NonDim r_w_consistency=r_w_fromTable2/data.r_w - 1
    "+0.26 %. data.r_w is therefore confirmed by the report's own table, and the residual
     is far too small to matter to the 22 % question";

  final parameter Real A_flow_total_in2=45.00*0.256 + 1880.0*0.224 + 216.0*0.224 + 245.9*
      0.142 + 29.55*1.000 "545.49 in2, Table 2 summed over all five regions";
  final parameter SI.Velocity u_mean=(1200*GAL/60)/(A_flow_total_in2*IN^2)
    "0.7058 ft/s. Table 2's own total flow over Table 2's own total flow area";
  final parameter SI.Velocity u_region2=0.60*FT_S "Table 2, region 2 - the hot channel sits here";

  /* ---------------- ROUTE 1: power / volume, times the two peaking factors -------------
     This is the Phase 46C chain, with the radial factor re-integrated on the machine
     digitization over the Table 3 domain that V_fuel_mainCore itself covers, r <= 27.75 in.
     Getting the domain right MATTERS here and was checked: pairing Table 2's 24.76 in with
     Table 3's volume gives 1.4725 and would cut the overshoot to +6.8 %, but those are two
     different regionalizations of the core and combining them is not permitted. The
     favourable number is rejected for that reason, not kept because it is favourable. */
  parameter SIadd.NonDim radialPeakToAverage=1.6997
    "FIGURE_DERIVED, machine digitization, area-weighted over 0 <= r <= 27.75 in (Table 3).
     The eye reading gave 1.6859; the difference is not what closes anything";
  final parameter SIadd.VolumetricHeatGenerationRate P_f_average=data.f_fuel*data.Q_mainCore
      /data.V_fuel_mainCore "14.166 MW/m3";
  final parameter SIadd.VolumetricHeatGenerationRate P_f_max_route1=P_f_average*data.axialPeakToAverage
      *radialPeakToAverage;

  /* ---------------- ROUTE 2: the report's own Eq. (3)-(5), inverted --------------------
     Eq. (4)-(5) give the fuel temperature along a channel in terms of (Q_f)_m, the MAXIMUM
     equivalent specific power including the heat the graphite hands to the fuel. Reading
     the rise off Fig. 14 at r = 7 in and taking the velocity from Table 2 inverts it. This
     route uses NO peaking factor, NO Table 3 volume and NO region power. */
  final parameter Real bracket=cos(Modelica.Constants.pi/data.z_shape_period_in*data.z_shape_offset_in)
       - cos(Modelica.Constants.pi/data.z_shape_period_in*(64.59 + data.z_shape_offset_in))
    "1.92257 - the {cos alpha - cos beta} of Eq. (4) across the main core";
  parameter SI.TemperatureDifference dT_hotChannel=84.4*5/9
    "FIGURE_DERIVED: Fig. 14 fuel curve rises from the 1177.3 F main-core inlet of p.33 to
     1261.7 F at z = 64.59 in";
  final parameter Real X_eq5(unit="K.m/s") = dT_hotChannel*u_region2/bracket
    "Eq. (5)'s collection of constants, inverted out of Eq. (4) at r = 7 in where A(r) = 1";
  final parameter SIadd.VolumetricHeatGenerationRate Qf_max=X_eq5*Modelica.Constants.pi*
      rhoCp_reactor/(data.z_shape_period_in*IN) "Eq. (5) solved for (Q_f)_m";
  final parameter SIadd.VolumetricHeatGenerationRate P_f_max_route2=data.f_fuel*Qf_max
    "The fission part of it, which is what Eq. (13) calls P_f";

  /* ---------------- What Table 5 requires ---------------------------------------------- */
  final parameter Real dT_per_P_f(unit="K.m3/W") = 1.308881e-6
    "Eq. (17) evaluated at unit P_f with the 6/94 split over the Table 3 volumes. It is a
     pure function of the transcribed geometry and conductivities";
  final parameter SIadd.VolumetricHeatGenerationRate P_f_max_required=data.dT_maxLocal_target
      /dT_per_P_f "2.6528e7 W/m3 - the ONLY peak specific power that reproduces 62.5 F";

  final parameter SIadd.NonDim routeAgreement=P_f_max_route1/P_f_max_route2 - 1
    "How far the two independent routes are apart";
  final parameter SIadd.NonDim excess_route1=P_f_max_route1/P_f_max_required - 1;
  final parameter SIadd.NonDim excess_route2=P_f_max_route2/P_f_max_required - 1;

equation
  when terminal() then
    assert(abs(rhoCp_consistency) < 0.01, "Table 4 does not close on a single rho*Cp: the
whole-reactor and region-J rows differ by " + String(rhoCp_consistency*100) + " %. Every
derivation below rests on that closure.", AssertionLevel.error);

    assert(abs(r_w_consistency) < 0.02, "The equal-flow-area channel radius implied by Table 2 (" +
      String(r_w_fromTable2) + " m) disagrees with data.r_w by " + String(r_w_consistency*100) +
      " %. r_w enters Eq. (13) squared, so this would be a live suspect for the overshoot.",
      AssertionLevel.error);

    assert(abs(routeAgreement) < 0.05, "The two independent routes to the peak fuel specific
power disagree by " + String(routeAgreement*100) + " %. They share no intermediate quantity, so
a disagreement here would mean the overshoot is an artefact of one of them and the audit is
inconclusive.", AssertionLevel.error);

    /* This is the finding, stated as an assertion that is EXPECTED TO FAIL. It is not a
       defect of the model: it records, in executable form, that the report does not close on
       itself. Silencing it by widening the bound would be the fitting this study forbids. */
    assert(abs(excess_route2) < 0.05, "ABSOLUTE_NORMALIZATION_UNRESOLVED. Two independent
source-internal routes put the peak fuel specific power at " + String(P_f_max_route1) + " and " +
      String(P_f_max_route2) + " W/m3, agreeing with each other to " + String(routeAgreement*100) +
      " %. Table 5's 62.5 F requires " + String(P_f_max_required) + " W/m3, which is " + String(
      excess_route2*100) + " % lower. The discrepancy is therefore NOT in the peaking factors,
NOT in r_w and NOT in the graphite shape - all of which are now sourced or corroborated. It lies
between Eq. (17) and Table 5, and the report contains nothing further to resolve it.",
      AssertionLevel.warning);
  end when;

  annotation (
    experiment(StopTime=1, Tolerance=1e-6),
    Documentation(info="<html>
<h4>WHAT THIS MODEL IS</h4>
<p>An <b>elimination</b>, not a reconstruction. It does not try to reproduce Table 5. It asks
where the +22 % overshoot can and cannot live, and answers that with two routes to the same
quantity that share no intermediate step.</p>

<h4>Route 1 - power over volume, times peaking</h4>
<pre>  P_f_max = f_fuel * Q_mainCore / V_fuel_mainCore * axialP2A * radialP2A</pre>
<p>Table 4 regional powers (which sum to exactly 10 000 kw), Table 3 volumes (which reproduce
<code>V_fuel = 35 253.8 in3</code> exactly from the stated radii, elevations and volume percents),
B(z) from Fig. 8, A(r) from Fig. 4.</p>

<h4>Route 2 - the report's own channel equation, inverted</h4>
<pre>  T_f(r,z) = T_f(0) + X * A(r)/u(r) * {cos a - cos[pi/77.7 (z + 4.36)]}     (4)
  X        = (77.7/pi) * (Q_f)_m / (rho Cp)_f                               (5)</pre>
<p>At r = 7 in, A(r) = 1 by construction of Fig. 4. Fig. 14 gives the rise along that channel,
Table 2 gives its velocity, and Table 4 gives <code>rho Cp</code> - the report never states a heat
capacity, but a power, a flow and a temperature rise determine one, and two different rows of
Table 4 give the same answer to 0.06 %.</p>

<h4>A third, weaker corroboration</h4>
<p>The flow-area-weighted radial peaking (1.709) times Table 2's own velocity ratio (1.176)
predicts a hot-channel to mixed-mean temperature-rise ratio of 2.010; Fig. 14 with the p.33
boundaries gives 1.940. That is 3.6 %, with no free parameter, and it independently rules out the
radial peaking of 1.3785 that would close Table 5.</p>

<h4>What has been ELIMINATED as the cause of the overshoot</h4>
<table border=\"1\">
<tr><th>Candidate</th><th>Status</th></tr>
<tr><td>graphite deposition shape differs from fission density</td><td>REFUTED - p.31, p.38, p.40</td></tr>
<tr><td>radial shape of DT wrong</td><td>REFUTED - Phase 49, RMSE 0.0048</td></tr>
<tr><td>radial peaking factor wrong</td><td>REFUTED - corroborated twice, to 3.1 % and 3.6 %</td></tr>
<tr><td>r_w wrong</td><td>REFUTED - Table 2 gives the same radius to 0.26 %</td></tr>
<tr><td>Table 3 volumes wrong</td><td>REFUTED - reproduced exactly from the table</td></tr>
<tr><td>Table 4 / domain mismatch</td><td>REFUTED - powers sum to 10 000 kw; rho*Cp closes</td></tr>
<tr><td>Table 5 mistyped</td><td>REFUTED - Figs. 13 and 14 give 62.44 and 62.32 F</td></tr>
<tr><td>combining Table 2's 24.76 in with Table 3's volume</td><td>REJECTED - would give +6.8 %, but the two are different regionalizations</td></tr>
</table>

<h4>What remains</h4>
<p>The step from Eq. (17) to Table 5 - <q>the maximum values ... may be obtained by applying the
appropriate specific powers to Equation (17)</q>, p.40 - is the only link in the chain the report
does not make checkable. <b>It states no numerical specific power anywhere.</b> The audit ends
there, and it ends there for a reason that is a property of the source, not of this study.</p>

<h4>NOT a licence to adjust anything</h4>
<p>No production parameter follows from this model. <code>CASE B</code> remains
<code>SOURCE_MAPPING_UNRESOLVED</code>.</p>
</html>"));
end AbsoluteNormalizationAudit;
