within MSRE.Verification;
model Graphite_EnergyClosure
  "G1 to G4: does the graphite heat source go where it is supposed to, before any temperature is read"
  extends MSRE.Verification.Core1D_TH_Baseline(
    Q_core=10e6,
    core(f_graphiteHeating=0.06),
    tol_energy=1e-6);

  /* ================================================================
     Power provenance: the two MSRE powers are NOT the same number
     ================================================================
     10 MW and 7.4 MW are different statements about the MSRE and are kept apart deliberately.
     Neither is used as a universal "nominal power" anywhere in this library.

     LITERATURE SOURCE: NOT RECORDED for either value. They are carried here with the roles
     given to them, and NOT with a citation that has not been checked. Anything that needs the
     provenance must resolve this first; nothing downstream may treat 10 MW as "the" MSRE power. */
  parameter SI.Power Q_design_reference=10e6
    "DESIGN / GRAPHITE REFERENCE CASE. This is the value Q_core is set to above, restated here
     so the role is attached to the number. PROVENANCE: literature source NOT RECORDED";
  parameter SI.Power Q_fullPower_actual=7.4e6
    "ACTUAL FULL-POWER OPERATION CASE. Carried for provenance separation only; NOT used by this
     model. PROVENANCE: source not recorded";

  /* ---------------- G1: the split of the fission power ---------------- */
  SI.Power Q_toFuelDirect=sum(core.Qs_channels)
    "Fission power deposited directly in the fuel";
  SI.Power Q_toGraphite=core.Q_graphite_source_total
    "Fission power deposited directly in the graphite";
  SIadd.NonDim err_powerSplit=abs((Q_toFuelDirect + Q_toGraphite)/noEvent(max(abs(
      core.Q_imposed), 1)) - 1)
    "Does the split conserve the imposed power? An identity: the two shares are (1-f) and f";
  SIadd.NonDim err_graphiteFraction=abs(Q_toGraphite/noEvent(max(abs(core.Q_imposed), 1))
       - core.f_graphiteHeating) "Is the graphite share actually f_graphiteHeating?";

  /* ---------------- G2: the radial distribution inside the graphite ----------------
     The source must be split between the graphite radial nodes in proportion to their VOLUME,
     which for the uniform-in-radius division TRANSFORM uses means in proportion to the mean
     radius of each node. Equal power per node would be wrong by +25.7 % on the inner node. */
  final parameter SIadd.NonDim fV_expected[core.channels[1].nR]={core.channels[1].rs_graphite[
      i]/sum(core.channels[1].rs_graphite) for i in 1:core.channels[1].nR}
    "Volume fraction each graphite radial node should receive";
  final parameter SIadd.NonDim err_fV=max({abs(core.channels[1].fV_graphite[i] -
      fV_expected[i]) for i in 1:core.channels[1].nR})
    "Departure of the implemented weighting from the volume weighting";
  final parameter SIadd.NonDim err_fV_sum=abs(sum(core.channels[1].fV_graphite) - 1)
    "The weights must sum to one, or the graphite would gain or lose power outright";
  final parameter SIadd.NonDim fV_vs_equal=max({abs(core.channels[1].fV_graphite[i]*
      core.channels[1].nR - 1) for i in 1:core.channels[1].nR})
    "REPORTED, not asserted: how far the volume weighting is from the equal-power split it
     replaced. Zero would mean the fix changed nothing";

  /* ---------------- G3: the graphite energy balance closes ---------------- */
  SI.Power graphiteResidual=core.graphiteEnergyResidual;
  SI.Power Q_graphite_to_fuel=core.Q_graphite_to_fuel_total;
  SI.Energy E_graphite=core.E_graphite;
  SI.Power der_E_graphite=core.der_E_graphite;
  SIadd.NonDim err_graphiteClosure=abs(graphiteResidual)/noEvent(max(abs(Q_toGraphite), 1))
    "Graphite energy closure, normalized by the graphite source itself";

  /* ---------------- G4: temperatures, read ONLY once G3 has closed ---------------- */
  SI.Temperature T_graphite_max=max(core.Ts_graphite_cells)
    "Peak graphite temperature. REPORTED - there is no accepted reference value in this
     repository to compare it against, so no assertion is made on it";
  SI.Temperature T_graphite_mean=sum(core.Ts_graphite_cells)/size(core.Ts_graphite_cells,
      1);
  SI.Temperature T_fuel_max=max(core.Ts_fuel_core);
  SI.TemperatureDifference dT_graphiteToFuel=T_graphite_mean - sum(core.Ts_fuel_core)/size(
      core.Ts_fuel_core, 1)
    "Mean graphite-to-fuel temperature difference; must be POSITIVE when the graphite is heated";

  parameter SIadd.NonDim tol_identity=1e-9
    "Round-off bound on the G1/G2/G3 identities. None of them is a physical tolerance";

equation
  when terminal() then
    /* G1 */
    assert(err_powerSplit < tol_identity, "G1 FAILED. The fuel and graphite shares do not add
back up to the imposed power; they are off by " + String(err_powerSplit) + " relative. The two
shares are (1 - f_graphiteHeating) and f_graphiteHeating of the same cell power, so this is an
identity and a failure means the source is being scaled somewhere it should not be.",
      AssertionLevel.error);
    assert(err_graphiteFraction < tol_identity, "G1 FAILED. The graphite received a fraction of
the core power differing from f_graphiteHeating by " + String(err_graphiteFraction) + ".",
      AssertionLevel.error);

    /* G2 */
    assert(err_fV < tol_identity, "G2 FAILED. The graphite radial source weighting departs from
the node volume fractions by " + String(err_fV) + ". TRANSFORM divides the graphite annulus
uniformly in RADIUS, so the node volumes grow with radius; weighting the source any other way
puts the wrong power density in the node that faces the fuel.", AssertionLevel.error);
    assert(err_fV_sum < tol_identity, "G2 FAILED. The graphite radial weights sum to " + String(
      1 + err_fV_sum) + " instead of one, so the graphite is gaining or losing power outright.",
      AssertionLevel.error);

    /* G3 - and this is what G4 is gated on */
    assert(err_graphiteClosure < tol_identity, "G3 FAILED. The graphite energy balance does not
close: source - to_fuel - storage = " + String(graphiteResidual) + " W, which is " + String(
      err_graphiteClosure) + " of the graphite source. Every graphite boundary except the fuel
interface is adiabatic, so this residual is structurally zero; a non-zero value means the source
scaling, one of those adiabatic assumptions, or a sign convention is wrong. NO GRAPHITE
TEMPERATURE MAY BE INTERPRETED UNTIL THIS CLOSES.", AssertionLevel.error);

    /* G4 - only a sign/direction statement is asserted. There is no reference temperature in
       this repository to compare against, and inventing one is exactly what this library does
       not do, so the temperatures are REPORTED and left for the gate decision. */
    assert(dT_graphiteToFuel > 0, "G4 FAILED. The graphite is heated but sits " + String(
      dT_graphiteToFuel) + " K BELOW the fuel on average, so heat would flow the wrong way. With
a positive graphite source and the fuel as the only heat sink, the graphite must be hotter.",
      AssertionLevel.error);
  end when;

  annotation (
    experiment(StopTime=8000, Tolerance=1e-6),
    Documentation(info="<html>
<h4>Order, and why it is an order</h4>
<table border=\"1\">
<tr><th>gate</th><th>question</th><th>kind</th></tr>
<tr><td>G1</td><td>does the fission power split into (1-f) and f without loss?</td><td>identity</td></tr>
<tr><td>G2</td><td>is the graphite share distributed by node VOLUME?</td><td>identity</td></tr>
<tr><td>G3</td><td>does the graphite energy balance close?</td><td>identity</td></tr>
<tr><td>G4</td><td>are the resulting temperatures sensible?</td><td>reported, one sign assertion</td></tr>
</table>
<p><b>G4 is gated on G3.</b> A graphite temperature computed while the energy balance does not
close is not evidence of anything, so the closure is asserted first and the temperatures are only
worth reading after it holds.</p>

<h4>What is deliberately NOT asserted</h4>
<p><code>T_graphite_max</code> and <code>T_graphite_mean</code> are reported, not bounded. There
is no accepted MSRE graphite temperature in this repository to compare them with, and inventing
a target would make this a fit rather than a check. The only thing asserted at G4 is the
<i>direction</i>: a heated graphite must be hotter than the fuel it is heating.</p>

<h4>Run length, and why it is 8000 s rather than 2000 s</h4>
<p>Activating <code>f_graphiteHeating</code> adds a slow thermal mode that the zero-power cases
do not have: the graphite has to charge before the core energy balance closes. At 2000 s the
graphite was still storing 15.3 W, and the inherited core balance was correspondingly short by
15.8 W - <b>97.2 % of the deficit was the graphite storage term</b>, which is what identified it
as incomplete convergence rather than a leak. The response was a longer run, NOT a looser
tolerance:</p>
<table border=\"1\">
<tr><th></th><th>2000 s</th><th>8000 s</th></tr>
<tr><td><code>err_energy</code></td><td>-1.576e-06</td><td><b>1.82e-08</b></td></tr>
<tr><td><code>der_E_graphite</code></td><td>15.312 W</td><td><b>-0.0074 W</b></td></tr>
<tr><td><code>Q_graphite_to_fuel</code></td><td>599984.688 W</td><td><b>600000.007 W</b></td></tr>
<tr><td><code>T_graphite_max</code></td><td>949.6925 K</td><td>949.6932 K</td></tr>
</table>
<p>The temperatures were already converged at 2000 s; only the storage term lagged. At steady
state all 600 kW deposited in the graphite leaves through the fuel interface, which is the
physical statement <code>Q_graphite_to_fuel = Q_graphite_source</code> that G3 checks.</p>

<h4>Power provenance</h4>
<table border=\"1\">
<tr><th>value</th><th>role</th><th>source</th></tr>
<tr><td>10 MW</td><td>DESIGN / GRAPHITE REFERENCE CASE - used here</td><td><b>not recorded</b></td></tr>
<tr><td>7.4 MW</td><td>ACTUAL FULL-POWER OPERATION CASE - not used here</td><td><b>not recorded</b></td></tr>
</table>
<p>They are kept as two separate parameters precisely so that neither becomes a universal
<q>nominal power</q>. <code>MSRE.Verification.CoreTH_Baseline</code> keeps its own independent
8 MW test condition, which is a thermal test condition and not a claim about the MSRE either.</p>

<h4>What this model does not change</h4>
<p><code>Nus_Core</code> (Nu = 4.36, recorded as <code>BASELINE_CLOSURE</code>), the
<code>Graphite_1</code> property model, <code>A_HT</code> and the equivalent graphite geometry
are all inherited unchanged. Developing-flow closure and constant-property graphite are
sensitivity cases for a later phase, not part of this one.</p>
</html>"));
end Graphite_EnergyClosure;
