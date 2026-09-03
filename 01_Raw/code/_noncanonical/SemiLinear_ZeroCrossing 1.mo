within MSRE.Verification;
package ORNL0378
  "HISTORICAL_ORNL0378_CALCULATION - a 1962 thermal calculation, reproduced as-is"
  extends Modelica.Icons.ExamplesPackage;
  annotation (Documentation(info="<html>
<h4>REFERENCE</h4>
<p>J. R. Engel and P. N. Haubenreich, <i>Temperatures in the MSRE Core During Steady-State Power
Operation</i>, ORNL-TM-0378 (1962).</p>

<h4>PURPOSE</h4>
<p>Reproduce the historical 1962 MSRE thermal calculation on its own terms.</p>

<h4>NOT FOR</h4>
<p><b>Production MSRE_TRANSFORM thermal closure.</b></p>

<p>This package intentionally uses <b>historical property values</b>, <b>equivalent-area circular
geometry</b>, and the <b>Poppendiek/Palmer internally heated laminar-flow treatment</b>.
<b>Do not combine it with <code>Nus_Core</code> or with the modern fuel-salt properties.</b>
The report states that the film temperature drop is already contained in the Poppendiek effect, so
adding any Nusselt-based convective closure alongside Eq. (13) counts the film resistance twice.</p>

<h4>What is NOT in this package</h4>
<p>The absolute specific powers <code>P_f</code> and <code>P_g</code>. ORNL-TM-0378 does not state
them numerically, and the nomenclature (p.49) defines <code>P</code> as the <i>relative</i> specific
power while Eqs. (13), (16) and (17) require an absolute one. That gap is recorded rather than
filled: see <code>AlgebraicVerification</code>.</p>
</html>"));
end ORNL0378;
