within MSRE.Verification;
model CoreTH_ZeroPower
  "Stage 2-1 isothermal hydraulic baseline: the same equivalent 1-D core at zero power"
  extends MSRE.Verification.CoreTH_Baseline(
    Q_core=0,
    tol_energy=1e-6);

  parameter SI.SpecificEnergy tol_dh=1e-3
    "Allowed departure of the specific-enthalpy drop from the gravitational work [J/kg]";

  final parameter SI.SpecificEnergy dh_gravity=Modelica.Constants.g_n*geometry.H_channels
    "Specific work the salt does against gravity climbing the core (15.9417 J/kg)";
  SI.SpecificEnergy dh_actual=h_in - h_out "Specific enthalpy the salt actually gives up";

equation
  when terminal() then
    assert(abs(dh_actual - dh_gravity) < tol_dh, "At zero power the specific enthalpy the salt
gives up must equal the work it does against gravity, g*H = " + String(dh_gravity) + " J/kg. It
gave up " + String(dh_actual) + " J/kg instead. Any gap is an unintended energy path. Do not
adjust a property or a geometry to remove it.", AssertionLevel.error);
  end when;

  annotation (
    experiment(
      StopTime=300,
      __Dymola_NumberOfIntervals=1500,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>Purpose</h4>
<p>The hydraulic half of the Stage 2 verification, run before the heated case so that the
momentum balance can be read without any density gradient in it. Same geometry, same fuel salt,
same boundary conditions and the same equivalent one-group, twenty-cell core as
<a href=\"modelica://MSRE.Verification.CoreTH_Baseline\">CoreTH_Baseline</a>; only
<code>Q_core</code> changes, to zero.</p>

<table border=\"1\">
<tr><th>Condition</th><th>Value</th></tr>
<tr><td>radial groups</td><td>1 equivalent group of 1140 channels</td></tr>
<tr><td>axial cells</td><td>20</td></tr>
<tr><td>mass flow</td><td>168 kg/s, imposed</td></tr>
<tr><td>inlet temperature</td><td>908 K, imposed</td></tr>
<tr><td>core power</td><td><b>0 W</b></td></tr>
<tr><td>wall heat transfer</td><td>off</td></tr>
</table>

<h4>What it verifies</h4>
<ol>
<li><b>Mass conservation</b> - inherited from the base model, same tolerance.</li>
<li><b>The zero-power energy path</b> - with no source and no wall coupling, the salt must
still give up exactly the work it does climbing the core, <code>g*H = 15.9417 J/kg</code>. The
model does <b>not</b> come out isothermal, and it should not: <code>dT_core</code> is
-1.93 mK, which is gravitational and pressure work, not numerical noise. An earlier version of
this model asserted isothermal behaviour to 1e-3 K on the premise that only numerical sources
remained; that premise was wrong and the assertion has been replaced by the enthalpy statement
above, which is both correct and tighter.</li>
<li><b>Momentum balance with a uniform density</b> - at constant temperature
<code>dp_gravity_local</code> and <code>dp_gravity_bulk</code> must agree to round-off, which
makes this case the calibration of the static-head diagnostic itself before it is trusted in
the heated case.</li>
<li><b>Acceleration term</b> - it should be negligible here because the density is uniform, but
it is <b>computed rather than assumed</b>, so that its magnitude in the heated case can be
judged against a measured baseline instead of an expectation.</li>
</ol>

<h4>Energy tolerance</h4>
<p><code>tol_energy</code> is tightened to 1e-6 because the residual is now normalized by
<code>Q_energyNorm</code> rather than by the test power: at zero power there is no physical
energy input to hide a numerical residual behind. This is a stricter condition than the base
model\'s, not a relaxed one.</p>

<h4>What this case found</h4>
<p>It was worth running before the heated case. The base model checked
<code>m_flow*(h_out - h_in)</code> against <code>Q_core</code> and nothing else, which carries a
built-in deficit of <code>m_flow*g*H = 2678.2 W</code> because the salt climbs 1.6256 m. At
8 MW that deficit is a relative 3.35e-4 against a 1e-3 tolerance, so the heated case had been
passing with a factor of three of margin for the wrong reason. At zero power there is no power
to hide it behind and it failed immediately. The energy balance in
<a href=\"modelica://MSRE.Verification.CoreTH_Baseline\">CoreTH_Baseline</a> now reads
<code>Q_core = m_flow*(h_out - h_in) + Q_potential + Q_kinetic</code>, and the residual dropped
to 9.7e-12 here and 5.6e-9 at 8 MW - with no tolerance changed.</p>

<h4>What this is not</h4>
<p>It is not a Jeong comparison and not an MSRE measurement. No pressure drop here is asserted
against experimental data, because no independent MSRE core pressure-loss reference has been
established in this library yet.</p>
</html>"));
end CoreTH_ZeroPower;
