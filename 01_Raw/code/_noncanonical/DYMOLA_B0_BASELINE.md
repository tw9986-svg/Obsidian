within MSRE.Verification.ORNL0378;
function combinedDeltaT
  "Eq. (17) of ORNL-TM-0378: local graphite-stringer mean minus adjacent-fuel transverse mean temperature"
  extends Modelica.Icons.Function;

  input SIadd.VolumetricHeatGenerationRate P_f "ABSOLUTE fuel specific power";
  input SIadd.VolumetricHeatGenerationRate P_g "ABSOLUTE graphite specific power";
  input Real q_w(unit="W/m2") "Wall heat flux, graphite into fuel (positive)";
  input SI.ThermalConductivity k_f "Fuel thermal conductivity";
  input SI.ThermalConductivity k_g "Graphite thermal conductivity";
  input SI.Radius r_w "Equal-FLOW-AREA circular channel radius";
  input SI.Radius r_s=0.9935*0.0254 "Equal-area cylinder radius";
  input SI.Length l_slab=0.8*0.0254 "Slab half-thickness";
  output SI.TemperatureDifference dT "T_g' - T_f', the report's DT";
  output SI.TemperatureDifference dT_graphiteConduction "Eq. (16) term";
  output SI.TemperatureDifference dT_fuelSide "Eq. (13) term";
protected
  SI.TemperatureDifference c1, c2;
  SI.Area cc;
algorithm
  (dT_graphiteConduction,c1,c2,cc) := graphiteConductionDeltaT(
      P_g,
      k_g,
      r_s,
      l_slab);
  dT_fuelSide := poppendiekDeltaT(
      P_f,
      r_w,
      k_f,
      q_w);
  dT := dT_graphiteConduction + dT_fuelSide;

  annotation (Inline=true, Documentation(info="<html>
<h4>REFERENCE</h4>
<p>ORNL-TM-0378, Eq. (17), p.40, transcribed from the page image:</p>
<pre>
               P_g      P_f r_w^2  [ 11 ( 1 + (2 q_w)/(P_f r_w) ) - 8 ]
  DT = 9.97e-4 ---  +  --------- [ -------------------------------- ]
               k_g        k_f     [                48                ]
</pre>
<p>and Eq. (18), which scales it by the relative local power density:</p>
<pre>  DT(r,z) = DT_m * P(r,z)/P_m                                        (18)</pre>

<h4>What DT is</h4>
<p>Nomenclature p.50: <q>local temperature difference between mean temperature across a graphite
stringer and the mean temperature in the adjacent fuel</q>. p.36 writes it as
<code>T_g = T'_f + DT</code> with DT a positive number.</p>
<p>Both terms are <b>transverse means</b>, so this is <b>not</b> a surface temperature difference and
must not be compared against one.</p>

<h4>NOT FOR production</h4>
<p>No modern heat structure, no <code>Nus_Core</code>, no <code>h*A*(Tg-Tf)</code>. This algebraic
closure is the whole of the historical fuel-side and graphite-side treatment.</p>
</html>"));
end combinedDeltaT;
