within MSRE.Verification;
model LowFlow_InverseClosure
  "O-24 | The from_dp direction: m_flow(dp) through zero, which is the direction natural circulation uses"
  extends Modelica.Icons.Example;

  import TRANSFORM.Fluid.ClosureRelations.PressureLoss.Functions.TubesAndConduits.SinglePhase.LaminarTurbulent_MSLDetailed;

  parameter MSRE.Data.Geometry geometry "MSRE hardware geometry";
  parameter SI.Temperature T=908 "Isothermal test temperature";

  /* ------------------------------------------------------------------
     Why this model exists separately from LowFlow_Closure

     LowFlow_Closure swept the FORWARD law dp(m_flow) and found it flawless.
     That is not sufficient. Natural circulation is a from_dp problem: buoyancy
     sets the pressure difference and the flow follows from it, so the relation
     the solver actually inverts is m_flow(dp). It is a different function -
     dp_MFLOW_staticHead rather than dp_DP_staticHead - with its own
     regularization and its own behaviour at the origin.
     ------------------------------------------------------------------ */
  parameter Integer n=33 "Number of sweep points";
  parameter SI.Pressure dps[n]={1000,100,10,1,0.5,0.2,0.1,0.05,0.02,0.01,1e-3,1e-4,1e-5,1e-6,
      1e-8,1e-10,0,-1e-10,-1e-8,-1e-6,-1e-5,-1e-4,-1e-3,-0.01,-0.02,-0.05,-0.1,-0.2,-0.5,-1,-10,
      -100,-1000} "Pressure differences, spanning the regularization band and exact zero";

  final parameter SI.Density d=MSRE.Media.FuelSalt.Utilities.d_T(T) "Cantor density";
  final parameter SI.DynamicViscosity mu=MSRE.Media.FuelSalt.Utilities.eta_T(T) "Cantor viscosity";
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
    Re_turbulent=4000) "One axial node of one fuel channel";

  final parameter LaminarTurbulent_MSLDetailed.dp_IN_var IN_var(
    rho_a=d,
    rho_b=d,
    mu_a=mu,
    mu_b=mu) "Isothermal salt properties";

  /* SinglePhase_Developed_2Region_NumStable passes dp_small/nFM to this function,
     with dp_small = 1 Pa by default. nFM is the number of flow segments. */
  parameter Integer nFM=geometry.nAxial "Flow segments in the channel";
  parameter SI.Pressure dp_small=1.0/nFM "Regularization half-width actually used";

  /* ------------------------------------------------------------------
     The inverse closure, evaluated with no solver present
     ------------------------------------------------------------------ */
  final parameter SI.MassFlowRate mch[n]={LaminarTurbulent_MSLDetailed.dp_MFLOW_staticHead(
      IN_con,
      IN_var,
      dps[i],
      dp_small,
      0) for i in 1:n}   /* horizontal node: static head removed, so this is the friction inverse */
    "Per-channel mass flow rate returned for each pressure difference";
  final parameter SI.MassFlowRate m_flows[n]={mch[i]*nCh for i in 1:n}
    "Equivalent whole-core mass flow rate";
  final parameter SIadd.NonDim Re[n]={d*abs(mch[i]/(d*geometry.A_channel))*geometry.Dh_channel/mu
      for i in 1:n} "Reynolds number, magnitude";

  /* ------------------------------------------------------------------
     Well-posedness of the INVERSE relation
     ------------------------------------------------------------------ */
  final parameter SI.MassFlowRate m_at_zero=mch[17] "Must be exactly zero";
  final parameter SI.MassFlowRate m_plus=mch[16] "+1e-10 Pa";
  final parameter SI.MassFlowRate m_minus=mch[18] "-1e-10 Pa";
  /* Normalizing the symmetry defect by |m_plus| would divide by a quantity that is itself at
     the round-off scale - at dp = 1e-10 Pa the returned flow is about 6e-13 kg/s - which turns
     ordinary double-precision cancellation inside regFun3's cubic into an apparent 1e-7
     asymmetry. The defect is therefore normalized by the per-channel RATED flow, which is the
     scale the answer has to be odd against, and the raw absolute defect is reported alongside
     it so neither number has to be taken on trust. */
  final parameter SI.MassFlowRate m_flow_rated_channel=geometry.m_flow_nominal/nCh
    "Rated per-channel mass flow rate, the scale for the symmetry test";
  final parameter SI.MassFlowRate asym_abs=abs(m_plus + m_minus)
    "Raw absolute odd-symmetry defect [kg/s]";
  final parameter SIadd.NonDim asym=asym_abs/m_flow_rated_channel
    "Odd-symmetry defect, relative to rated per-channel flow";
  final parameter SIadd.NonDim asym_selfRelative=if abs(m_plus) > 0 then asym_abs/abs(m_plus)
       else 0
    "DIAGNOSTIC ONLY: the same defect divided by the returned flow itself. Dominated by
     round-off at these magnitudes and deliberately not asserted on";

  final parameter Boolean monotone[n - 1]={mch[i] > mch[i + 1] for i in 1:n - 1}
    "dp is swept descending, so m_flow must decrease strictly";
  final parameter Integer nNonMonotone=sum({if monotone[i] then 0 else 1 for i in 1:n - 1})
    "Monotonicity violations; must be zero";
  final parameter Integer nSignErrors=sum({if (dps[i] > 0 and mch[i] <= 0) or (dps[i] < 0 and mch[
      i] >= 0) then 1 else 0 for i in 1:n}) "Sign inconsistencies; must be zero";

  /* The quantity that decides Jacobian regularity. A Newton solver working in
     the from_dp direction needs dm_flow/ddp to be finite AND non-zero at the
     origin. Either failure mode is a blocker: infinite means a singular
     Jacobian, zero means the flow cannot respond to a pressure difference. */
  final parameter Real dm_ddp[n - 1]={(mch[i] - mch[i + 1])/(dps[i] - dps[i + 1]) for i in 1:n - 1}
    "Secant slope of the inverse relation [kg/(s.Pa)] per channel";
  final parameter Real dm_ddp_min=min(dm_ddp) "Must be strictly positive";
  final parameter Real dm_ddp_max=max(dm_ddp) "Must be finite";
  final parameter Real slopeRatio=dm_ddp_max/max(dm_ddp_min, Modelica.Constants.small)
    "Dynamic range of the inverse slope across the sweep";
  final parameter Real dm_ddp_atZero=(mch[16] - mch[18])/(dps[16] - dps[18])
    "Slope straddling exact zero, over +/-1e-10 Pa";

equation
  assert(abs(m_at_zero) < 1e-30, "The inverse closure returns " + String(m_at_zero) +
    " kg/s at exactly zero pressure difference instead of zero. Natural circulation passes
through this point.", AssertionLevel.error);

  assert(asym < 1e-12, "The inverse closure is not odd about zero: +1e-10 Pa gives " + String(
    m_plus) + " kg/s and -1e-10 Pa gives " + String(m_minus) + " kg/s, an absolute defect of "
     + String(asym_abs) + " kg/s against a rated per-channel flow of "
     + String(m_flow_rated_channel) + " kg/s.", AssertionLevel.error);

  assert(nNonMonotone == 0, "The inverse relation m_flow(dp) is not strictly monotonic: "
     + String(nNonMonotone) + " violations. A non-monotonic inverse admits several flows at one
pressure difference.", AssertionLevel.error);

  assert(nSignErrors == 0, "At " + String(nSignErrors) + " points the returned flow does not
carry the sign of the pressure difference.", AssertionLevel.error);

  assert(dm_ddp_min > 0, "The inverse slope reaches " + String(dm_ddp_min) + " kg/(s.Pa), which
is not strictly positive. The flow cannot respond to a pressure difference there.",
    AssertionLevel.error);

  assert(dm_ddp_max < Modelica.Constants.inf, "The inverse slope is not finite (" + String(
    dm_ddp_max) + " kg/(s.Pa)). A Newton solver working in the from_dp direction would have a
singular Jacobian.", AssertionLevel.error);

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<h4>Purpose</h4>
<p>Open item <b>O-24</b>. <a href=\"modelica://MSRE.Verification.LowFlow_Closure\">LowFlow_Closure</a>
established that the <b>forward</b> law <code>dp(m_flow)</code> is flawless through zero. That is
<b>necessary but not sufficient</b>: natural circulation is a <code>from_dp</code> problem -
buoyancy sets the pressure difference and the flow follows - so the relation the solver inverts
is <code>m_flow(dp)</code>, a different function with its own regularization.</p>

<h4>What the source says, and why it still has to be measured</h4>
<p><code>dp_MFLOW_staticHead</code> regularizes with
<code>Modelica.Fluid.Utilities.regFun3</code> over <code>|dp| &lt; dp_small</code> and inserts an
explicit zero point. Inside that band it <b>never calls</b>
<code>Internal.m_flow_of_dp_fric</code>, which is where the <code>1/|dp_fric|</code> derivative
singularity lives - it evaluates that function at <code>+/-dp_small</code> and interpolates
between them. The function carries <code>smoothOrder = 1</code>.</p>

<p>So the singularity exists in the library but may be <b>guarded in use</b>. This model measures
which, rather than concluding it from reading. The sweep deliberately includes points far inside
the regularization band (1e-10 Pa) and exact zero.</p>

<h4>Acceptance, separated as O-24 requires</h4>
<table border=\"1\">
<tr><th>Criterion</th><th>Meaning</th></tr>
<tr><td><code>m_flow(0) = 0</code>, odd, monotone, sign-correct</td><td>FUNCTION_VALUE_CONTINUOUS</td></tr>
<tr><td><code>dm_flow/ddp</code> finite <b>and</b> strictly positive at the origin</td><td>JACOBIAN_REGULARITY</td></tr>
</table>
<p>These are reported separately. A closure can be continuous in value and still unusable: an
infinite slope means a singular Jacobian, and a zero slope means the flow cannot respond to a
pressure difference at all. Passing on value alone is <b>not</b> a pass.</p>
</html>"));
end LowFlow_InverseClosure;
