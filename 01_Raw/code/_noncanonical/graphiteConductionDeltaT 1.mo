within MSRE.Verification.ORNL0378;
function axialPowerShape
  "B(z) of ORNL-TM-0378 Fig. 8: the axial fission power density shape of the 1962 calculation"
  extends Modelica.Icons.Function;

  input SI.Length z "Axial distance from the INLET END OF THE MAIN CORE (nomenclature p.50)";
  input Real period_in=77.7 "Argument scale, in inches. SOURCE: Fig. 8 / Eqs. (4)-(6)";
  input Real offset_in=4.36 "Argument offset, in inches. SOURCE: Fig. 8 / Eqs. (4)-(6)";
  output Real B "Relative axial power density";
protected
  constant Real IN_TO_M=0.0254;
  Real z_in "z expressed in inches, which is the unit the constants belong to";
algorithm
  z_in := z/IN_TO_M;
  B := Modelica.Math.sin(Modelica.Constants.pi*(z_in + offset_in)/period_in);

  annotation (Inline=true, Documentation(info="<html>
<h4>REFERENCE</h4>
<p>ORNL-TM-0378, Fig. 8, quoted on p.32 as <q>the <b>sine</b> approximation for the axial variation
of the power density</q>:</p>
<pre>B(z) = sin[ (pi/77.7) (z + 4.36) ]      z in INCHES</pre>
<p>Applicable over <code>0 &lt;= z &lt;= 64.6 in</code> (p.32), the lower and upper boundaries of the
main part of the core.</p>

<h4>Why the constants stay in inches</h4>
<p>77.7 and 4.36 are lengths in inches. Converting <code>z</code> to inches inside the function is
the only transformation that leaves them meaning what the report says they mean; rescaling them into
metres would silently change the shape.</p>

<h4>Do not confuse with Eq. (4)</h4>
<p>Equation (4) of the report contains <b>cosines</b>. That is not a different shape - Eq. (4) is the
<i>fuel temperature</i>, which is the <b>integral</b> of B(z), so the sine integrates to a cosine.
B(z) itself is a sine.</p>

<h4>NOT FOR production</h4>
<p>This is deliberately separate from <a href=\"modelica://MSRE.Functions.corePowerShape\">
MSRE.Functions.corePowerShape</a>, which is the modern cosine-with-extrapolation shape. The two are
skewed relative to each other - the ORNL peak sits about 2.03 in above mid-core - and they must not
be substituted for one another.</p>
</html>"));
end axialPowerShape;
