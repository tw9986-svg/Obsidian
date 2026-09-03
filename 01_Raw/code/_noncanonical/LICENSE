within MSRE.Experiments;
model PumpStartup_StagnantStart
  "MSRE pump startup begun from the analytic stagnant precursor distribution, with no null transient"
  extends MSRE.Experiments.PumpStartup1D_RotorDynamics(
    t_null=0,
    msre(use_stagnantStart=true, N_neutron_start=1));

  annotation (
    experiment(
      StopTime=150,
      __Dymola_NumberOfIntervals=7500,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>Why this model exists</h4>
<p><a href=\"modelica://MSRE.Experiments.PumpStartup\">PumpStartup</a> holds the loop stagnant for
<code>t_null = 600 s</code> before starting the pump, purely so that the stagnant precursor
distribution has time to build. <b>That hold is not integrable.</b> With the pump off the loop is
isothermal, elevation closed and motionless; the fuel salt is nearly incompressible
(<code>kappa = 2.89e-10 1/Pa</code>, so about 1255 m/s), the mass balance is dynamic, and there
is no bulk motion for the solver's error test to be dominated by. The integrator spends
everything on acoustic modes. Measured: <b>0.036 s of simulated time per four minutes of wall
time</b>, which makes the 600 s hold a run of roughly six weeks.</p>

<p>That was not for want of trying. None of the following changed the rate by more than a factor
of ten: regularizing the pump's zero-flow singularity, giving the momentum balance dynamics,
forcing the dense nonlinear solver, or loosening the solver tolerance by three orders of
magnitude (1e-6 to 1e-3 reached the same time in the same wall clock).</p>

<h4>What this model does instead</h4>
<p>The stagnant distribution is <b>analytic</b>. With no transport, the steady state of the
precursor equation in a core cell is</p>
<pre>
  0 = S_ij - lambda_j*mC_ij      with  S_ij = beta_j/Lambda*N*SF_i
  so  mC_ij = beta_j*N*SF_i/(Lambda*lambda_j)   in the channels, and 0 everywhere else
</pre>
<p>so it is imposed as an initial condition and the pump starts at <code>t = 0</code>. The loop
never sits stagnant, and the run is the pump transient and nothing else.</p>

<p>Summed over the core that is <code>mC_j = beta_j*N/(Lambda*lambda_j)</code>, <b>independent of
the source shape</b>, which is why this initial condition gives exactly the static
<code>Beta_eff = Beta = 0.006781</code> - the number the test has to start from. Setting it at
all is only possible because closing O-23 made <code>C_start</code> effective; before that
TRANSFORM defaulted <code>traceDynamics</code> to <code>massDynamics</code> and the declared
initial precursor condition was discarded.</p>

<h4>What is approximated, and what is not</h4>
<table border=\"1\">
<tr><th>Quantity</th><th>Treatment</th></tr>
<tr><td>total core precursor inventory, per group</td><td><b>exact</b></td></tr>
<tr><td><code>Beta_eff</code> at t = 0</td><td><b>exact</b> (= static Beta, shape independent)</td></tr>
<tr><td>precursors outside the core</td><td><b>exact</b> (zero)</td></tr>
<tr><td>axial shape inside the channels</td><td><b>flat</b>, against the true cosine</td></tr>
</table>
<p>The axial shape is the one approximation. <code>SaltPipe</code> passes
<code>C_a_start</code> and <code>C_b_start</code> to TRANSFORM, which interpolates linearly
between them, so a cosine cannot be stated exactly. It affects the <i>timing</i> of the
sweep-out over the first core transit - about 10 s - and not the inventory, the initial
<code>Beta_eff</code>, or the asymptotic drift reactivity, none of which depends on where inside
the core a precursor sits. <b>It is an approximation of the initial condition, not of the
physics</b>, and it is listed as an open item rather than presented as exact.</p>
</html>"));
end PumpStartup_StagnantStart;
