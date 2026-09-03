within MSRE.Verification;
model LowFlow_Hydraulics_SteadyMass
  "O-24 | The same loop at rest with a steady-state mass balance, which removes the acoustic modes"
  extends MSRE.Verification.LowFlow_Hydraulics(
    massDynamics=Modelica.Fluid.Types.Dynamics.SteadyState,
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState);

  annotation (
    experiment(StopTime=10, Tolerance=1e-6),
    Documentation(info="<html>
<h4>What is different</h4>
<p>Only the balance formulation. <code>massDynamics = SteadyState</code> makes
<code>der(m) = 0</code>, so pressure stops being a state and the acoustic modes are removed from
the system rather than resolved by the integrator. TRANSFORM requires the energy balance to be
<code>SteadyState</code> as well in that case, or the medium to be single-state - see the
assertion in <code>PartialDistributedVolume</code>:</p>
<pre>
assert(not (energyDynamics &lt;&gt; SteadyState and massDynamics == SteadyState)
       or Medium.singleState, \"Bad combination of dynamics options ...\");
</pre>

<h4>What this does and does not establish</h4>
<p>For an <b>isothermal hydraulic</b> test both settings are physically appropriate: there is no
thermal transient to resolve, so a steady energy balance is not an approximation of anything.
If this arm is integrable and the baseline is not, the cause of O-24 is identified as
<code>MASS_DYNAMICS</code>.</p>

<p><b>It does not by itself unblock natural circulation.</b> Natural circulation is driven by
buoyancy, so its energy balance must stay dynamic, and this combination is then unavailable. The
route that would remain open is a single-state medium, whose justification has to be argued on
the physics: over the loop's pressure range the pressure-driven density change is
<code>kappa*dp</code>, while the buoyancy that drives the flow is <code>beta*dT</code>. Those two
numbers have to be compared and reported before any such medium is used, not assumed.</p>
</html>"));
end LowFlow_Hydraulics_SteadyMass;
