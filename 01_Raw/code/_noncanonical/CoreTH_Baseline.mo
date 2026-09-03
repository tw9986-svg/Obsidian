within MSRE.Verification;
model Core2D_RadialSourceSensitivity_ORNL
  "CASE ORNL of the 2-D radial source A/B. Identical to the J0 case except for the radial source shape"
  extends MSRE.Verification.Core2D_RadialSourceSensitivity(useORNLradialShape=true);

  annotation (
    experiment(StopTime=20000, Tolerance=1e-6),
    Documentation(info="<html>
<h4>This model is the FALLBACK route, not the primary one</h4>
<p>It was written on the expectation that <code>SF_core</code>, being a <code>final parameter</code>
built by a function call, would be constant-folded at translation time - which would have made a
run-time <code>-override=useORNLradialShape=true</code> unable to reach it, and two separate builds
the only honest way to run the A/B.</p>

<p><b>That expectation was wrong.</b> Inspection of the generated C shows omc keeps both statements
in the bound-parameter section, evaluated at initialization:</p>
<pre>
nodalization.f_radial[j] = if useORNLradialShape then f_radial_ORNL[j] else f_radial_J0[j]
SF_core = MSRE.Functions.corePowerShape(15, 20, {76 x 15}, nodalization.f_radial, ...)
</pre>
<p>So a <b>single</b> executable with <code>-override=useORNLradialShape=true</code> runs the ORNL
case, and that is the route actually used: it makes model identity a compile-time certainty rather
than a parameter diff between two independently translated binaries.</p>

<p>The model is kept because it names the case, and because building it is the only way to check
that the override and a recompile agree. It is not needed for the comparison itself.</p>
</html>"));
end Core2D_RadialSourceSensitivity_ORNL;
