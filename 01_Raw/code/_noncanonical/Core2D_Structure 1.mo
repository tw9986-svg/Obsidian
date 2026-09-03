within MSRE.Verification;
model Core2D_RadialHydraulics
  "2D-1: what flow split do the 15 radial rings actually produce, and is it a radial hydraulic model or radial nodalization?"
  extends MSRE.Verification.Core2D_TH_ZeroPower;

  /* ================================================================
     Per-ring hydraulic state, read from the components themselves
     ================================================================ */
  final parameter Integer nR=nodalization.nRings "# of radial rings";

  SI.MassFlowRate m_flows[nR]={core.channels[r].m_flow_ring for r in 1:nR}
    "Mass flow rate carried by each ring";
  SI.MassFlowRate m_flow_channels=sum(m_flows) "Total flow through the fuel channels";
  SIadd.NonDim fs_flow[nR]={m_flows[r]/noEvent(max(abs(m_flow_channels), 1e-9)) for r in 1:nR}
    "Fraction of the channel flow carried by each ring";
  SI.Velocity vs[nR]={m_flows[r]/(nodalization.nChannels[r]*geometry.A_channel*ds_ring[r]) for r
     in 1:nR} "Bulk velocity in the channels of each ring";
  SIadd.NonDim Res[nR]={core.channels[r].Re for r in 1:nR} "Channel Reynolds number of each ring";
  SI.Pressure dps[nR]={core.channels[r].port_a.p - core.channels[r].port_b.p for r in 1:nR}
    "Pressure drop across each ring";
  SI.Pressure dps_gravity[nR]={core.channels[r].dp_gravity_local for r in 1:nR}
    "Static-head part of each ring's drop, from its own node densities";
  SI.Pressure dps_nonstatic[nR]={dps[r] - dps_gravity[r] for r in 1:nR}
    "Friction plus form plus acceleration in each ring";
  SI.AbsolutePressure ps_in[nR]={core.channels[r].port_a.p for r in 1:nR} "Ring inlet pressure";
  SI.AbsolutePressure ps_out[nR]={core.channels[r].port_b.p for r in 1:nR} "Ring outlet pressure";

  SI.Density ds_ring[nR]={sum(core.channels[r].ds_channel)/nodalization.nAxial for r in 1:nR}
    "Axially averaged fuel salt density of each ring";
  SI.Temperature Ts_ring[nR]={sum(core.channels[r].Ts_fuel)/nodalization.nAxial for r in 1:nR}
    "Axially averaged fuel salt temperature of each ring";
  SI.Temperature Ts_out[nR]={core.channels[r].Ts_fuel[nodalization.nAxial] for r in 1:nR}
    "Fuel salt temperature leaving each ring";

  /* ================================================================
     Conservation and uniformity
     ================================================================ */
  SI.MassFlowRate err_massBalance=m_flow_channels - core.port_a.m_flow
    "Ring flows minus the flow entering the vessel. Not identically zero during a transient -
     the plena store mass - but it must vanish at steady state";
  SIadd.NonDim err_massBalance_rel=err_massBalance/geometry.m_flow_nominal
    "The same, relative to the rated flow";

  /* Equal-flow reference. Every ring holds the same 76 channels and, as the code trace shows,
     every geometric and hydraulic parameter of the ring array is passed with `each` except the
     two form losses, which are zero. So if the rings differ hydraulically at all, it can only be
     through the fluid properties their own power distribution creates. */
  SI.MassFlowRate m_flow_ref=m_flow_channels/nR "Flow each ring would carry if all were equal";
  SIadd.NonDim eps[nR]={m_flows[r]/noEvent(max(abs(m_flow_ref), 1e-9)) - 1 for r in 1:nR}
    "Relative departure of each ring from the equal-flow reference";
  SIadd.NonDim eps_max=max({abs(eps[r]) for r in 1:nR}) "Largest departure over the rings";

  SI.MassFlowRate m_flow_mean=m_flow_channels/nR "Mean ring flow";
  SI.MassFlowRate m_flow_sd=sqrt(sum({(m_flows[r] - m_flow_mean)^2 for r in 1:nR})/nR)
    "Standard deviation of the ring flows";
  SIadd.NonDim CV_mflow=m_flow_sd/noEvent(max(abs(m_flow_mean), 1e-9))
    "Coefficient of variation of the ring flow distribution";

  /* The radial power heterogeneity that is present, for comparison against the hydraulic one. */
  SIadd.NonDim CV_power=sqrt(sum({(nodalization.f_radial[r] - 1)^2 for r in 1:nR})/nR)
    "Coefficient of variation of the radial power distribution";
  SI.TemperatureDifference dT_radial=max(Ts_out) - min(Ts_out)
    "Spread of ring outlet temperature, the thermal signature of the radial power split";

  /* ================================================================
     Mechanism test: is the split the one buoyancy and viscosity predict?
     ================================================================
     The rings are parallel paths between two common plena, so they all see the SAME total
     pressure difference. What differs between them is how that difference is split between
     static head and friction. The channel is vertical and the salt is dense, so the static
     head is about 98.7 % of the total: a ring that is hotter has a lower density, a smaller
     static head, and therefore a LARGER friction budget - and being hotter it is also less
     viscous. In laminar flow, which is where the fuel channels are, both act linearly:

       m_i  proportional to  dp_nonstatic_i / mu_i

     That is the statement worth asserting, and it is much sharper than a bound on the size of
     the split. */
  SI.Pressure dp_shared_max=max(dps) "Largest ring total pressure drop";
  SI.Pressure dp_shared_min=min(dps) "Smallest ring total pressure drop";
  SIadd.NonDim err_sharedDp=(dp_shared_max - dp_shared_min)/noEvent(max(abs(dp_shared_max), 1))
    "Spread of the total ring pressure drop. The rings share both plena, so this must vanish";

  SI.DynamicViscosity mus[nR]={Medium.dynamicViscosity(Medium.setState_pTX(
      ps_out[r],
      Ts_out[r],
      Medium.X_default)) for r in 1:nR} "Fuel salt viscosity at each ring outlet";
  Real conductances[nR](each unit="1")={dps_nonstatic[r]/mus[r] for r in 1:nR}
    "Laminar conductance of each ring, up to a common constant";
  SI.MassFlowRate m_flows_predicted[nR]={m_flow_channels*conductances[r]/sum(conductances) for r
     in 1:nR} "Ring flow the buoyancy-plus-viscosity mechanism predicts";
  SIadd.NonDim err_mechanism=max({abs(m_flows[r]/noEvent(max(abs(m_flows_predicted[r]), 1e-9))
       - 1) for r in 1:nR})
    "Largest departure of the measured split from the predicted one";

  /* Ordering. A hotter ring must carry more flow, so the flow ranking must follow the power
     ranking. f_radial is tabulated in descending order, so the flows must be descending too. */
  Integer nOrderViolations=sum({(if m_flows[r] > m_flows[r - 1] then 1 else 0) for r in 2:nR})
    "# of adjacent ring pairs where the flow rises as the power falls";

  /* ---------------- Thresholds ----------------
     tol_uniform is a statement about numerical precision. tol_mechanism is a statement about a
     lumped prediction - it uses one outlet viscosity per ring where the real ring has an axial
     profile - so it is an order-of-magnitude agreement test, not a second solution. */
  parameter SIadd.NonDim tol_massBalance=1e-6
    "Allowed relative ring/vessel mass balance error at steady state";
  parameter SIadd.NonDim tol_sharedDp=1e-9
    "Allowed spread of the total ring pressure drop; the rings share both plena";
  parameter SIadd.NonDim tol_uniform=1e-6
    "At or below this, the ring flows are uniform to numerical precision, so the 15 rings carry
     NO hydraulic information and the discretization is radial nodalization only";
  parameter SIadd.NonDim tol_mechanism=0.10
    "Allowed departure of the measured split from the lumped buoyancy-plus-viscosity prediction";

equation
  when terminal() then
    assert(abs(err_massBalance_rel) < tol_massBalance, "The 15 ring flows sum to " + String(
      m_flow_channels) + " kg/s but the vessel receives " + String(core.port_a.m_flow) +
      " kg/s, a relative gap of " + String(err_massBalance_rel) + ". At steady state the plena
store nothing, so these are the same quantity and the ring flows below cannot be interpreted
until they agree.", AssertionLevel.error);

    assert(err_sharedDp < tol_sharedDp, "The 15 ring total pressure drops span " + String(100*
      err_sharedDp) + " % of their own magnitude. Every ring connects the same lower plenum to
the same upper plenum, so they see one pressure difference; a spread here means the parallel
connection is not doing what it is supposed to and no flow split below can be read.",
      AssertionLevel.error);

    assert(err_mechanism < tol_mechanism, "The ring flow split departs from the
buoyancy-plus-viscosity prediction by up to " + String(100*err_mechanism) + " %. The rings are
geometrically identical with zero form losses, so the only mechanism available is that a hotter
ring has a smaller static head - and so a larger share of the shared pressure difference for
friction - and a lower viscosity. If the measured split does not follow m ~ dp_nonstatic/mu,
something other than that mechanism is moving flow between the rings and it must be traced
before any 2-D result is interpreted.", AssertionLevel.error);

    /* Gated on there being a resolvable split at all. At zero power the rings are thermally
       identical and their flows agree to 1e-12, so their ORDERING is pure round-off and a
       strict ranking assertion has no content there - it failed on a correct zero-power
       solution before this gate was added. Where the split is real, the ranking is a genuine
       statement about the mechanism. */
    assert(eps_max < tol_uniform or nOrderViolations == 0,
      "The ring flow ranking does not follow the power ranking at "
       + String(nOrderViolations) + " of the " + String(nR - 1) + " adjacent pairs. f_radial is
tabulated in descending order, so a hotter, less dense, less viscous ring must carry more flow
and the ring flows must be descending too.", AssertionLevel.error);

  end when;

  annotation (
    experiment(
      StopTime=20000,
      __Dymola_NumberOfIntervals=2000,
      Tolerance=1e-6),
    Documentation(info="<html>
<h4>The question</h4>
<p>The 2-D core has 15 radial rings. This model asks what those rings actually <b>do</b>
hydraulically, and answers one question: is this a <b>radial hydraulic model</b> or
<b>radial nodalization</b> with a radial power distribution laid over it? Those are different
claims and only one of them is supported.</p>

<h4>What the code trace predicts before the run</h4>
<p>In <a href=\"modelica://MSRE.Components.ReactorCore\">ReactorCore</a> the ring array is
declared</p>
<pre>
  CoreChannel channels[nRings](
    nParallel = nChannels,          // 76 for every ring
    each length, each dheight, each crossArea, each dimension,
    each r_graphite_inner, each r_graphite_outer, ...
    K_inlet = K_channelInlet,       // zeros(nRings)
    K_exit  = K_channelExit,        // zeros(nRings)
    Q_gens  = Qs_channels)          // DIFFERS per ring
</pre>
<p>Every geometric and hydraulic parameter carries <code>each</code>. The only per-ring inputs
are the two form losses, which are <b>zero</b>, and the power. <code>K_distributed</code> is
zero as well, and no per-ring roughness is exposed. So there is <b>no geometric or form-loss
mechanism</b> by which the rings can differ hydraulically.</p>
<p>One coupling does remain, and it is physical: each ring's own power sets its temperature,
which sets its density and viscosity, which changes its friction and its static head. The rings
share the same inlet and outlet plenum pressures, so that property difference must show up as a
flow difference. It is a <b>secondary</b> effect, not a designed flow split.</p>

<h4>Provenance of every per-ring hydraulic input</h4>
<table border=\"1\">
<tr><th>Quantity</th><th>Per ring?</th><th>Provenance</th></tr>
<tr><td><code>nChannels</code> = 76</td><td>same</td><td>NUMERICAL_NODALIZATION, from the
    equal-area grouping</td></tr>
<tr><td><code>crossArea</code>, <code>dimension</code></td><td><code>each</code></td>
    <td>HARDWARE_GEOMETRY</td></tr>
<tr><td><code>length</code>, <code>dheight</code></td><td><code>each</code></td>
    <td>HARDWARE_GEOMETRY</td></tr>
<tr><td>roughness</td><td>not exposed</td><td>TRANSFORM default, OPEN</td></tr>
<tr><td><code>K_inlet</code>, <code>K_exit</code></td><td>per ring, both <b>0</b></td>
    <td>ASSUMED - the Kedl ORNL-TM-3229 form losses have not been extracted</td></tr>
<tr><td><code>K_distributed</code></td><td>zeros</td><td>ASSUMED</td></tr>
<tr><td><code>Q_gens</code></td><td><b>differs</b></td><td>ASSUMED radial profile</td></tr>
<tr><td>inlet / outlet pressure</td><td>shared plena</td><td>DERIVED</td></tr>
</table>

<h4>How the verdict is decided</h4>
<table border=\"1\">
<tr><th><code>eps_max</code></th><th>Verdict</th><th>Meaning</th></tr>
<tr><td>&lt; 1e-6</td><td><code>PASS_UNIFORM</code></td>
    <td>the rings carry no hydraulic information at all</td></tr>
<tr><td>1e-6 to 1e-2</td><td><code>PASS_PROPERTY_COUPLED</code></td>
    <td>the rings differ only through property feedback from their own power</td></tr>
<tr><td>&gt; 1e-6, and matching <code>m ~ dp_nonstatic/mu</code></td>
    <td><code>PASS_PROPERTY_COUPLED</code></td>
    <td>the split is buoyancy and viscosity feedback from the ring's own power</td></tr>
<tr><td>&gt; 1e-6, NOT matching it</td><td>trace before interpreting</td>
    <td>something other than property feedback is moving flow</td></tr>
</table>
<h4>Why the ordering check is gated</h4>
<p>At zero power the rings are thermally identical, their flows agree to 1e-12, and their
<i>ordering</i> is round-off. A strict ranking assertion has no content there and it failed on a
correct zero-power solution. It is therefore asserted only where <code>eps_max</code> exceeds
numerical precision - where the ranking is a real statement about the mechanism rather than
about summation order.</p>

<h4>A threshold that was wrong first</h4>
<p>The split was first bounded at 1 %, on the reasoning that property feedback is a
<q>secondary</q> effect. <b>That threshold was mis-calibrated and it failed on correct
behaviour</b>: at 8 MW the measured split is 12.9 %. The reason it is that large is worth
stating, because it is not obvious - the fuel channel is vertical and the salt is dense, so
<b>98.7 % of the channel pressure drop is static head</b> and only about 460 Pa out of 35 370 Pa
is friction. A 21 K radial temperature spread changes the static head by about 98 Pa, which is
a <b>24 % change in the friction budget</b>, and the flow follows that. Bounding the magnitude
was the wrong test; the size of the effect is a property of the geometry, not a defect. What is
asserted now is the <i>mechanism</i>.</p>
<p>Whichever comes out, the honest statement separates four things that are easy to conflate:
radial <b>power</b> distribution (implemented), radial <b>thermal</b> resolution (implemented),
radial <b>hydraulic discretization</b> (implemented), and radial <b>hydraulic heterogeneity</b>
and cross-ring flow redistribution (<b>not</b> implemented - the rings are parallel paths
between two common plena and exchange no mass with each other).</p>
</html>"));
end Core2D_RadialHydraulics;
