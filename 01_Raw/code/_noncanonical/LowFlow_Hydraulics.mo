within MSRE.Verification;
model Core1D_TH_ZeroPower
  "Stage-3 isothermal hydraulic baseline: the 1-D reactor core at zero power"
  extends MSRE.Verification.Core1D_TH_Baseline(Q_core=0, tol_energy=1e-6);

  parameter SI.SpecificEnergy tol_dh=1e-3
    "Allowed departure of the specific-enthalpy drop from the gravitational work [J/kg]";

  final parameter SI.SpecificEnergy dh_gravity=Modelica.Constants.g_n*core.dz_core
    "Specific work the salt does against gravity crossing the core (21.8281 J/kg)";
  SI.SpecificEnergy dh_actual=-Q_enthalpy/max(abs(m_flow_in), 1e-9)
    "Specific enthalpy the salt actually gives up";

equation
  when terminal() then
    assert(abs(dh_actual - dh_gravity) < tol_dh, "At zero power the specific enthalpy the salt
gives up must equal the work it does against gravity, g*dz_core = " + String(dh_gravity) +
      " J/kg. It gave up " + String(dh_actual) + " J/kg instead. Any gap is an unintended energy
path. Do not adjust a property or a geometry to remove it.", AssertionLevel.error);
  end when;

  annotation (
    experiment(
      StopTime=20000,
      __Dymola_NumberOfIntervals=2000,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>Purpose</h4>
<p>The hydraulic half of the Stage 3 verification, run before the heated case so that the
momentum balance of the assembled core can be read with no density gradient in it. Identical to
<a href=\"modelica://MSRE.Verification.Core1D_TH_Baseline\">Core1D_TH_Baseline</a> except that
<code>Q_core = 0</code> and <code>tol_energy</code> is tightened to 1e-6, which is stricter than
the heated case rather than looser: with no power there is nothing to hide a numerical residual
behind.</p>

<p>The core is <b>not</b> isothermal and should not be. It rises 2.2256 m, so the salt gives up
<code>g*dz_core = 21.8281 J/kg</code> of enthalpy doing work against gravity, and the
assertion is on that statement rather than on a constant temperature. The same trap caught the
Stage 2 model, where an isothermal assertion had been written on the false premise that only
numerical sources remained.</p>
</html>"));
end Core1D_TH_ZeroPower;
