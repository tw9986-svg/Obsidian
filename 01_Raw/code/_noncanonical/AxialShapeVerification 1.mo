within MSRE.Verification;
model O32_ReducedLoop
  "O-32 | A minimal CLOSED hydraulic loop: two vertical legs and two connectors, driven through zero"
  extends Modelica.Icons.Example;

  replaceable package Medium = MSRE.Media.FuelSalt_U235 constrainedby
    Modelica.Media.Interfaces.PartialMedium "Fuel salt";

  parameter MSRE.Data.Geometry geometry "MSRE hardware geometry";
  parameter SI.Temperature T_start=908 "Isothermal temperature";
  parameter SI.AbsolutePressure p_ref=geometry.p_system "Reference pressure";

  /* Physics layering. Each is switched independently so the ladder can add one
     at a time and see which step breaks integrability. */
  /* FixedInitial, not SteadyState, and this is the central result of the O-32 investigation
     rather than a convenience. With a steady energy balance every enthalpy flow is
     H_flow = semiLinear(m_flow, h_up, h_down), so the balance 0 = H_in - H_out constrains only
     the DIFFERENCES between temperatures, never their level. In a closed adiabatic loop nothing
     else supplies it, and the initialization Jacobian loses rank in exactly the T and h
     directions: measured rank 7 of 14, with 81.7 % of the null space on T and 18.2 % on h, and
     T/h column norms 116x below the pressure columns.

     Measured, changing only this parameter:

       SteadyState,  m_flow_start = 0      rank 7/14   1415 singular msgs   FAIL
       SteadyState,  m_flow_start = 100    rank 6/14   1427 singular msgs   FAIL
       FixedInitial, m_flow_start = 0      full rank      0 singular msgs   PASS

     Note the middle row: a non-zero initial flow does NOT rescue the steady formulation. */
  parameter Modelica.Fluid.Types.Dynamics energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial
    "Formulation of the energy balance. FixedInitial supplies the absolute thermal state a closed adiabatic loop cannot otherwise determine";
  /* A closed loop needs der(p) = 0 for the volumes PLUS exactly one pressure anchor.

     Both alternatives were measured and both give a (nearly) singular Jacobian, for opposite
     reasons:

       SteadyStateInitial, no anchor : der(p) = 0 leaves the absolute level free
                                       -> UNDER-determined
       FixedInitial                  : pins p = ps_start at EVERY volume while the momentum
                                       balance also constrains the pressure differences
                                       -> OVER-determined

     Measured on this model, all three A/B/C start-value and nominal variants reported
     "Homotopy solver total pivot: Matrix (nearly) singular at initialization", with residuals
     of 1e16 to 1e22. The full primary loop avoids this because its pump bowl is a free surface
     that anchors the level while the volumes stay SteadyStateInitial. This model now does the
     same with an expansion tank. */
  parameter Modelica.Fluid.Types.Dynamics massDynamics=Modelica.Fluid.Types.Dynamics.SteadyStateInitial
    "Mass balance";
  parameter Modelica.Fluid.Types.Dynamics traceDynamics=Modelica.Fluid.Types.Dynamics.SteadyState
    "SteadyState = no precursor states; FixedInitial = trace transport on";

  parameter Integer nV=3 "Volumes per leg";

  /* ---------------- Anchor selection, for the rank-deficiency experiment ----------------
     Exactly ONE absolute pressure equation must exist in a closed loop. Which component
     supplies it is switchable here so that precisely one initial condition changes between
     runs and nothing else does.

       use_tank = true   the ExpansionTank supplies it: level = level_start
       use_tank = false  connBottom supplies it: massDynamics = FixedInitial pins p = ps_start
                         on its volumes, which with nV = 1 is exactly one equation

     With nV = 1 the two settings differ by a single initial equation, which is what makes the
     comparison a controlled experiment rather than a rearrangement. */
  parameter Boolean use_tank=true
    "true: tank is the pressure anchor; false: connBottom is, via FixedInitial";
  parameter SI.Length L_leg=3.0 "Length of each vertical leg";
  parameter SI.Length L_conn=1.0 "Length of each horizontal connector";
  parameter SI.Volume V_leg=0.2 "Fluid volume of each leg";
  parameter SI.Volume V_conn=0.07 "Fluid volume of each connector";

  /* The driving pressure difference. A prescribed source rather than buoyancy,
     because this test is about whether the loop can be integrated through zero
     flow, not about reproducing natural circulation. */
  parameter SI.Pressure dp_amplitude=2000 "Peak driving pressure difference";

  /* Initial operating point. Both default to zero, which is the startup-from-rest case. Setting
     them to a matched non-zero pair gives the already-circulating case, which is what
     distinguishes whether a steady energy balance can initialize a loop that is already moving.
     The two must be consistent with each other: the loop is laminar throughout, so the flow
     responds linearly to the drive and dp_initial/dp_amplitude = m_flow_start/m_flow_at_dp_amplitude. */
  parameter SI.MassFlowRate m_flow_start=0 "Initial flow in every component";
  parameter SI.Pressure dp_initial=0 "Driving pressure difference at t = 0";
  parameter SI.Time t_sweep=10 "Time to sweep from +dp to -dp";

  inner TRANSFORM.Fluid.SystemTF systemTF(
    p_start=p_ref,
    T_start=T_start,
    allowFlowReversal=true,
    energyDynamics=TRANSFORM.Types.Dynamics.SteadyState,
    momentumDynamics=TRANSFORM.Types.Dynamics.SteadyState)
    annotation (Placement(transformation(extent={{-90,70},{-70,90}})));

  MSRE.Components.SaltPipe legUp(
    redeclare package Medium = Medium,
    nV=nV, V=V_leg, length=L_leg, dheight=L_leg,
    energyDynamics=energyDynamics, massDynamics=massDynamics, traceDynamics=traceDynamics,
    p_a_start=p_ref, T_a_start=T_start, m_flow_a_start=m_flow_start,
    exposeState_a=true, exposeState_b=false) "Upward leg"
    annotation (Placement(transformation(extent={{-40,-10},{-20,10}}, rotation=90)));

  MSRE.Components.SaltPipe connTop(
    redeclare package Medium = Medium,
    nV=nV, V=V_conn, length=L_conn, dheight=0,
    energyDynamics=energyDynamics, massDynamics=massDynamics, traceDynamics=traceDynamics,
    p_a_start=p_ref, T_a_start=T_start, m_flow_a_start=m_flow_start,
    exposeState_a=false, exposeState_b=false) "Top connector"
    annotation (Placement(transformation(extent={{-10,30},{10,50}})));

  MSRE.Components.SaltPipe legDown(
    redeclare package Medium = Medium,
    nV=nV, V=V_leg, length=L_leg, dheight=-L_leg,
    energyDynamics=energyDynamics, massDynamics=massDynamics, traceDynamics=traceDynamics,
    p_a_start=p_ref, T_a_start=T_start, m_flow_a_start=m_flow_start,
    exposeState_a=false, exposeState_b=false) "Downward leg"
    annotation (Placement(transformation(extent={{20,-10},{40,10}}, rotation=-90)));

  MSRE.Components.SaltPipe connBottom(
    redeclare package Medium = Medium,
    nV=nV, V=V_conn, length=L_conn, dheight=0,
    energyDynamics=energyDynamics,
    massDynamics=if use_tank then massDynamics else Modelica.Fluid.Types.Dynamics.FixedInitial,
    traceDynamics=traceDynamics,
    p_a_start=p_ref, T_a_start=T_start, m_flow_a_start=m_flow_start,
    exposeState_a=false, exposeState_b=false) "Bottom connector"
    annotation (Placement(transformation(extent={{10,-50},{-10,-30}})));

  /* The drive. A pump cannot command a negative pressure rise, so it cannot sweep
     the loop through zero into reverse; this is an ideal reversible pressure rise
     used for that purpose only. It is diagnostic scope and is not a pump model. */
  MSRE.Verification.BaseClasses.IdealPressureRise drive(redeclare package Medium = Medium)
    "Ideal reversible drive, swept from +dp through zero to -dp"
    annotation (Placement(transformation(extent={{-70,-50},{-50,-30}})));

  /* The drive profile starts at ZERO, not at +dp_amplitude. Momentum is algebraic, so the
     initial flow is whatever the momentum balance says the initial drive demands; starting the
     ramp at +2000 Pa while every m_flow_a_start is 0 puts the Newton initial guess far from
     the solution and the initialization fails before the test has begun. Starting from rest is
     both consistent with m_flow_a_start = 0 and the state this test has to prove is
     initializable in the first place.

       0 s -> 0 Pa      at rest
       2 s -> +dp       forward flow established
       7 s ->  0 Pa     crosses zero
      12 s -> -dp       reversed
  */
  Modelica.Blocks.Sources.TimeTable dpDrive(
    table=[0, dp_initial; 2, dp_amplitude; 7, 0; 12, -dp_amplitude],
    offset=0,
    startTime=0) "Driving pressure difference: rest, forward, through zero, reversed"
    annotation (Placement(transformation(extent={{-100,-46},{-86,-34}})));

  /* The single pressure anchor. A free surface at a known cover-gas pressure fixes the loop's
     absolute pressure level, which der(p) = 0 alone does not. This is the same role the pump
     bowl plays in PrimarySystem. Only port_a is connected: port_b is a FluidPort_State and an
     unconnected one carries no flow, so the tank acts as a single-port surge volume.

     massDynamics is FixedInitial here and SteadyStateInitial everywhere else, and the
     distinction is the whole point. ExpansionTank's initial equations are

       FixedInitial        level = level_start      ABSOLUTE
       SteadyStateInitial  der(level) = 0           DIFFERENTIAL

     and since port_a.p = p = p_ambient + rho*g*level, only the fixed form produces an equation
     that pins the loop's absolute pressure. A first attempt set the tank to
     SteadyStateInitial: every equation in the loop was then differential in pressure, nothing
     fixed the level, and the Jacobian stayed singular. That tank was not an anchor at all. */
  TRANSFORM.Fluid.Volumes.ExpansionTank tank(
    redeclare package Medium = Medium,
    A=0.25,
    V0=0.02,
    p_start=p_ref,
    level_start=0.1,
    T_start=T_start,
    massDynamics=TRANSFORM.Types.Dynamics.FixedInitial) if use_tank "Pressure anchor"
    annotation (Placement(transformation(extent={{-14,56},{6,76}})));

  SI.MassFlowRate m_flow=legUp.port_a.m_flow "Loop flow";
  SI.Temperature T_min=min(legUp.Ts) "Coldest node in the upward leg";
  SI.Temperature T_max=max(legUp.Ts) "Hottest node in the upward leg";
  SI.Density d_min=min(legUp.ds) "Lowest density";
  SI.Density d_max=max(legUp.ds) "Highest density";
  /* Continuous, not a when clause. An earlier version used
     "when m_flow < -1e-6 then reversed = true" and that condition generated about 100 state
     events of chattering at the crossing - a zero-crossing created by the INSTRUMENT, not by
     the physics. It did not change the result, but a diagnostic that perturbs the solver it is
     observing is exactly the mistake already made once with actualStream in Phase 20. */
  Real m_flow_min_seen(start=0) "Most negative flow reached; negative iff the loop reversed";

equation
  connect(dpDrive.y, drive.dp_in);
  connect(drive.port_b, legUp.port_a);
  connect(legUp.port_b, connTop.port_a);
  connect(connTop.port_b, legDown.port_a);
  if use_tank then
    connect(tank.port_a, connTop.port_b);
  end if;
  connect(legDown.port_b, connBottom.port_a);
  connect(connBottom.port_b, drive.port_a);

  der(m_flow_min_seen) = noEvent(if m_flow < m_flow_min_seen then -1e3*(m_flow_min_seen - m_flow) else 0);

  annotation (
    experiment(StopTime=12, Tolerance=1e-6),
    Documentation(info="<html>
<h4>Purpose</h4>
<p>Open item <b>O-32</b>, the closed-loop rung of the ladder. It uses the same
<a href=\"modelica://MSRE.Components.SaltPipe\">SaltPipe</a> components as
<a href=\"modelica://MSRE.Verification.O32_SinglePipe\">O32_SinglePipe</a> but wires them into a
<b>closed circuit</b>: an upward leg, a top connector, a downward leg, a bottom connector, and a
short drive section, with a single expansion tank as pressure anchor.</p>

<p>If the open single pipe passes and this fails, the difference is <b>loop closure</b> - the
circulating inventory and the closed pressure balance - and not the transport scheme, which is
identical in both. That is the discrimination the ladder exists to make.</p>

<h4>Physics layering</h4>
<p><code>energyDynamics</code> and <code>traceDynamics</code> are exposed so the same model can
be run isothermal, then with dynamic energy, then with trace transport, one step at a time.
Whichever step first breaks integrability is the answer, and each step is a separate run rather
than a judgement call.</p>

<h4>Scope</h4>
<p>This is <b>not</b> a natural circulation model. The drive is a prescribed pressure difference,
not buoyancy, because the question here is whether a closed loop can be integrated through zero
flow at all. Nothing is tuned, and the candidates already ruled out - the friction closure in
either direction, and <code>semiLinear</code> - are not revisited.</p>
</html>"));
end O32_ReducedLoop;
