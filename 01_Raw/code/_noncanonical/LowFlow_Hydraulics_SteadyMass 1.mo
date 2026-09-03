within MSRE.Verification;
model Loop_Hydraulics2D
  "Loop_Hydraulics on the 15 x 20 core, for the 1-D versus 2-D comparison"
  extends MSRE.Verification.Loop_Hydraulics(
    redeclare record Nodalization = MSRE.Data.Nodalization.Core2D);

  annotation (
    experiment(
      StopTime=300,
      __Dymola_NumberOfIntervals=3000,
      Tolerance=1e-6),
    Documentation(info="<html>
<p><a href=\"modelica://MSRE.Verification.Loop_Hydraulics\">Loop_Hydraulics</a> on
<a href=\"modelica://MSRE.Data.Nodalization.Core2D\">Core2D</a>. Same geometry, same total flow,
same total power, same inlet temperature, same properties - the spatial representation of the
core is the only thing that differs, which is what makes the comparison against the 1-D run a
measurement of the representation rather than of two models.</p>

<h4>What the comparison should show, and why</h4>
<p>Every <b>global</b> quantity should agree to solver tolerance, and that is a prediction rather
than a hope. The rings are hydraulically identical (<code>K_channelInlet</code> and
<code>K_channelExit</code> are both zero and every ring has the same channel geometry), so they
split the flow evenly and present the same resistance in parallel as the one equivalent group
does alone;
<a href=\"modelica://MSRE.Verification.Core1D_Structure\">the structural check</a> shows the
ring-summed axial source shape is identical to fifteen digits. Nothing is left for the radial
discretization to change in the loop flow, the pressure drops, the inventory or the transit
times.</p>

<p>What the 15 rings <i>do</i> carry is a radial <b>power</b> profile with a peak-to-average of
1.607, which the 1-D core cannot represent at all. At the zero power this model runs at, that
profile multiplies nothing, so the two runs must agree; at 8 MW they would not, and the
difference would be the spatial-representation effect the 1-D/2-D comparison exists to measure.
Running the comparison at zero power first is what separates a discretization difference from a
power-shape difference.</p>

<h4>Check 6 means something here</h4>
<p>In the 1-D run the flow-split check is trivially satisfied - one ring always carries all of
the flow. Here it is the real test of the parallel connection: if the plena did not expose their
state, or if the rings did, this is where it would show.</p>
</html>"));
end Loop_Hydraulics2D;
