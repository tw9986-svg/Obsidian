within MSRE.Verification.BaseClasses;
model IdealPressureRise
  "DIAGNOSTIC ONLY | An ideal, reversible pressure rise used to drive a closed test loop through zero flow"

  replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium"
    annotation (choicesAllMatching=true);

  Modelica.Blocks.Interfaces.RealInput dp_in(unit="Pa")
    "Commanded pressure rise from port_a to port_b"
    annotation (Placement(transformation(extent={{-20,-20},{20,20}}, origin={0,60})));

  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_a(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_b(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{90,-10},{110,10}})));

  SI.MassFlowRate m_flow=port_a.m_flow "Mass flow rate, port_a to port_b";
  SI.Pressure dp=port_b.p - port_a.p "Pressure rise actually delivered";
  SI.Density d=Medium.density(Medium.setState_phX(
      port_a.p,
      inStream(port_a.h_outflow),
      inStream(port_a.Xi_outflow))) "Suction density";
  SI.SpecificEnergy dh=dp/d "Specific work added, ideal and reversible";
  SI.Power W=m_flow*dh "Shaft power";

equation
  /* Mass */
  port_a.m_flow + port_b.m_flow = 0;

  /* The prescribed rise. Sign is free, so the drive can push the loop in either
     direction and through zero, which a pump characteristic cannot do. */
  dp = dp_in;

  /* Energy. The work is put into the stream rather than discarded, so the
     component is energy-consistent and the dynamic-energy rung of the ladder is
     not confounded by a drive that quietly loses power. Reversible and adiabatic:
     no efficiency, no dissipation. */
  port_b.h_outflow = inStream(port_a.h_outflow) + dh;
  port_a.h_outflow = inStream(port_b.h_outflow) - dh;

  /* Species and trace pass through untouched */
  port_b.Xi_outflow = inStream(port_a.Xi_outflow);
  port_a.Xi_outflow = inStream(port_b.Xi_outflow);
  port_b.C_outflow = inStream(port_a.C_outflow);
  port_a.C_outflow = inStream(port_b.C_outflow);

  annotation (
    defaultComponentName="drive",
    Icon(graphics={
        Ellipse(extent={{-60,60},{60,-60}}, lineColor={0,127,255}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
        Polygon(points={{-20,30},{40,0},{-20,-30},{-20,30}}, lineColor={0,127,255},
            fillColor={0,127,255}, fillPattern=FillPattern.Solid),
        Text(extent={{-100,-70},{100,-95}}, textString="%name", textColor={0,0,0})}),
    Documentation(info="<html>
<h4>Scope: diagnostic only</h4>
<p>This component exists to drive the <b>O-32 reduced loop</b> from positive flow, through zero,
into reverse. It is <b>not</b> a model of the MSRE fuel pump and must not be used in any
benchmark model. <a href=\"modelica://MSRE.Components.FuelPump\">FuelPump</a> and
<a href=\"modelica://MSRE.Components.FuelPump_Dynamics\">FuelPump_Dynamics</a> remain the only
pump models in this library.</p>

<h4>What it does</h4>
<p>It imposes a commanded pressure rise <code>dp_in</code> between its ports and conserves mass,
species and trace substances exactly. The work is delivered to the stream as
<code>dh = dp/d</code>, so it is <b>energy-consistent</b>: the dynamic-energy rung of the ladder
is not confounded by a drive that adds momentum while quietly losing power. It is ideal and
reversible - no efficiency, no dissipation, no rotor.</p>

<h4>Why a pump could not be used instead</h4>
<p>A pump characteristic is <code>head(N, V_flow)</code> with <code>head &gt;= 0</code> at
positive speed; it cannot command a negative pressure rise, so it cannot sweep a loop through
zero into reverse. That sweep is the whole point of the test.</p>

<h4>What it is not evidence of</h4>
<p>A closed loop driven this way passing through zero says the <b>loop formulation</b> can be
integrated through a flow reversal. It says nothing about whether buoyancy can drive that loop,
which is a separate question and a separate model.</p>
</html>"));
end IdealPressureRise;
