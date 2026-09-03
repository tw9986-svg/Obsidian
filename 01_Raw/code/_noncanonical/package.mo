within MSRE.ClosureRelations;
model Nus_HX
  "Heat exchanger Nusselt number: fully developed laminar duct closure at constant wall temperature below Re 2300, Gnielinski above Re 3000, smoothly blended between"
  extends
    TRANSFORM.Fluid.ClosureRelations.HeatTransfer.Models.DistributedPipe_1D_MultiTransferSurface.PartialSinglePhase;

  parameter Real Nu_laminar=3.66
    "ASSUMPTION / GENERIC LAMINAR CLOSURE: fully developed laminar Nusselt number. 3.66 is the circular-duct CONSTANT WALL TEMPERATURE value, which is the condition both sides of this heat exchanger see. Deliberately NOT the 4.36 of MSRE.ClosureRelations.Nus_Core, which is the constant-heat-flux value the fission-heated core channels see"
    annotation (Dialog(group="Laminar closure"));
  parameter SI.ReynoldsNumber Re_laminar=2300
    "Upper end of the laminar branch" annotation (Dialog(group="Laminar closure"));
  parameter SI.ReynoldsNumber Re_turbulent=3000
    "Lower end of the Gnielinski branch, its usual validity limit"
    annotation (Dialog(group="Laminar closure"));

  input SI.Length L_char[nHT,nSurfaces]=transpose({dimensions for i in 1:nSurfaces})
    "Length scale the Nusselt number is referred to; defaults to the hydraulic diameter, which is also what the Reynolds number is formed with"
    annotation (Dialog(group="Inputs"));
  parameter SI.ReynoldsNumber Re_min=100
    "Numerical guard applied to the friction-factor logarithm only. The Gnielinski branch is still evaluated below Re_turbulent, at zero weight, so the logarithm still has to stay away from its pole near Re = 8"
    annotation (Dialog(tab="Advanced"));

protected
  Real Re_eff[nHT] "Reynolds number magnitude used by the correlations";
  Real fs[nHT] "Darcy friction factor of the Filonenko/Petukhov fit";
  Real Nu_gnielinski[nHT]
    "Gnielinski branch, evaluated everywhere but only weighted in above Re_laminar";
  Real x[nHT] "Position within the transition window";
  Real w[nHT] "Smoothstep weight of the Gnielinski branch";

equation
  for i in 1:nHT loop
    Re_eff[i] = max(abs(Res[i]), Re_min);
    fs[i] = (0.79*Modelica.Math.log(Re_eff[i]) - 1.64)^(-2);
    Nu_gnielinski[i] = (fs[i]/8)*(Re_eff[i] - 1000)*Prs[i]/(1 + 12.7*sqrt(fs[i]/8)*(Prs[i]^(
      2/3) - 1));
    x[i] = max(0, min(1, (Re_eff[i] - Re_laminar)/(Re_turbulent - Re_laminar)));
    w[i] = x[i]^2*(3 - 2*x[i]);
    for j in 1:nSurfaces loop
      Nus[i, j] = (1 - w[i])*Nu_laminar + w[i]*Nu_gnielinski[i];
      alphas[i, j] = Nus[i, j]*mediaProps[i].lambda/L_char[i, j];
    end for;
  end for;

  annotation (defaultComponentName="heatTransfer", Documentation(info="<html>
<h4>What this replaced, and why it had to be replaced</h4>
<p>Both sides of the heat exchanger previously used
<a href=\"modelica://MSRE.ClosureRelations.Nus_MoltenSalt\">Nus_MoltenSalt</a>, which is plain
Gnielinski. Gnielinski carries a factor <code>(Re - 1000)</code>, so it returns</p>
<table border=\"1\">
<tr><th>shell side flow</th><th>Re</th><th>Nu from plain Gnielinski</th></tr>
<tr><td>100 %</td><td>8637</td><td>101.6</td></tr>
<tr><td>25 %</td><td>2159</td><td>19.9</td></tr>
<tr><td><b>11.58 %</b></td><td><b>1000</b></td><td><b>0</b></td></tr>
<tr><td>10 %</td><td>864</td><td>-2.85</td></tr>
<tr><td>1 %</td><td>86</td><td>-36.9</td></tr>
</table>
<p>This is not only a wrong sign. The heat transfer interface forms</p>
<pre>
  alphas = Nu*lambda/L_char
  UA     = 1/(Rs_add + 1/(alphas*surfaceArea))
</pre>
<p>so at <code>Re = 1000</code> exactly, <code>alpha = 0</code> and <b>UA divides by zero</b>.
Below it, <code>UA</code> is negative and the heat exchanger <i>heats</i> the fuel salt. The
natural circulation flow range is a few per cent of rated, i.e. entirely below that point, so
this had to be fixed before any natural circulation result could mean anything.</p>

<h4>Why this is not just Nus_Core connected to the heat exchanger</h4>
<p>The <b>structure</b> is the same as
<a href=\"modelica://MSRE.ClosureRelations.Nus_Core\">Nus_Core</a> - laminar constant below
<code>Re_laminar</code>, Gnielinski above <code>Re_turbulent</code>, smoothstep between - because
that structure is what removes the singularity. The <b>value</b> is not, and copying it would
have been wrong:</p>
<table border=\"1\">
<tr><th></th><th>core fuel channel</th><th>heat exchanger</th></tr>
<tr><td>what sets the wall condition</td>
    <td>fission heat deposited in the graphite, at a rate independent of the salt temperature</td>
    <td>the tube wall, pinned near the coolant salt, which runs at rated flow and fixed inlet
    temperature</td></tr>
<tr><td>idealization</td><td>constant heat flux</td><td>constant wall temperature</td></tr>
<tr><td>fully developed laminar Nu</td><td>4.36</td><td><b>3.66</b></td></tr>
</table>
<p>Using the core's 4.36 here would import the core's boundary condition into the heat
exchanger, a 19 % error in the laminar branch for no reason.</p>

<h4>Why a duct closure and not a tube bank closure</h4>
<p>TRANSFORM ships
<code>FlowAcrossTubeBundles_Grimison</code> for crossflow over a bundle. It does not apply here.
The geometry model actually being solved is
<code>StraightPipeHX</code> with a shell length, a shell elevation change and
<code>counterCurrent = true</code> - the shell side is treated as an <b>axial duct</b> of
hydraulic diameter <code>Dh_shell</code>, not as a bank in crossflow. Using a crossflow
correlation would contradict the geometry the solver is integrating. Within the model's own
idealization the shell side is a duct, so a fully developed laminar duct Nusselt number is the
internally consistent closure.</p>

<h4>The laminar branch is conservative, not flattering</h4>
<p>The thermal entry length of a laminar duct is about <code>0.05*Re*Pr*Dh</code>. On the shell
side at <code>Re = 1000</code> and <code>Pr = 20.1</code> that is <b>56 m</b>, against a shell
length of 2.44 m, so the shell side is thermally <i>developing</i> over the whole low-Reynolds
range and the true Nusselt number is <b>higher</b> than the fully developed value. Taking 3.66
therefore under-predicts the heat removed. It cannot manufacture a natural circulation result;
if anything it suppresses one.</p>

<h4>What does not change</h4>
<p>Above <code>Re_turbulent</code> the weight <code>w</code> is exactly 1 and this model reduces
<b>identically</b> to the previous closure. The heat exchanger runs at <code>Re</code> 8637
(shell) and 9851 (tube) at rated flow, both far above 3000, so <b>every rated-flow result in
this library is bit-for-bit unchanged</b>. The closures differ only below
<code>Re = 3000</code>, which is 34.7 % of rated flow on the shell side.</p>

<h4>Basis</h4>
<p>The fully developed laminar circular-duct Nusselt numbers 3.66 (constant wall temperature)
and 4.36 (constant heat flux) are standard results (Incropera and DeWitt; Rohsenow, Hartnett and
Cho). They are tagged <code>ASSUMPTION / GENERIC LAMINAR CLOSURE</code> for the same reason they
are in <code>Nus_Core</code>: they are the generic duct values, not values measured for this
hardware. Nothing here is fitted to any transient, to any MARS result or to any MSRE
measurement.</p>
</html>"));
end Nus_HX;
