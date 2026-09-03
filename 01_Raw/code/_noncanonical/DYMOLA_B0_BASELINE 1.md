within MSRE.Data.Nodalization;
partial record PartialCoreNodalization
  "Interface every core nodalization record satisfies"
  extends Modelica.Icons.Record;

  parameter MSRE.Data.Geometry geometry "Physical geometry, the single source of truth";

  parameter Integer nRings "NODALIZATION | # of radial groups";
  parameter Integer nAxial "NODALIZATION | # of axial cells per group";

  parameter Real nChannels[nRings]
    "DERIVED | # of physical fuel channels represented by each radial group";
  parameter Real f_radial[nRings]
    "NODALIZATION | radial peaking factor of each group, channel-weighted average 1";
  parameter Real f_axialExtrapolation
    "NODALIZATION | axial extrapolation factor of the cosine source profile";
  parameter Real K_channelInlet[nRings]
    "NODALIZATION | form loss where each group leaves the lower plenum, per channel";
  parameter Real K_channelExit[nRings]
    "NODALIZATION | form loss where each group enters the upper plenum, per channel";

  parameter Integer nV_core
    "DERIVED | core cells seen by the kinetics: channel cells plus the two plenum core nodes";

  annotation (Documentation(info="<html>
<h4>Why this exists</h4>
<p><a href=\"modelica://MSRE.Systems.PrimarySystem\">PrimarySystem</a> takes its core
discretization as a <b>replaceable record</b> so that the 1-D and the 2-D benchmark differ in
spatial representation and in nothing else (open item O-21). A replaceable record only exposes
the members of the class it is constrained by, so the constraining class has to name every
field the system model reads - that is all this record is.</p>

<p>It declares no physical quantity of its own. <code>geometry</code> is the single source of
truth for the hardware and every implementation draws from it; what an implementation adds is
how that hardware is <i>cut into cells</i>.</p>

<table border=\"1\">
<tr><th>Implementation</th><th>Rings</th><th>Axial</th><th>nV_core</th></tr>
<tr><td><a href=\"modelica://MSRE.Data.Nodalization.Core1D\">Core1D</a></td>
    <td>1</td><td>20</td><td>22</td></tr>
<tr><td><a href=\"modelica://MSRE.Data.Nodalization.Core2D\">Core2D</a></td>
    <td>15</td><td>20</td><td>302</td></tr>
</table>
</html>"));
end PartialCoreNodalization;
