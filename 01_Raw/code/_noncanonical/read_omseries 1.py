// ---------------------------------------------------------------------------
// Dymola verification sequence for the MSRE primary system.
//
//   usage:  dymola tools/dymola_verification.mos
//     or:   File > Run Script inside Dymola
//
// Run order is deliberate and each step gates the next:
//     1  PrimarySystem as shipped, steady        -> initialization and consistency
//     2  pump coastdown into the low-flow regime -> low flow, zero crossing, reversal
//     3  buoyancy-driven natural circulation     -> no pump, no prescribed flow
//
// NOTHING here tunes the model. No solver option is changed from Dymola's
// defaults except the tolerance, which is stated per experiment and matches
// what OpenModelica used, so the two are comparable.
//
// The sandbox TRANSFORM workarounds in tools/apply_sandbox_workarounds.sh are
// for OpenModelica ONLY and must NOT be applied for a Dymola run - Dymola
// accepts the stock library. See docs/PHASE_LOG.md, section on workarounds.
// ---------------------------------------------------------------------------

openModel("MSRE/package.mo");            // adjust the path if run from elsewhere

// ---- 1. Steady primary loop -----------------------------------------------
simulateModel("MSRE.Verification.Loop_Hydraulics",
  stopTime = 300, method = "dassl", tolerance = 1e-6,
  resultFile = "dym_1_loop");

// The quantities to read out of dym_1_loop, per the verification plan:
//   m_flow, dp_loop_total, dp_loop_gravity, dp_loop_nonstatic, dp_pump,
//   err_dpBalance, err_inventory, tau_core, tau_external, Re_max,
//   msre.core.T_in, msre.core.T_out, msre.hx.* inlet and outlet temperatures
//
// OpenModelica reference for the same model, for cross-tool comparison:
//   m_flow            166.5420006 kg/s
//   dp_pump           301271.07 Pa
//   dp_loop_gravity   -1.199578 Pa
//   err_dpBalance     5.82e-11 Pa
//   err_inventory     -8.88e-16
//   tau_core          9.96304429 s
//   tau_external      17.68764511 s
//   Re_max            806.178

// ---- 2. Pump coastdown into low flow --------------------------------------
simulateModel("MSRE.Experiments.PumpCoastdown_RotorDynamics",
  stopTime = 300, method = "dassl", tolerance = 1e-6,
  resultFile = "dym_2_coastdown");

// Read out: N/N_nominal, m_flow, pump head, dp across each section, core and
// HX inlet/outlet temperatures, density. Watch specifically for the flow
// magnitude at which the step size collapses, and record it - that is the
// low-flow threshold the plan asks for.

// ---- 3. Natural circulation, buoyancy driven ------------------------------
// The pump speed is zero throughout and no flow is prescribed anywhere, so
// m_flow is a RESULT. If it is not, the test is meaningless.
simulateModel("MSRE.Experiments.NaturalCirculation",
  stopTime = 3000, method = "dassl", tolerance = 1e-6,
  resultFile = "dym_3_naturalcirculation");

// Read out, and check the causal chain in this order rather than only the
// final flow:
//   Q_fission -> core dT -> hot/cold leg density difference
//             -> buoyancy head -> balance against friction -> m_flow
//
//   msre.m_flow_fuel          the resulting circulation rate
//   msre.core.T_in / T_out    core temperature rise
//   msre.hx.* in / out        heat sink temperatures
//   msre.*.dp_gravity_local   static head per section, from LOCAL densities
//   msre.*.dp_nonstatic       friction and form losses per section
//
// At a steady natural circulation the buoyancy head and the friction loss must
// balance. Report both, not just their difference.

