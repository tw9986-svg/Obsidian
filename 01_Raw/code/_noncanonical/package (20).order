within MSRE.Data.Nodalization;
record Core1D
  "1-D core nodalization: one equivalent radial group, 20 axial cells"
  extends MSRE.Data.Nodalization.PartialCoreNodalization(
    final nRings=1,
    final nAxial=20,
    final nChannels={geometry.nChannels_total},
    final f_radial={1.0},
    final f_axialExtrapolation=geometry.f_axialExtrapolation,
    final K_channelInlet=zeros(nRings),
    final K_channelExit=zeros(nRings),
    final nV_core=nRings*nAxial + 2);

  annotation (defaultComponentName="nodalization", Documentation(info="<html>
<p>One equivalent radial group of 1140 channels, 20 axial cells, plus the two plenum
core nodes: <code>nV_core = 22</code>.</p>

<p>The collapse is <b>hydraulic</b>, not physical. Every channel keeps its own documented
cross-section and hydraulic diameter; what is dropped is the ability to resolve a radial
profile. <code>f_radial = {1.0}</code> is therefore not an assumption about the MSRE, it is a
statement that a single group cannot carry radial detail - the flat profile is exact for the
representation, and the difference against a 15-ring run is exactly the spatial-representation
effect the 1-D/2-D comparison exists to measure.</p>

<p>Nothing physical is redefined here. <code>nChannels_total</code>,
<code>f_axialExtrapolation</code> and everything else come from
<a href=\"modelica://MSRE.Data.Geometry\">Data.Geometry</a>.</p>
</html>"));
end Core1D;
