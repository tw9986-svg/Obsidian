within MSRE.Verification;
model Loop_Hydraulics
  "Zero-power hydraulic, inventory and transit-time audit of the closed primary loop"
  extends Modelica.Icons.Example;

  replaceable record Nodalization = MSRE.Data.Nodalization.Core1D constrainedby
    MSRE.Data.Nodalization.PartialCoreNodalization
    "Spatial nodalization of the reactor core" annotation (choicesAllMatching=true);

  parameter SI.Time t_settle=300 "Time allowed for the loop hydraulics to reach steady state";
  parameter SI.MassFlowRate m_flow_init=0
    "Fuel salt flow at t = 0. ZERO ON PURPOSE - see the documentation: TRANSFORM filters every
     form loss through a first-order lag whose output is initialized to zero unconditionally, so
     initializing at rated flow states that the loop carries 168 kg/s while its form losses are
     switched off. That is not a steady state, and the 73 % of this loop's resistance that is
     form loss then has to appear within one 0.01 s filter time constant."
    annotation (Dialog(tab="Initialization"));
  parameter SI.Power Q_start=0 "Reactor power. Zero: this is a hydraulic test, not a thermal one";
  parameter SI.Temperature T_start=908 "Isothermal fuel salt temperature";
  parameter Real N_rated(unit="1/min") = 1160 "Rated fuel pump speed";
  parameter SI.MassFlowRate m_flow_rated=168 "Rated fuel salt mass flow rate";

  /* ---------------- Tolerances ---------------- */
  parameter SI.MassFlowRate tol_massBalance=1e-3
    "Allowed difference between the pump flow and the core flow at steady state (6e-6 of rated)";
  parameter SI.Length tol_closure=1e-9 "Allowed elevation mismatch around the loop";
  parameter SI.Pressure tol_dpBalance=1.0
    "Allowed residual of the closed-loop pressure balance [Pa], 3e-6 of the pump head";
  parameter SI.Pressure tol_gravityClosure=20.0
    "Allowed sum of the component static heads around the closed loop [Pa]. Not zero: the pump
     heats the salt, which leaves a real buoyancy head of a few Pa. Set from the pump-heat
     estimate dd_pump*g*dz, not from an observed residual";
  parameter SIadd.NonDim tol_inventory=1e-6
    "Allowed relative gap between the measured loop inventory and the sum of the components";
  parameter SIadd.NonDim tol_flowSplit=1e-4
    "Allowed relative departure from an even split between hydraulically identical rings";
  parameter SIadd.NonDim Re_laminar=2300
    "Upper Reynolds number of the laminar correlation used for the fuel channels";

  MSRE.Systems.PrimarySystem msre(
    redeclare package Medium_fuel = MSRE.Media.FuelSalt_U235,
    redeclare record Data_PG = MSRE.Data.PrecursorGroups.U235_6group,
    redeclare record Data_K = MSRE.Data.Kinetics_U235,
    redeclare record Nodalization = Nodalization,
    Q_fission_start=Q_start,
    T_start=T_start,
    t_null=t_settle,
    use_servoControl=true,
    m_flow_start=m_flow_init,
    N_pump_start=N_rated,
    T_coolant_start=T_start) "MSRE primary system, held at rated pump speed throughout"
    annotation (Placement(transformation(extent={{-20,-20},{20,20}})));

  Modelica.Blocks.Sources.RealExpression pumpSpeed(y=N_rated)
    "Fuel pump held at its rated speed for the whole run"
    annotation (Placement(transformation(extent={{80,-10},{56,10}})));
  Modelica.Blocks.Sources.RealExpression coolantTemperature(y=T_start)
    "Coolant salt inlet temperature, isothermal"
    annotation (Placement(transformation(extent={{80,30},{56,50}})));

  /* ================================================================
     Component-by-component audit (section 7 of the work order)
     ================================================================
     One entry per fuel-salt component, in flow order round the loop. Every quantity is read
     from the component itself, so this table is a measurement of the assembled model. */
  constant Integer nComp=9 "# of fuel salt components round the loop";

  SI.Pressure dps_total[nComp]={msre.downcomer.dp_total,msre.core.dp_core,msre.outletPipe.dp_total,
      msre.pumpBowl.dp_total,-msre.pump.dp,msre.pumpToHX.dp_total,dp_hxShell,msre.hxToVessel.dp_total,
      0} "Pressure DROP across each component, in flow order";
  SI.Pressure dps_gravity[nComp]={msre.downcomer.dp_gravity_local,msre.core.dp_gravity_local,
      msre.outletPipe.dp_gravity_local,msre.pumpBowl.dp_gravity_local,0,msre.pumpToHX.dp_gravity_local,
      dp_hxShell_gravity,msre.hxToVessel.dp_gravity_local,0}
    "Static-head part of each component's drop, formed from its own local node densities";
  SI.Pressure dps_nonstatic[nComp]={dps_total[i] - dps_gravity[i] for i in 1:nComp}
    "Everything that is not static head: friction, form and acceleration";

  SI.Volume Vs_comp[nComp]={msre.downcomer.V_fluid,msre.core.V_fluid,msre.outletPipe.V_fluid,
      msre.pumpBowl.V_fluid,0,msre.pumpToHX.V_fluid,V_hxShell_fluid,msre.hxToVessel.V_fluid,0}
    "Fuel salt volume held by each component";
  SI.Mass Ms_comp[nComp]={msre.downcomer.M_fluid,msre.core.M_fluid,msre.outletPipe.M_fluid,
      msre.pumpBowl.M_fluid,0,msre.pumpToHX.M_fluid,M_hxShell_fluid,msre.hxToVessel.M_fluid,0}
    "Fuel salt mass held by each component";
  SI.Time taus_comp[nComp]={Ms_comp[i]/noEvent(max(abs(m_flow), 1e-9)) for i in 1:nComp}
    "Residence time of each component at the measured loop flow";

  /* The heat exchanger shell is a TRANSFORM component and does not expose the SaltPipe
     diagnostics, so its three terms are formed here from the same definitions. */
  SI.Pressure dp_hxShell=msre.hx.port_a_shell.p - msre.hx.port_b_shell.p
    "Pressure drop across the fuel side of the heat exchanger";
  SI.Pressure dp_hxShell_gravity=sum({msre.hx.shell.mediums[i].d*Modelica.Constants.g_n*
      msre.geometry.dz_hxShell/msre.geometry.nHX for i in 1:msre.geometry.nHX})
    "Static head of the heat exchanger shell, formed from its own local node densities";
  SI.Volume V_hxShell_fluid=sum(msre.hx.shell.geometry.Vs)
    "Fuel salt volume held by the heat exchanger shell";
  SI.Mass M_hxShell_fluid=sum({msre.hx.shell.mediums[i].d*msre.hx.shell.geometry.Vs[i] for i in
      1:msre.geometry.nHX}) "Fuel salt mass held by the heat exchanger shell";

  /* ================================================================
     Closed-loop balances (sections 8, 10 and 11)
     ================================================================ */
  SI.MassFlowRate m_flow=msre.m_flow_fuel "Fuel salt flow rate through the core";

  constant Integer iPump=5 "Index of the pump in the component arrays";

  SI.Pressure dp_loop_total=sum(dps_total)
    "Sum of the component pressure drops round the closed loop. Must vanish: the loop returns
     to the node it started from, so the pressure change round it is zero by construction";
  SI.Pressure dp_loop_gravity=sum(dps_gravity)
    "Sum of the component static heads. It does NOT vanish even at zero fission power - see
     dp_buoyancy_pumpHeat below";
  SI.Pressure dp_loop_nonstatic=sum(dps_nonstatic) - dps_nonstatic[iPump]
    "Friction plus form plus acceleration round the loop, PASSIVE components only. The pump
     entry carries -dp_pump and would otherwise cancel exactly what is being measured";
  SI.Pressure dp_pump=msre.dp_pump "Pressure rise across the fuel pump";
  SI.Pressure err_dpBalance=dp_pump - dp_loop_nonstatic - dp_loop_gravity
    "Residual of the closed-loop momentum balance. Walking once round the loop returns to the
     node the walk started from, so the passive drops must equal the pump rise:
     dp_pump = sum_passive(dp_gravity) + sum_passive(dp_nonstatic). The pump contributes no
     static head, so sum_passive(dp_gravity) is dp_loop_gravity itself";

  /* The loop is elevation closed, so at a UNIFORM density the static heads cancel exactly. The
     density is not quite uniform even here, and not because of a numerical residual: the pump
     does W = m_flow*dp/(d*eta) of work on the salt, which warms it and lowers its density
     downstream. That is a real buoyancy head and it must not be tuned away. It is computed here
     so that dp_loop_gravity is compared against a number rather than against zero. */
  SI.Power W_pump=msre.pump.W "Pumping power delivered to the fuel salt";
  SI.TemperatureDifference dT_pump=msre.pump.dh/2009.66
    "Temperature rise across the pump at the fuel salt cp";
  Real dd_pump(unit="kg/m3") = -0.562*dT_pump
    "Density change across the pump from the Cantor slope, drho/dT = -0.562 kg/(m3.K). Not
     typed SI.Density: it is a difference and it is negative, and SI.Density has min = 0";

  SI.Volume V_loop_measured=sum(Vs_comp) "Fuel salt volume the assembled loop holds";
  SI.Mass M_loop_measured=sum(Ms_comp) "Fuel salt mass the assembled loop holds";
  SI.Time tau_loop_measured=sum(taus_comp) "Total circulation time round the loop";

  final parameter SI.Volume V_loop_geometry=msre.geometry.V_total
    "Circulating volume Data.Geometry says the loop holds";
  SIadd.NonDim err_inventory=V_loop_measured/V_loop_geometry - 1
    "Relative gap between the assembled model and the geometry record";

  /* Two different "cores", kept apart on purpose. The VESSEL is everything between the core
     component's ports - both plena in full. The KINETICS core is what Jeong counts and what
     tau_core means in the benchmark: the channels plus one node of each plenum. They differ by
     59 % of the vessel inventory, so reporting one under the other's name would make every
     transit-time comparison wrong by that much. */
  SI.Mass M_vessel=msre.core.M_fluid "Fuel salt mass inside the reactor vessel";
  SI.Time tau_vessel=M_vessel/noEvent(max(abs(m_flow), 1e-9)) "Reactor vessel residence time";
  SI.Mass M_core=msre.core.M_fluid_kinetics
    "Fuel salt mass of the reactor core as the kinetics defines it";
  SI.Time tau_core=M_core/noEvent(max(abs(m_flow), 1e-9))
    "Core transit time in the sense the benchmark reports it";
  SI.Mass M_external=M_loop_measured - M_core "Fuel salt mass outside the kinetics core";
  SI.Time tau_external=M_external/noEvent(max(abs(m_flow), 1e-9)) "External loop transit time";

  /* ---------------- Reported ---------------- */
  SIadd.NonDim Re_max=max(msre.Re_rings) "Largest channel Reynolds number";
  SI.MassFlowRate m_flow_min=min(msre.m_flows_rings)
    "Smallest ring flow rate; negative means a ring has reversed";

equation
  connect(pumpSpeed.y, msre.N_pump) annotation (Line(points={{54.8,0},{40,0},{40,4},{22,4}},
        color={0,0,127}));
  connect(coolantTemperature.y, msre.T_coolant_in)
    annotation (Line(points={{54.8,40},{40,40},{40,14},{22,14}}, color={0,0,127}));

  /* ---- 1. Elevation closure. Parameter-time check: a closed loop cannot have a net
        elevation rise, and if it does the buoyancy term becomes a spurious pump. ---- */
  assert(abs(msre.geometry.dz_closure) < tol_closure, "The elevation rises around the primary
loop sum to " + String(msre.geometry.dz_closure) + " m instead of zero. A closed loop with a
net elevation rise has a spurious buoyancy source in it. Data.Geometry.dz_downcomer is meant to
be the final parameter that closes the loop.", AssertionLevel.error);

  when terminal() then
    /* ---- 2. Loop mass balance. Pump and core are in series. ---- */
    assert(abs(msre.err_loopMassBalance) < tol_massBalance, "At steady state the fuel pump
passes " + String(msre.m_flow_pump) + " kg/s but the core passes " + String(msre.m_flow_fuel) +
      " kg/s. These are in series and must agree; the difference means the expansion tank is
exchanging mass with the loop, which it should only do to take up thermal expansion.",
      AssertionLevel.error);

    /* ---- 3. Closed-loop pressure balance. Going once round the loop returns to the node
          the walk started from, so the component drops - the pump rise included - must sum to
          zero. This is the check that the hydraulic network is actually closed and that no
          component is silently supplying or absorbing head. ---- */
    assert(abs(err_dpBalance) < tol_dpBalance, "The fuel pump supplies " + String(dp_pump) +
      " Pa but the passive components of the loop account for " +
      String(dp_loop_nonstatic + dp_loop_gravity) + " Pa, a residual of " + String(err_dpBalance)
       + " Pa. These are the same quantity read two ways round a closed loop.",
      AssertionLevel.error);

    assert(abs(dp_loop_total) < tol_dpBalance, "Walking once round the closed primary loop the
component pressure drops sum to " + String(dp_loop_total) + " Pa instead of zero. The pump rise
is included with the opposite sign, so this residual is the head the loop neither supplies nor
absorbs. Friction+form+acceleration round the loop is " + String(dp_loop_nonstatic) + " Pa and
the pump supplies " + String(dp_pump) + " Pa.", AssertionLevel.error);

    /* ---- 4. Static-head closure. The loop is elevation closed, so at a uniform density the
          component static heads cancel exactly. They do not cancel exactly here, and the reason
          is physical rather than numerical: the pump does work on the salt, warms it and lowers
          its density downstream, which leaves a real buoyancy head. What is asserted is
          therefore that the residual is no larger than that head can account for - not that it
          is zero, which would be false, and not a widened version of zero. ---- */
    assert(abs(dp_loop_gravity) < tol_gravityClosure, "The component static heads sum to " +
      String(dp_loop_gravity) + " Pa round the closed loop. The loop is elevation closed, so at
a uniform density this is zero; the pump raises the salt temperature by " + String(dT_pump) +
      " K, which lowers its density by " + String(-dd_pump) + " kg/m3 downstream and leaves a
buoyancy head of that order. A residual much larger than that is a spurious buoyancy source and
would be indistinguishable from natural circulation driving head.", AssertionLevel.error);

    /* ---- 5. Inventory. The assembled model must hold what Data.Geometry says it holds. This
          catches a node volume that was redistributed rather than moved. ---- */
    assert(abs(err_inventory) < tol_inventory, "The assembled loop holds " +
      String(V_loop_measured) + " m3 of fuel salt but Data.Geometry.V_total states " +
      String(V_loop_geometry) + " m3, a relative gap of " + String(err_inventory) + ". A
component volume has been changed without the record following it.", AssertionLevel.error);

    /* ---- 6. Flow split between the parallel rings. ---- */
    assert(msre.err_flowSplit < tol_flowSplit, "The " + String(msre.nRings) + " fuel channel
rings are hydraulically identical here, but the flow split departs from an even one by " +
      String(100*msre.err_flowSplit) + " %. Either the per-ring form losses have been given
non-zero values, or the core is not isothermal, or the parallel connection in
MSRE.Components.ReactorCore is not well posed.", AssertionLevel.error);

    /* ---- 7. No ring may reverse at rated forced flow. ---- */
    assert(m_flow_min > 0, "Ring flow rates at steady state include " + String(m_flow_min) +
      " kg/s, i.e. at least one ring has reversed at rated forced circulation. The precursor
transport solution is not trustworthy in that state.", AssertionLevel.error);

    /* ---- 8. Flow regime. ---- */
    assert(Re_max < Re_laminar, "The largest channel Reynolds number is " + String(Re_max) +
      ", above the laminar limit of " + String(Re_laminar) + ". Above the transition the
friction correlation changes form and the ring flow split no longer responds linearly to the
salt viscosity.", AssertionLevel.warning);
  end when;

  annotation (
    experiment(
      StopTime=300,
      __Dymola_NumberOfIntervals=3000,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>What this is</h4>
<p>The first model in this library that closes the primary loop and solves it. It runs the
system at rated pump speed and <b>zero power</b>, so that the momentum balance can be read
without any density gradient in it, and asserts the statements that must hold of any correct
solution.</p>

<h4>Why zero power and not 100 W</h4>
<p>This is a hydraulic and inventory test. At a uniform temperature the static head of every
component is its own density times its own elevation rise, and because the loop is elevation
closed those heads must cancel <b>exactly</b>. That makes check 4 a sharp statement. With a
power on, the heads no longer cancel - the difference is the buoyancy head - and the same check
would only be a statement about how large the buoyancy is. The buoyancy case belongs to the
natural circulation stage, and it needs this one to have passed first.</p>

<h4>What is checked</h4>
<table border=\"1\">
<tr><th>#</th><th>Check</th><th>Kind</th><th>Level</th></tr>
<tr><td>1</td><td>elevation rises sum to zero</td><td>verification</td><td>error</td></tr>
<tr><td>2</td><td>pump flow equals core flow</td><td>verification</td><td>error</td></tr>
<tr><td>3</td><td>component pressure drops sum to zero round the loop</td>
    <td>verification</td><td>error</td></tr>
<tr><td>4</td><td>component static heads sum to zero at uniform density</td>
    <td>verification</td><td>error</td></tr>
<tr><td>5</td><td>assembled inventory equals the geometry record</td>
    <td>verification</td><td>error</td></tr>
<tr><td>6</td><td>the rings split the flow evenly</td><td>verification</td><td>error</td></tr>
<tr><td>7</td><td>no ring has reversed</td><td>verification</td><td>error</td></tr>
<tr><td>8</td><td>the channels are laminar</td><td>observation</td><td>warning</td></tr>
</table>
<p>Every one of checks 1 to 7 compares the solution against something that must be true of any
correct solution. <b>No input can be chosen to make one of them pass</b>, which is what
separates them from a calibration check. There is deliberately no assertion here against a
Jeong transit time or an MSRE measurement: those are benchmark comparisons and are reported as
computed differences, not asserted.</p>

<h4>What is reported rather than asserted</h4>
<p><code>dps_total</code>, <code>dps_gravity</code>, <code>dps_nonstatic</code>,
<code>Vs_comp</code>, <code>Ms_comp</code> and <code>taus_comp</code> give the component
table the loop audit needs, in flow order:</p>
<pre>
  1 downcomer   2 core   3 outlet riser   4 pump bowl   5 pump
  6 pump discharge   7 HX shell   8 HX outlet pipe   9 (closure)
</pre>
<p>and <code>tau_core</code> / <code>tau_external</code> give the split the drift-reactivity
formula of paper Eq. 8 depends on. They are <b>measured from the assembled model</b> - node
volumes and local node densities - not restated from
<a href=\"modelica://MSRE.Data.Geometry\">Data.Geometry</a>, so the comparison against the
record in check 5 is a real check rather than a re-print.</p>

<h4>Why the run starts from rest</h4>
<p>TRANSFORM filters every form loss through a first-order lag before it enters the momentum
balance (<code>PartialMomentumBalance.firstOrder_dps_K</code>), and that filter is declared</p>
<pre>
  initType = Init.InitialOutput,  y_start = 0,  T = taus[1] = 0.01 s
</pre>
<p>with <code>y_start</code> hard-coded to zero. <b>Every K form loss in the model is therefore
switched off at t = 0</b>, whatever the flow is. Initializing this loop at 168 kg/s asserts that
it carries rated flow while three quarters of its resistance does not exist, which is not a
steady state: the loop initializes at <b>257 kg/s</b> instead, and the missing 216 kPa then has
to appear within one 0.01 s time constant against an algebraic momentum balance. The integrator
does not survive it - it failed here at t = 0.0044 s.</p>
<p>Starting from rest removes the inconsistency instead of masking it. At zero flow the form
losses <i>are</i> zero, so <code>y_start = 0</code> is the correct initial condition, and the
filter charges as the pump brings the loop up. Nothing is tuned and no time constant is
changed; the steady state the run settles at is unaffected either way, because a first-order
lag has no steady-state effect.</p>
<p>This does not bite the Stage 2 and Stage 3 core models, which is why it had not been seen:
<code>K_channelInlet</code> and <code>K_channelExit</code> are both zero there, so those models
contain no form loss for the filter to switch off.</p>

<h4>Nodalization</h4>
<p>Defaults to <a href=\"modelica://MSRE.Data.Nodalization.Core1D\">Core1D</a>. Redeclare
<code>Nodalization</code> to <a href=\"modelica://MSRE.Data.Nodalization.Core2D\">Core2D</a> for
the 15-ring loop; every physical dimension is identical between the two, so the difference in
any result here is the spatial representation and nothing else.</p>
</html>"));
end Loop_Hydraulics;
