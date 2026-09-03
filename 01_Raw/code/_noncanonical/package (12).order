within MSRE.Experiments;
model PumpCoastdown1D_RotorDynamics
  "MSRE pump coastdown on the 1-D core, with the shaft speed solved from the rotor equation"
  extends MSRE.Experiments.PumpCoastdown_RotorDynamics(
    redeclare record Nodalization = MSRE.Data.Nodalization.Core1D,
    t_null=1500);

  annotation (
    experiment(
      StopTime=1800,
      __Dymola_NumberOfIntervals=9000,
      Tolerance=1e-6),
    Documentation(info="<html>
<p><a href=\"modelica://MSRE.Experiments.PumpCoastdown_RotorDynamics\">PumpCoastdown_RotorDynamics</a>
on <a href=\"modelica://MSRE.Data.Nodalization.Core1D\">Core1D</a>. See
<a href=\"modelica://MSRE.Experiments.PumpStartup1D_RotorDynamics\">PumpStartup1D_RotorDynamics</a>
for why the precursor results should be nodalization independent.</p>
<h4>Why the null transient is 1500 s</h4>
<p>The coastdown starts from the <b>circulating</b> precursor equilibrium, and that distribution
fills at the decay rate of the slowest group. The production-minus-decay residual falls as
<code>exp(-lambda_1*t)</code> with <code>lambda_1 = 0.0125 1/s</code>, which
<a href=\"modelica://MSRE.Verification.DNP_Circulation\">DNP_Circulation</a> measured directly:
5.5e-4 at 600 s, 1.5e-6 at 1500 s. 600 s is 10.8 half-lives, which sounds ample and is not.</p>

<p>This is the pair of tests that share a single <code>tau_shaft</code>. The prescribed-speed
<a href=\"modelica://MSRE.Experiments.PumpCoastdown\">PumpCoastdown</a> imposes
<code>N = N_0/(1 + t/tau_coast)</code>, which is the exact solution of the rotor equation this
model integrates, so the two speed histories must coincide to solver tolerance. That agreement
is the regression check on the rotor ODE - it is the case where the analytic answer is known, so
any deviation is a defect in the equation or its initialization rather than a modelling
choice.</p>
</html>"));
end PumpCoastdown1D_RotorDynamics;
