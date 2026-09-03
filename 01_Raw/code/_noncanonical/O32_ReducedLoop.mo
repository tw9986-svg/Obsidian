within MSRE.Verification;
model Core2D_Structure
  "Structural verification of the 2-D core nodalization (15 radial rings x 20 axial cells)"
  extends MSRE.Verification.CoreNodalization_Structure(
    redeclare record Nodalization = MSRE.Data.Nodalization.Core2D);

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<p><a href=\"modelica://MSRE.Verification.CoreNodalization_Structure\">CoreNodalization_Structure</a>
run on <a href=\"modelica://MSRE.Data.Nodalization.Core2D\">Core2D</a>, the 15 x 20 nodalization
of the Jeong MARS core.</p>
<p>This is the one that can actually fail: the 15 radial peaking factors are the only hand
entered array in either record, and <code>f_radial_mean</code> measures whether they are a shape
(mean 1) or a rescaling. It comes out at 0.99998 - four-decimal rounding in the published table,
not a modelling choice - and <code>corePowerShape</code> renormalizes it away, which is precisely
why it has to be measured here instead of being left to show up somewhere else.</p>
</html>"));
end Core2D_Structure;
