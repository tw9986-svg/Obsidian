within MSRE.Verification;
model LowFlow_Hydraulics
  "O-24 | Is the primary loop integrable at rest? Baseline mass-balance formulation"
  extends Modelica.Icons.Example;

  replaceable record Nodalization = MSRE.Data.Nodalization.Core1D constrainedby
    MSRE.Data.Nodalization.PartialCoreNodalization
    "Spatial nodalization of the reactor core" annotation (choicesAllMatching=true);

  /* ------------------------------------------------------------------
     The variable under test. Everything else is held fixed, so the only
     difference between this model and its SteadyStateMass variant is the
     formulation of the mass and energy balances.
     ------------------------------------------------------------------ */
  parameter Modelica.Fluid.Types.Dynamics energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial
    "Formulation of the energy balance" annotation (Evaluate=true);
  parameter Modelica.Fluid.Types.Dynamics massDynamics=Modelica.Fluid.Types.Dynamics.SteadyStateInitial
    "Formulation of the mass balance - THE VARIABLE UNDER TEST" annotation (Evaluate=true);
  /* Third contributor under test. This is a zero-power hydraulic model, so there is no precursor
     source and the trace states should be identically zero; in practice they wander to +/-1e-17
     and trip the min = 0 constraint on Cs, once per group per node per step. Making the trace
     balance SteadyState removes those states from the integration entirely. No hydraulic
     quantity depends on them here. */
  parameter Modelica.Fluid.Types.Dynamics traceDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial
    "Formulation of the trace-substance balance" annotation (Evaluate=true);

  parameter SI.Temperature T_start=908 "Isothermal fuel salt temperature";
  parameter Real N_pump(unit="1/min") = 0
    "Fuel pump speed. ZERO: the loop is at rest, which is the regime natural circulation lives in";

  MSRE.Systems.PrimarySystem msre(
    redeclare package Medium_fuel = MSRE.Media.FuelSalt_U235,
    redeclare record Data_PG = MSRE.Data.PrecursorGroups.U235_6group,
    redeclare record Data_K = MSRE.Data.Kinetics_U235,
    redeclare record Nodalization = Nodalization,
    energyDynamics=energyDynamics,
    massDynamics=massDynamics,
    traceDynamics=traceDynamics,
    Q_fission_start=0,
    T_start=T_start,
    t_null=1e9,
    use_servoControl=false,
    m_flow_start=0,
    N_pump_start=0,
    T_coolant_start=T_start) "MSRE primary system, isothermal, zero power, pump off"
    annotation (Placement(transformation(extent={{-20,-20},{20,20}})));

  Modelica.Blocks.Sources.RealExpression pumpSpeed(y=N_pump) "Pump off"
    annotation (Placement(transformation(extent={{80,-10},{56,10}})));
  Modelica.Blocks.Sources.RealExpression coolantTemperature(y=T_start) "Isothermal"
    annotation (Placement(transformation(extent={{80,30},{56,50}})));

  /* ---------------- Reported ---------------- */
  SI.MassFlowRate m_flow_fuel=msre.m_flow_fuel "Loop flow; should stay at rest";
  SI.Mass M_core=msre.core.M_fluid "Fuel salt mass inside the reactor vessel";
  SI.Pressure p_core=msre.core.port_a.p "A representative loop pressure";

equation
  connect(pumpSpeed.y, msre.N_pump)
    annotation (Line(points={{54.8,0},{22,4}}, color={0,0,127}));
  connect(coolantTemperature.y, msre.T_coolant_in)
    annotation (Line(points={{54.8,40},{22,14}}, color={0,0,127}));

  annotation (
    experiment(StopTime=10, Tolerance=1e-6),
    Documentation(info="<html>
<h4>Purpose</h4>
<p>Open item <b>O-24</b>, the blocker for natural circulation. The loop at rest is not a corner
case for natural circulation - it is where natural circulation starts and, if the flow ever
reverses, where it passes through. Phase 17 measured <b>0.036 s of simulated time per four
minutes of wall clock</b> for this state and ruled out solver tolerance, the nonlinear solver
choice, the homotopy path, the pump's zero-flow singularity and the momentum formulation.</p>

<p>The remaining candidate was the <b>mass-balance formulation</b>. With a dynamic mass balance
and a nearly incompressible fluid the pressure states carry acoustic modes: at
<code>kappa = 2.89e-10 1/Pa</code> and <code>rho = 2196.5 kg/m3</code> the sound speed is about
1255 m/s, so an acoustic traverse of the loop is a few tens of milliseconds. At rest there is no
bulk motion for the solver's error test to be dominated by, and the integrator spends everything
resolving those modes.</p>

<p>This model is the baseline arm of that experiment: the mass balance as the repository
currently formulates it. The other arm is
<a href=\"modelica://MSRE.Verification.LowFlow_Hydraulics_SteadyMass\">LowFlow_Hydraulics_SteadyMass</a>,
which is identical in every respect except that the mass balance is <code>SteadyState</code>.
Nothing physical differs between them - no geometry, no property, no friction, no form loss.</p>

<h4>How to read the result</h4>
<p>The measurement is <b>simulated seconds per wall-clock second</b>, not an assertion. A model
that reaches <code>StopTime</code> is integrable in this regime; one that does not is the
blocker. There is deliberately no tolerance to widen here.</p>
</html>"));
end LowFlow_Hydraulics;
