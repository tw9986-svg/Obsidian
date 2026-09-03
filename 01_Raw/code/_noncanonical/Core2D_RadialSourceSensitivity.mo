within MSRE.Verification;
model Core1D_Structure
  "Structural verification of the 1-D core nodalization (1 equivalent group x 20 axial cells)"
  extends MSRE.Verification.CoreNodalization_Structure(
    redeclare record Nodalization = MSRE.Data.Nodalization.Core1D);

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<p><a href=\"modelica://MSRE.Verification.CoreNodalization_Structure\">CoreNodalization_Structure</a>
run on <a href=\"modelica://MSRE.Data.Nodalization.Core1D\">Core1D</a>. Every check has to hold
for a one-group core exactly as it does for a fifteen-ring one: the closure statements are about
the discretization being self-consistent, not about how fine it is.</p>
<p>Two of them are trivially satisfied here and are worth running anyway, because they are what
would catch a 1-D record that had been edited to hold something other than all 1140 channels:
<code>sum(nChannels_ring)</code> is a one-term sum and <code>f_radial_mean</code> is a single
1.0. That last one is <b>exactly</b> 1 in the 1-D case and 0.99998 in the 15-ring case, which is
the precision of the published four-decimal radial table rather than a modelling difference.</p>
<p><code>peak_axial</code> comes out at 1.265427 for both, which is the statement that
collapsing the rings does not touch the axial source shape.</p>
</html>"));
end Core1D_Structure;
