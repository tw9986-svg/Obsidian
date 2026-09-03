within MSRE.Verification;
model Core1D_TH_Baseline
  "Stage-3 1-D reactor core TH verification: lower plenum, one equivalent channel group, upper plenum, fixed flow and fixed power"
  extends Modelica.Icons.Example;

  import TRANSFORM;

  replaceable package Medium = MSRE.Media.FuelSalt_U235 constrainedby
    Modelica.Media.Interfaces.PartialMedium "Fuel salt property model"
    annotation (choicesAllMatching=true);

  parameter MSRE.Data.Geometry geometry "MSRE hardware geometry and reference operating data";
  parameter MSRE.Data.Nodalization.Core1D nodalization(geometry=geometry)
    "1-D core nodalization";

  /* ------------------------------------------------------------------
     Test definition
     ------------------------------------------------------------------ */
  parameter SI.MassFlowRate m_flow_set=geometry.m_flow_nominal "Imposed total core flow rate";
  parameter SI.Temperature T_in_set=908 "Imposed core inlet temperature";
  parameter SI.Power Q_core=8e6
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

  MSRE.Components.ReactorCore1D core(
    redeclare package Medium = Medium,
    nChannels_1D=geometry.nChannels_total,
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
    m_flow_start=m_flow_set) "1-D reactor core"
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
<p>Stage 3. Where
<a href=\"modelica://MSRE.Verification.CoreTH_Baseline\">CoreTH_Baseline</a> tested one bare
pipe, this adds the two plena and the graphite heat structure and uses the real
<a href=\"modelica://MSRE.Components.ReactorCore1D\">ReactorCore1D</a>. Still no kinetics, no
precursor transport, no pump and no heat exchanger: the flow and the power are imposed and the
only question is whether the assembled 1-D core conserves mass and energy and produces a
momentum balance that decomposes.</p>

<h4>What is verified</h4>
<ol>
<li><b>Mass</b> - inlet and outlet flow agree to <code>tol_mass</code>.</li>
<li><b>Energy</b> - <code>sum(Qs_core) = m_flow*(h_out - h_in) + Q_potential + Q_kinetic</code>.
The core rises 2.2256 m, so the potential term is 3.67 kW at rated flow and an enthalpy-only
check would miss it. This is open item O-22.</li>
<li><b>Source normalization</b> - <code>sum(SF) = 1</code> and the two plenum core nodes carry
<b>exactly zero</b> fission source, which is the O-20 domain split exercised through the 1-D
nodalization.</li>
<li><b>Momentum</b> - <code>dp_core</code> split into the local-density static head and the
remainder, summed over the three sections.</li>
</ol>

<h4>Why the run is long</h4>
<p><code>StopTime = 20000 s</code>, not the few hundred seconds the salt transit time would
suggest. The graphite heat structure relaxes far more slowly than the fluid: measured on the
zero-power case, the energy residual falls from 4.31 W at 600 s to 0.130 W at 2000 s,
5.98e-4 W at 10000 s, and then plateaus at 2.58e-4 W, unchanged between 20000 s and 200000 s.
Asserting a steady-state balance at 600 s was testing a state the model had not reached yet.
The tolerances are unchanged - only the time given to reach steady state is.</p>

<h4>What is intentionally not validated</h4>
<ul>
<li><code>Q_core = 8 MW</code> is a fixed thermal test condition. Passing does not validate an
8 MW MSRE operating point.</li>
<li>The inlet temperature is a boundary condition, not a predicted benchmark value.</li>
<li>The graphite is present as a heat structure but with <code>f_graphiteHeating = 0</code> it
has no source, so its temperature equilibrates to the salt and the laminar closure
<a href=\"modelica://MSRE.ClosureRelations.Nus_Core\">Nus_Core</a> is exercised without being
verified against anything.</li>
</ul>
</html>"));
end Core1D_TH_Baseline;
