within MSRE.Verification.BaseClasses;
record Core2D_EqualDr
  "VERIFICATION-ONLY 2-D core nodalization: 15 rings of EQUAL RADIAL THICKNESS instead of equal area"
  extends MSRE.Data.Nodalization.PartialCoreNodalization(
    final nRings=15,
    final nAxial=20,
    final nChannels={5.0667,15.2000,25.3333,35.4667,45.6000,55.7333,65.8667,76.0000,86.1333,
        96.2667,106.4000,116.5333,126.6667,136.8000,146.9333},
    f_radial={1.6539,1.6404,1.6133,1.5733,1.5206,1.4559,1.3801,1.2941,1.1989,1.0957,0.9857,
        0.8702,0.7506,0.6284,0.5050},
    final f_axialExtrapolation=geometry.f_axialExtrapolation,
    K_channelInlet=zeros(15),
    K_channelExit=zeros(15),
    final nV_core=15*20 + 2);

  annotation (defaultComponentName="nodalization", Documentation(info="<html>
<h4>VERIFICATION ONLY. This is not a production nodalization and nothing depends on it.</h4>
<p>It exists to answer one question that
<a href=\"modelica://MSRE.Data.Nodalization.Core2D\">Core2D</a> cannot: whether the 2-D result
depends on <b>where the radial ring boundaries are put</b>, at the same number of rings and the
same total channel count.</p>

<h4>The difference from Core2D, and why it matters</h4>
<p><code>Core2D</code> gives every ring the same 76 channels, which makes the rings equal in
<b>flow area</b> and therefore equal-area annuli: <code>r_k = 27.75 sqrt(k/15)</code>. Ring 1 then
spans <b>0 to 7.165 in</b> - and ORNL-TM-0378's Fig. 4 peaks at 7.0 in with a control-rod-thimble
depression at 2.5 in, so the entire inner structure falls inside a single ring and is averaged
away. Adding rings on an equal-area mesh does not help: they cluster at large radius.</p>

<p>This record instead makes the rings equal in <b>radial thickness</b>,
<code>dr = 1.85 in</code>, and lets the channel count follow the annulus area,
<code>nChannels_k = 1140 (r_k^2 - r_(k-1)^2)/R^2</code>, which sums to 1140 exactly. Ring 1 is
then 0 to 1.85 in and the ORNL peak lands on ring 4 (5.55 to 7.40 in), so the depression is
resolved at the same 15 rings and the same 300 cells.</p>

<table border=\"1\">
<tr><th></th><th>Core2D (equal area)</th><th>this record (equal dr)</th></tr>
<tr><td>ring 1 outer radius</td><td>7.165 in</td><td>1.850 in</td></tr>
<tr><td>rings inside r = 7 in</td><td>0</td><td>3</td></tr>
<tr><td>channels per ring</td><td>76 throughout</td><td>5.07 .. 146.93</td></tr>
<tr><td>source projection error vs the continuous ORNL profile</td><td>0.03542</td><td>0.04303</td></tr>
<tr><td>ORNL peak/average retained</td><td>1.6726 of 1.6997</td><td>1.6944 of 1.6997</td></tr>
</table>

<p>Note the trade recorded in that table: equal-dr is <b>worse</b> in the whole-domain L2 sense
(0.04303 against 0.03542) because it under-resolves the outer region where most of the volume is,
and <b>much better</b> where the structure is - it keeps 99.7 % of the peak-to-average against
98.4 %. A single scalar error norm does not decide which mesh is right for a question about a
local feature.</p>

<h4>The radial profile</h4>
<p><code>f_radial</code> is the volume-weighted average, over each ring, of the <b>continuous</b>
profile that <code>Core2D</code>'s own fifteen numbers came from:
<code>J0(2.404826 r / 34.684 in)</code>, a Bessel J0 with a 24.99 % reflector saving. That
function reproduces all fifteen published <code>Core2D</code> values to 5e-5, which is what makes
it legitimate to project onto a different mesh: the two records then represent the SAME physical
profile at two resolutions, rather than two different profiles.</p>
</html>"));
end Core2D_EqualDr;
