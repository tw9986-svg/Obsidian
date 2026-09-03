within MSRE.Experiments;
model PumpStartup1D_R1
  "PumpStartup1D_RotorDynamics with the R1 operating-point hydraulic torque"
  extends MSRE.Experiments.PumpStartup1D_RotorDynamics(msre(pump(use_operatingPointTorque=true)));
  annotation (Documentation(info="<html>
<p>Identical to
<a href=\"modelica://MSRE.Experiments.PumpStartup1D_RotorDynamics\">PumpStartup1D_RotorDynamics</a>
in every respect but one: the pump uses the R1 hydraulic torque, which follows the actual
pressure rise and flow, instead of the R0 torque, which follows the speed alone. The rotor
inertia, the motor torque, the friction, the pump characteristic, the loop resistance, the
initial condition and the trip timing are all inherited unchanged, so the single independent
variable in the comparison is the torque relation.</p>
</html>"));
end PumpStartup1D_R1;
