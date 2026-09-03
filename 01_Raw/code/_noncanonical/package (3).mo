within MSRE.Components;
model FuelPump_Dynamics
  "MSRE fuel salt circulation pump whose shaft speed is a state of the rotor angular momentum equation"

  extends MSRE.Components.BaseClasses.PartialFuelPump;

  /* ------------------------------------------------------------------
     Rotor
     ------------------------------------------------------------------ */
  parameter SI.Torque tau_hyd_nominal=dp_nominal*V_flow_nominal/(omega_nominal*eta_is)
    "Hydraulic (impeller reaction) torque at the rated operating point (236.11 N.m at the active Cantor density; it was 231 N.m at the retired ORNL-TM-4865 one, and it follows d_nominal rather than being restated)";
  parameter SI.Time tau_shaft=4.0
    "Shaft time constant; the single fitted parameter, which sets the startup and the coastdown together";
  parameter SI.MomentOfInertia J=tau_shaft*tau_hyd_nominal/omega_nominal
    "Polar moment of inertia of the rotor, impeller and entrained salt (7.775 kg.m2 at the active density). Set either this or tau_shaft, not both";
  parameter SI.Torque tau_motor_nominal=tau_hyd_nominal + tau_fric_coulomb +
      tau_fric_viscous
    "Motor torque at full demand; the default balances the rated hydraulic and friction torque, so full demand settles the shaft exactly at N_nominal";
  parameter SI.Torque tau_fric_coulomb=0
    "Speed independent bearing and seal drag (Coulomb friction)";
  parameter SI.Torque tau_fric_viscous=0
    "Windage and viscous drag torque at the rated speed";

  /* ------------------------------------------------------------------
     Hydraulic torque relation: R0 or R1
     ------------------------------------------------------------------
     R0  tau_hyd = tau_hyd_nominal*(omega/omega_nominal)^2
         depends on the SPEED alone. The impeller absorbs whatever the affinity law says for the
         rated point, whether or not the pump is actually at that point on its curve.

     R1  tau_hyd = P_shaft/omega
         depends on the ACTUAL operating point, through the power the pump is really delivering.

     R1 introduces NO new parameter. tau_hyd_nominal is already DEFINED in this model as
     dp_nominal*V_flow_nominal/(omega_nominal*eta_is) - that is the R1 relation evaluated at the
     rated point - so R1 is the generalization of R0's own definition off that point, and the two
     agree identically wherever the pump runs on its rated similarity line. */
  parameter Boolean use_operatingPointTorque=false
    "= true for the R1 hydraulic torque, which follows the actual dp and flow; false keeps R0,
     which follows the speed alone. R0 is the default so that nothing already run moves";

  final parameter SI.AngularVelocity omega_reg_torque=omega_reg
    "Regularization width of the 1/omega in the R1 torque. Deliberately the SAME width already
     used by the Coulomb friction term rather than a second, independently chosen number";

  /* N_start, m_flow_start and the start values derived from them are inherited from
     PartialFuelPump, so that the shaft state and the hydraulic variables are initialized from
     the same operating point. */
  final parameter SI.AngularVelocity omega_reg=0.01*omega_nominal
    "Regularization width of the Coulomb friction term at zero speed";
  final parameter SI.Time tau_shaft_eff=J*omega_nominal/tau_hyd_nominal
    "Shaft time constant that actually results from J; equals tau_shaft unless J was overridden directly";

  /* ------------------------------------------------------------------
     State and torques
     ------------------------------------------------------------------ */
  SI.AngularVelocity omega(start=omega_start, fixed=true) "Shaft angular velocity";
  SIadd.NonDim u_motor "Motor torque demand, clipped to [0,1]";
  SI.Torque tau_motor "Motor torque";
  SI.Torque tau_hyd "Hydraulic torque absorbed by the impeller";
  SI.Torque tau_fric "Bearing, seal and windage friction torque";
  SI.Torque tau_net "Net accelerating torque on the shaft";
  SI.Power W_shaft "Shaft power delivered by the motor";

  SI.Power P_hyd "Hydraulic power delivered to the stream, dp*V_flow";
  SI.Power P_shaft_hyd "Shaft power absorbed by the impeller to deliver P_hyd";
  SI.Torque tau_hyd_R0 "R0 hydraulic torque, reported whichever relation is active";
  SI.Torque tau_hyd_R1 "R1 hydraulic torque, reported whichever relation is active";

equation
  /* The commanded speed of the connector is read as a motor torque demand: only its ratio to
     the rated speed is used. A step from 0 to N_nominal is the pump start, a step from
     N_nominal to 0 is the trip. The actual speed is the state, never the command. */
  u_motor = min(1, max(0, N_cmd/N_nominal));
  tau_motor = tau_motor_nominal*u_motor;

  /* ---------------- Hydraulic torque ----------------

     R0. omega*abs(omega) rather than omega^2 so that the sign is right if the shaft is ever
     driven backwards; the affinity law makes the impeller reaction torque scale with the square
     of the speed at a fixed point on the head curve. */
  tau_hyd_R0 = tau_hyd_nominal*omega*abs(omega)/omega_nominal^2;

  /* R1, step 1: the power actually crossing the impeller.

     P_hyd is what the stream receives. What the SHAFT must supply is larger when the machine
     pumps and smaller when the stream drives it, because the losses sit between the two in both
     directions. Writing that as a branch on the sign of P_hyd would be correct but would put a
     state event in the middle of the coastdown, where P_hyd passes through zero; the algebraic
     form below is the same function with no branch and no event:

         P_shaft = P_hyd/eta      for P_hyd > 0   (pumping)
         P_shaft = eta*P_hyd      for P_hyd < 0   (the stream drives the impeller)

     and it is continuous at P_hyd = 0, where both give zero. eta_is is NOT fitted here: it is
     the value already used to define tau_hyd_nominal, so R1 adds no freedom. */
  P_hyd = dp*V_flow;
  P_shaft_hyd = 0.5*(1/eta_is + eta_is)*P_hyd + 0.5*(1/eta_is - eta_is)*noEvent(abs(P_hyd));

  /* R1, step 2: the torque, with the 1/omega regularized.

     P_shaft/omega is singular at rest, and rest is exactly where the startup begins and the
     coastdown ends. The regularized reciprocal

         1/omega  ->  omega/(omega^2 + omega_reg_torque^2)

     is the standard device and it is chosen for five properties, all of which the low-speed test
     checks rather than assumes: it is FINITE at omega = 0 (the torque goes to zero there, not to
     infinity); it is SMOOTH, being a rational function with a strictly positive denominator, so
     it introduces no event and cannot chatter; it is ODD in omega, so reversing the shaft
     reverses the torque and the sign stays right on both sides of zero; it recovers 1/omega to
     within (omega_reg/omega)^2, which is 1e-4 at the rated speed; and it needs no max() or
     branch, which is what would have broken the sign - max(omega, omega_min) is even in neither
     argument and would hold the torque POSITIVE through a reversal, driving the shaft the wrong
     way. */
  tau_hyd_R1 = P_shaft_hyd*omega/(omega^2 + omega_reg_torque^2);

  tau_hyd = if use_operatingPointTorque then tau_hyd_R1 else tau_hyd_R0;

  /* Friction. Both terms default to zero, which is what makes the two analytic speed laws
     below exact; they are exposed because the paper (Section 4.2) identifies precisely these
     torques as what would have to be adjusted to fit the startup and the coastdown at once. */
  tau_fric = tau_fric_coulomb*tanh(omega/omega_reg) + tau_fric_viscous*omega/omega_nominal;

  tau_net = tau_motor - tau_hyd - tau_fric;
  J*der(omega) = tau_net;

  N = 60*omega/(2*pi);
  W_shaft = tau_motor*omega;

  assert(omega > -0.01*omega_nominal,
    "The fuel pump shaft has been driven to a negative speed (" + String(60*omega/(2*pi)) +
    " rpm). The MSRE fuel pump cannot be back-driven; check the motor torque demand and the
friction parameters.", AssertionLevel.warning);

  annotation (
    defaultComponentName="pump",
    Documentation(info="<html>
<h4>What this model adds</h4>
<p>The shaft speed becomes a state instead of a boundary condition:</p>
<p><code>J*der(omega) = tau_motor - tau_hyd - tau_fric</code></p>
<p>This is the equation the paper solves for the MARS pump component, and solving it here is
what lets the pump tests be run from a <i>trip</i> and a <i>start</i> rather than from a fitted
speed history. The flow is then two integrations away from the input: motor torque drives the
shaft, the shaft drives the head, the head drives the loop momentum balance.</p>

<h4>Why one parameter is enough for both tests</h4>
<p>With the default friction (zero) and the hydraulic torque scaling as the square of the
speed, the rotor equation has closed-form solutions, and <b>both</b> pump tests come out of the
<b>same</b> <code>J</code>:</p>
<table border=\"1\">
<tr><th>Test</th><th>Motor torque</th><th>Solution</th></tr>
<tr><td>startup, from rest</td><td><code>tau_motor_nominal</code></td>
    <td><code>omega = omega_nominal*tanh(t/tau_shaft)</code></td></tr>
<tr><td>coastdown, from rated</td><td>0</td>
    <td><code>omega = omega_0/(1 + t/tau_shaft)</code></td></tr>
</table>
<p>with the single time constant</p>
<p><code>tau_shaft = J*omega_nominal/tau_hyd_nominal</code>.</p>
<p><code>tau_shaft</code> and <code>J</code> are two ways of writing the same degree of freedom,
so set one or the other. <code>J</code> defaults to the value that produces
<code>tau_shaft</code>, and <code>tau_shaft_eff</code> reports what the shaft time constant
actually came out as, which differs from <code>tau_shaft</code> only if <code>J</code> was
given directly.</p>
<p>The previous <a href=\"modelica://MSRE.Components.FuelPump\">FuelPump</a> needed two
independently fitted laws for the same rotor (an exponential with 3.4 s for the startup, a
hyperbola with 4.0 s for the coastdown). Here the coastdown hyperbola is recovered exactly and
the startup becomes a <code>tanh</code>, which reaches 98.7 % of rated flow at 10 s with
<code>tau_shaft = 4.0 s</code> and so matches the reported startup as well as the fitted
exponential did, from the same number.</p>

<h4>Default numbers, and where they come from</h4>
<table border=\"1\">
<tr><th>Quantity</th><th>Value</th><th>Origin</th></tr>
<tr><td>rated hydraulic power</td><td>22.95 kW (30.8 hp)</td>
    <td><code>dp_nominal*V_flow_nominal</code>, i.e. 3.0 bar at 0.076485 m3/s</td></tr>
<tr><td><code>tau_hyd_nominal</code></td><td>236.11 N.m</td>
    <td>that power divided by <code>omega_nominal*eta_is</code></td></tr>
<tr><td><code>tau_shaft</code></td><td>4.0 s</td><td><b>fitted</b></td></tr>
<tr><td><code>J</code></td><td>7.775 kg.m2</td>
    <td><code>tau_shaft*tau_hyd_nominal/omega_nominal</code></td></tr>
</table>
<p>These three numbers moved when the fuel salt density moved: they were 22.4 kW, 231 N.m and
7.59 kg.m2 at the retired ORNL-TM-4865 density and are 22.95 kW, 236.11 N.m and 7.775 kg.m2 at
the Cantor density now active. Nothing was refitted - the pump reads <code>d_nominal</code> from
the medium through <code>PrimarySystem</code>, so the torque and the inertia follow the property
model rather than being restated beside it.</p>
<p>Only the shaft time constant is free; the rest follows from the rated duty. That is the same
single degree of freedom the paper describes as <q>typical generic pump parameters</q>, and the
paper's sensitivity case (moment of inertia halved) is run here by setting
<code>tau_shaft = 2.0</code>.</p>

<h4>What is still missing</h4>
<p>The hydraulic torque depends on the speed alone, not on the operating point on the head
curve. A homologous torque characteristic would make it a function of both speed and flow, and
that is what would be needed to reproduce a pump running far off its design point, such as the
reverse-flow region. It does not matter for the two zero-power tests, where the pump stays on
its rated curve, and it is the reason <code>tau_fric_coulomb</code> and
<code>tau_fric_viscous</code> are exposed rather than hard-wired to zero.</p>
</html>"));
end FuelPump_Dynamics;
