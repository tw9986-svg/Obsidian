within MSRE.Data.Nodalization;
record Core2D
  "2-D R-Z core nodalization: 15 radial rings, 20 axial cells"
  extends MSRE.Data.Nodalization.PartialCoreNodalization(
    final nRings=15,
    final nAxial=20,
    final nChannels=fill(geometry.nChannels_total/nRings, nRings),
    f_radial={1.6067,1.5076,1.4115,1.3184,1.2283,1.1410,1.0565,0.9748,0.8958,0.8194,0.7456,
        0.6743,0.6055,0.5392,0.4751},
    final f_axialExtrapolation=geometry.f_axialExtrapolation,
    K_channelInlet=zeros(nRings),
    K_channelExit=zeros(nRings),
    final nV_core=nRings*nAxial + 2);

  annotation (defaultComponentName="nodalization", Documentation(info="<html>
<p>15 radial rings of 76 channels, 20 axial cells each, plus the two plenum core nodes:
<code>nV_core = 302</code>. This is the nodalization of the Jeong MARS core.</p>

<h4>The radial profile is an ASSUMPTION, not a measurement</h4>
<p>Jeong et al. take the radial power profile from a Serpent calculation (their Ref. [9]) and
that tabulation is not published. The 15 values here are a J0 shape with a 25 % reflector
saving, giving a radial peak-to-average of 1.61. <b>They must not be presented as the paper's
radial distribution or as an MSRE measurement.</b> Replace them if the Serpent tabulation
becomes available.</p>

<h4>Radial discretization is not yet a radial flow model</h4>
<p>With <code>K_channelInlet = K_channelExit = 0</code> and every ring geometrically identical,
the rings differ only through their power. The hydraulic flow split will therefore come out
close to uniform, which is a property of this input set rather than of the MSRE - the measured
MSRE channel flow distribution would need the Kedl (ORNL-TM-3229) form losses, which have not
been extracted. Having 15 rings is not by itself a physical radial flow model, and the
hydraulic audit of the 2-D benchmark has to establish which of the two it is.</p>
</html>"));
end Core2D;
