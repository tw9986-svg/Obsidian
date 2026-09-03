within MSRE.Verification;
model LowFlow_Closure
  "O-24 | Mathematical behaviour of the pressure-loss closure from rated flow down through zero and into reverse"
  extends Modelica.Icons.Example;

  import TRANSFORM.Fluid.ClosureRelations.PressureLoss.Functions.TubesAndConduits.SinglePhase.LaminarTurbulent_MSLDetailed;

  parameter MSRE.Data.Geometry geometry "MSRE hardware geometry";
  parameter SI.Temperature T=908 "Isothermal test temperature";

  /* ------------------------------------------------------------------
     The sweep. Rated flow down through zero and symmetrically negative,
     so that flow reversal is exercised and not merely assumed.
     ------------------------------------------------------------------ */
  parameter Integer n=29 "Number of sweep points";
  parameter SI.MassFlowRate m_flows[n]={168,100,50,20,10,5,2,1,0.5,0.2,0.1,0.05,0.01,1e-3,
      0,-1e-3,-0.01,-0.05,-0.1,-0.2,-0.5,-1,-2,-5,-10,-20,-50,-100,-168}
    "Sweep points, including exact zero and a symmetric reverse branch";

  /* ------------------------------------------------------------------
     Salt properties from the active correlations, evaluated once
     ------------------------------------------------------------------ */
  final parameter SI.Density d=MSRE.Media.FuelSalt.Utilities.d_T(T) "Cantor density";
  final parameter SI.DynamicViscosity mu=MSRE.Media.FuelSalt.Utilities.eta_T(T) "Cantor viscosity";

  /* ------------------------------------------------------------------
     One representative core channel node. Per-channel flow, since that
     is what the closure sees inside CoreChannel.
     ------------------------------------------------------------------ */
  final parameter SI.Length dz=geometry.H_channels/geometry.nAxial "Node length";
  final parameter Real nCh=geometry.nChannels_total "Channels in parallel";

  final parameter LaminarTurbulent_MSLDetailed.dp_IN_con IN_con(
    diameter_a=geometry.Dh_channel,
    diameter_b=geometry.Dh_channel,
    crossArea_a=geometry.A_channel,
    crossArea_b=geometry.A_channel,
    length=dz,
    roughness_a=2.5e-5,
    roughness_b=2.5e-5,
    Re_turbulent=4000) "Geometry of one axial node of one fuel channel";

  final parameter LaminarTurbulent_MSLDetailed.dp_IN_var IN_var(
    rho_a=d,
    rho_b=d,
    mu_a=mu,
    mu_b=mu) "Isothermal salt properties";

  parameter SI.MassFlowRate m_flow_small=0.001*geometry.m_flow_nominal/nCh
    "TRANSFORM regularization half-width, per channel";

  /* ------------------------------------------------------------------
     Evaluated closure. dp_DP_staticHead is the exact function
     SinglePhase_Developed_2Region_NumStable calls, so this tests the
     closure the loop actually runs on, with no solver involved.
     ------------------------------------------------------------------ */
  final parameter SI.MassFlowRate mch[n]={m_flows[i]/nCh for i in 1:n}
    "Per-channel mass flow rate";
  final parameter SI.Velocity v[n]={mch[i]/(d*geometry.A_channel) for i in 1:n} "Node velocity";
  final parameter SIadd.NonDim Re[n]={d*abs(v[i])*geometry.Dh_channel/mu for i in 1:n}
    "Reynolds number, magnitude";
  final parameter SI.Pressure dp[n]={LaminarTurbulent_MSLDetailed.dp_DP_staticHead(
      IN_con,
      IN_var,
      mch[i],
      m_flow_small,
      0) for i in 1:n}   /* g*dheight = 0: a horizontal node, so this is friction alone */
    "Frictional pressure loss of one node at each sweep point";

  /* Static head of the same node, evaluated separately so that the two
     contributions can be reported independently. */
  final parameter SI.Pressure dp_gravity=d*Modelica.Constants.g_n*dz
    "Static head of one node, independent of flow";

  /* ------------------------------------------------------------------
     Well-posedness diagnostics
     ------------------------------------------------------------------ */
  final parameter SI.Pressure dp_at_zero=dp[15] "Must be exactly zero for a horizontal node";
  final parameter SI.Pressure dp_plus_eps=dp[14] "+1e-3 kg/s";
  final parameter SI.Pressure dp_minus_eps=dp[16] "-1e-3 kg/s";
  final parameter SIadd.NonDim asym_eps=if abs(dp_plus_eps) > 0 then
      abs(dp_plus_eps + dp_minus_eps)/abs(dp_plus_eps) else 0
    "Odd-symmetry defect at +/- 1e-3 kg/s; must be zero for a horizontal node";

  /* Monotonicity: dp must increase strictly with m_flow across the whole
     sweep, including through zero. The sweep is ordered descending, so
     each successive entry must be strictly smaller. */
  final parameter Boolean monotone[n - 1]={dp[i] > dp[i + 1] for i in 1:n - 1}
    "Strict monotonicity of dp(m_flow) between consecutive sweep points";
  final parameter Integer nNonMonotone=sum({if monotone[i] then 0 else 1 for i in 1:n - 1})
    "Count of monotonicity violations; must be zero";

  /* Sign consistency: dp must carry the sign of the flow. */
  final parameter Integer nSignErrors=sum({if (mch[i] > 0 and dp[i] <= 0) or (mch[i] < 0 and dp[i]
       >= 0) then 1 else 0 for i in 1:n})
    "Count of points where dp does not carry the sign of the flow; must be zero";

  /* Local slope, to show that the derivative stays finite and positive
     through zero rather than collapsing or blowing up. */
  final parameter Real ddp_dm[n - 1]={(dp[i] - dp[i + 1])/(mch[i] - mch[i + 1]) for i in 1:n - 1}
    "Secant slope between consecutive sweep points [Pa/(kg/s)]";
  final parameter Real ddp_dm_min=min(ddp_dm) "Must be strictly positive";
  final parameter Real ddp_dm_max=max(ddp_dm) "Must be finite";
  final parameter Real slopeRatio=ddp_dm_max/max(ddp_dm_min, Modelica.Constants.small)
    "Dynamic range of the slope over the whole sweep";

equation
  /* ---- Mathematical well-posedness of the closure. None of this is a
        benchmark comparison and none of it depends on a solver. ---- */
  assert(abs(dp_at_zero) < 1e-12, "The frictional pressure loss of a horizontal node at exactly
zero flow is " + String(dp_at_zero) + " Pa instead of zero. Natural circulation passes through
zero flow, so a non-zero value here is a spurious source.", AssertionLevel.error);

  assert(asym_eps < 1e-9, "The closure is not odd-symmetric about zero flow: +1e-3 kg/s gives "
     + String(dp_plus_eps) + " Pa and -1e-3 kg/s gives " + String(dp_minus_eps) + " Pa, an
asymmetry of " + String(asym_eps) + ". Flow reversal would then inject or remove energy.",
    AssertionLevel.error);

  assert(nNonMonotone == 0, "dp(m_flow) is not strictly monotonic across the sweep: "
     + String(nNonMonotone) + " violations. A non-monotonic pressure loss admits multiple flow
solutions at one pressure difference, which is what makes a low-flow loop non-integrable.",
    AssertionLevel.error);

  assert(nSignErrors == 0, "At " + String(nSignErrors) + " sweep points the frictional pressure
loss does not carry the sign of the mass flow rate. Friction must always oppose the flow.",
    AssertionLevel.error);

  assert(ddp_dm_min > 0, "The secant slope of dp(m_flow) reaches " + String(ddp_dm_min) +
    " Pa/(kg/s), which is not strictly positive. The momentum balance is then locally
singular.", AssertionLevel.error);

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<h4>Purpose</h4>
<p>Open item <b>O-24</b>. Natural circulation lives entirely in the low-flow regime and passes
through exactly zero flow, possibly changing direction. Before any natural circulation run is
attempted, the pressure-loss closure itself has to be known to be mathematically well behaved
there. This model answers that question <b>without a solver</b>: it evaluates
<code>dp_DP_staticHead</code> - the exact function
<a href=\"modelica://TRANSFORM.Fluid.ClosureRelations.PressureLoss.Models.DistributedPipe_1D.SinglePhase_Developed_2Region_NumStable\">SinglePhase_Developed_2Region_NumStable</a>
calls - at 29 mass flow rates from rated flow down through zero and symmetrically into
reverse.</p>

<h4>What is asserted</h4>
<ol>
<li><b>Zero at zero.</b> A horizontal node must have exactly zero frictional loss at zero flow.</li>
<li><b>Odd symmetry.</b> Equal and opposite flows must give equal and opposite losses.</li>
<li><b>Strict monotonicity</b> of <code>dp(m_flow)</code> across the whole sweep, including
through zero. A non-monotonic closure admits several flow solutions at one pressure difference.</li>
<li><b>Sign consistency.</b> Friction always opposes the flow.</li>
<li><b>Finite positive slope.</b> The secant slope never reaches zero, so the momentum balance
is never locally singular.</li>
</ol>

<h4>What this does not test</h4>
<p>This is the <b>closure</b>, not the <b>loop</b>. A well-posed pressure-loss function is
necessary for natural circulation but not sufficient: the integrability of the assembled loop
depends on the mass-balance formulation and on state scaling as well. That is tested separately.
Passing this model does not by itself make the natural circulation stage ready.</p>

<h4>Regularization</h4>
<p>TRANSFORM regularizes with <code>Modelica.Fluid.Utilities.regFun3</code> over
<code>|m_flow| &lt; m_flow_small</code>, with a deliberately inserted zero point. The closure is
therefore C1 through zero by construction. This model measures that rather than assuming it, and
records the slope range the regularization produces.</p>
</html>"));
end LowFlow_Closure;
