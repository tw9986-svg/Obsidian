within MSRE.Verification.ORNL0378;
record HistoricalData
  "1962 inputs of ORNL-TM-0378. CLASS: HISTORICAL_CALCULATION_INPUT - none of these is a measurement"
  extends Modelica.Icons.Record;

  /* Every value below is transcribed from ORNL-TM-0378 page images. None is a measured quantity:
     the report is a hydraulic model plus a nuclear power distribution plus a thermal calculation.
     These values must NOT be copied into the modern property package. */

  constant Real BTU_HR_FT_F_TO_W_M_K=1.730735
    "SOURCE: unit definition. 1 Btu/(hr.ft.F) in W/(m.K)";
  constant Real IN_TO_M=0.0254 "SOURCE: unit definition";

  /* ---------------- Power ---------------- */
  parameter SI.Power Q_reactor_ref=10e6
    "SOURCE: ORNL-TM-0378 Table 4, footnote b ('At 10 Mw'). CLASS: HISTORICAL_CALCULATION_INPUT";
  parameter SIadd.NonDim f_graphite=0.06
    "Fraction of REACTOR power generated in the graphite, 0 % fuel permeation.
     SOURCE: ORNL-TM-0378 p.40 footnote. CLASS: HISTORICAL_CALCULATION_INPUT.
     It is an ASSUMPTION from an unpublished gamma/neutron heating calculation by C. W. Nestor.
     It is NOT a measured fraction";
  parameter SIadd.NonDim f_fuel=1 - f_graphite "Complement of f_graphite. DERIVED";

  /* ---------------- Temperature boundaries: three distinct definitions ---------------- */
  parameter SI.Temperature T_reactor_in=908.1500
    "1175 F. SOURCE: ORNL-TM-0378 Table 4 footnote c. Reactor inlet - NOT the main-core boundary";
  parameter SI.Temperature T_reactor_out=935.9278
    "1225 F. SOURCE: ORNL-TM-0378 Table 4 footnote c. Reactor outlet";
  parameter SI.Temperature T_mainCore_in=909.4278
    "1177.3 F. SOURCE: ORNL-TM-0378 p.33. THE boundary a core-only model must use";
  parameter SI.Temperature T_mainCore_out_mixedMean=933.5944
    "1220.8 F. SOURCE: ORNL-TM-0378 p.33. Mixed-mean leaving the main core";
  final parameter SI.TemperatureDifference dT_peripheral_below=T_mainCore_in - T_reactor_in
    "DIAGNOSTIC ONLY (1.2778 K). Heat picked up in the peripheral regions below the main core.
     It is a historical boundary fact and must NOT be recomputed inside a core model";
  final parameter SI.TemperatureDifference dT_peripheral_above=T_reactor_out -
      T_mainCore_out_mixedMean "DIAGNOSTIC ONLY (2.3334 K). Peripheral regions above the core";

  /* ---------------- Axial domain and shape ---------------- */
  parameter SI.Length z_mainCore_max=64.6*IN_TO_M
    "Upper bound of the main core. SOURCE: ORNL-TM-0378 p.32, '0 <= z <= 64.6 in'";
  parameter Real z_shape_period_in=77.7
    "SOURCE: ORNL-TM-0378 Fig. 8 / Eq. (4)-(6). Argument scale of B(z), in INCHES";
  parameter Real z_shape_offset_in=4.36
    "SOURCE: ORNL-TM-0378 Fig. 8 / Eq. (4)-(6). Argument offset of B(z), in INCHES";

  /* ---------------- Historical transport properties ---------------- */
  parameter SI.ThermalConductivity k_f=3.21*BTU_HR_FT_F_TO_W_M_K
    "5.5557 W/(m.K), from 3.21 Btu/(hr.ft.F). SOURCE: ORNL-TM-0378 p.40 footnote.
     CLASS: HISTORICAL_CALCULATION_INPUT. This is the 1962 vintage value and is NOT the corrected
     MSRE primary-salt conductivity (1.0 W/(m.K)) that the production package uses";
  parameter SI.ThermalConductivity k_g=13*BTU_HR_FT_F_TO_W_M_K
    "22.4996 W/(m.K), from 13 Btu/(hr.ft.F). SOURCE: ORNL-TM-0378 p.40 footnote.
     CLASS: HISTORICAL_CALCULATION_INPUT";

  /* ---------------- Geometry required by the historical equations ---------------- */
  parameter SI.Radius r_w=0.0095667
    "Equivalent radius of a fuel channel, defined on ORNL-TM-0378 p.38 as the radius of a circular
     channel whose FLOW AREA equals the actual channel area: r_w = sqrt(A/pi) = 0.37664 in.
     THIS IS NOT THE HYDRAULIC RADIUS. The production model's Dh/2 is 0.0079253 m, 20.71 % smaller,
     and r_w enters Eq. (13) SQUARED";
  parameter SI.Radius r_s=0.9935*IN_TO_M
    "Equivalent radius of a graphite stringer treated as a cylinder of equal CROSS-SECTIONAL area.
     SOURCE: ORNL-TM-0378 p.39";
  parameter SI.Length l_slab=0.8*IN_TO_M
    "Equivalent half-thickness of a graphite stringer treated as a slab: stringer centre line to the
     edge of the fuel channel. SOURCE: ORNL-TM-0378 p.39";
  parameter Real SV_cylinder(unit="1/m") = 2.01/IN_TO_M
    "Surface-to-volume ratio of the equal-area cylinder, 2.01 in^-1. SOURCE: p.39";
  parameter Real SV_actual(unit="1/m") = 1.84/IN_TO_M
    "Surface-to-volume ratio of the ACTUAL graphite stringer counting only the fuel-channel surface,
     1.84 in^-1. SOURCE: p.39. This is the value interpolated TO";
  parameter Real SV_slab(unit="1/m") = 1.25/IN_TO_M
    "Surface-to-volume ratio of the slab approximation, 1.25 in^-1. SOURCE: p.39";

  /* ---------------- Main-core extent, as the report defines it ---------------- */
  /* ---------------- Main core, as Table 3 and p.19 actually define it ---------------- */
  /* p.19: "The reference plane for measurements in the axial direction is the bottom of the
     horizontal array of graphite bars at the lower end of the main portion of the core... the top
     of the main portion of the core is at 64.59 in." So z = 0 is that bottom plane, and the MAIN
     CORE is Table 3's regions N + M + J + L stacked over z = 0 to 64.59 in - NOT region J alone. */
  parameter SI.Volume V_fuel_mainCore=0.577707
    "35,253.8 in3. DERIVED_FROM_ORNL: Table 3 volume percents over regions N, M, J, L";
  parameter SI.Volume V_graphite_mainCore=1.981812
    "120,937.6 in3. DERIVED_FROM_ORNL: Table 3, same four regions";
  parameter SI.Power Q_mainCore=8706e3
    "DERIVED_FROM_ORNL: Table 4 regions J + L + M + N = 8287 + 159 + 192 + 68 kw = 87.06 % of the
     reactor's 10 MW. Q_reactor is NOT the main-core power";
  final parameter SIadd.NonDim axialPeakToAverage=1.3585
    "DERIVED_FROM_ORNL: computed from B(z) over 0 <= z <= 64.6 in. NOT pi/2 - that belongs to the
     idealised uniform core of p.35, whose sine vanishes at both ends. This one does not";

  parameter Real nChannels_mainCore=940
    "SOURCE: ORNL-TM-0378 Table 2, region 2. The MAIN CORE has 940 channels, not the 1140 of the
     whole vessel; regions 1, 3 and 4 (12, 108, 78) are peripheral";
  parameter SIadd.NonDim fuelVolumeFraction_mainCore=0.224
    "SOURCE: ORNL-TM-0378 Table 2, region 2";
  parameter SI.Radius R_mainCore_equiv=24.76*IN_TO_M
    "Equivalent outer radius of the main core. SOURCE: ORNL-TM-0378 Table 2, region 2";

  /* ---------------- The acceptance target ---------------- */
  parameter SI.TemperatureDifference dT_maxLocal_target=62.5*5/9
    "34.7222 K, from 62.5 F. SOURCE: ORNL-TM-0378 Table 5, 0 % fuel permeation row.
     This is the MAXIMUM LOCAL graphite-fuel temperature difference, NOT a mean";

  annotation (Documentation(info="<html>
<p>Inputs of ORNL-TM-0378, kept apart from every modern value. See the package documentation for
why they must never be merged into the production property package.</p>
<p><b>Deliberately absent:</b> a fuel heat capacity, and the absolute specific powers
<code>P_f</code> and <code>P_g</code>. The report contains no numerical <code>Cp</code> or
<code>rho*Cp</code> - and needs none, since Eq. (a15) derives the specific power from a prescribed
temperature rise and Eqs. (13)-(18) contain no heat capacity at all.</p>
</html>"));
end HistoricalData;
