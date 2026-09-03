within MSRE.Components;
model ReactorCore1D
  "1-D MSRE reactor core: lower plenum, one equivalent channel group, upper plenum"
  extends MSRE.Components.ReactorCore(
    final nRings=1,
    final nChannels={nChannels_1D},
    final nChannels_total=nChannels_1D);

  parameter Real nChannels_1D=1140
    "Total # of fuel channels, all carried by the single equivalent group";

  /* ---------------- 1-D specific summary ----------------
     dz_core, dp_core, dp_gravity_local, dp_nonstatic, the four Q_* terms, err_energy_W and
     err_mass now live in ReactorCore itself, so that the 15-ring core exposes the same
     summary and the loop-level audit can read one set of names for both nodalizations. Only
     the genuinely 1-D quantities are left here. */

  annotation (defaultComponentName="core", Documentation(info="<html>
<h4>What this is</h4>
<p>The 1-D counterpart of <a href=\"modelica://MSRE.Components.ReactorCore\">ReactorCore</a>,
built by <b>fixing its <code>nRings</code> to 1</b> rather than by writing a second core model.
<code>ReactorCore</code> is already parameterized by the number of radial groups and does not
use the radial power profile itself, so no physical component is duplicated here: the lower
plenum, the channel group and the upper plenum are the same
<a href=\"modelica://MSRE.Components.SaltPipe\">SaltPipe</a> and
<a href=\"modelica://MSRE.Components.CoreChannel\">CoreChannel</a> instances the 2-D core uses.</p>

<pre>
   port_a
     |
   lower plenum  (nLP nodes, the last one is MARS Volume 120-03)
     |
   one equivalent channel group of 1140 channels, nAxial cells
     |
   upper plenum  (nUP nodes, the first one is MARS Volume 190-01)
     |
   port_b
</pre>

<p>The collapse is <b>hydraulic</b>. Each of the 1140 channels keeps its own documented flow
area and hydraulic diameter; what is given up is the ability to resolve a radial profile, which
is exactly the difference the 1-D versus 2-D comparison is meant to measure. The nodalization
belongs to <a href=\"modelica://MSRE.Data.Nodalization.Core1D\">Data.Nodalization.Core1D</a>;
every physical dimension still comes from
<a href=\"modelica://MSRE.Data.Geometry\">Data.Geometry</a>.</p>

<h4>Energy accounting</h4>
<p>The core rises <code>dz_core = 2.2256 m</code> from inlet to outlet, so at steady state</p>
<p><code>sum(Qs_core) = m_flow*(h_out - h_in) + m_flow*g*dz_core + kinetic</code></p>
<p>and checking the enthalpy rise alone against the imposed power would leave a deficit of
<code>m_flow*g*dz_core = 3666.9 W</code> at rated flow. <code>Q_balance</code> is the
conserved statement and <code>err_energy_W</code> the residual. This is open item O-22, first
found in the core channel alone and general to every elevation-changing component.</p>
</html>"));
end ReactorCore1D;
