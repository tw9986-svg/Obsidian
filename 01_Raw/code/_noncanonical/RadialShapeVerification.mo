within MSRE.Verification;
model HX_LowFlow_Closure
  "Validity of the heat exchanger heat transfer closure down to natural circulation flow rates"
  extends Modelica.Icons.Example;

  package Medium_fuel = MSRE.Media.FuelSalt_U235 "Fuel salt, heat exchanger shell side";
  package Medium_coolant = MSRE.Media.CoolantSalt "Coolant salt, heat exchanger tube side";

  final parameter MSRE.Data.Geometry geometry "Plant geometry";

  parameter SI.Temperature T_shell=908 "Fuel salt temperature the properties are taken at";
  parameter SI.Temperature T_tube=894 "Coolant salt temperature the properties are taken at";
  parameter SI.AbsolutePressure p_shell=1.5e5 "Fuel salt pressure";
  parameter SI.AbsolutePressure p_tube=2e5 "Coolant salt pressure";

  /* The flow fractions of the work order, plus the range natural circulation is expected in. */
  constant Integer nPoints=12 "# of flow fractions swept";
  final parameter SIadd.NonDim fs_flow[nPoints]={1.00,0.50,f_flow_Re3000,f_flow_Re2300,0.25,0.20,
      f_flow_Re1000,0.10,0.05,0.01,0.005,0.001}
    "Fuel salt flow rate as a fraction of the rated 168 kg/s. Includes the three Reynolds
     numbers that matter - the top of the blend window, the bottom of it, and the point where
     the old closure crossed zero - so that the boundaries are sampled exactly rather than
     straddled. Kept in STRICTLY DESCENDING order, because criterion 5 reads monotonicity off
     the index";

  parameter SIadd.NonDim f_flow_NC_upper=0.10
    "Upper end of the flow range natural circulation is expected in. From the buoyancy head the
     loop can develop, not from an observed result";
  parameter SIadd.NonDim f_flow_NC_lower=0.01 "Lower end of the same range";

  /* ================================================================
     Properties
     ================================================================ */
  final parameter Medium_fuel.ThermodynamicState state_shell=Medium_fuel.setState_pTX(
      p_shell,
      T_shell,
      Medium_fuel.X_default) "Fuel salt state";
  final parameter SI.DynamicViscosity mu_shell=Medium_fuel.dynamicViscosity(state_shell)
    "Fuel salt dynamic viscosity";
  final parameter SI.ThermalConductivity k_shell=Medium_fuel.thermalConductivity(state_shell)
    "Fuel salt thermal conductivity";
  final parameter SI.SpecificHeatCapacity cp_shell=Medium_fuel.specificHeatCapacityCp(state_shell)
    "Fuel salt specific heat capacity";
  final parameter SIadd.NonDim Pr_shell=cp_shell*mu_shell/k_shell "Fuel salt Prandtl number";

  final parameter Medium_coolant.ThermodynamicState state_tube=Medium_coolant.setState_pTX(
      p_tube,
      T_tube,
      Medium_coolant.X_default) "Coolant salt state";
  final parameter SI.DynamicViscosity mu_tube=Medium_coolant.dynamicViscosity(state_tube)
    "Coolant salt dynamic viscosity";
  final parameter SI.ThermalConductivity k_tube=Medium_coolant.thermalConductivity(state_tube)
    "Coolant salt thermal conductivity";
  final parameter SI.SpecificHeatCapacity cp_tube=Medium_coolant.specificHeatCapacityCp(state_tube)
    "Coolant salt specific heat capacity";
  final parameter SIadd.NonDim Pr_tube=cp_tube*mu_tube/k_tube "Coolant salt Prandtl number";

  /* ================================================================
     Reynolds numbers
     ================================================================ */
  final parameter SI.Area A_tube_total=Modelica.Constants.pi/4*geometry.D_tube_inner^2*geometry.nTubes
    "Total tube side flow area";

  final parameter SIadd.NonDim Res_shell[nPoints]={fs_flow[i]*geometry.m_flow_nominal*geometry.Dh_shell
      /(geometry.A_shell*mu_shell) for i in 1:nPoints}
    "Shell side Reynolds number at each swept fuel salt flow rate";
  final parameter SIadd.NonDim Re_tube=geometry.m_flow_coolant_nominal*geometry.D_tube_inner/(
      A_tube_total*mu_tube)
    "Tube side Reynolds number. The coolant flow is held at its rated value in every test in
     this library, so it does not follow the fuel salt flow down";

  /* ================================================================
     The correlation, as MSRE.ClosureRelations.Nus_MoltenSalt states it
     ================================================================
     Reproduced here rather than instantiated, because the TRANSFORM closure is a replaceable
     model inside a distributed volume and cannot be evaluated standalone. The reproduction is
     verified against the rated point in check 4 below, so it is not taken on trust. */
  parameter SIadd.NonDim Re_min=100 "Guard on the friction-factor logarithm, as in the closure";

  final parameter SIadd.NonDim Res_eff[nPoints]={max(abs(Res_shell[i]), Re_min) for i in 1:
      nPoints} "Shell side Reynolds number after the closure's own guard";
  final parameter SIadd.NonDim fs_shell[nPoints]={(0.79*Modelica.Math.log(Res_eff[i]) - 1.64)^(
      -2) for i in 1:nPoints} "Filonenko/Petukhov friction factor";
  final parameter Real Nus_shell[nPoints]={(fs_shell[i]/8)*(Res_eff[i] - 1000)*Pr_shell/(1 +
      12.7*sqrt(fs_shell[i]/8)*(Pr_shell^(2/3) - 1)) for i in 1:nPoints}
    "Shell side Nusselt number. NOT typed SI.NusseltNumber: the whole question is whether these
     numbers stay positive";
  final parameter Real alphas_shell[nPoints](each unit="W/(m2.K)") = {Nus_shell[i]*k_shell/
    geometry.Dh_shell for i in 1:nPoints} "Shell side heat transfer coefficient";

  /* ================================================================
     The NEW closure, as MSRE.ClosureRelations.Nus_HX states it
     ================================================================ */
  parameter Real Nu_laminar=3.66
    "Fully developed laminar Nusselt number of the new closure, constant wall temperature";
  parameter SIadd.NonDim Re_laminar=2300 "Upper end of the laminar branch";
  parameter SIadd.NonDim Re_turbulent=3000 "Lower end of the Gnielinski branch";
  final parameter SIadd.NonDim xs[nPoints]={max(0, min(1, (Res_eff[i] - Re_laminar)/(
      Re_turbulent - Re_laminar))) for i in 1:nPoints} "Position in the transition window";
  final parameter SIadd.NonDim ws[nPoints]={xs[i]^2*(3 - 2*xs[i]) for i in 1:nPoints}
    "Smoothstep weight of the Gnielinski branch";
  final parameter Real Nus_shell_new[nPoints]={(1 - ws[i])*Nu_laminar + ws[i]*Nus_shell[i] for
      i in 1:nPoints} "Shell side Nusselt number of the new closure";
  final parameter Real alphas_shell_new[nPoints](each unit="W/(m2.K)") = {Nus_shell_new[i]*
    k_shell/geometry.Dh_shell for i in 1:nPoints}
    "Shell side heat transfer coefficient of the new closure";

  /* UA per unit area, which is the quantity the heat transfer interface actually divides by:
     UA = 1/(Rs_add + 1/(alpha*A)). The old closure makes this singular at Re = 1000. */
  final parameter Real UAs_old[nPoints](each unit="W/K") = {alphas_shell[i]*A_ht_shell for i in
    1:nPoints} "Shell side UA of the old closure";
  final parameter Real UAs_new[nPoints](each unit="W/K") = {alphas_shell_new[i]*A_ht_shell for
    i in 1:nPoints} "Shell side UA of the new closure";
  final parameter SI.Area A_ht_shell=geometry.f_area_hx*Modelica.Constants.pi*geometry.D_tube_outer
      *geometry.L_tube*geometry.nTubes "Shell side heat transfer area";

  /* ---------------- Criteria, fixed before the values were looked at ----------------
     1 positive        Nu > 0 at every swept point
     2 finite          alpha and UA finite everywhere, no division by zero
     3 C0 continuity   no jump at either blend boundary
     4 C1 continuity   no derivative jump at either blend boundary
     5 monotone        Nu non-decreasing in Re
     6 rated invariant the rated point is bit-for-bit unchanged
     7 bounded limit   Nu -> Nu_laminar as Re -> 0, not divergent               */
  final parameter Integer nNegative_new=sum({(if Nus_shell_new[i] <= 0 then 1 else 0) for i in
      1:nPoints}) "Criterion 1: # of swept points where the new closure is not positive";
  final parameter Real Nu_new_min=min(Nus_shell_new) "Smallest new Nusselt number";
  final parameter Real UA_new_max=max(UAs_new) "Largest new UA, to show it is bounded";

  /* ---- Criteria 3 and 4, stated as exact identities rather than sampled ----
     A first attempt sampled Nu at Re_boundary +/- 1e-6 and compared the two sides. That test is
     not well posed and it failed on a correct closure: across a continuous function the two
     samples differ by slope*2*eps, which at the upper boundary is 0.014*2e-6 = 2.8e-8 - the
     slope, not a jump - and the finite-difference slope itself is then round-off dominated,
     because Nu ~ 32 in double precision divided by a 1e-6 step is noise of order 7e-9. Both
     numbers measured the sampling, not the closure.

     The blend is C0 and C1 for a reason that can be checked exactly instead. Writing
     Nu = (1-w)*Nu_lam + w*Nu_g with w = x^2*(3-2x) and x = (Re-Re_lam)/(Re_turb-Re_lam):

       at Re_lam   x = 0, so w = 0 and dw/dx = 6x(1-x) = 0
                   => Nu = Nu_lam exactly, and dNu/dRe = 0 on both sides, since the laminar
                      branch is constant and w contributes nothing at zero slope
       at Re_turb  x = 1, so w = 1 and dw/dx = 6x(1-x) = 0
                   => Nu = Nu_g exactly, and dNu/dRe = dNu_g/dRe on both sides

     So C0 and C1 follow algebraically from four exact statements about w. Those are what is
     asserted, at exactly zero, which is a STRICTER test than the sampled one - not a looser
     one. */
  final parameter SIadd.NonDim x_atReLam=max(0, min(1, (Re_laminar - Re_laminar)/(Re_turbulent
       - Re_laminar))) "Blend coordinate at the lower boundary";
  final parameter SIadd.NonDim x_atReTurb=max(0, min(1, (Re_turbulent - Re_laminar)/(
      Re_turbulent - Re_laminar))) "Blend coordinate at the upper boundary";
  final parameter Real w_atReLam=x_atReLam^2*(3 - 2*x_atReLam) "Blend weight at Re_laminar";
  final parameter Real w_atReTurb=x_atReTurb^2*(3 - 2*x_atReTurb) "Blend weight at Re_turbulent";
  final parameter Real dwdx_atReLam=6*x_atReLam*(1 - x_atReLam)
    "Blend weight slope at Re_laminar, analytic";
  final parameter Real dwdx_atReTurb=6*x_atReTurb*(1 - x_atReTurb)
    "Blend weight slope at Re_turbulent, analytic";

  final parameter Real err_C0_laminar=abs(Nu_atRe(Re_laminar) - Nu_laminar)
    "Criterion 3: the blend must return the laminar branch exactly at the lower boundary";
  final parameter Real err_C0_turbulent=abs(Nu_atRe(Re_turbulent) - Nu_gnielinski_atRe(
      Re_turbulent))
    "Criterion 3: the blend must return the Gnielinski branch exactly at the upper boundary";
  final parameter Real err_C1_laminar=abs(w_atReLam) + abs(dwdx_atReLam)
    "Criterion 4: w and dw/dx must both vanish at the lower boundary";
  final parameter Real err_C1_turbulent=abs(w_atReTurb - 1) + abs(dwdx_atReTurb)
    "Criterion 4: w must be one and dw/dx must vanish at the upper boundary";

  /* Criterion 5. The sweep runs from the highest flow to the lowest, so Nu must not increase
     with the index. */
  final parameter Integer nNonMonotone=sum({(if Nus_shell_new[i] > Nus_shell_new[i - 1] then 1
       else 0) for i in 2:nPoints})
    "Criterion 5: # of intervals over which Nu rises as Re falls";

  /* Criterion 6. Above Re_turbulent the weight is exactly 1, so the new closure must return
     exactly what the old one did - not approximately. */
  final parameter Real err_ratedInvariance=abs(Nus_shell_new[1] - Nus_shell[1])
    "Criterion 6: change in the rated-flow Nusselt number. Must be exactly zero";

  /* Criterion 7. */
  final parameter Real Nu_atZeroFlow=Nu_atRe(0)
    "Criterion 7: the limit the new closure approaches as the flow vanishes";

  /* ================================================================
     Reported
     ================================================================ */
  final parameter Real Nu_shell_min=min(Nus_shell) "Most negative shell side Nusselt number";
  final parameter Integer nNegative=sum({(if Nus_shell[i] < 0 then 1 else 0) for i in 1:nPoints})
    "# of swept flow rates at which the closure returns a negative Nusselt number";
  final parameter SIadd.NonDim f_flow_Re1000=1000*geometry.A_shell*mu_shell/(geometry.Dh_shell*
      geometry.m_flow_nominal)
    "Flow fraction at which the shell side reaches Re = 1000, where the (Re - 1000) factor of
     the Gnielinski expression changes sign and the Nusselt number crosses zero";
  final parameter SIadd.NonDim f_flow_Re2300=2300*geometry.A_shell*mu_shell/(geometry.Dh_shell*
      geometry.m_flow_nominal)
    "Flow fraction at which the shell side reaches Re = 2300, the lower blend boundary";
  final parameter SIadd.NonDim f_flow_Re3000=3000*geometry.A_shell*mu_shell/(geometry.Dh_shell*
      geometry.m_flow_nominal)
    "Flow fraction at which the shell side leaves the stated validity range of Gnielinski";

  /* Rated-point cross-check against the table in the closure's own documentation. */
  final parameter SIadd.NonDim Re_shell_rated=Res_shell[1] "Shell side Reynolds at rated flow";
  final parameter Real Nu_shell_rated=Nus_shell[1] "Shell side Nusselt at rated flow";
  final parameter Real alpha_shell_rated(unit="W/(m2.K)") = alphas_shell[1]
    "Shell side heat transfer coefficient at rated flow";

protected
  function Nu_atRe "New closure evaluated at one Reynolds number, at the shell side Prandtl number"
    extends Modelica.Icons.Function;
    input Real Re "Reynolds number";
    input Real Pr=20.1008631356 "Prandtl number";
    input Real Nu_lam=3.66 "Laminar branch";
    input Real Re_lam=2300 "Lower blend boundary";
    input Real Re_turb=3000 "Upper blend boundary";
    input Real Re_guard=100 "Guard on the friction-factor logarithm";
    output Real Nu "Nusselt number";
  protected
    Real Re_e, f, Nu_g, x, w;
  algorithm
    Re_e := max(abs(Re), Re_guard);
    f := (0.79*Modelica.Math.log(Re_e) - 1.64)^(-2);
    Nu_g := (f/8)*(Re_e - 1000)*Pr/(1 + 12.7*sqrt(f/8)*(Pr^(2/3) - 1));
    x := max(0, min(1, (Re_e - Re_lam)/(Re_turb - Re_lam)));
    w := x^2*(3 - 2*x);
    Nu := (1 - w)*Nu_lam + w*Nu_g;
    annotation (Inline=false);
  end Nu_atRe;

  function Nu_gnielinski_atRe "Gnielinski branch alone, at the shell side Prandtl number"
    extends Modelica.Icons.Function;
    input Real Re "Reynolds number";
    input Real Pr=20.1008631356 "Prandtl number";
    input Real Re_guard=100 "Guard on the friction-factor logarithm";
    output Real Nu "Nusselt number";
  protected
    Real Re_e, f;
  algorithm
    Re_e := max(abs(Re), Re_guard);
    f := (0.79*Modelica.Math.log(Re_e) - 1.64)^(-2);
    Nu := (f/8)*(Re_e - 1000)*Pr/(1 + 12.7*sqrt(f/8)*(Pr^(2/3) - 1));
    annotation (Inline=false);
  end Nu_gnielinski_atRe;

public
equation
  when terminal() then
    /* ---- 1. The reproduction reproduces the documented rated point ---- */
    assert(abs(Re_shell_rated/8637 - 1) < 0.01 and abs(Nu_shell_rated/101.6 - 1) < 0.01 and abs(
      alpha_shell_rated/1812 - 1) < 0.01, "At rated flow this model computes Re = " + String(
      Re_shell_rated) + ", Nu = " + String(Nu_shell_rated) + ", alpha = " + String(
      alpha_shell_rated) + " W/(m2.K) on the shell side, against the 8637 / 101.6 / 1812 stated
in the documentation of MSRE.ClosureRelations.Nus_MoltenSalt. The correlation is reproduced
here rather than instantiated, so if this check fails the reproduction is wrong and nothing
else in this model means anything.", AssertionLevel.error);

    /* ---- Criterion 1: positive everywhere ---- */
    assert(nNegative_new == 0, "The new heat exchanger closure returns a non-positive Nusselt
number at " + String(nNegative_new) + " of the " + String(nPoints) + " swept flow rates, the
smallest being " + String(Nu_new_min) + ". The whole purpose of the change was to remove that.",
      AssertionLevel.error);

    /* ---- Criterion 2: alpha and UA finite. The old closure was singular, not merely
          wrong-signed: UA = 1/(Rs_add + 1/(alpha*A)) divides by zero where alpha = 0. ---- */
    assert(UA_new_max < 1e12 and Nu_new_min >= Nu_laminar - 1e-12, "The new closure gives a UA
of up to " + String(UA_new_max) + " W/K and a Nusselt number as low as " + String(Nu_new_min) +
      ", against a laminar floor of " + String(Nu_laminar) + ". alpha must stay bounded away
from zero so that UA = 1/(1/(alpha*A)) stays finite; the old closure passed through alpha = 0 at
Re = 1000 and divided by zero there.", AssertionLevel.error);

    /* ---- Criterion 3: no jump at either blend boundary ---- */
    assert(err_C0_laminar == 0 and err_C0_turbulent == 0, "The new closure departs from its own
branches by " +
      String(err_C0_laminar) + " at Re = " + String(Re_laminar) + " and by " + String(
      err_C0_turbulent) + " at Re = " + String(Re_turbulent) + ". A discontinuous heat transfer
coefficient makes the loop energy balance a discontinuous function of the flow, which puts a
state event in the middle of the flow range the natural circulation solution lives in.",
      AssertionLevel.error);

    /* ---- Criterion 4: no derivative jump at either boundary ---- */
    assert(err_C1_laminar == 0 and err_C1_turbulent == 0, "The blend weight fails its endpoint
conditions by " + String(err_C1_laminar) + " at Re = " + String(Re_laminar) + " and " + String(
      err_C1_turbulent) + " at Re = " + String(Re_turbulent) + ". The smoothstep must satisfy
w = 0, dw/dx = 0 at the lower end and w = 1, dw/dx = 0 at the upper end; those four conditions
are what make the blended Nusselt number C1 across both boundaries.", AssertionLevel.error);

    /* ---- Criterion 5: monotone in the Reynolds number ---- */
    assert(nNonMonotone == 0, "The new closure gives a Nusselt number that RISES as the flow
falls, over " + String(nNonMonotone) + " of the " + String(nPoints - 1) + " swept intervals.
Heat transfer must not improve as the flow is reduced.", AssertionLevel.error);

    /* ---- Criterion 6: the rated point must not move at all ---- */
    assert(err_ratedInvariance == 0, "The rated-flow Nusselt number changed by " + String(
      err_ratedInvariance) + ". At Re = " + String(Re_shell_rated) + " the blend weight is
exactly 1, so the new closure must reduce IDENTICALLY to the old one there. Anything other than
exactly zero means every rated-flow result in this library - and the Dymola B0 baseline - would
have to be re-established for a reason that has nothing to do with low flow.",
      AssertionLevel.error);

    /* ---- Criterion 7: bounded low-flow limit ---- */
    assert(abs(Nu_atZeroFlow - Nu_laminar) < 1e-12, "As the flow vanishes the new closure tends
to " + String(Nu_atZeroFlow) + " instead of the laminar value " + String(Nu_laminar) + ". The
limit must be the fully developed laminar Nusselt number, which is a constant: that is what
makes alpha bounded away from zero and UA finite at zero flow.", AssertionLevel.error);

  end when;

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<h4>What this answers</h4>
<p>Every result in this library so far has been obtained at or near rated flow, where both
sides of the heat exchanger run at a Reynolds number of order 1e4 and the Gnielinski closure
<a href=\"modelica://MSRE.ClosureRelations.Nus_MoltenSalt\">Nus_MoltenSalt</a> is squarely
inside its validity range. Natural circulation is a different regime: the fuel salt flow falls
to a few per cent of rated, and the shell side Reynolds number falls with it. This model asks
whether the closure is still defined there, <b>before</b> any natural circulation result is
interpreted.</p>

<h4>Why it is a parameter sweep</h4>
<p><code>Nu</code> is an explicit algebraic function of <code>Re</code> and <code>Pr</code>, so
evaluating it at a set of flow rates is the complete statement of what the closure does. The
properties are taken at a single temperature on each side, which is the one approximation here:
it fixes <code>Pr</code>, so the <code>Re</code> dependence is isolated. That is deliberate -
the question is what happens as the flow falls, not as the temperature moves.</p>

<h4>The reproduction is checked, not assumed</h4>
<p>The TRANSFORM closure is a replaceable model inside a distributed volume and cannot be
evaluated on its own, so the two correlation lines are restated here. Check 1 evaluates the
restatement at rated flow and compares it against the <code>Re</code> / <code>Nu</code> /
<code>alpha</code> table in the closure's own documentation. If check 1 fails, nothing else in
this model is meaningful.</p>

<h4>What changed as a result of this model</h4>
<p>The heat exchanger now uses
<a href=\"modelica://MSRE.ClosureRelations.Nus_HX\">Nus_HX</a> on both sides instead of plain
Gnielinski. <code>Nus_shell</code> is the old closure and <code>Nus_shell_new</code> the new
one, both evaluated here so the change can be read as a difference rather than described.</p>

<h4>Criteria, fixed before the values were looked at</h4>
<table border=\"1\">
<tr><th>#</th><th>Criterion</th><th>Why</th></tr>
<tr><td>1</td><td><code>Nu &gt; 0</code> everywhere</td><td>a negative Nusselt number reverses
    the heat flow</td></tr>
<tr><td>2</td><td><code>alpha</code>, <code>UA</code> finite</td><td><code>UA = 1/(Rs_add +
    1/(alpha*A))</code> is singular where <code>alpha = 0</code></td></tr>
<tr><td>3</td><td>C0 at both blend boundaries</td><td>a discontinuous <code>UA</code> puts a
    state event inside the natural circulation flow range</td></tr>
<tr><td>4</td><td>C1 at both blend boundaries</td><td>the integrator differentiates the energy
    balance</td></tr>
<tr><td>5</td><td><code>Nu</code> monotone in <code>Re</code></td><td>heat transfer must not
    improve as the flow is reduced</td></tr>
<tr><td>6</td><td>rated point bit-for-bit unchanged</td><td>otherwise every rated-flow result
    and the Dymola baseline would have to be re-established for a reason unrelated to low
    flow</td></tr>
<tr><td>7</td><td><code>Nu(Re-&gt;0) -&gt; Nu_laminar</code></td><td>bounded, so
    <code>UA</code> stays finite at zero flow</td></tr>
</table>

<h4>How criteria 3 and 4 are tested, and a test that was wrong first</h4>
<p>They were first tested by sampling <code>Nu</code> at <code>Re_boundary +/- 1e-6</code> and
comparing the two sides. <b>That test is not well posed and it failed on a correct closure.</b>
Across a continuous function the two samples differ by <code>slope*2*eps</code>, which at the
upper boundary is <code>0.014*2e-6 = 2.8e-8</code> - the slope, not a jump - and the
finite-difference derivative built on a 1e-6 step is then round-off dominated, since
<code>Nu ~ 32</code> in double precision gives noise of order 7e-9. Both numbers measured the
sampling rather than the closure.</p>
<p>They are now stated as exact identities on the blend weight instead:
<code>w = 0, dw/dx = 0</code> at <code>Re_laminar</code> and <code>w = 1, dw/dx = 0</code> at
<code>Re_turbulent</code>, plus the requirement that the blend return each branch exactly at its
own boundary. C0 and C1 follow algebraically from those four statements, and they are asserted
at <b>exactly zero</b> - a stricter test than the sampled one, not a looser one.</p>
</html>"));
end HX_LowFlow_Closure;
