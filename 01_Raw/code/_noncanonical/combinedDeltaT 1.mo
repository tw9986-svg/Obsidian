within MSRE.Verification.ORNL0378;
model AxialShapeVerification
  "SHAPE_ONLY_VERIFICATION of the axial graphite-fuel temperature difference against ORNL-TM-0378 Fig. 14"
  extends Modelica.Icons.Example;

  parameter HistoricalData data;
  constant Real IN_TO_M=0.0254;
  parameter Integer n=15 "# of digitized stations";

  /* ---- ORNL-TM-0378 Fig. 14, digitized from the page image ----
     "Axial Temperature Profiles in Hottest Channel of MSRE Core (7 in. from Core Center Line)".
     Abscissa: DISTANCE FROM BOTTOM OF CORE (in.) - the same datum as B(z), fixed on p.19.
     Both curves are read at the same radial station, so their difference is the report's DT.
     MACHINE-TRACKED by tools/digitize_ornl0378.py, replacing the eye reading this model
     originally carried. The eye reading was not badly wrong here - it survives the same test -
     but the companion radial reading WAS wrong by up to 7 F, so both were redone by tool. */
  final parameter Real z_in[n]={4,8,12,16,24,28,32,36,40,44,48,52,56,60,64}
    "z = 20 in is absent because the tracker loses the curve at the gridline there. The gap is
     left as a gap rather than filled by interpolation";
  final parameter Real Tg_F[n]={1200.31,1212.16,1224.42,1236.32,1258.89,1268.65,1277.48,1284.57,
      1290.53,1294.52,1296.13,1295.62,1293.85,1289.72,1284.36} "FIGURE_DERIVED, graphite curve";
  final parameter Real Tf_F[n]={1179.23,1182.09,1185.88,1190.51,1202.30,1208.47,1214.99,1222.26,
      1229.91,1236.61,1242.68,1248.59,1253.05,1257.24,1261.24} "FIGURE_DERIVED, fuel curve";
  final parameter Real dT_F[n]={Tg_F[i] - Tf_F[i] for i in 1:n} "Local graphite-fuel difference";
  final parameter Real dT_max_F=max(dT_F);

  /* ---- The source shape, exactly as the report writes it ---- */
  final parameter Real z_peak_in=data.z_shape_period_in/2 - data.z_shape_offset_in
    "34.49 in - the analytic peak of B(z), from the report's own constants";
  final parameter Real B[n]={axialPowerShape(z_in[i]*IN_TO_M, data.z_shape_period_in, data.z_shape_offset_in)
      for i in 1:n};
  final parameter Real B_peak=axialPowerShape(z_peak_in*IN_TO_M, data.z_shape_period_in, data.z_shape_offset_in);

  /* ---- The comparison. At FIXED r*, Eq. (18) gives
              DT(r*,z)/DT(r*,z_peak) = P(r*,z)/P(r*,z_peak) = B(z)/B(z_peak)
     because A(r*) appears in numerator and denominator alike and CANCELS. No absolute specific
     power, no thermal normalization constant and no radial factor enters this test. ---- */
  /* Variables rather than final parameters, so that they reach the result file; a final
     parameter is constant-folded away and cannot be inspected after the run. */
  Real dT_norm[n];
  Real B_norm[n];
  Real dev[n];
  Real rmse "Root-mean-square normalized deviation";
  Real dev_absmax "Largest normalized deviation at any station";
  Real dev_mean "Signed mean";
  Integer nWithinBand "Stations inside the read band";

  parameter Real tol_readBand=3.0/64.0
    "Normalized band implied by the digitization: +-2 F on each curve gives +-3 F on their
     difference, against a maximum difference of 64 F. NOT a physical tolerance";

equation
  dT_norm = {dT_F[i]/dT_max_F for i in 1:n};
  B_norm = {B[i]/B_peak for i in 1:n};
  dev = {dT_norm[i] - B_norm[i] for i in 1:n};
  rmse = sqrt(sum(dev[i]^2 for i in 1:n)/n);
  dev_absmax = max({abs(dev[i]) for i in 1:n});
  dev_mean = sum(dev)/n;
  nWithinBand = sum({(if abs(dev[i]) <= tol_readBand then 1 else 0) for i in 1:n});

  when terminal() then
    assert(rmse < tol_readBand, "SHAPE_ONLY_FAIL. The normalized axial shape of the digitized
graphite-fuel difference departs from B(z)/B(z_peak) with an RMSE of " + String(rmse) + ", beyond
the band the figure reading itself allows (" + String(tol_readBand) + "). At fixed radius Eq. (18)
makes these two identical, so a failure here is a failure of the source shape or of the reading -
not of any normalization, since none is used.", AssertionLevel.error);

    assert(dev_absmax < 3*tol_readBand, "SHAPE_ONLY_FAIL. One station departs by " + String(
      dev_absmax) + ", more than three times the reading band.", AssertionLevel.error);
  end when;

  annotation (
    experiment(StopTime=1, Tolerance=1e-6),
    Documentation(info="<html>
<h4>REFERENCE</h4>
<p>ORNL-TM-0378, Fig. 14 and Fig. 8 / Eq. (4)-(6).</p>
<h4>PURPOSE</h4>
<p><b>SHAPE_ONLY_VERIFICATION.</b> Test whether the axial <i>shape</i> of the historical
graphite-fuel temperature difference follows the report's own axial source shape.</p>
<h4>NOT FOR</h4>
<p>Production thermal closure, and <b>not</b> an absolute graphite temperature validation. No
absolute specific power, no thermal normalization constant and no radial factor is used here, and
none is validated by this model.</p>

<h4>Why the absolute scale drops out</h4>
<p>At a <b>fixed</b> radial station r*, Eq. (18) gives</p>
<pre>  DT(r*,z)/DT(r*,z_peak) = P(r*,z)/P(r*,z_peak) = B(z)/B(z_peak)</pre>
<p>because <code>P(r,z) = A(r)B(z)</code> (Eq. 2) and <code>A(r*)</code> cancels between numerator
and denominator. This is the corrected form of a looser statement made earlier, which said the
normalized difference was determined by <code>A(r)B(z)</code>; at fixed r* only <b>B(z)</b> remains.</p>

<h4>What this does NOT resolve</h4>
<p>The absolute power normalization is still <b>unresolved</b>. Phase 46E's
<code>SOURCE_MAPPING_UNRESOLVED</code> stands unchanged, and passing this shape test does not touch
it - the test is constructed precisely so that the unresolved quantity cannot influence it.</p>
</html>"));
end AxialShapeVerification;
