within MSRE.Verification;
model NaturalCirculation_TH
  "Thermal-hydraulic only natural circulation: verification of the buoyancy physics chain"
  extends Modelica.Icons.Example;

  replaceable record Nodalization = MSRE.Data.Nodalization.Core1D constrainedby
    MSRE.Data.Nodalization.PartialCoreNodalization
    "Spatial nodalization of the reactor core" annotation (choicesAllMatching=true);

  /* ---------------- Operating point ---------------- */
  parameter SI.Power Q_core_test=1e5
    "Core power held constant throughout. A fixed heat input, not a kinetics solution";
  parameter SI.Temperature T_start=908 "Initial isothermal fuel salt temperature";
  parameter SI.Temperature T_sink=894
    "Coolant salt inlet temperature. This is the only heat sink in the model";
  parameter Real N_rated(unit="1/min") = 1160 "Rated fuel pump speed";

  /* ---------------- The transient ----------------
     The run is a PUMP TRIP, not a start from rest. The loop is brought to its forced steady
     state at rated speed, the pump speed is then ramped to exactly zero, and the loop is left
     to find whatever circulation the density field can sustain. That is the physical natural
     circulation situation, and it is also the only one this model can be initialized in - see
     the documentation, section "Why the run starts at rated speed". Nothing about the flow is
     prescribed at any point: the pump SPEED is an input and it is set to zero, which is what
     the operator does. */
  parameter SI.Time t_trip=300
    "Time at which the pump speed starts to fall. Long enough for the forced loop to settle";
  parameter SI.Time t_ramp=10 "Duration of the speed ramp to zero";
  final parameter SI.Time t_natural=t_trip + t_ramp
    "Time from which the pump speed is exactly zero";
  parameter SI.Time t_settle=4000
    "Run length. Natural circulation settles on the loop transit time, which is minutes at
     these flows, not the 27.7 s of the forced loop";

  /* ---------------- Tolerances ---------------- */
  parameter SI.MassFlowRate tol_massBalance=1e-3
    "Allowed difference between the pump flow and the core flow at steady state";
  parameter SI.Pressure tol_dpBalance=1e-2
    "Allowed residual of the closed-loop momentum balance [Pa]. Tighter than the forced-loop
     value because the head being balanced here is of order 1e2 Pa, not 1e5 Pa";
  parameter SIadd.NonDim tol_energyBalance=1e-3
    "Allowed relative gap between the core power and the heat removed by the heat exchanger";
  parameter SI.Power tol_pumpPower=1e-6
    "Allowed POSITIVE hydraulic power delivered by the pump at zero speed. A pump at rest may
     only dissipate; any positive value is a spurious driving source. Stated as a power rather
     than as a pressure because dp is an ODD function of the flow - see MSRE.Verification.Pump_ZeroSpeed";
  parameter SIadd.NonDim tol_buoyancyEstimate=0.25
    "Allowed relative gap between the measured buoyancy head and the two-thermal-centre
     estimate. Loose on purpose: the estimate lumps each leg into one density and one
     elevation, so it is an order-of-magnitude cross-check, not a second solution";

  MSRE.Systems.PrimarySystem msre(
    redeclare package Medium_fuel = MSRE.Media.FuelSalt_U235,
    redeclare record Data_PG = MSRE.Data.PrecursorGroups.U235_6group,
    redeclare record Data_K = MSRE.Data.Kinetics_U235,
    redeclare record Nodalization = Nodalization,
    Q_fission_start=Q_core_test,
    T_start=T_start,
    t_null=0,
    use_servoControl=true,
    m_flow_start=0,
    N_pump_start=N_rated,
    T_coolant_start=T_sink)
    "MSRE primary system driven by a constant core power. m_flow_start = 0 for the reason given
     in MSRE.Verification.Loop_Hydraulics: TRANSFORM initializes every form-loss filter output
     to zero, so a rated-flow initial guess states that the loop carries 168 kg/s with three
     quarters of its resistance switched off"
    annotation (Placement(transformation(extent={{-20,-20},{20,20}})));

  Modelica.Blocks.Sources.Ramp pumpSpeed(
    height=-N_rated,
    duration=t_ramp,
    offset=N_rated,
    startTime=t_trip)
    "Fuel pump speed: rated until t_trip, then ramped to EXACTLY zero and held there. NOT a
     prescribed flow - the pump stays in the loop and its characteristic degenerates to a
     passive quadratic resistance once the speed reaches zero"
    annotation (Placement(transformation(extent={{80,-10},{56,10}})));
  Modelica.Blocks.Sources.RealExpression coolantTemperature(y=T_sink)
    "Coolant salt inlet temperature, the single heat sink"
    annotation (Placement(transformation(extent={{80,30},{56,50}})));

  /* ================================================================
     1. Flow and temperatures
     ================================================================
     Nothing here is imposed. m_flow is a solution variable of the momentum balance, and the
     only thing driving it is the density field. */
  Real N_pump_actual(unit="1/min") = msre.N_pump_actual "Actual pump shaft speed";
  SI.MassFlowRate m_flow=msre.m_flow_fuel "Fuel salt flow rate. SOLVED, not prescribed";
  SIadd.NonDim m_flow_norm=m_flow/168 "Flow rate as a fraction of the rated 168 kg/s";

  SI.Temperature T_core_in=msre.core.T_in "Fuel salt temperature entering the reactor vessel";
  SI.Temperature T_core_out=msre.core.T_out "Fuel salt temperature leaving the reactor vessel";
  SI.TemperatureDifference dT_core=T_core_out - T_core_in "Core temperature rise";

  SI.Temperature T_hx_in=msre.hx.shell.mediums[1].T
    "Fuel salt temperature at the first heat exchanger shell node";
  SI.Temperature T_hx_out=msre.hx.shell.mediums[msre.geometry.nHX].T
    "Fuel salt temperature at the last heat exchanger shell node";
  SI.TemperatureDifference dT_hx=T_hx_in - T_hx_out "Fuel salt temperature drop in the HX";

  /* ================================================================
     2. Density field: the cause, measured separately from the effect
     ================================================================
     The hot leg is everything between the core exit and the heat exchanger inlet; the cold leg
     is everything between the heat exchanger exit and the core inlet. Each leg density is
     VOLUME weighted, because that is the weighting a static head applies. */
  SI.Volume V_hot=msre.outletPipe.V_fluid + msre.pumpBowl.V_fluid + msre.pumpToHX.V_fluid
    "Fuel salt volume of the hot leg";
  SI.Mass M_hot=msre.outletPipe.M_fluid + msre.pumpBowl.M_fluid + msre.pumpToHX.M_fluid
    "Fuel salt mass of the hot leg";
  SI.Density rho_hot=M_hot/V_hot "Volume-averaged hot leg density";

  SI.Volume V_cold=msre.hxToVessel.V_fluid + msre.downcomer.V_fluid
    "Fuel salt volume of the cold leg";
  SI.Mass M_cold=msre.hxToVessel.M_fluid + msre.downcomer.M_fluid
    "Fuel salt mass of the cold leg";
  SI.Density rho_cold=M_cold/V_cold "Volume-averaged cold leg density";

  Real delta_rho(unit="kg/m3") = rho_cold - rho_hot
    "Density difference driving the circulation. POSITIVE is the physical direction: the cold
     leg is heavier. Not typed SI.Density, which has min = 0 and would hide a sign failure";

  /* ================================================================
     3. Momentum balance of the closed loop
     ================================================================
     Read component by component in flow order, exactly as MSRE.Verification.Loop_Hydraulics
     does, so that the two models measure the same quantity two ways. */
  constant Integer nComp=9 "# of fuel salt components round the loop";
  constant Integer iPump=5 "Index of the pump in the component arrays";

  SI.Pressure dps_total[nComp]={msre.downcomer.dp_total,msre.core.dp_core,msre.outletPipe.dp_total,
      msre.pumpBowl.dp_total,-msre.pump.dp,msre.pumpToHX.dp_total,dp_hxShell,msre.hxToVessel.dp_total,
      0} "Pressure DROP across each component, in flow order";
  SI.Pressure dps_gravity[nComp]={msre.downcomer.dp_gravity_local,msre.core.dp_gravity_local,
      msre.outletPipe.dp_gravity_local,msre.pumpBowl.dp_gravity_local,0,msre.pumpToHX.dp_gravity_local,
      dp_hxShell_gravity,msre.hxToVessel.dp_gravity_local,0}
    "Static head of each component, formed from its own local node densities";
  SI.Pressure dps_nonstatic[nComp]={dps_total[i] - dps_gravity[i] for i in 1:nComp}
    "Friction, form and acceleration of each component";

  SI.Pressure dp_hxShell=msre.hx.port_a_shell.p - msre.hx.port_b_shell.p
    "Pressure drop across the fuel side of the heat exchanger";
  SI.Pressure dp_hxShell_gravity=sum({msre.hx.shell.mediums[i].d*Modelica.Constants.g_n*
      msre.geometry.dz_hxShell/msre.geometry.nHX for i in 1:msre.geometry.nHX})
    "Static head of the heat exchanger shell, from its own local node densities";

  SI.Pressure dp_buoyancy=-sum(dps_gravity)
    "Net driving head produced by the density field. The component terms are pressure DROPS, so
     the head the loop GAINS from buoyancy is minus their sum. At a uniform density the loop is
     elevation closed and this vanishes identically; it is nonzero here only because the salt
     is hot in one leg and cold in the other";
  SI.Pressure dp_friction_total=sum(dps_nonstatic) - dps_nonstatic[iPump]
    "Friction plus form plus acceleration round the loop, PASSIVE components only";
  SI.Pressure dp_pump=msre.dp_pump
    "Pressure rise across the fuel pump. Negative in forward flow at N = 0";
  SI.Power W_pump=msre.pump.W "Power the pump delivers to the fuel salt. Expected <= 0 at N = 0";
  SI.Pressure dp_loop_residual=dp_buoyancy + dp_pump - dp_friction_total
    "Residual of the closed-loop momentum balance: what drives the loop minus what resists it";

  /* Per-segment contributions, so that a wrong sign can be attributed to one component rather
     than inferred from the total. */
  SI.Pressure dp_buoyancy_core=-dps_gravity[2] "Buoyancy head gained across the reactor vessel";
  SI.Pressure dp_buoyancy_hotLeg=-(dps_gravity[3] + dps_gravity[4] + dps_gravity[6])
    "Buoyancy head gained across the hot leg";
  SI.Pressure dp_buoyancy_hx=-dps_gravity[7] "Buoyancy head gained across the heat exchanger";
  SI.Pressure dp_buoyancy_coldLeg=-(dps_gravity[8] + dps_gravity[1])
    "Buoyancy head gained across the cold leg";

  /* ---- Independent calculation, not a second solution ----
     Lumping each leg into one density and the source and the sink into one elevation each
     gives the textbook two-thermal-centre head. It is computed from the geometry record and
     from the two leg densities above, and it is compared against dp_buoyancy only to confirm
     the ORDER OF MAGNITUDE and the SIGN of the measured head. It is not used anywhere in the
     solution and nothing is fitted to it. */
  final parameter SI.Length z_coreOutlet=msre.geometry.dz_lowerPlenum + msre.geometry.dz_channels
       + msre.geometry.dz_upperPlenum "Elevation of the core exit above the core inlet";
  final parameter SI.Length z_coreCentre=z_coreOutlet/2 "Elevation of the heat source centre";
  final parameter SI.Length z_hxInlet=z_coreOutlet + msre.geometry.dz_outletPipe + msre.geometry.dz_pumpBowl
       + msre.geometry.dz_pumpToHX "Elevation of the heat exchanger inlet";
  final parameter SI.Length z_hxCentre=z_hxInlet + msre.geometry.dz_hxShell/2
    "Elevation of the heat sink centre";
  final parameter SI.Length H_thermal=z_hxCentre - z_coreCentre
    "Elevation of the sink centre above the source centre. Must be POSITIVE for the loop to
     circulate in the forward direction at all";
  SI.Pressure dp_buoyancy_estimate=delta_rho*Modelica.Constants.g_n*H_thermal
    "INDEPENDENT CALCULATION: two-thermal-centre buoyancy head";

  /* ================================================================
     4. Conservation
     ================================================================ */
  SI.MassFlowRate err_massBalance=msre.err_loopMassBalance
    "Pump flow minus core flow. Zero at steady state";

  SI.Power Q_core=msre.Q_core "Core power. Held constant by the servo, so a fixed heat input";
  SI.Power Qs_hx_nodes[msre.geometry.nHX]={msre.hx.shell.nParallel*sum(msre.hx.shell.heatTransfer.Q_flows[
      i, :]) for i in 1:msre.geometry.nHX}
    "Heat flow INTO each heat exchanger shell node from the tube wall. Negative when the node is
     being cooled, which is the expected direction";
  SI.Power Q_hx=-sum(Qs_hx_nodes)
    "Heat removed from the fuel salt by the heat exchanger. Read from the wall heat flows rather
     than from a port enthalpy difference: an actualStream() taken on a connector inside the
     system model adds an outside reader to a stream connection set, and that changed how the
     loop pressure network was torn";
  SIadd.NonDim err_energyBalance=(Q_core - Q_hx)/Q_core
    "Relative gap between what is put in and what is taken out. Zero at steady state";

  /* ================================================================
     5. Regime
     ================================================================ */
  SIadd.NonDim Re_channel=msre.Re_rings[1] "Fuel channel Reynolds number";
  SI.Time tau_system=msre.tau_system "Loop transit time at the circulating flow";

equation
  connect(pumpSpeed.y, msre.N_pump) annotation (Line(points={{54.8,0},{40,0},{40,4},{22,4}},
        color={0,0,127}));
  connect(coolantTemperature.y, msre.T_coolant_in)
    annotation (Line(points={{54.8,40},{40,40},{40,14},{22,14}}, color={0,0,127}));

  /* ---- Parameter-time check: the sink must sit above the source ---- */
  assert(H_thermal > 0, "The heat exchanger thermal centre is " + String(H_thermal) + " m above
the core thermal centre. A non-positive value means the sink is at or below the source and the
loop cannot circulate in the forward direction by buoyancy at all - any forward flow the model
then produces has some other origin.", AssertionLevel.error);

  when terminal() then
    /* ---- 0. The pump really is off ---- */
    assert(abs(N_pump_actual) < 1e-12, "The fuel pump is turning at " + String(N_pump_actual) +
      " rpm at the end of the run. Every statement below is about a loop with the pump stopped;
if the speed is not identically zero the circulation reported is partly forced.",
      AssertionLevel.error);

    /* ---- 1. The pump is not a power source at rest ---- */
    assert(W_pump < tol_pumpPower, "With the shaft at rest the fuel pump delivers " +
      String(W_pump) + " W to the fuel salt, at a pressure rise of " + String(dp_pump) + " Pa
and a flow of " + String(m_flow) + " kg/s. A pump at zero speed has
head = -R_pump*regSquare(V_flow), which is dissipative whichever way the flow runs. A positive
value means the model is supplying driving power at N = 0, and the circulation reported here
would then not be natural circulation. The invariant is the POWER, not the sign of dp: dp is an
odd function of the flow and is legitimately positive in reverse flow.",
      AssertionLevel.error);

    /* ---- 2. The density field has the physical sign ---- */
    assert(delta_rho > 0, "The cold leg density minus the hot leg density is " + String(delta_rho)
       + " kg/m3. The heated leg must be the lighter one. A non-positive value means either the
heat is not reaching the fuel salt, or the density is not responding to temperature, and in
either case the buoyancy head below is not what it claims to be.", AssertionLevel.error);

    /* ---- 3. The measured driving head is the buoyancy head ---- */
    assert(dp_buoyancy > 0, "The net static head round the loop gives a driving head of " +
      String(dp_buoyancy) + " Pa. The loop is elevation closed, so at a uniform density this is
identically zero; it can only be positive here, and only because the cold leg is heavier.",
      AssertionLevel.error);

    /* ---- 4. Closed-loop momentum balance ---- */
    assert(abs(dp_loop_residual) < tol_dpBalance, "The loop is driven by " + String(dp_buoyancy)
       + " Pa of buoyancy and " + String(dp_pump) + " Pa of pump head, and resisted by " +
      String(dp_friction_total) + " Pa, leaving a residual of " + String(dp_loop_residual) +
      " Pa. Round a closed loop these are the same quantity read two ways and the residual must
vanish.", AssertionLevel.error);

    /* ---- 5. Mass balance ---- */
    assert(abs(err_massBalance) < tol_massBalance, "The fuel pump passes " + String(msre.m_flow_pump)
       + " kg/s and the core passes " + String(msre.m_flow_fuel) + " kg/s. They are in series
and must agree at steady state.", AssertionLevel.error);

    /* ---- 6. Energy balance ---- */
    assert(abs(err_energyBalance) < tol_energyBalance, "The core adds " + String(Q_core) +
      " W and the heat exchanger removes " + String(Q_hx) + " W, a relative gap of " +
      String(err_energyBalance) + ". At steady state the loop stores nothing.",
      AssertionLevel.error);

    /* ---- 7. Cross-check against the independent two-thermal-centre calculation ---- */
    assert(abs(dp_buoyancy/dp_buoyancy_estimate - 1) < tol_buoyancyEstimate, "The measured
buoyancy head is " + String(dp_buoyancy) + " Pa and the two-thermal-centre estimate formed from
the same leg densities is " + String(dp_buoyancy_estimate) + " Pa. These are the same head
computed from the distributed density field and from a lumped one; a large gap means the
density is not distributed the way the lumped picture assumes, which changes what H_thermal
means.", AssertionLevel.warning);

    /* ---- 8. Forward circulation ---- */
    assert(m_flow > 0, "The circulating flow settled at " + String(m_flow) + " kg/s. A negative
value is a reversed loop; zero is a stagnant one. Neither is a natural circulation solution,
and the temperatures reported above would then not be transport temperatures.",
      AssertionLevel.error);
  end when;

  annotation (
    experiment(
      StopTime=4000,
      __Dymola_NumberOfIntervals=8000,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>What this is and what it is not</h4>
<p>This model is <b>physics-chain verification, not benchmark reproduction</b>. It exists to
answer one question: when the pump is switched off and a fixed heat input is left in the core,
does this model produce a circulating flow, and is that flow produced by the density field
rather than by anything else? No result from it is to be compared against Jeong or against an
MSRE measurement.</p>

<h4>What has been removed</h4>
<table border=\"1\">
<tr><th>Removed</th><th>How</th></tr>
<tr><td>prescribed flow</td><td><code>m_flow</code> is a solution variable throughout; there is
no flow boundary condition anywhere on the fuel side</td></tr>
<tr><td>pump head</td><td><code>N_pump = 0</code> for the whole run. The pump component stays in
the loop, where its characteristic degenerates to
<code>head = -R_pump*regSquare(V_flow)</code> - a passive resistance. Check 1 asserts that it
delivers no power to the salt.
<a href=\"modelica://MSRE.Verification.Pump_ZeroSpeed\">Pump_ZeroSpeed</a> verifies the same
thing over the whole characteristic rather than at the single point reached here</td></tr>
<tr><td>kinetics</td><td><code>use_servoControl = true</code> sets <code>der(N) = 0</code>, so
<code>Q_fission = Q_fission_start</code> identically. The core power is a fixed number and no
reactivity, feedback or flux solution can change it</td></tr>
<tr><td>precursor feedback</td><td>the six groups are still transported, because they are trace
substances of the medium, but with the servo on they enter no equation that affects the flow,
the temperature or the density. <code>Beta_eff</code> is reported by the system model and is
diagnostic only here</td></tr>
</table>

<h4>What is left</h4>
<p>Gravity, the salt density law, the friction and form closures, the heat exchanger, and one
pressure anchor - the expansion tank at the pump suction, which is the only fuel-side pressure
boundary in <a href=\"modelica://MSRE.Systems.PrimarySystem\">PrimarySystem</a>. The causal
chain the model has to close on its own is</p>
<pre>
  Q_core -> dT_core -> delta_rho -> dp_buoyancy -> m_flow -> dT_core
</pre>
<p>and each arrow is reported separately so that a break can be located rather than inferred.</p>

<h4>Why the checks are written the way they are</h4>
<p>Every assertion compares the solution against something that must be true of any correct
solution - a sign, a conservation law, or a closed-loop identity. <b>None of them can be made
to pass by choosing an input.</b> In particular:</p>
<ul>
<li>check 2 (<code>delta_rho &gt; 0</code>) and check 3 (<code>dp_buoyancy &gt; 0</code>) are
written on the signed quantities. Taking an absolute value anywhere in this model would let a
reversed density gradient or a reversed driving head pass unnoticed, so no
<code>abs()</code> appears in the definition of any of them - only in the residual checks,
where the quantity being bounded is a difference that should vanish;</li>
<li>check 7 is a <code>warning</code>, not an <code>error</code>. The two-thermal-centre
estimate lumps each leg into a single density and a single elevation, which the distributed
solution does not do. It is an independent order-of-magnitude calculation and it is labelled as
one; it is not a second solution and the model is not fitted to it.</li>
</ul>

<h4>Why the run starts at rated speed</h4>
<p>The obvious way to set this test up is to start from a stagnant isothermal loop and switch
the power on. <b>That initial condition cannot be solved</b>, and the reason is a property of
the discretization rather than of the physics: the face states of the TRANSFORM flow model are
donor-cell upwind states, so the weight that selects between the two neighbouring cells
<i>is</i> the mass flow rate. At exactly zero flow the face temperature has no determining
equation at all, while the pressure network still needs the density - and therefore the
temperature - of every face to form its static heads. OpenModelica reports this as</p>
<pre>
  residualFunc6802: Iteration variable
  msre.outletPipe.pipe.flowModel.states[5].T is inf or nan
</pre>
<p>on the 65-unknown loop pressure system, with or without homotopy. It is the same degeneracy
that was traced in the reduced loop, one level further in: <code>energyDynamics =
FixedInitial</code> pins the <i>cell</i> temperatures, and those are fine; it says nothing about
the <i>face</i> states, which are algebraic.</p>
<p>So the run is set up as the transient it actually is. The pump trips, and a tripping pump is
what produces natural circulation in a real loop. Initialization then happens at 1160 rpm,
which is the operating point
<a href=\"modelica://MSRE.Verification.Loop_Hydraulics\">Loop_Hydraulics</a> already
initializes cleanly, and the loop passes through the low-flow region as a <i>transient</i>,
where the face states are carried by the integrator and never have to be solved for from
nothing.</p>
<p>Nothing is prescribed about the flow by doing this. The pump <b>speed</b> is the input and
it is driven to exactly zero; the flow that remains afterwards is whatever the momentum balance
sustains. Check 0 asserts that the speed really is zero at the end, and checks 1 to 8 are all
evaluated there.</p>

<h4>Run length</h4>
<p><code>t_settle</code> defaults to 4000 s rather than the 300 s of
<a href=\"modelica://MSRE.Verification.Loop_Hydraulics\">Loop_Hydraulics</a>, of which the
first 300 s are the forced settling phase. Natural
circulation settles on the loop transit time, and at a few per cent of rated flow that time is
tens of minutes rather than the 27.7 s of the forced loop. A run that stops before the
temperatures have come round the loop several times reports a transient as a steady state, and
checks 4 to 6 would then fail for a reason that has nothing to do with the physics.</p>
</html>"));
end NaturalCirculation_TH;
