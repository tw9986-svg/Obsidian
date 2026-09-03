within MSRE.Verification;
model O32_SinglePipe
  "O-32 | One SaltPipe between two pressure boundaries, driven from positive flow through zero into reverse"
  extends Modelica.Icons.Example;

  replaceable package Medium = MSRE.Media.FuelSalt_U235 constrainedby
    Modelica.Media.Interfaces.PartialMedium "Fuel salt";

  parameter MSRE.Data.Geometry geometry "MSRE hardware geometry";
  parameter SI.Temperature T_start=908 "Isothermal temperature";
  parameter SI.AbsolutePressure p_ref=geometry.p_system "Reference pressure";

  /* The driving pressure difference is swept linearly through zero, so the flow
     must pass +ve -> 0 -> -ve. Nothing about the sweep is fitted: it is a ramp. */
  parameter SI.Pressure dp_amplitude=200 "Peak driving pressure difference";
  parameter SI.Time t_sweep=10 "Time to go from +dp_amplitude to -dp_amplitude";

  parameter Integer nV=3 "Number of volumes";
  parameter Modelica.Fluid.Types.Dynamics energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState
    "Energy balance. SteadyState here = isothermal case";
  parameter Modelica.Fluid.Types.Dynamics massDynamics=Modelica.Fluid.Types.Dynamics.SteadyStateInitial
    "Mass balance";
  parameter Modelica.Fluid.Types.Dynamics traceDynamics=Modelica.Fluid.Types.Dynamics.SteadyState
    "Trace balance. SteadyState here = no precursor states";

  inner TRANSFORM.Fluid.SystemTF systemTF(
    p_start=p_ref,
    T_start=T_start,
    allowFlowReversal=true,
    energyDynamics=TRANSFORM.Types.Dynamics.SteadyState,
    momentumDynamics=TRANSFORM.Types.Dynamics.SteadyState)
    annotation (Placement(transformation(extent={{-90,70},{-70,90}})));

  Modelica.Blocks.Sources.Ramp dpDrive(
    height=-2*dp_amplitude,
    duration=t_sweep,
    offset=dp_amplitude,
    startTime=1) "Driving pressure difference, swept through zero"
    annotation (Placement(transformation(extent={{-100,-10},{-80,10}})));

  TRANSFORM.Fluid.BoundaryConditions.Boundary_pT inlet(
    redeclare package Medium = Medium,
    nPorts=1,
    use_p_in=true,
    T=T_start) "Upstream boundary"
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));

  TRANSFORM.Fluid.BoundaryConditions.Boundary_pT outlet(
    redeclare package Medium = Medium,
    nPorts=1,
    p=p_ref,
    T=T_start) "Downstream boundary"
    annotation (Placement(transformation(extent={{60,-10},{40,10}})));

  Modelica.Blocks.Math.Add pInlet(k1=1, k2=1) "p_ref + dp"
    annotation (Placement(transformation(extent={{-76,4},{-68,12}})));
  Modelica.Blocks.Sources.Constant pBase(k=p_ref)
    annotation (Placement(transformation(extent={{-100,14},{-92,22}})));

  MSRE.Components.SaltPipe pipe(
    redeclare package Medium = Medium,
    nV=nV,
    V=geometry.V_downcomer,
    length=geometry.L_downcomer,
    dheight=0,
    energyDynamics=energyDynamics,
    massDynamics=massDynamics,
    traceDynamics=traceDynamics,
    p_a_start=p_ref,
    T_a_start=T_start,
    m_flow_a_start=0,
    exposeState_a=false,
    exposeState_b=false) "One pipe, horizontal, no heat, no source"
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));

  /* ---------------- Reported ---------------- */
  SI.MassFlowRate m_flow=pipe.port_a.m_flow "Flow through the pipe";
  SI.Pressure dp=pipe.port_a.p - pipe.port_b.p "Pressure difference actually applied";
  SI.Temperature T_min=min(pipe.Ts) "Coldest node";
  SI.Temperature T_max=max(pipe.Ts) "Hottest node";
  SI.Density d_min=min(pipe.ds) "Lowest node density";
  SI.Density d_max=max(pipe.ds) "Highest node density";
  SI.AbsolutePressure p_min=min(pipe.pipe.mediums.p) "Lowest node pressure";
  SI.AbsolutePressure p_max=max(pipe.pipe.mediums.p) "Highest node pressure";
  /* Continuous, not a when clause. An earlier version used
     "when m_flow < -1e-6 then reversed = true" and that condition generated about 100 state
     events of chattering at the crossing - a zero-crossing created by the INSTRUMENT, not by
     the physics. It did not change the result, but a diagnostic that perturbs the solver it is
     observing is exactly the mistake already made once with actualStream in Phase 20. */
  Real m_flow_min_seen(start=0) "Most negative flow reached; negative iff the loop reversed";

equation
  connect(pBase.y, pInlet.u1) annotation (Line(points={{-91.6,18},{-76.8,10.4}}, color={0,0,127}));
  connect(dpDrive.y, pInlet.u2) annotation (Line(points={{-79,0},{-76.8,5.6}}, color={0,0,127}));
  connect(pInlet.y, inlet.p_in) annotation (Line(points={{-67.6,8},{-62,8}}, color={0,0,127}));
  connect(inlet.ports[1], pipe.port_a) annotation (Line(points={{-40,0},{-10,0}}, color={0,127,255}));
  connect(pipe.port_b, outlet.ports[1]) annotation (Line(points={{10,0},{40,0}}, color={0,127,255}));

  der(m_flow_min_seen) = noEvent(if m_flow < m_flow_min_seen then -1e3*(m_flow_min_seen - m_flow) else 0);

  annotation (
    experiment(StopTime=12, Tolerance=1e-6),
    Documentation(info="<html>
<h4>Purpose</h4>
<p>Open item <b>O-32</b>. The full primary loop is fine at rated flow and fails at low flow, and
the friction closure has been verified through zero in <b>both</b> directions, so the failure is
not in the closure. This is the smallest model that still contains the machinery under
suspicion: one <a href=\"modelica://MSRE.Components.SaltPipe\">SaltPipe</a>, two pressure
boundaries, and a driving pressure difference ramped from +200 Pa through zero to -200 Pa.</p>

<p>The pipe is <b>horizontal</b> and unheated, so there is no static head and no source. What
remains is the transport machinery, the momentum balance and the boundary conditions.</p>

<h4>What is being asked</h4>
<ul>
<li>Does the flow actually pass through zero and reverse? <code>reversed</code> records it.</li>
<li>Do <code>m_flow</code>, <code>p</code>, <code>T</code> and <code>rho</code> stay in physical
range throughout?</li>
<li>Does the solver stall at the crossing, or step through it?</li>
</ul>

<p>This model is deliberately <b>open</b>, not a closed loop: a pressure boundary at each end
fixes the pressure level, so there is no loop closure and no circulating inventory. If this
passes and a closed loop of the same components fails, the difference is the closure itself
rather than the transport scheme - which is the question the ladder exists to answer.</p>

<h4>Nothing here is tuned</h4>
<p>The sweep is a linear ramp. No tolerance, geometry, property or friction coefficient is
adjusted, and the already-ruled-out candidates are not revisited.</p>
</html>"));
end O32_SinglePipe;
