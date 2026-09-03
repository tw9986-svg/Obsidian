within MSRE.Components;
model SaltPipe
  "Fuel salt pipe that transports the delayed neutron precursors and decays them locally"

  import TRANSFORM;
  outer TRANSFORM.Fluid.SystemTF systemTF;

  replaceable package Medium = Modelica.Media.Interfaces.PartialMedium
    "Fuel salt medium, whose trace substances are the delayed neutron precursor groups"
    annotation (choicesAllMatching=true);

  /* ---------------- Geometry ---------------- */
  parameter Integer nV=1 "# of nodes";
  parameter SI.Volume V=1 "Total fluid volume";
  parameter SI.Length length=1 "Total flow length";
  parameter SI.Length dheight=0 "Elevation rise from port_a to port_b";
  final parameter SI.Area crossArea=V/length "Flow area";
  parameter SI.Length dimension=sqrt(4*crossArea/pi)
    "Hydraulic diameter (defaults to the equivalent circular pipe)";

  /* Node volumes. The default splits V evenly, which is what every component of the loop wants
     except the two reactor plena: there the node that the kinetics counts as part of the core
     is a thin slice at the core boundary and is much smaller than the rest of the plenum. The
     flow area is held uniform and the node lengths carry the difference, so a non-uniform split
     describes a plenum of constant bore cut at an arbitrary station rather than a shape change. */
  parameter SI.Volume Vs_nodes[nV]=fill(V/nV, nV) "Fluid volume of each node";
  final parameter SI.Length dlengths[nV]={Vs_nodes[i]/crossArea for i in 1:nV}
    "Flow length of each node";
  final parameter SI.Length dheights[nV]={dheight*dlengths[i]/length for i in 1:nV}
    "Elevation rise across each node";

  /* ---------------- Precursor transport ---------------- */
  parameter SIadd.InverseTime lambdas[Medium.nC]=zeros(Medium.nC)
    "Decay constant of each precursor group";
  input SIadd.ExtraPropertyFlowRate mC_sources[nV,Medium.nC]=zeros(nV, Medium.nC)
    "Precursor production by fission (non-zero only for nodes inside the reactor core)"
    annotation (Dialog(group="Inputs"));
  input SI.HeatFlowRate Q_gens[nV]=zeros(nV) "Volumetric heat source of each node"
    annotation (Dialog(group="Inputs"));

  /* ---------------- Pressure loss ---------------- */
  parameter Real Ks[nFM]=zeros(nFM) "Form loss coefficient of each flow segment";

  /* ---------------- Initialization ---------------- */
  parameter SI.AbsolutePressure p_a_start=1.5e5 "Pressure at port_a"
    annotation (Dialog(tab="Initialization"));
  parameter SI.Temperature T_a_start=908 "Temperature at port_a"
    annotation (Dialog(tab="Initialization"));
  /* Initial guess only, but a decisive one: momentumDynamics is SteadyState in the pipe, so
     the flows are algebraic and are read straight out of the initial pressure field. TRANSFORM's
     own default is p_a_start - 1e3, which ignores elevation entirely and plants an arbitrary
     1 kPa offset at the outlet; across a plenum with almost no friction that offset alone
     initialized the core outlet at 229807 kg/s. The guess here is the static head and nothing
     else, with the density taken from the active fuel-salt property model rather than a
     hard-coded number (O-13, O-18). */
  final parameter SI.Density d_start=Medium.density(Medium.setState_pTX(
      p_a_start,
      T_a_start,
      Medium.X_default)) "Fuel salt density at the initialization state";
  parameter SI.AbsolutePressure p_b_start=p_a_start - d_start*Modelica.Constants.g_n*dheight
    "Pressure at port_b" annotation (Dialog(tab="Initialization"));
  parameter SI.Temperature T_b_start=T_a_start "Temperature at port_b"
    annotation (Dialog(tab="Initialization"));
  parameter SIadd.ExtraProperty C_a_start[Medium.nC]=zeros(Medium.nC)
    "Precursor concentration at port_a" annotation (Dialog(tab="Initialization"));
  parameter SIadd.ExtraProperty C_b_start[Medium.nC]=C_a_start
    "Precursor concentration at port_b" annotation (Dialog(tab="Initialization"));
  parameter SI.MassFlowRate m_flow_a_start=0 "Mass flow rate at port_a"
    annotation (Dialog(tab="Initialization"));


  /* ---------------- Balance formulation ----------------
     TRANSFORM's GenericPipe does NOT read these from the inner SystemTF: its own defaults are
     energyDynamics = DynamicFreeInitial and massDynamics = energyDynamics, so setting them on
     the system object has no effect on the volumes. With a free initial energy balance the
     zero-power core is under-determined in temperature, and the initialization is free to drift
     to T = 4816.4 K, where the linear-fluid density (1 - beta*(T - T_reference))*d_reference
     crosses zero and every division by density blows up. They are exposed and defaulted to
     FixedInitial here so the declared initial temperature is actually imposed. */
  parameter Modelica.Fluid.Types.Dynamics energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial
    "Formulation of the energy balance"
    annotation (Evaluate=true, Dialog(tab="Advanced", group="Dynamics"));
  /* Mass is SteadyStateInitial rather than FixedInitial on purpose. Momentum is algebraic
     (SteadyState), so the flows are read straight out of the pressure field; pinning every node
     pressure at its start value then over-specifies the network. The plena have almost no
     hydraulic resistance - a 1 Pa error across a square metre of flow area is worth about
     1e5 kg/s - so no start-value guess can ever be accurate enough. der(p) = 0 lets the
     pressures settle consistently with the flows instead. Temperature stays pinned by
     energyDynamics = FixedInitial, which is what keeps the solver off the zero-density root. */
  parameter Modelica.Fluid.Types.Dynamics massDynamics=Modelica.Fluid.Types.Dynamics.SteadyStateInitial
    "Formulation of the mass balance"
    annotation (Evaluate=true, Dialog(tab="Advanced", group="Dynamics"));
  parameter Modelica.Fluid.Types.Dynamics momentumDynamics=Modelica.Fluid.Types.Dynamics.SteadyState
    "Formulation of the momentum balance"
    annotation (Evaluate=true, Dialog(tab="Advanced", group="Dynamics"));
  /* O-23. TRANSFORM's PartialDistributedVolume defaults traceDynamics to massDynamics, so
     leaving it unset made it SteadyStateInitial and C_a_start / C_b_start were never imposed:
     the declared precursor initial condition had no effect at all. Unlike mass, the trace
     balances are not coupled to the momentum equation - a precursor concentration cannot
     over-specify a pressure - so FixedInitial is safe here and it is what makes C_a_start mean
     what its description says. The circulating equilibrium is then reached by the null
     transient, which is the mechanism the paper itself uses to obtain Beta_eff (Eq. 6). */
  parameter Modelica.Fluid.Types.Dynamics traceDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial
    "Formulation of the delayed neutron precursor balances"
    annotation (Evaluate=true, Dialog(tab="Advanced", group="Dynamics"));

  /* ---------------- Advanced ---------------- */
  parameter Boolean exposeState_a=true "=true, p is calculated at port_a else m_flow"
    annotation (Dialog(tab="Advanced", group="Model Structure"));
  parameter Boolean exposeState_b=false "=true, p is calculated at port_b else m_flow"
    annotation (Dialog(tab="Advanced", group="Model Structure"));
  final parameter Integer nFM=if exposeState_a and exposeState_b then nV - 1 elseif not
      exposeState_a and not exposeState_b then nV + 1 else nV "# of flow segments";
  parameter Boolean use_HeatTransfer=false "=true to expose the wall heat ports"
    annotation (Dialog(tab="Advanced"));

  replaceable model HeatTransfer = MSRE.ClosureRelations.Nus_MoltenSalt constrainedby
    TRANSFORM.Fluid.ClosureRelations.HeatTransfer.Models.DistributedPipe_1D_MultiTransferSurface.PartialHeatTransfer_setT
    "Wall heat transfer" annotation (choicesAllMatching=true);

  /* ---------------- Ports ---------------- */
  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_a(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
  TRANSFORM.Fluid.Interfaces.FluidPort_Flow port_b(redeclare package Medium = Medium)
    annotation (Placement(transformation(extent={{90,-10},{110,10}})));
  TRANSFORM.HeatAndMassTransfer.Interfaces.HeatPort_Flow heatPorts[nV] if use_HeatTransfer
    annotation (Placement(transformation(extent={{-10,40},{10,60}})));

  TRANSFORM.Fluid.Pipes.GenericPipe_MultiTransferSurface pipe(
    redeclare package Medium = Medium,
    use_HeatTransfer=use_HeatTransfer,
    redeclare model HeatTransfer = HeatTransfer,
    redeclare model Geometry =
        TRANSFORM.Fluid.ClosureRelations.Geometry.Models.DistributedVolume_1D.GenericPipe (
        nV=nV,
        dimensions=fill(dimension, nV),
        crossAreas=fill(crossArea, nV),
        perimeters=fill(4*crossArea/dimension, nV),
        dlengths=dlengths,
        dheights=dheights),
    redeclare model FlowModel =
        TRANSFORM.Fluid.ClosureRelations.PressureLoss.Models.DistributedPipe_1D.SinglePhase_Developed_2Region_NumStable
        (Ks_ab=Ks, Ks_ba=Ks),
    redeclare model InternalHeatGen =
        TRANSFORM.Fluid.ClosureRelations.InternalVolumeHeatGeneration.Models.DistributedVolume_1D.GenericHeatGeneration
        (Q_gens=Q_gens),
    redeclare model InternalTraceGen =
        TRANSFORM.Fluid.ClosureRelations.InternalTraceGeneration.Models.DistributedVolume_Trace_1D.GenericTraceGeneration
        (mC_gens=mC_gens_total),
    energyDynamics=energyDynamics,
    massDynamics=massDynamics,
    momentumDynamics=momentumDynamics,
    traceDynamics=traceDynamics,
    p_a_start=p_a_start,
    p_b_start=p_b_start,
    T_a_start=T_a_start,
    T_b_start=T_b_start,
    C_a_start=C_a_start,
    C_b_start=C_b_start,
    m_flow_a_start=m_flow_a_start,
    exposeState_a=exposeState_a,
    exposeState_b=exposeState_b)
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));

  /* ---------------- Summary ---------------- */
  SIadd.ExtraPropertyFlowRate mC_gens_total[nV,Medium.nC]={{mC_sources[i, j] - lambdas[j]*
      pipe.mCs[i, j] for j in 1:Medium.nC} for i in 1:nV}
    "Right hand side of the precursor transport equation (production minus decay)";
  SIadd.ExtraPropertyExtrinsic mCs[nV,Medium.nC]=pipe.mCs
    "# of precursors of each group in each node";
  SI.Volume Vs[nV]=pipe.geometry.Vs "Fluid volume of each node";
  SI.Temperature Ts[nV]=pipe.mediums.T "Temperature of each node";
  SI.Density ds[nV]=pipe.mediums.d "Fuel salt density of each node";

  /* ---------------- Momentum-balance decomposition (diagnostic) ----------------
     Sign convention: every dp_* below is a DROP from port_a to port_b, so a positive value
     means the pressure falls in the direction of nominal flow.

     dp_gravity_local is the primary static term and uses the LOCAL density of each node, which
     is what matters as soon as the fluid is heated. dp_gravity_bulk is a cross-check only.
     dp_acceleration is the momentum-flux change of a constant-area duct, G^2*(1/d_out-1/d_in),
     computed here independently of the TRANSFORM flow model.

     dp_nonstatic is deliberately NOT called a friction or irreversible loss: it is whatever is
     left after the static head, and it still contains the acceleration term, the wall friction
     and any form loss from Ks. dp_residual isolates the friction-plus-form part, but only as a
     remainder - it is not read from the TRANSFORM pressure-loss model, whose internal split
     could not be inspected (no TRANSFORM source is available in the environment this was
     written in). Treat dp_residual as "friction + form + whatever else the flow model does",
     not as a verified friction term. */
  SI.Pressure dp_total=port_a.p - port_b.p
    "Total pressure drop from port_a to port_b";
  SI.Pressure dp_gravity_local=sum({ds[i]*Modelica.Constants.g_n*dheights[i] for i in 1:nV})
    "PRIMARY static term: sum over nodes of the local density times the local elevation rise";
  SI.Density d_bulk=sum(ds)/nV "Node-average density";
  SI.Pressure dp_gravity_bulk=d_bulk*Modelica.Constants.g_n*dheight
    "CROSS-CHECK ONLY: the same static term formed with a single average density";
  SI.Pressure dp_nonstatic=dp_total - dp_gravity_local
    "Everything that is not static head. NOT a friction loss: still contains acceleration, friction and form";
  Real G(unit="kg/(m2.s)")=port_a.m_flow/crossArea "Mass flux";
  SI.Pressure dp_acceleration=G^2*(1/ds[nV] - 1/ds[1])
    "Momentum-flux change of a constant-area duct, computed independently of the flow model";
  SI.Pressure dp_residual=dp_nonstatic - dp_acceleration
    "Remainder after static head and acceleration: friction plus form plus anything else the TRANSFORM flow model contributes";

  /* ---------------- Energy-balance decomposition (diagnostic, O-22) ----------------
     A pipe that changes elevation does not conserve ENTHALPY against its heat input: the salt
     also gains or gives up potential energy. At steady state the conserved statement is

       sum(Q_gens) = m_flow*(h_b - h_a) + m_flow*g*dheight + kinetic

     Checking m_flow*(h_b - h_a) against sum(Q_gens) alone leaves a deficit of exactly
     m_flow*g*dheight, which for the core is 2678 W. These terms are exposed here so that any
     verification model built on SaltPipe states the balance correctly rather than rediscovering
     it. Nothing here changes an equation: they are all diagnostic outputs.

     Note that the primary loop is elevation-closed (Data.Geometry.dz_closure = 0), so the
     potential term cancels around the whole loop and only matters component by component. */
  /* noEvent: actualStream expands to a conditional on port.m_flow > 0, which OpenModelica
     turns into a state event. At zero flow that zero-crossing chatters - measured at 100 state
     events inside 5.6e-6 s on the loop at rest, reported against msre.m_flow_pump > 0. These
     two are DIAGNOSTIC OUTPUTS ONLY: no balance equation reads them, so suppressing the event
     changes no conserved quantity and no value away from the crossing. */
  SI.SpecificEnthalpy h_a=noEvent(actualStream(port_a.h_outflow)) "Specific enthalpy at port_a";
  SI.SpecificEnthalpy h_b=noEvent(actualStream(port_b.h_outflow)) "Specific enthalpy at port_b";
  SI.Power Q_enthalpy=port_a.m_flow*(h_b - h_a) "Enthalpy rise of the stream";
  SI.Power Q_potential=port_a.m_flow*Modelica.Constants.g_n*dheight
    "Rate of gravitational potential-energy gain over the elevation rise";
  SI.Power Q_kinetic=0.5*port_a.m_flow*((G/ds[nV])^2 - (G/ds[1])^2)
    "Kinetic-energy flux change; reported so that it is measured rather than assumed negligible";
  SI.Power Q_balance=Q_enthalpy + Q_potential + Q_kinetic
    "Total energy the stream carries away; equals sum(Q_gens) at steady state";
  SI.Power Q_gens_total=sum(Q_gens) "Total heat generation imposed on this pipe";
  SI.Power err_energy_W=Q_balance - Q_gens_total
    "Absolute steady-state energy residual of this pipe [W]";

  /* ---------------- Inventory and residence time (diagnostic) ----------------
     Measured from the assembled model - the node volumes and the local node densities - not
     restated from Data.Geometry, so that the loop inventory audit is a check on the model
     rather than a re-print of its input. */
  SI.Volume V_fluid=sum(Vs) "Fuel salt volume this component holds";
  SI.Mass M_fluid=sum({ds[i]*Vs[i] for i in 1:nV}) "Fuel salt mass this component holds";
  SI.Time tau_fluid=M_fluid/noEvent(max(abs(port_a.m_flow), 1e-9))
    "Fuel salt residence time of this component at the current flow rate";

equation
  assert(abs(sum(Vs_nodes) - V) < 1e-12*max(V, 1e-9), "The node volumes of " + getInstanceName()
     + " sum to " + String(sum(Vs_nodes)) + " m3 but the component volume V is " + String(V) +
    " m3. Vs_nodes redistributes V between the nodes; it does not change how much fluid the
component holds.", AssertionLevel.error);

  connect(port_a, pipe.port_a) annotation (Line(points={{-100,0},{-10,0}}, color={0,127,255}));
  connect(port_b, pipe.port_b) annotation (Line(points={{100,0},{10,0}}, color={0,127,255}));
  connect(pipe.heatPorts[:, 1], heatPorts)
    annotation (Line(points={{0,5},{0,50}}, color={191,0,0}));

  annotation (
    defaultComponentName="pipe",
    Icon(coordinateSystem(preserveAspectRatio=false), graphics={
        Rectangle(
          extent={{-90,40},{90,-40}},
          lineColor={0,0,0},
          fillColor={0,127,255},
          fillPattern=FillPattern.HorizontalCylinder),
        Text(
          extent={{-149,-50},{151,-90}},
          lineColor={0,0,255},
          textString="%name")}),
    Diagram(coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<p>A thin wrapper around <code>TRANSFORM.Fluid.Pipes.GenericPipe_MultiTransferSurface</code>
that is parameterized by <b>volume and length</b> rather than diameter, because the MSRE
nodalization is defined by fuel-salt volumes, and that automatically applies the decay term
of the precursor transport equation,</p>

<p><code>mC_gens[i,j] = mC_sources[i,j] - lambda_j*mC[i,j]</code></p>

<p>Every fuel-salt component of the primary loop uses it, so that precursors decay everywhere
they are carried, which is the whole point of solving paper Eq. 3 over the entire system
rather than over a core plus a single lumped loop.</p>
</html>"));
end SaltPipe;
