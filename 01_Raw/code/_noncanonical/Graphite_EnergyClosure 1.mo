within MSRE.Verification;
partial model CoreNodalization_Structure
  "Structural verification of a core nodalization: geometry closure and source normalization"
  extends Modelica.Icons.Example;

  replaceable record Nodalization = MSRE.Data.Nodalization.Core2D constrainedby
    MSRE.Data.Nodalization.PartialCoreNodalization
    "Core nodalization under test. Redeclared by the two experiments that extend this model"
    annotation (choicesAllMatching=true);

  parameter MSRE.Data.Geometry geometry "Plant geometry, the single source of truth";
  parameter Nodalization nodalization(geometry=geometry) "Core nodalization under test";

  final parameter Integer nRings=nodalization.nRings "# of radial groups";
  final parameter Integer nAxial=nodalization.nAxial "# of axial cells per group";
  final parameter Integer nV_core=nodalization.nV_core "# of core cells seen by the kinetics";

  /* ---------------- Tolerances ---------------- */
  parameter SIadd.NonDim tol_closure=1e-12
    "Allowed relative gap when a per-ring sum is compared with its total. Round-off only";
  parameter SIadd.NonDim tol_norm=1e-12 "Allowed departure of sum(SF) from 1";
  parameter SIadd.NonDim tol_radialMean=1e-4
    "Allowed departure of the channel-weighted mean radial peaking factor from 1";

  /* The reported quantities below are declared as variables rather than parameters even though
     none of them changes in time. OpenModelica constant-folds a parameter whose only use is
     inside an assert, which removes it from the result file entirely - the model then passes
     its checks and reports nothing, which for a verification model is the wrong trade. They
     are time-invariant by construction; nothing here integrates.

     ================================================================
     1. Geometry closure: the rings must reassemble the core
     ================================================================
     Nodalization redistributes the hardware between cells. It may not create or destroy any of
     it, so each per-ring sum has to return the total that Data.Geometry states. */
  Real nChannels_sum=sum(nodalization.nChannels) "Channels summed over the rings";
  SI.Area As_rings[nRings]={nodalization.nChannels[r]*geometry.A_channel for r in 1:nRings}
    "Flow area of each ring";
  SI.Area A_rings_sum=sum(As_rings) "Flow area summed over the rings";
  SI.Volume Vs_rings[nRings]={As_rings[r]*geometry.H_channels for r in 1:nRings}
    "Channel fuel salt volume of each ring";
  SI.Volume V_rings_sum=sum(Vs_rings) "Channel volume summed over the rings";

  SIadd.NonDim err_nChannels=nChannels_sum/geometry.nChannels_total - 1
    "Relative gap on the channel count";
  SIadd.NonDim err_A_flow=A_rings_sum/geometry.A_core_total - 1
    "Relative gap on the total flow area";
  SIadd.NonDim err_V_channels=V_rings_sum/geometry.V_channels - 1
    "Relative gap on the total channel volume";

  /* ================================================================
     2. Cell volumes: the nodalization must reassemble the core volume
     ================================================================ */
  SI.Volume Vs_cells[nV_core]=MSRE.Functions.coreCellVolumes(
      nRings,
      nAxial,
      nodalization.nChannels,
      geometry.A_channel,
      geometry.H_channels,
      geometry.V_lowerPlenum_core,
      geometry.V_upperPlenum_core) "Volume of every core cell";
  SI.Volume V_cells_sum=sum(Vs_cells) "Core volume summed over the cells";
  SIadd.NonDim err_V_core=V_cells_sum/geometry.V_core - 1
    "Relative gap between the summed cell volumes and Data.Geometry.V_core";

  /* ================================================================
     3. Fission source: normalization and the O-20 domain split
     ================================================================ */
  SIadd.NonDim SF[nV_core]=MSRE.Functions.corePowerShape(
      nRings,
      nAxial,
      nodalization.nChannels,
      nodalization.f_radial,
      geometry.A_channel,
      geometry.H_channels,
      geometry.L_lowerPlenum_core,
      geometry.L_upperPlenum_core,
      geometry.V_lowerPlenum_core,
      geometry.V_upperPlenum_core,
      nodalization.f_axialExtrapolation) "Fission source fraction of every core cell";
  SIadd.NonDim SF_sum=sum(SF) "Must be exactly 1";
  SIadd.NonDim SF_lowerPlenum=SF[nRings*nAxial + 1]
    "Must be exactly 0 (O-20: the plena are in the precursor domain, not the source domain)";
  SIadd.NonDim SF_upperPlenum=SF[nRings*nAxial + 2] "Must be exactly 0";

  /* Axial and radial marginals of the source. The axial one must be identical for every
     nodalization: collapsing the rings cannot change the axial shape. */
  SIadd.NonDim SF_axial[nAxial]={sum({SF[(r - 1)*nAxial + k] for r in 1:nRings}) for k in 1:
      nAxial} "Fission source fraction of each axial level, summed over the rings";
  SIadd.NonDim SF_radial[nRings]={sum({SF[(r - 1)*nAxial + k] for k in 1:nAxial}) for r in 1:
      nRings} "Fission source fraction of each ring, summed over the axial levels";
  SIadd.NonDim peak_axial=max(SF_axial)*nAxial/sum(SF_axial)
    "Axial peak-to-average of the fission source";
  SIadd.NonDim peak_radial=max(SF_radial)*nRings/sum(SF_radial)
    "Radial peak-to-average of the fission source";

  /* The radial peaking factors are a SHAPE, so their channel-weighted mean has to be 1. If it
     is not, the profile is silently rescaling the total power - which corePowerShape then
     removes again by normalizing, so the error is invisible in any result. That is exactly why
     it is asserted here rather than left to be noticed. */
  SIadd.NonDim f_radial_mean=sum({nodalization.f_radial[r]*nodalization.nChannels[r] for r in
      1:nRings})/geometry.nChannels_total "Channel-weighted mean radial peaking factor";

  /* ================================================================
     4. Normalized flux, which is what paper Eq. 4 divides by
     ================================================================ */
  SIadd.NonDim phis[nV_core]={SF[i]*V_cells_sum/Vs_cells[i] for i in 1:nV_core}
    "Normalized neutron flux of each core cell";
  SI.Volume phiV_sum=sum({phis[i]*Vs_cells[i] for i in 1:nV_core})
    "sum(phi_i*V_i), which the definition of phi forces to equal sum(V_i)";
  SIadd.NonDim err_phiV=phiV_sum/V_cells_sum - 1 "Relative gap on that identity";

equation
  assert(abs(err_nChannels) < tol_closure, "The rings hold " + String(nChannels_sum) +
    " fuel channels but Data.Geometry states " + String(geometry.nChannels_total) + ". A
nodalization redistributes the hardware between cells; it cannot change how much there is.",
    AssertionLevel.error);

  assert(abs(err_A_flow) < tol_closure, "The ring flow areas sum to " + String(A_rings_sum) +
    " m2 against a total core flow area of " + String(geometry.A_core_total) + " m2.",
    AssertionLevel.error);

  assert(abs(err_V_channels) < tol_closure, "The ring channel volumes sum to " +
    String(V_rings_sum) + " m3 against a total channel volume of " + String(geometry.V_channels)
     + " m3.", AssertionLevel.error);

  assert(abs(err_V_core) < tol_closure, "The core cell volumes sum to " + String(V_cells_sum) +
    " m3 against Data.Geometry.V_core = " + String(geometry.V_core) + " m3. The cell volumes
come from coreCellVolumes and the total from the geometry record; they are two routes to the
same quantity and must agree.", AssertionLevel.error);

  assert(abs(SF_sum - 1) < tol_norm, "The fission source fractions sum to " + String(SF_sum) +
    " instead of 1. The point kinetics model distributes the total fission power by this array,
so a normalization error is a power error of the same size.", AssertionLevel.error);

  assert(abs(SF_lowerPlenum) < tol_norm and abs(SF_upperPlenum) < tol_norm, "The two plenum core
nodes carry a fission source fraction of " + String(SF_lowerPlenum) + " and " +
    String(SF_upperPlenum) + " instead of zero. O-20 puts them in the precursor transport and
decay domain but not in the fission source domain, because they hold no graphite. Setting
corePowerShape's plenumFissionSource = true restores the volume-weighted treatment, which hands
them about 15 % of the fission power.", AssertionLevel.error);

  assert(abs(f_radial_mean - 1) < tol_radialMean, "The channel-weighted mean radial peaking
factor is " + String(f_radial_mean) + " instead of 1, so the radial profile is not a shape: it
rescales the total power. corePowerShape normalizes the result, so this error would leave no
trace in any simulated quantity.", AssertionLevel.error);

  assert(abs(err_phiV) < tol_norm, "sum(phi_i*V_i) is " + String(phiV_sum) + " m3 against
sum(V_i) = " + String(V_cells_sum) + " m3. This identity follows from the definition of phi and
is what makes the flux weighting of paper Eq. 4 a weighting rather than a scaling.",
    AssertionLevel.error);

  annotation (
    experiment(StopTime=1),
    Documentation(info="<html>
<h4>What this is</h4>
<p>A verification of a core nodalization that runs no thermal hydraulics and integrates nothing.
It exists because the failure modes it catches - a ring array that does not sum to its total, a
radial profile that is not a shape, a source that is not normalized - are all invisible in a
simulated result, either because the code renormalizes them away or because they show up as a
plausible-looking few-percent shift somewhere else.</p>

<h4>What is checked</h4>
<table border=\"1\">
<tr><th>#</th><th>Statement</th><th>Why it can fail</th></tr>
<tr><td>1</td><td><code>sum(nChannels_ring) = nChannels_total</code></td>
    <td>a ring count entered by hand</td></tr>
<tr><td>2</td><td><code>sum(A_flow_ring) = A_core_total</code></td>
    <td>a per-ring flow area that is not the channel area times the count</td></tr>
<tr><td>3</td><td><code>sum(V_ring) = V_channels</code></td><td>the same, in volume</td></tr>
<tr><td>4</td><td><code>sum(V_cell) = V_core</code></td>
    <td>coreCellVolumes and Data.Geometry disagreeing about the plenum core nodes</td></tr>
<tr><td>5</td><td><code>sum(SF) = 1</code></td>
    <td>a source distribution that is not normalized</td></tr>
<tr><td>6</td><td><code>SF = 0</code> in both plenum core nodes</td>
    <td>the O-20 domain split being undone</td></tr>
<tr><td>7</td><td>channel-weighted mean <code>f_radial = 1</code></td>
    <td>a radial profile that rescales rather than shapes</td></tr>
<tr><td>8</td><td><code>sum(phi_i*V_i) = sum(V_i)</code></td>
    <td>the flux normalization of paper Eq. 4</td></tr>
</table>
<p>Checks 1 to 6 and 8 hold to round-off and are asserted at <code>1e-12</code>. Check 7 is
asserted at <code>1e-4</code> because the 15 published radial factors are given to four decimal
places, so their channel-weighted mean is 0.99998 rather than exactly 1 - a property of the
table's precision, not of the model. The value is reported as <code>f_radial_mean</code> so
that the 2e-5 is a number rather than a remark.</p>

<h4>Geometry is not nodalization</h4>
<p>Nothing here is a benchmark comparison. There is no assertion against a Jeong transit time, a
Serpent power shape or an MSRE measurement, because none of those is a statement about whether
the discretization is self-consistent. Both
<a href=\"modelica://MSRE.Verification.Core1D_Structure\">Core1D_Structure</a> and
<a href=\"modelica://MSRE.Verification.Core2D_Structure\">Core2D_Structure</a> have to pass every
check above: that is the point of running it on both.</p>

<h4>What the axial marginal shows</h4>
<p><code>SF_axial</code> is the source summed over the rings, so it is the axial shape the whole
core sees. Collapsing 15 rings into 1 cannot change it, and <code>peak_axial</code> comes out at
1.265427 for both nodalizations. Any 1-D versus 2-D difference in a global result therefore
comes from the hydraulics or the radial power spread, never from the axial source - which is
what makes the comparison interpretable.</p>
</html>"));
end CoreNodalization_Structure;
