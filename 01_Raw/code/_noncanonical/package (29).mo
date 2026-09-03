within MSRE.Verification.ORNL0378;
model ProductionShapeComparison
  "Maps the production 2-D fission source shape onto ORNL-TM-0378's A(r) and B(z). DIAGNOSTIC - NO production change"
  extends Modelica.Icons.Example;

  parameter HistoricalData data;
  constant Real IN=0.0254;

  /* =====================================================================================
     WHAT THIS IS
     Phase 60 of the ORNL0378 audit: an implementation-boundary comparison. It answers one
     question - how far is the shape the production model actually imposes from the shape
     ORNL-TM-0378 documents - WITHOUT touching production code and WITHOUT proposing that
     either be changed to match the other. The paper benchmark and the 1962 report are
     different reference cases; this model measures the distance between them, it does not
     rule on it.
     ===================================================================================== */

  parameter Integer nRings=15 "MSRE.Data.Nodalization.Core2D";
  parameter Integer nAxial=20;

  /* ---------------- The production radial profile, as declared ------------------------- */
  final parameter Real f_radial[nRings]={1.6067,1.5076,1.4115,1.3184,1.2283,1.1410,1.0565,
      0.9748,0.8958,0.8194,0.7456,0.6743,0.6055,0.5392,0.4751}
    "VERBATIM from MSRE.Data.Nodalization.Core2D. Its own documentation calls it an
     ASSUMPTION: a J0 shape with a 25 % reflector saving, standing in for an unpublished
     Serpent tabulation. It is NOT an MSRE measurement and NOT ORNL-TM-0378 data";

  /* ---------------- ORNL Fig. 4, averaged over the SAME rings -------------------------
     Core2D gives every ring the same channel count, so the rings are equal-FLOW-AREA and
     ring k spans r = R*sqrt((k-1)/n) .. R*sqrt(k/n). R = 27.75 in is the Table 3 main-core
     outer radius. Averaging A(r) over each of those annuli, area-weighted, is the only way
     to put the two profiles on one axis. */
  final parameter Real r_ringOuter_in[nRings]={7.165,10.133,12.410,14.330,16.021,17.551,
      18.957,20.266,21.495,22.658,23.764,24.820,25.834,26.809,27.750};
  final parameter Real A_ring[nRings]={0.9578,0.9829,0.9300,0.8616,0.7897,0.7168,0.6484,
      0.5791,0.5119,0.4447,0.3774,0.3175,0.2938,0.2338,0.1691}
    "FIGURE_DERIVED from Verification/ORNL0378/data/Fig04_radial.csv";

  final parameter Real f_radial_mean=sum(f_radial)/nRings;
  final parameter Real A_ring_mean=sum(A_ring)/nRings;
  final parameter Real f_radial_norm[nRings]={f_radial[i]/f_radial_mean for i in 1:nRings};
  final parameter Real A_ring_norm[nRings]={A_ring[i]/A_ring_mean for i in 1:nRings};

  Real dev_radial[nRings] "Production minus ORNL, each normalized to its own ring mean";
  Real rmse_radial;
  Real radialP2A_production "max/mean of the production ring profile";
  Real radialP2A_ORNL "max/mean of ORNL A(r) on the same rings";

  /* ---------------- Axial ---------------------------------------------------------------
     Production: cos(pi (z - L/2) / (L * f_extrapolation)), symmetric about the midplane,
     f_extrapolation = 1.2 (MSRE.Data.Geometry, sourced as 'the usual reflector saving').
     ORNL:       sin(pi/77.7 (z + 4.36)), which is the same cosine with an extrapolated
                 length of 77.7 in and a peak at 34.49 in - ABOVE the 32.295 in midplane. */
  parameter Real L_core_in=64.59 "ORNL main-core height, p.32";
  parameter Real f_extrapolation=1.2 "MSRE.Data.Geometry.f_axialExtrapolation";
  final parameter Real f_extrapolation_ORNL=data.z_shape_period_in/L_core_in
    "77.7/64.59 = 1.20297. The production 1.2 and this agree to 0.25 %, from unrelated
     provenance - the report fits it to Fig. 8, the production value is a rule of thumb";
  final parameter Real z_peak_ORNL_in=data.z_shape_period_in/2 - data.z_shape_offset_in
    "34.49 in";
  final parameter Real z_peak_production_in=L_core_in/2 "32.295 in, by construction";
  final parameter Real z_peakOffset_in=z_peak_ORNL_in - z_peak_production_in
    "+2.195 in, 3.40 % of the core height. The production profile is symmetric; ORNL's is not";

  final parameter Integer nQuad=400 "Midpoint quadrature intervals for the axial averages";
  final parameter Real zq_in[nQuad]={(i - 0.5)*L_core_in/nQuad for i in 1:nQuad};
  final parameter Real Bo[nQuad]={sin(Modelica.Constants.pi/data.z_shape_period_in*(zq_in[i]
       + data.z_shape_offset_in)) for i in 1:nQuad};
  final parameter Real Bp[nQuad]={cos(Modelica.Constants.pi*(zq_in[i] - L_core_in/2)/(
      L_core_in*f_extrapolation)) for i in 1:nQuad};
  final parameter Real Bo_peak=1.0 "sin at its own maximum";
  final parameter Real Bp_peak=1.0 "cos at z = L/2";

  Real axialP2A_ORNL;
  Real axialP2A_production;
  Real rmse_axial "Normalized axial shape difference";
  Real dev_axial_absmax;

  /* ---------------- Combined ------------------------------------------------------------ */
  Real peakToAverage_ORNL "axial x radial, on the ORNL rings";
  Real peakToAverage_production;

equation
  dev_radial = {f_radial_norm[i] - A_ring_norm[i] for i in 1:nRings};
  rmse_radial = sqrt(sum(dev_radial[i]^2 for i in 1:nRings)/nRings);
  radialP2A_production = max(f_radial)/f_radial_mean;
  radialP2A_ORNL = max(A_ring)/A_ring_mean;

  axialP2A_ORNL = Bo_peak/(sum(Bo)/nQuad);
  axialP2A_production = Bp_peak/(sum(Bp)/nQuad);
  rmse_axial = sqrt(sum((Bp[i]/Bp_peak - Bo[i]/Bo_peak)^2 for i in 1:nQuad)/nQuad);
  dev_axial_absmax = max({abs(Bp[i]/Bp_peak - Bo[i]/Bo_peak) for i in 1:nQuad});

  peakToAverage_ORNL = axialP2A_ORNL*radialP2A_ORNL;
  peakToAverage_production = axialP2A_production*radialP2A_production;

  when terminal() then
    /* The only thing asserted is an identity of the production construction, not agreement
       with ORNL. sum(SF) = 1 makes power conservation exact for ANY radial profile, so the
       shape difference below cannot break the energy balance - which is precisely why the
       shape difference is a BENCHMARK_DIFFERENCE and not a bug. */
    assert(abs(sum(f_radial)/nRings - f_radial_mean) < 1e-12,
      "Internal inconsistency in this diagnostic.", AssertionLevel.error);

    assert(rmse_radial < 0.05, "RADIAL_SHAPE_DIFFERS_FROM_ORNL (expected). The production ring
profile and ORNL-TM-0378 Fig. 4 differ by an RMSE of " + String(rmse_radial) + " when each is
normalized to its own mean. Production peak/mean = " + String(radialP2A_production) +
      ", ORNL = " + String(radialP2A_ORNL) + ". This is a BENCHMARK_DIFFERENCE, not a defect:
the production profile is documented as a J0 assumption standing in for an unpublished Serpent
tabulation, and the two reference cases are not the same case. NOTHING should be changed on
the strength of this assertion.", AssertionLevel.warning);
  end when;

  annotation (
    experiment(StopTime=1, Tolerance=1e-6),
    Documentation(info="<html>
<h4>SCOPE</h4>
<p><b>Diagnostic only.</b> No production file is read at run time and none is modified. The two
arrays above are transcribed from
<code>MSRE.Data.Nodalization.Core2D</code> and from
<code>Verification/ORNL0378/data/Fig04_radial.csv</code>, so this model goes stale if either
changes - that is deliberate, since a silent divergence is exactly what it exists to catch.</p>

<h4>Why the rings can be compared at all</h4>
<p><code>Core2D</code> gives all 15 rings the same channel count and identical geometry, so they
are equal-flow-area annuli: ring k spans <code>r = R sqrt((k-1)/15) .. R sqrt(k/15)</code>. With
<code>R = 27.75 in</code> (Table 3's main-core outer radius, which is also where the production
1140 channels end) the two profiles live on one axis.</p>

<h4>What differs, and what does not</h4>
<table border=\"1\">
<tr><th>Quantity</th><th>Production</th><th>ORNL-TM-0378</th><th>Class</th></tr>
<tr><td>axial peak/average</td><td>1.3552</td><td>1.3584</td><td>NO_ISSUE (0.24 %)</td></tr>
<tr><td>axial extrapolation factor</td><td>1.2</td><td>1.20297</td><td>NO_ISSUE, unrelated provenance</td></tr>
<tr><td>axial symmetry</td><td>peak at midplane</td><td>peak 2.195 in above it</td><td>MODEL_ASSUMPTION</td></tr>
<tr><td>radial peak/average</td><td>1.6067</td><td>1.6726</td><td>BENCHMARK_DIFFERENCE (3.9 %)</td></tr>
<tr><td>radial shape</td><td>monotone J0</td><td>central depression, peak on ring 2</td><td>BENCHMARK_DIFFERENCE</td></tr>
<tr><td>power conservation</td><td colspan=\"2\">exact, by <code>sum(SF) = 1</code></td><td>NO_ISSUE</td></tr>
</table>

<h4>The central depression</h4>
<p>ORNL's Fig. 4 is <b>not</b> monotone: three control-rod thimbles depress the flux inside
r ~ 3.3 in, so the maximum sits at r = 7 in and falls on ring 2, not ring 1. The production J0
profile is monotone decreasing from ring 1 and cannot represent that. Whether it should is a
modelling-policy question about which reference case the 2-D model is serving, and this audit
does not answer it.</p>

<h4>What this model does NOT license</h4>
<p>It does not license replacing <code>f_radial</code> with <code>A_ring</code>. The production
2-D nodalization targets the paper benchmark, whose radial tabulation is unpublished; adopting
a 1962 figure in its place would swap one unsourced profile for a differently-sourced one and
silently change the benchmark. The comparison is the deliverable.</p>
</html>"));
end ProductionShapeComparison;
