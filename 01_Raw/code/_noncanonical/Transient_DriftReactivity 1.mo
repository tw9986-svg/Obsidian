within MSRE.Verification.ORNL0378;
function poppendiekDeltaT
  "Eq. (13) of ORNL-TM-0378: wall minus transverse-mean fuel temperature, laminar flow with internal heat generation"
  extends Modelica.Icons.Function;

  input SIadd.VolumetricHeatGenerationRate P_f
    "ABSOLUTE fuel specific power (per unit fuel volume) at this location";
  input SI.Radius r_w
    "Equivalent radius of the fuel channel: the radius of a circular channel whose FLOW AREA equals
     the actual channel area (p.38). NOT the hydraulic radius";
  input SI.ThermalConductivity k_f "Fuel thermal conductivity (historical: 5.5557 W/m/K)";
  input Real q_w(unit="W/m2")
    "Rate of heat transfer per unit area at the wall, i.e. the fuel-graphite interface
     (nomenclature p.49-50: q = rate of heat transfer per unit area, subscript w = wall).
     SIGN: positive when heat flows FROM the graphite INTO the fuel, which is the direction the
     report treats throughout (the graphite is the hotter body, p.36)";
  output SI.TemperatureDifference dT "T_w - T_f', wall minus local transverse-mean fuel temperature";
algorithm
  dT := (P_f*r_w^2/k_f)*((11*(1 + 2*q_w/(P_f*r_w)) - 8)/48);

  annotation (Inline=true, Documentation(info="<html>
<h4>REFERENCE</h4>
<p>ORNL-TM-0378, Eq. (13), p.38, transcribed from the page image:</p>
<pre>
                P_f r_w^2   [  11 ( 1 + (2 q_w)/(P_f r_w) ) - 8  ]
  T_w - T_f'  = --------- * [ ---------------------------------- ]
                   k_f      [                 48                 ]
</pre>
<p><code>T'</code> is defined on p.49 as the <b>local transverse mean temperature in a single fuel
channel</b>.</p>

<h4>THIS REPLACES THE CONVECTIVE CLOSURE - it does not supplement it</h4>
<p>p.38, verbatim: <q>Since the Poppendiek effect in the core is calculated for laminar flow, the
temperature drop through the fluid immediately adjacent to the channel wall <b>is included in this
effect. Therefore, a separate calculation of film temperature drop is not required.</b></q></p>
<p>So <b>do not</b> call <code>Nus_Core</code>, compute a Nusselt number, or evaluate
<code>h*A*(Tg-Tf)</code> anywhere alongside this function. Doing so counts the film resistance
twice.</p>

<h4>Applicability, as the report states it</h4>
<p>p.37: the flow in the entire core <q>is assumed to be laminar to provide conservatively
pessimistic estimates</q>. p.38: the equation is <q>strictly applicable only if the power density and
heat flux are uniform along the channel and the length of the channel is infinite</q>, and is applied
to the finite MSRE channel by assuming the fluid profile follows the local parameters at each
elevation. Sources: Poppendiek and Palmer, ORNL-1395 (1953) and ORNL-1701 (1954).</p>
</html>"));
end poppendiekDeltaT;
