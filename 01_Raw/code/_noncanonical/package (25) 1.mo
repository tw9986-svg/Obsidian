within MSRE.Experiments;
model PumpStartup1D_RotorDynamics
  "MSRE pump startup on the 1-D core, with the shaft speed solved from the rotor equation"
  extends MSRE.Experiments.PumpStartup_RotorDynamics(
    redeclare record Nodalization = MSRE.Data.Nodalization.Core1D);

  annotation (
    experiment(
      StopTime=750,
      __Dymola_NumberOfIntervals=7500,
      Tolerance=1e-6),
    Documentation(info="<html>
<p><a href=\"modelica://MSRE.Experiments.PumpStartup_RotorDynamics\">PumpStartup_RotorDynamics</a>
on <a href=\"modelica://MSRE.Data.Nodalization.Core1D\">Core1D</a>: one equivalent radial group of
1140 channels instead of fifteen rings of 76. Every physical dimension is identical, so the
difference between this model and the 15-ring one is the spatial representation and nothing
else.</p>
<p>For the <b>precursor</b> results the two should agree to solver tolerance and not merely
closely, and that is a prediction rather than a hope: the rings are hydraulically identical
(<code>K_channelInlet = K_channelExit = 0</code>), the neutron importance is flat, and
<a href=\"modelica://MSRE.Verification.Core1D_Structure\">the structural check</a> shows the
ring-summed axial source shape is identical to fifteen digits. Nothing is left for the radial
discretization to change. A difference would mean one of those three statements is false.</p>
</html>"));
end PumpStartup1D_RotorDynamics;
