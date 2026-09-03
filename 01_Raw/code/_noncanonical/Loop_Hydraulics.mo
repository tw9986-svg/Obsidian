within MSRE.Verification;
model Core1D2D_Identity
  "2D-0: the 1-D and the 2-D core nodalizations must describe the same hardware"
  extends Modelica.Icons.Example;

  parameter MSRE.Data.Geometry geometry "Plant hardware, the single source of truth";
  parameter MSRE.Data.Nodalization.Core1D nod1D(geometry=geometry) "1-D nodalization";
  parameter MSRE.Data.Nodalization.Core2D nod2D(geometry=geometry) "2-D nodalization";

  final parameter Integer nV1=nod1D.nV_core "Core cells the 1-D kinetics sees";
  final parameter Integer nV2=nod2D.nV_core "Core cells the 2-D kinetics sees";

  /* Tolerances. These are integral identities between two ways of cutting the SAME hardware
     into cells, so the only thing separating them is floating-point summation order. They are
     not physical tolerances and they are not to be widened: a real discretization
     inconsistency is orders of magnitude larger than a summation residual. */
  parameter SIadd.NonDim tol_identity=1e-12
    "Allowed relative gap between the two nodalizations on any conserved integral";
  parameter SIadd.NonDim tol_shape=1e-9
    "Allowed departure of a normalized power shape from summing to one";

  /* ================================================================
     Channel counting and flow area
     ================================================================ */
  final parameter Real nCh1=sum(nod1D.nChannels) "Channels the 1-D grouping represents";
  final parameter Real nCh2=sum(nod2D.nChannels) "Channels the 2-D grouping represents";
  final parameter SI.Area A_flow1=geometry.A_channel*nCh1 "1-D total fuel channel flow area";
  final parameter SI.Area A_flow2=geometry.A_channel*nCh2 "2-D total fuel channel flow area";

  /* ================================================================
     Fuel and graphite inventory
     ================================================================ */
  final parameter SI.Volume V_fuel1=geometry.A_channel*geometry.H_channels*nCh1
    "1-D fuel salt volume inside the graphite channels";
  final parameter SI.Volume V_fuel2=geometry.A_channel*geometry.H_channels*nCh2
    "2-D fuel salt volume inside the graphite channels";
  final parameter SI.Volume V_graphite1=geometry.A_graphite_perChannel*geometry.H_channels*nCh1
    "1-D graphite volume";
  final parameter SI.Volume V_graphite2=geometry.A_graphite_perChannel*geometry.H_channels*nCh2
    "2-D graphite volume";

  /* ================================================================
     Cell volumes, from the function PrimarySystem itself calls
     ================================================================ */
  final parameter SI.Volume Vs1[nV1]=MSRE.Functions.coreCellVolumes(
      nod1D.nRings,
      nod1D.nAxial,
      nod1D.nChannels,
      geometry.A_channel,
      geometry.H_channels,
      geometry.V_lowerPlenum_core,
      geometry.V_upperPlenum_core) "1-D core cell volumes";
  final parameter SI.Volume Vs2[nV2]=MSRE.Functions.coreCellVolumes(
      nod2D.nRings,
      nod2D.nAxial,
      nod2D.nChannels,
      geometry.A_channel,
      geometry.H_channels,
      geometry.V_lowerPlenum_core,
      geometry.V_upperPlenum_core) "2-D core cell volumes";
  final parameter SI.Volume V_cells1=sum(Vs1) "Total 1-D core cell volume";
  final parameter SI.Volume V_cells2=sum(Vs2) "Total 2-D core cell volume";

  /* ================================================================
     Fission source distribution
     ================================================================ */
  final parameter SIadd.NonDim SF1[nV1]=MSRE.Functions.corePowerShape(
      nod1D.nRings,
      nod1D.nAxial,
      nod1D.nChannels,
      nod1D.f_radial,
      geometry.A_channel,
      geometry.H_channels,
      geometry.L_lowerPlenum_core,
      geometry.L_upperPlenum_core,
      geometry.V_lowerPlenum_core,
      geometry.V_upperPlenum_core,
      nod1D.f_axialExtrapolation) "1-D fission source fraction of each cell";
  final parameter SIadd.NonDim SF2[nV2]=MSRE.Functions.corePowerShape(
      nod2D.nRings,
      nod2D.nAxial,
      nod2D.nChannels,
      nod2D.f_radial,
      geometry.A_channel,
      geometry.H_channels,
      geometry.L_lowerPlenum_core,
      geometry.L_upperPlenum_core,
      geometry.V_lowerPlenum_core,
      geometry.V_upperPlenum_core,
      nod2D.f_axialExtrapolation) "2-D fission source fraction of each cell";
  final parameter SIadd.NonDim SF_sum1=sum(SF1) "1-D source fractions, must be one";
  final parameter SIadd.NonDim SF_sum2=sum(SF2) "2-D source fractions, must be one";

  /* The plena carry the same two core nodes in both nodalizations, so the fraction of the
     fission power that lands in the CHANNELS - and therefore the fraction available to be
     redistributed radially - has to be identical too. */
  final parameter SIadd.NonDim SF_channels1=sum(SF1[1:nod1D.nRings*nod1D.nAxial])
    "1-D source fraction in the fuel channels";
  final parameter SIadd.NonDim SF_channels2=sum(SF2[1:nod2D.nRings*nod2D.nAxial])
    "2-D source fraction in the fuel channels";

  /* ================================================================
     Radial weighting: the property that makes the 2-D grouping meaningful
     ================================================================
     Every ring holds the same number of channels, so the rings are equal-AREA annuli and the
     channel-weighted mean of f_radial is its plain mean. That mean must be one, or the 2-D
     core would produce a different total power from the same total flux. */
  final parameter SIadd.NonDim f_radial_mean2=sum({nod2D.nChannels[r]*nod2D.f_radial[r] for r in
      1:nod2D.nRings})/nCh2 "Channel-weighted mean radial peaking factor of the 2-D grouping";
  final parameter SIadd.NonDim f_radial_mean1=sum({nod1D.nChannels[r]*nod1D.f_radial[r] for r in
      1:nod1D.nRings})/nCh1 "The same for the 1-D grouping, which has one ring";

  /* ---------------- Reported ---------------- */
  final parameter SIadd.NonDim err_channels=nCh2/nCh1 - 1 "Relative gap in channel count";
  final parameter SIadd.NonDim err_A_flow=A_flow2/A_flow1 - 1 "Relative gap in flow area";
  final parameter SIadd.NonDim err_V_fuel=V_fuel2/V_fuel1 - 1 "Relative gap in fuel volume";
  final parameter SIadd.NonDim err_V_graphite=V_graphite2/V_graphite1 - 1
    "Relative gap in graphite volume";
  final parameter SIadd.NonDim err_V_cells=V_cells2/V_cells1 - 1 "Relative gap in cell volume";
  final parameter SIadd.NonDim err_SF_channels=SF_channels2/SF_channels1 - 1
    "Relative gap in the channel share of the fission power";

equation
  when terminal() then
    assert(abs(err_channels) < tol_identity, "The 2-D grouping represents " + String(nCh2) +
      " fuel channels and the 1-D grouping " + String(nCh1) + ". Both cut the same 1140-channel
core, so a difference here means one of the two nChannels arrays does not close.",
      AssertionLevel.error);

    assert(abs(err_A_flow) < tol_identity, "Total fuel channel flow area is " + String(A_flow2)
       + " m2 in 2-D against " + String(A_flow1) + " m2 in 1-D. Every ring velocity, Reynolds
number and channel pressure drop is referred to this area, so the two models would not be
hydraulically comparable.", AssertionLevel.error);

    assert(abs(err_V_fuel) < tol_identity, "Fuel salt volume in the channels is " + String(
      V_fuel2) + " m3 in 2-D against " + String(V_fuel1) + " m3 in 1-D. This is the volume the
core transit time and the precursor inventory are formed from.", AssertionLevel.error);

    assert(abs(err_V_graphite) < tol_identity, "Graphite volume is " + String(V_graphite2) +
      " m3 in 2-D against " + String(V_graphite1) + " m3 in 1-D. The graphite is the slow
thermal mass of the core and it sets the temperature feedback time scale.",
      AssertionLevel.error);

    assert(abs(err_V_cells) < tol_identity, "The core cell volumes sum to " + String(V_cells2) +
      " m3 in 2-D against " + String(V_cells1) + " m3 in 1-D. MSRE.Functions.coreCellVolumes
distributes the same hardware over a different number of cells; the total cannot move.",
      AssertionLevel.error);

    assert(abs(SF_sum1 - 1) < tol_shape and abs(SF_sum2 - 1) < tol_shape, "The fission source
fractions sum to " + String(SF_sum1) + " in 1-D and " + String(SF_sum2) + " in 2-D instead of
one. The kinetics distributes the total power by this array, so a sum other than one changes
the total power the core receives.", AssertionLevel.error);

    assert(abs(err_SF_channels) < tol_shape, "The fuel channels receive " + String(100*
      SF_channels2) + " % of the fission power in 2-D and " + String(100*SF_channels1) +
      " % in 1-D. The two plenum core nodes are identical in both nodalizations, so the channel
share must be identical as well; if it is not, the radial redistribution has also moved power
between the channels and the plena, and no 1-D to 2-D comparison could separate the two.",
      AssertionLevel.error);

    assert(abs(f_radial_mean2 - 1) < 1e-4 and abs(f_radial_mean1 - 1) < tol_identity, "The
channel-weighted mean radial peaking factor is " + String(f_radial_mean2) + " in 2-D and " +
      String(f_radial_mean1) + " in 1-D. It must be one in both, or the same total flux would
produce a different total power.", AssertionLevel.error);
  end when;

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<h4>2D-0, and why it comes before any 2-D physics</h4>
<p>The 2-D core exists to add <b>spatial resolution</b>, not to change the plant. Before any
2-D result is interpreted, the two nodalizations have to be shown to describe the same hardware:
if a total moves, the difference between a 1-D and a 2-D run is a discretization inconsistency
and not a physical radial effect, and every later comparison would be measuring the wrong
thing.</p>

<p>This model is <b>parameters only</b>. It instantiates both nodalization records against one
<a href=\"modelica://MSRE.Data.Geometry\">Geometry</a> and calls the same
<code>MSRE.Functions.coreCellVolumes</code> and <code>MSRE.Functions.corePowerShape</code> that
<a href=\"modelica://MSRE.Systems.PrimarySystem\">PrimarySystem</a> calls, so it tests the
functions the plant model actually uses rather than a restatement of them.</p>

<h4>What is checked</h4>
<table border=\"1\">
<tr><th>Identity</th><th>Why it must hold</th></tr>
<tr><td>channel count</td><td>both cut the same 1140-channel core</td></tr>
<tr><td>total flow area</td><td>ring velocity, Reynolds number and channel pressure drop are
    all referred to it</td></tr>
<tr><td>fuel volume in the channels</td><td>core transit time and precursor inventory</td></tr>
<tr><td>graphite volume</td><td>the slow thermal mass that sets the feedback time scale</td></tr>
<tr><td>total core cell volume</td><td>the same hardware over a different number of cells</td></tr>
<tr><td>source fractions sum to one</td><td>the kinetics distributes total power by this
    array</td></tr>
<tr><td>channel share of the power</td><td>the two plenum core nodes are identical in both, so
    the radial split must not move power between the channels and the plena</td></tr>
<tr><td>channel-weighted mean of f_radial</td><td>the same total flux must give the same total
    power</td></tr>
</table>
<p>What is deliberately <b>not</b> checked here is anything that needs a solution -
ring mass flow, ring power in watts, precursor inventory. Those are conservation statements
about a <i>run</i> and belong to 2D-1 and 2D-2; this model is the geometry gate that comes
first.</p>

<h4>Ring grouping: what kind of thing it is</h4>
<p><a href=\"modelica://MSRE.Data.Nodalization.Core2D\">Core2D</a> gives every ring
<code>nChannels_total/nRings</code> = 76 channels, so the rings are <b>equal-channel-count</b>,
which for a uniform channel lattice means <b>equal-area annuli</b> of decreasing radial width.
That is a <code>NUMERICAL_NODALIZATION</code> choice, not
<code>HARDWARE_GEOMETRY</code>: the MSRE core has no 15 physical rings, and the ring boundaries
are not an ORNL quantity. The 15 <code>f_radial</code> values are separately tagged
<code>ASSUMED</code> in that record - a J0 shape with a 25 % reflector saving, standing in for a
Serpent tabulation that is not published.</p>
<p>The two choices are consistent with each other, which is worth stating because it need not
have been: evaluating that J0 shape at the <b>equal-area</b> ring centres
<code>r_i = R*sqrt((i-0.5)/15)</code> reproduces the tabulated <code>f_radial</code> to an RMS
of 0.0000, while evaluating it at equally spaced centres does not (RMS 0.0949). The radial
profile therefore belongs to the equal-area grouping it is used with.</p>
</html>"));
end Core1D2D_Identity;
