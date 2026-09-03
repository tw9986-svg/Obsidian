within MSRE.Verification.ORNL0378;
function graphiteConductionDeltaT
  "Eqs. (14)-(16) of ORNL-TM-0378: stringer-mean minus wall temperature, by S/V interpolation between a cylinder and a slab"
  extends Modelica.Icons.Function;

  input SIadd.VolumetricHeatGenerationRate P_g
    "ABSOLUTE graphite specific power (per unit graphite volume) at this location";
  input SI.ThermalConductivity k_g "Graphite thermal conductivity (historical: 22.4996 W/m/K)";
  input SI.Radius r_s=0.9935*0.0254 "Equal-cross-sectional-area cylinder radius (p.39)";
  input SI.Length l_slab=0.8*0.0254 "Slab half-thickness (p.39)";
  input Real SV_cylinder(unit="1/m") = 2.01/0.0254 "Cylinder S/V (p.39)";
  input Real SV_actual(unit="1/m") = 1.84/0.0254 "Actual fuel-contact S/V (p.39)";
  input Real SV_slab(unit="1/m") = 1.25/0.0254 "Slab S/V (p.39)";
  output SI.TemperatureDifference dT "T_g' - T_w";
  output SI.TemperatureDifference dT_cylinder "Eq. (14) limit, UNDERestimates";
  output SI.TemperatureDifference dT_slab "Eq. (15) limit, OVERestimates";
  output SI.Area coeff "Interpolated coefficient, the SI counterpart of Eq. (16)'s 9.97e-4 ft2";
protected
  SI.Area c_cyl "(1/8) r_s^2";
  SI.Area c_slab "(1/3) l^2";
  Real w "Interpolation fraction from the cylinder towards the slab, on an S/V basis";
algorithm
  c_cyl := (1/8)*r_s^2;
  c_slab := (1/3)*l_slab^2;
  /* Linear interpolation on the basis of surface-to-volume ratio (p.39). The fraction is COMPUTED
     from the three S/V values, never hard-coded, so that changing any of them stays consistent. */
  w := (SV_cylinder - SV_actual)/(SV_cylinder - SV_slab);
  coeff := c_cyl + w*(c_slab - c_cyl);
  dT_cylinder := c_cyl*P_g/k_g;
  dT_slab := c_slab*P_g/k_g;
  dT := coeff*P_g/k_g;

  annotation (Inline=true, Documentation(info="<html>
<h4>REFERENCE</h4>
<p>ORNL-TM-0378, Eqs. (14)-(16), p.39, transcribed from the page image:</p>
<pre>
  T_g' - T_w = (1/8) (P_g r_s^2)/k_g      (14)   cylinder, equal cross-sectional area
  T_g' - T_w = (1/3) (P_g l^2)/k_g        (15)   slab, cooled on two sides
  T_g' - T_w = 9.97e-4 * P_g/k_g          (16)   linear S/V interpolation between them
</pre>
<p>p.39: the cylinder approximation <b>under</b>estimates the mean graphite temperature (its S/V,
2.01 in^-1, is higher than the actual fuel-contact 1.84 in^-1); the slab, at 1.25 in^-1,
<b>over</b>estimates it. <q>The value assigned to the difference between the mean graphite
temperature and the channel-wall temperature was obtained by a linear interpolation between the two
approximations on the basis of surface-to-volume ratio.</q></p>

<h4>Unit audit</h4>
<p>Eq. (16)'s coefficient <b>9.97e-4 is an AREA in ft2</b>, not a dimensionless number: with
<code>P_g</code> in Btu/(hr.ft3) and <code>k_g</code> in Btu/(hr.ft.F), <code>P_g/k_g</code> is
F/ft2, so the coefficient must carry ft2 to leave a temperature. Reconstructing it from Eqs. (14)
and (15) in feet gives 9.96537e-4 ft2 against the report's rounded 9.97e-4, agreeing to 0.046 %.
In SI the same coefficient is 9.25813e-5 m2. This function computes it from the geometry rather than
transcribing the rounded number, so no unit constant is ever carried across systems.</p>
</html>"));
end graphiteConductionDeltaT;
