within MSRE.Verification;
model LowFlow_Hydraulics_NoTrace
  "O-24 | The at-rest loop with the precursor states taken out of the integration"
  extends MSRE.Verification.LowFlow_Hydraulics(
    traceDynamics=Modelica.Fluid.Types.Dynamics.SteadyState);

  annotation (
    experiment(StopTime=0.5, Tolerance=1e-6),
    Documentation(info="<html>
<h4>What is different</h4>
<p>Only <code>traceDynamics</code>. This is a zero-power hydraulic model: there is no fission,
so no precursor source, and the trace states are identically zero as a matter of physics. In the
integration they instead wander to about 1e-17 and trip the <code>min = 0</code> constraint that
TRANSFORM puts on <code>Cs</code>, once per group per node. The measured run logged 126 such
assertions before failing at t = 0.015 s.</p>

<p><code>SteadyState</code> takes those states out of the integration. <b>No hydraulic quantity
in this model depends on them</b> - not a pressure, not a flow, not an inventory - so this
changes what the solver has to carry, not what the model says.</p>

<h4>What it would establish</h4>
<p>If this run reaches its stop time and the baseline does not, the precursor trace states are
a contributor to O-24 in their own right, separate from the event chattering already fixed and
from the inverse friction law's derivative singularity. If it fails in the same place, they are
not, and the residual cause lies elsewhere.</p>

<p>Either way this is a <b>diagnostic experiment on a hydraulic test model</b>. It is not a
proposal to run the benchmark without precursor transport, which would be a different and much
larger claim.</p>
</html>"));
end LowFlow_Hydraulics_NoTrace;
