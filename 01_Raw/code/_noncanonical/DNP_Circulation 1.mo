within MSRE.Verification;
model Core2D_TH_ZeroPower
  "O-29 rung 2 | The 15-ring reactor core with its plena, zero power, fixed flow: does the 2-D core initialize on its own?"
  extends Modelica.Icons.Example;

  import TRANSFORM;

  replaceable package Medium = MSRE.Media.FuelSalt_U235 constrainedby
    Modelica.Media.Interfaces.PartialMedium "Fuel salt property model"
    annotation (choicesAllMatching=true);

  parameter MSRE.Data.Geometry geometry "MSRE hardware geometry and reference operating data";
  replaceable parameter MSRE.Data.Nodalization.Core2D nodalization(geometry=geometry)
    constrainedby MSRE.Data.Nodalization.PartialCoreNodalization
    "15-ring 2-D core nodalization. Replaceable so that a mesh-convergence study can supply a
     different radial cut of the same hardware without duplicating this model; the default and
     every behaviour of this model are unchanged."
    annotation (choicesAllMatching=true);

  /* ------------------------------------------------------------------
     Test definition
     ------------------------------------------------------------------ */
  parameter SI.MassFlowRate m_flow_set=geometry.m_flow_nominal "Imposed total core flow rate";
  parameter SI.Temperature T_in_set=908 "Imposed core inlet temperature";
  parameter SI.Power Q_core=0
    "Fixed thermal test power. A TH verification condition, not a Jeong transient validation target";
  parameter SI.AbsolutePressure p_out=geometry.p_system "Outlet pressure boundary condition";
  final parameter SI.Length dz_coreColumn=geometry.dz_lowerPlenum + geometry.dz_channels +
      geometry.dz_upperPlenum "Elevation the salt gains crossing the whole core";
  final parameter SI.AbsolutePressure p_start_core=p_out + geometry.d_fuel_ref*Modelica.Constants.g_n
      *dz_coreColumn
    "Initial guess for the core inlet pressure: the outlet boundary plus the static head of the whole column. A start value, not a test condition";
  parameter SI.Power Q_energyNorm=8e6
    "Scale used to normalize the energy residual when Q_core = 0. Not a test condition";

  parameter SIadd.NonDim tol_energy=1e-3 "Allowed relative steady-state energy imbalance";
  parameter SI.MassFlowRate tol_mass=1e-6 "Allowed inlet/outlet mass-flow mismatch";

  /* Fission source shape. Exercises the O-20 domain split: sum(SF) = 1 over the channel cells
     alone, with SF = 0 in the two plenum core nodes. */
  final parameter SIadd.NonDim SF_core[nodalization.nV_core]=MSRE.Functions.corePowerShape(
      nodalization.nRings,
      nodalization.nAxial,
      nodalization.nChannels,
      nodalization.f_radial,
      geometry.A_channel,
      geometry.H_channels,
      geometry.L_lowerPlenum_core,
      geometry.L_upperPlenum_core,
      geometry.V_lowerPlenum_core,
      geometry.V_upperPlenum_core,
      nodalization.f_axialExtrapolation) "Fission source fraction of each core cell";
  final parameter SIadd.NonDim SF_sum=sum(SF_core) "Must be 1";
  final parameter SIadd.NonDim SF_plena=SF_core[nodalization.nV_core - 1] + SF_core[
      nodalization.nV_core] "Must be 0 with the O-20 domain split";

  /* ------------------------------------------------------------------
     System and boundaries
     ------------------------------------------------------------------ */
  inner TRANSFORM.Fluid.SystemTF systemTF(
    p_start=p_start_core,
    T_start=T_in_set,
    allowFlowReversal=false,
    energyDynamics=TRANSFORM.Types.Dynamics.FixedInitial,
    momentumDynamics=TRANSFORM.Types.Dynamics.DynamicFreeInitial)
    annotation (Placement(transformation(extent={{-90,70},{-70,90}})));

  TRANSFORM.Fluid.BoundaryConditions.MassFlowSource_T inlet(
    redeclare package Medium = Medium,
    nPorts=1,
    m_flow=m_flow_set,
    T=T_in_set) "Fixed total MSRE core flow and inlet temperature"
    annotation (Placement(transformation(extent={{-80,-10},{-60,10}})));

  TRANSFORM.Fluid.BoundaryConditions.Boundary_pT outlet(
    redeclare package Medium = Medium,
    nPorts=1,
    p=p_out,
    T=T_in_set) "Pressure boundary downstream of the core"
    annotation (Placement(transformation(extent={{80,-10},{60,10}})));

  MSRE.Components.ReactorCore core(
    redeclare package Medium = Medium,
    nRings=nodalization.nRings,
    nChannels=nodalization.nChannels,
    nChannels_total=geometry.nChannels_total,
    nAxial=nodalization.nAxial,
    nLP=geometry.nLP,
    nUP=geometry.nUP,
    nR_graphite=geometry.nR_graphite,
    iLP_core=geometry.iLP_core,
    iUP_core=geometry.iUP_core,
    H_channels=geometry.H_channels,
    A_channel=geometry.A_channel,
    Dh_channel=geometry.Dh_channel,
    r_graphite_inner=geometry.r_graphite_inner,
    r_graphite_outer=geometry.r_graphite_outer,
    dz_channels=geometry.dz_channels,
    V_lowerPlenum=geometry.V_lowerPlenum,
    L_lowerPlenum=geometry.L_lowerPlenum,
    dz_lowerPlenum=geometry.dz_lowerPlenum,
    V_upperPlenum=geometry.V_upperPlenum,
    L_upperPlenum=geometry.L_upperPlenum,
    dz_upperPlenum=geometry.dz_upperPlenum,
    V_lowerPlenum_core=geometry.V_lowerPlenum_core,
    V_upperPlenum_core=geometry.V_upperPlenum_core,
    K_channelInlet=nodalization.K_channelInlet,
    K_channelExit=nodalization.K_channelExit,
    Qs_core={Q_core*SF_core[i] for i in 1:nodalization.nV_core},
    p_start=p_start_core,
    T_start=T_in_set,
    m_flow_start=m_flow_set) "15-ring 2-D reactor core"
    annotation (Placement(transformation(extent={{-20,-10},{20,10}})));

  /* ------------------------------------------------------------------
     Reported quantities
     ------------------------------------------------------------------ */
  SI.MassFlowRate m_flow_in=core.port_a.m_flow "Mass flow entering the core";
  SI.MassFlowRate m_flow_out=-core.port_b.m_flow "Mass flow leaving the core";
  SI.MassFlowRate err_mass=core.err_mass "Steady-state mass conservation residual";

  SI.Power Q_enthalpy=core.Q_enthalpy "Enthalpy rise of the stream";
  SI.Power Q_potential=core.Q_potential "Gravitational potential-energy gain";
  SI.Power Q_kinetic=core.Q_kinetic "Kinetic-energy flux change";
  SI.Power Q_balance=core.Q_balance "Conserved total";
  SI.Power Q_imposed=core.Q_imposed "Total imposed fission power";
  final parameter SI.Power Q_norm=if abs(Q_core) > 0 then abs(Q_core) else Q_energyNorm
    "Scale of the energy residual";
  SIadd.NonDim err_energy=(Q_balance - Q_imposed)/Q_norm
    "Relative steady-state energy residual; target is zero";
  SIadd.NonDim err_energy_enthalpyOnly=(Q_enthalpy - Q_imposed)/Q_norm
    "DIAGNOSTIC: the enthalpy-only residual, carrying the -m_flow*g*dz_core offset";

  SI.Temperature T_in=core.T_in "Core inlet temperature";
  SI.Temperature T_out=core.T_out "Core outlet temperature";
  SI.TemperatureDifference dT_core=core.dT_core "Core temperature rise";
  SIadd.NonDim Re_channel=core.Re_channel "Reynolds number of the equivalent channel";
  SI.Pressure dp_core=core.dp_core "Total pressure drop across the core";
  SI.Pressure dp_gravity_local=core.dp_gravity_local "Static head, local node densities";
  SI.Pressure dp_nonstatic=core.dp_nonstatic "Everything that is not static head";

equation
  connect(inlet.ports[1], core.port_a)
    annotation (Line(points={{-60,0},{-20,0}}, color={0,127,255}));
  connect(core.port_b, outlet.ports[1])
    annotation (Line(points={{20,0},{60,0}}, color={0,127,255}));

  when terminal() then
    assert(abs(err_mass) < tol_mass, "Core mass balance failed: inlet = " + String(m_flow_in) +
      " kg/s, outlet = " + String(m_flow_out) + " kg/s.", AssertionLevel.error);
    assert(abs(err_energy) < tol_energy, "Core energy balance failed: Q_balance = " + String(
      Q_balance) + " W against an imposed " + String(Q_imposed) + " W, relative error " +
      String(err_energy) + ". The balance already includes the potential and kinetic terms, so a
residual here is a real energy path. Do not tune geometry or properties to force it to pass.",
      AssertionLevel.error);
    assert(abs(SF_sum - 1) < 1e-10, "The fission source fractions sum to " + String(SF_sum) +
      " instead of 1.", AssertionLevel.error);
    assert(abs(SF_plena) < 1e-12, "The two plenum core nodes carry a fission source fraction of "
       + String(SF_plena) + " instead of zero. O-20 requires the fission source domain to be the
active channel cells alone.", AssertionLevel.error);
  end when;

  annotation (
    experiment(
      StopTime=20000,
      __Dymola_NumberOfIntervals=2000,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>Purpose</h4>
<p>Open item <b>O-29</b>, rung 2 of the reduction ladder. <code>Loop_Hydraulics2D</code> compiles
and then fails to initialize: fifteen parallel rings under an algebraic momentum balance give one
coupled nonlinear system of 10086 variables that neither the sparse nor the dense path converges.
Before concluding anything about the 2-D branch, the question is <b>where</b> in the assembly the
initialization stops converging.</p>

<p>This model is the 15-ring core <b>with its two plena and nothing else</b>: no piping, no heat
exchanger, no pump, no loop closure. Flow and power are imposed at the boundaries exactly as in
<a href=\"modelica://MSRE.Verification.Core1D_TH_ZeroPower\">Core1D_TH_ZeroPower</a>, and the
only difference from that model is <code>nRings = 15</code> instead of 1.</p>

<h4>How to read the result</h4>
<ul>
<li>If this <b>initializes</b>, the 15 rings are not by themselves the problem and the blocker is
in the loop coupling - the closed pressure balance, the pump, or the heat exchanger.</li>
<li>If this <b>fails</b>, the blocker is the parallel-ring core itself, and the loop is
irrelevant to it.</li>
</ul>
<p>Either way the nonlinear system size is recorded, so the growth from one ring to fifteen is a
measured number rather than an inference.</p>

<h4>What is not claimed</h4>
<p>The radial power profile in <a href=\"modelica://MSRE.Data.Nodalization.Core2D\">Core2D</a>
is an <b>assumption</b>, not the paper\'s Serpent tabulation. This model is a numerical
initialization test and makes no benchmark claim whatsoever.</p>
</html>"));
end Core2D_TH_ZeroPower;
