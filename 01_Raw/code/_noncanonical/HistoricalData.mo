within MSRE.Verification;
model DNP_Circulation
  "Steady circulating delayed-neutron-precursor transport over the whole primary loop"
  extends Modelica.Icons.Example;

  replaceable record Nodalization = MSRE.Data.Nodalization.Core1D constrainedby
    MSRE.Data.Nodalization.PartialCoreNodalization
    "Spatial nodalization of the reactor core" annotation (choicesAllMatching=true);

  parameter SI.Time t_settle=1500
    "Null transient length. The circulating distribution starts empty and fills at the decay rate
     of the slowest group, so the production-minus-decay residual falls as exp(-lambda_1*t) with
     lambda_1 = 0.0125 1/s. At 600 s that is 5.5e-4 and the conservation check fails; at 1500 s
     it is 7e-9. The length is set from lambda_1 and the tolerance, not from an observed residual";
  parameter SI.Power Q_start=100 "Reactor power. 100 W: low enough that feedback is negligible";
  parameter SI.Temperature T_start=908 "Isothermal fuel salt temperature";
  parameter Real N_rated(unit="1/min") = 1160 "Rated fuel pump speed";

  /* ---------------- Tolerances ---------------- */
  parameter SIadd.NonDim tol_conservation=1e-4
    "Allowed relative gap between total precursor production and total decay at steady state";
  parameter SIadd.NonDim tol_transport=2e-2
    "Allowed relative gap between the transported Beta_eff and the closed form of paper Eq. 8";

  MSRE.Systems.PrimarySystem msre(
    redeclare package Medium_fuel = MSRE.Media.FuelSalt_U235,
    redeclare record Data_PG = MSRE.Data.PrecursorGroups.U235_6group,
    redeclare record Data_K = MSRE.Data.Kinetics_U235,
    redeclare record Nodalization = Nodalization,
    Q_fission_start=Q_start,
    T_start=T_start,
    t_null=t_settle,
    use_servoControl=true,
    m_flow_start=0,
    N_pump_start=N_rated,
    T_coolant_start=T_start) "MSRE primary system at rated pump speed"
    annotation (Placement(transformation(extent={{-20,-20},{20,20}})));

  Modelica.Blocks.Sources.RealExpression pumpSpeed(y=N_rated)
    "Fuel pump held at its rated speed for the whole run"
    annotation (Placement(transformation(extent={{80,-10},{56,10}})));
  Modelica.Blocks.Sources.RealExpression coolantTemperature(y=T_start)
    "Coolant salt inlet temperature, isothermal"
    annotation (Placement(transformation(extent={{80,30},{56,50}})));

  final parameter Integer nC=msre.nC "# of precursor groups";
  final parameter Integer nV_core=msre.nV_core "# of core cells";

  /* ================================================================
     1. Where the precursors are (section 14 / 19 of the work order)
     ================================================================
     mCs_core is what the kinetics sees. The rest of the loop carries the balance, and it has to
     be gathered component by component because no single TRANSFORM object owns it. */
  SIadd.ExtraPropertyExtrinsic mC_core[nC]={sum(msre.core.mCs_core[:, j]) for j in 1:nC}
    "Precursors of each group inside the reactor core cells";
  SIadd.ExtraPropertyExtrinsic mC_vessel[nC]={sum(msre.core.lowerPlenum.mCs[:, j]) + sum({sum(
      msre.core.channels[r].mCs[:, j]) for r in 1:msre.nRings}) + sum(msre.core.upperPlenum.mCs[
      :, j]) for j in 1:nC} "Precursors of each group inside the whole reactor vessel";
  SIadd.ExtraPropertyExtrinsic mC_hx[nC]={sum(msre.hx.shell.mCs[:, j]) for j in 1:nC}
    "Precursors of each group inside the heat exchanger shell";
  SIadd.ExtraPropertyExtrinsic mC_piping[nC]={sum(msre.downcomer.mCs[:, j]) + sum(msre.outletPipe.mCs[
      :, j]) + sum(msre.pumpBowl.mCs[:, j]) + sum(msre.pumpToHX.mCs[:, j]) + sum(msre.hxToVessel.mCs[
      :, j]) for j in 1:nC} "Precursors of each group in the downcomer, piping and pump bowl";
  SIadd.ExtraPropertyExtrinsic mC_total[nC]={mC_vessel[j] + mC_hx[j] + mC_piping[j] for j in 1:
      nC} "Precursors of each group anywhere in the primary system";
  SIadd.ExtraPropertyExtrinsic mC_external[nC]={mC_total[j] - mC_core[j] for j in 1:nC}
    "Precursors of each group outside the reactor core";

  SIadd.NonDim f_core[nC]={mC_core[j]/max(mC_total[j], Modelica.Constants.small) for j in 1:nC}
    "Fraction of each group's inventory that is inside the core";

  /* ================================================================
     2. Conservation: production must equal decay at steady state (section 15)
     ================================================================
     Production is the fission source the kinetics hands to the core cells. Decay is
     lambda_j*mC_j summed over the WHOLE loop, core and external alike - that is the statement
     that distinguishes a transport treatment from a core-only one. */
  SIadd.ExtraPropertyFlowRate gen[nC]={sum(msre.kinetics.mC_sources[:, j]) for j in 1:nC}
    "Total production rate of each group, from fission in the core cells";
  SIadd.ExtraPropertyFlowRate decay[nC]={msre.data_PG.lambdas[j]*mC_total[j] for j in 1:nC}
    "Total decay rate of each group, over the whole primary system";
  SIadd.NonDim err_conservation[nC]={(gen[j] - decay[j])/max(gen[j], Modelica.Constants.small)
      for j in 1:nC} "Relative production-minus-decay residual of each group";
  SIadd.NonDim err_conservation_max=max({abs(err_conservation[j]) for j in 1:nC})
    "Largest relative residual over the groups";

  /* ================================================================
     3. Circulation reactivity (sections 18 and 19)
     ================================================================ */
  SIadd.NonDim Beta_eff_static=msre.data_PG.Beta
    "Delayed neutron fraction with the fuel salt at rest (0.006781)";
  SIadd.NonDim Beta_eff_circulating=msre.kinetics.Beta_eff_inst
    "Effective delayed neutron fraction with the fuel salt circulating (paper Eq. 6)";
  SIadd.NonDim drho_circulation=Beta_eff_static - Beta_eff_circulating
    "Reactivity lost to precursor drift";
  Real drho_circulation_pcm=1e5*drho_circulation "The same, in pcm";
  Real rho_CR_pcm=msre.rho_CR_pcm
    "Control rod reactivity the flux servo has to supply to stay critical [pcm]";

  /* The closed form of paper Eq. 8, evaluated at the transit times THIS RUN delivers rather
     than at the ones the paper reports. That is what makes the comparison a code-to-analytic
     check of the transport rather than a benchmark comparison: both sides then describe the
     same loop, and any gap is the difference between a distributed transport solution over 60-odd
     volumes and a two-region closed form, not a geometry difference. */
  SI.Time tau_core=msre.core.tau_fluid_kinetics "Core transit time this run delivers";
  SI.Time tau_external=(M_loop - msre.core.M_fluid_kinetics)/noEvent(max(abs(msre.m_flow_fuel), 1e-9))
    "External loop transit time this run delivers";
  SI.Mass M_loop=msre.core.M_fluid + msre.downcomer.M_fluid + msre.outletPipe.M_fluid + msre.pumpBowl.M_fluid
       + msre.pumpToHX.M_fluid + msre.hxToVessel.M_fluid + sum({msre.hx.shell.mediums[i].d*msre.hx.shell.geometry.Vs[
      i] for i in 1:msre.geometry.nHX}) "Circulating fuel salt mass";

  SIadd.NonDim drho_analytic=MSRE.Functions.driftReactivity(
      msre.data_PG.alphas*msre.data_PG.Beta,
      msre.data_PG.lambdas,
      tau_core,
      tau_external) "Paper Eq. 8 at the transit times of this run";
  Real drho_analytic_pcm=1e5*drho_analytic "The same, in pcm";
  SIadd.NonDim err_transport=drho_circulation/max(drho_analytic, Modelica.Constants.small) - 1
    "Relative gap between the transported and the closed-form drift reactivity";

  /* Reported for the group-by-group discussion: how the loop time compares with each
     precursor's own lifetime is what decides which groups feel the circulation at all. */
  SIadd.NonDim lambdaTau_core[nC]={msre.data_PG.lambdas[j]*tau_core for j in 1:nC}
    "lambda_j times the core transit time";
  SIadd.NonDim lambdaTau_external[nC]={msre.data_PG.lambdas[j]*tau_external for j in 1:nC}
    "lambda_j times the external loop transit time";
  SI.Time halfLife[nC]={Modelica.Math.log(2)/msre.data_PG.lambdas[j] for j in 1:nC}
    "Half-life of each group";

equation
  connect(pumpSpeed.y, msre.N_pump) annotation (Line(points={{54.8,0},{40,0},{40,4},{22,4}},
        color={0,0,127}));
  connect(coolantTemperature.y, msre.T_coolant_in)
    annotation (Line(points={{54.8,40},{40,40},{40,14},{22,14}}, color={0,0,127}));

  when terminal() then
    /* ---- 1. Precursor conservation. At steady state every precursor born in the core must
          decay somewhere, and "somewhere" is the whole loop. This is the check that the
          transport is not losing or creating precursors at a component boundary. ---- */
    assert(err_conservation_max < tol_conservation, "The largest relative gap between precursor
production and precursor decay over the whole primary system is " +
      String(err_conservation_max) + ". At steady state every precursor born by fission must
decay somewhere in the loop; a residual means the transport is losing or creating them at a
component boundary, or that the run has not converged.", AssertionLevel.error);

    /* ---- 2. The transported solution against the closed form, at the SAME transit times.
          Paper Eq. 8 is the steady-state limit of the transport this model integrates, for a
          two-region loop with a cosine source and flat importance. Evaluating it at the transit
          times of this run rather than at the paper's makes it a code-to-analytic check of the
          transport instead of a benchmark comparison. ---- */
    assert(abs(err_transport) < tol_transport, "The circulating precursor solution gives a drift
reactivity of " + String(drho_circulation_pcm) + " pcm, while paper Eq. 8 at the same transit
times (" + String(tau_core) + " s core, " + String(tau_external) + " s loop) gives " +
      String(drho_analytic_pcm) + " pcm, a relative gap of " + String(err_transport) + ". These
are the same physics by two routes: a distributed transport over the whole loop, and a
two-region closed form. A gap means the transport, the core definition used for paper Eq. 4, or
the source distribution is wrong.", AssertionLevel.error);
  end when;

  annotation (
    experiment(
      StopTime=1500,
      __Dymola_NumberOfIntervals=3000,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>What this is</h4>
<p>The steady circulating precursor distribution, solved as a <b>transport problem over the whole
primary system</b> - core, plena, piping, pump bowl and heat exchanger shell - and checked
against the closed form of paper Eq. 8. The precursor groups are trace substances of the fuel
salt, so the TRANSFORM fluid components advect them and each applies its own decay term; the
fission production term is supplied to the core cells only (the O-20 domain split).</p>

<h4>The two checks, and why they are verification rather than benchmark</h4>
<ol>
<li><b>Conservation.</b> At steady state every precursor born by fission must decay somewhere in
the loop. Production is summed over the core cells, decay over every fuel-salt volume in the
system. Nothing can be chosen to make this pass; it is a statement about the transport being
closed.</li>
<li><b>Transport against the closed form.</b> Paper Eq. 8 is the steady-state limit of the same
precursor transport, for a two-region loop with a cosine source and flat importance. It is
evaluated here <b>at the transit times this run delivers</b>, not at the 9.56 s and 16.14 s the
paper reports. That is deliberate: with the same transit times on both sides, any gap is the
difference between a distributed solution over some sixty volumes and a two-region closed form,
and not a geometry difference. Comparing against the paper's transit times would mix the two and
measure neither.</li>
</ol>

<h4>What is reported rather than asserted</h4>
<p><code>f_core[j]</code> is the fraction of group j's inventory that is inside the core, and it
is the quantity that explains the whole circulation effect group by group. It follows the ratio
of the loop time to the precursor lifetime: a group whose half-life is short against the 17 s
external transit decays almost entirely before it can return, so essentially all of its
inventory is in the core and it is unaffected by circulation; a group whose half-life is long
against it circulates almost intact.</p>
<p><code>lambdaTau_core</code>, <code>lambdaTau_external</code> and <code>halfLife</code> are
reported alongside so that the ordering is a computed number rather than an argument.</p>

<h4>How long the null transient has to be</h4>
<p>The circulating distribution starts empty, so the production-minus-decay residual is the
filling transient of the slowest group and falls as <code>exp(-lambda_1*t)</code>. That was
measured, not assumed: the residual at 600 s is <b>5.4884e-4</b>, and
<code>-ln(5.4884e-4)/600 = 0.012513 1/s</code> against <code>lambda_1 = 0.0125 1/s</code> - the
tail is group 1 and nothing else. Every other group's residual is orders below it and ordered by
half-life, which is the same statement read a second way.</p>
<table border=\"1\">
<tr><th>group</th><th>half-life [s]</th><th>residual at 600 s</th></tr>
<tr><td>1</td><td>55.45</td><td>5.5e-4</td></tr>
<tr><td>2</td><td>21.80</td><td>2.3e-6</td></tr>
<tr><td>3</td><td>6.36</td><td>7.5e-7</td></tr>
<tr><td>4</td><td>2.19</td><td>1.7e-7</td></tr>
<tr><td>5</td><td>0.513</td><td>2.5e-9</td></tr>
<tr><td>6</td><td>0.080</td><td>2.0e-13</td></tr>
</table>
<p><code>t_settle</code> is therefore 1500 s, where <code>exp(-lambda_1*t) = 7e-9</code>. It is
set from the decay constant and the tolerance; <b>the tolerance was not moved to fit the
residual</b>. 600 s would have been the wrong answer for a right-looking reason - it is 10.8
half-lives, which sounds ample and is not.</p>

<h4>Why 100 W and not zero</h4>
<p>The fission source is proportional to the neutron population, so at exactly zero power there
are no precursors and <code>Beta_eff_inst = 0/0</code>. 100 W is the power of the zero-power pump
tests and is far too low for thermal feedback to matter; <code>use_servoControl = true</code>
holds the population constant so the distribution converges to a steady state rather than
drifting with the reactivity.</p>

<h4>Nodalization</h4>
<p>Defaults to <a href=\"modelica://MSRE.Data.Nodalization.Core1D\">Core1D</a>. The precursor
result should be nearly independent of it: the rings are hydraulically identical and the flux
weighting is flat, so collapsing them changes neither the axial source shape nor the residence
time distribution. Running both is how that expectation is tested rather than assumed.</p>
</html>"));
end DNP_Circulation;
