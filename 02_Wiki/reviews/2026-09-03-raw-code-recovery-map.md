---
type: review
date: 2026-09-03
systems: [msre]
tags: [code, provenance, canonical, recovery, audit]
---

# `01_Raw/code/` 낱개 파일 → canonical 경로 복원 맵 (2026-09-03)

> **방법**: 각 낱개 파일과 canonical zip(`MSRE_TRANSFORM-main (2).zip`, commit `80a8f6d7a2bee75c5810545cf95856653a39df51`) 내부 133개 blob을 **CRLF→LF 정규화 후 SHA-256**으로 대조.
> 이전 판정("zip과 일치 0개")은 줄바꿈 정규화를 하지 않아 생긴 오탐이며, 정규화 후 **낱개 233개 전부(233/233)가 canonical blob과 정확히 일치**한다.
>
> **결론**: 낱개 파일 집합은 canonical zip 대비 **고유 내용이 0개**다. 파일명만 어긋나 있을 뿐 내용은 전부 zip 안에 있다.
> - canonical 133 경로 중 **100개는 낱개 2개**가, **33개는 낱개 1개**가 담고 있음 (100×2 + 33 = 233).
> - `" 1"` 접미사 쌍은 같은 파일의 다른 버전이 아니라, **트리 순서가 한두 칸 밀린 서로 다른 canonical 파일**이다.
> - 따라서 낱개 파일은 **삭제해도 정보 손실이 없다**. (`01_Raw` 불변 원칙에 따라 실제 삭제/이동은 사용자 승인 후.)

## 복원 맵 (낱개 파일명 → canonical 저장소 경로)

| `01_Raw/code/` 낱개 파일명 | canonical 경로 (repo 기준) |
|---|---|
| `AbsoluteNormalizationAudit 1.mo` | `Verification/LowFlow_InverseClosure.mo` |
| `AbsoluteNormalizationAudit.mo` | `Verification/CoreNodalization_Structure.mo` |
| `AlgebraicVerification 1.mo` | `Verification/NaturalCirculation_TH.mo` |
| `AlgebraicVerification.mo` | `Verification/CoreTH_Baseline.mo` |
| `Analytic_DriftReactivity 1.mo` | `tools/read_omres.py` |
| `Analytic_DriftReactivity.mo` | `Media/FuelSalt/package.mo` |
| `AxialShapeVerification 1.mo` | `Verification/O32_ReducedLoop.mo` |
| `AxialShapeVerification.mo` | `Verification/CoreTH_ZeroPower.mo` |
| `BENCHMARK_BRANCH_ARCHITECTURE 1.md` | `Data/Nodalization/Core2D.mo` |
| `BENCHMARK_BRANCH_ARCHITECTURE.md` | `Verification/ORNL0378/axialPowerShape.mo` |
| `Core1D 1.mo` | `Components/FuelPump_Dynamics.mo` |
| `Core1D.mo` | `Components/package.order` |
| `Core1D2D_Identity.mo` | `Verification/BaseClasses/Core2D_EqualDr.mo` |
| `Core1D_Structure 1.mo` | `Verification/BaseClasses/IdealPressureRise.mo` |
| `Core1D_Structure.mo` | `Nuclear/PointKinetics_DNPtransport.mo` |
| `Core1D_TH_Baseline 1.mo` | `Verification/BaseClasses/package.mo` |
| `Core1D_TH_Baseline.mo` | `Nuclear/package.mo` |
| `Core1D_TH_ZeroPower 1.mo` | `Verification/BaseClasses/package.order` |
| `Core1D_TH_ZeroPower.mo` | `Nuclear/package.order` |
| `Core2D.mo` | `Components/ReactorCore.mo` |
| `Core2D_EqualDr 1.mo` | `tools/read_omseries.py` |
| `Core2D_EqualDr.mo` | `Media/FuelSalt/package.order` |
| `Core2D_RadialHydraulics 1.mo` | `Verification/Core1D2D_Identity.mo` |
| `Core2D_RadialHydraulics.mo` | `README.md` |
| `Core2D_RadialSourceSensitivity.mo` | `Verification/Core1D_Structure.mo` |
| `Core2D_RadialSourceSensitivity_EqualDr 1.mo` | `Verification/Core1D_TH_Baseline.mo` |
| `Core2D_RadialSourceSensitivity_EqualDr.mo` | `Systems/PrimarySystem.mo` |
| `Core2D_RadialSourceSensitivity_ORNL 1.mo` | `Verification/Core1D_TH_ZeroPower.mo` |
| `Core2D_RadialSourceSensitivity_ORNL.mo` | `Systems/package.mo` |
| `Core2D_Structure 1.mo` | `Verification/Core2D_RadialHydraulics.mo` |
| `Core2D_Structure.mo` | `Systems/package.order` |
| `Core2D_TH_ZeroPower.mo` | `Verification/Core2D_RadialSourceSensitivity.mo` |
| `CoreChannel.mo` | `ClosureRelations/Nus_HX.mo` |
| `CoreNodalization_Structure 1.mo` | `Verification/Core2D_RadialSourceSensitivity_EqualDr.mo` |
| `CoreNodalization_Structure.mo` | `Verification/Analytic_DriftReactivity.mo` |
| `CoreTH_Baseline.mo` | `Verification/Core2D_RadialSourceSensitivity_ORNL.mo` |
| `CoreTH_ZeroPower 1.mo` | `Verification/Core2D_Structure.mo` |
| `CoreTH_ZeroPower.mo` | `Verification/BaseClasses/Core2D_EqualDr.mo` |
| `DNP_Circulation 1.mo` | `Verification/Core2D_TH_ZeroPower.mo` |
| `DNP_Circulation.mo` | `Verification/BaseClasses/IdealPressureRise.mo` |
| `DYMOLA_B0_BASELINE 1.md` | `Data/Nodalization/PartialCoreNodalization.mo` |
| `DYMOLA_B0_BASELINE.md` | `Verification/ORNL0378/combinedDeltaT.mo` |
| `Fig04_radial 1.csv` | `Verification/ORNL0378/HistoricalData.mo` |
| `Fig04_radial.csv` | `Verification/LowFlow_Closure.mo` |
| `Fig13_radial_temperature 1.csv` | `Verification/ORNL0378/ProductionShapeComparison.mo` |
| `Fig13_radial_temperature.csv` | `Verification/LowFlow_Hydraulics.mo` |
| `Fig14_axial_temperature 1.csv` | `Verification/ORNL0378/RadialShapeVerification.mo` |
| `Fig14_axial_temperature.csv` | `Verification/LowFlow_Hydraulics_NoTrace.mo` |
| `FuelPump 1.mo` | `ClosureRelations/Nus_MoltenSalt.mo` |
| `FuelPump.mo` | `Components/BaseClasses/PartialFuelPump.mo` |
| `FuelPump_Dynamics 1.mo` | `ClosureRelations/package.mo` |
| `FuelPump_Dynamics.mo` | `Components/BaseClasses/package.mo` |
| `Geometry 1.mo` | `Components/BaseClasses/package.order` |
| `Geometry.mo` | `Components/ReactorCore1D.mo` |
| `Graphite_EnergyClosure 1.mo` | `Verification/CoreNodalization_Structure.mo` |
| `Graphite_EnergyClosure.mo` | `Verification/BaseClasses/package.mo` |
| `HX_LowFlow_Closure 1.mo` | `Verification/CoreTH_Baseline.mo` |
| `HX_LowFlow_Closure.mo` | `Verification/BaseClasses/package.order` |
| `HistoricalData 1.mo` | `Verification/O32_SinglePipe.mo` |
| `HistoricalData.mo` | `Verification/DNP_Circulation.mo` |
| `IdealPressureRise.mo` | `Media/MSRE_Properties.mo` |
| `Kinetics_U233 1.mo` | `Components/CoreChannel.mo` |
| `Kinetics_U233.mo` | `Components/SaltPipe.mo` |
| `Kinetics_U235 1.mo` | `Components/FuelPump.mo` |
| `Kinetics_U235.mo` | `Components/package.mo` |
| `LICENSE` | `Experiments/PumpStartup_StagnantStart.mo` |
| `LICENSE 1` | `Verification/SemiLinear_ZeroCrossing.mo` |
| `Loop_Hydraulics 1.mo` | `Verification/CoreTH_ZeroPower.mo` |
| `Loop_Hydraulics.mo` | `Verification/Core1D2D_Identity.mo` |
| `Loop_Hydraulics2D 1.mo` | `Verification/DNP_Circulation.mo` |
| `Loop_Hydraulics2D.mo` | `Verification/Core1D_Structure.mo` |
| `LowFlow_Closure 1.mo` | `Verification/Graphite_EnergyClosure.mo` |
| `LowFlow_Closure.mo` | `Verification/Core1D_TH_Baseline.mo` |
| `LowFlow_Hydraulics 1.mo` | `Verification/HX_LowFlow_Closure.mo` |
| `LowFlow_Hydraulics.mo` | `Verification/Core1D_TH_ZeroPower.mo` |
| `LowFlow_Hydraulics_NoTrace 1.mo` | `Verification/Loop_Hydraulics.mo` |
| `LowFlow_Hydraulics_NoTrace.mo` | `Verification/Core2D_RadialHydraulics.mo` |
| `LowFlow_Hydraulics_SteadyMass 1.mo` | `Verification/Loop_Hydraulics2D.mo` |
| `LowFlow_Hydraulics_SteadyMass.mo` | `Verification/Core2D_RadialSourceSensitivity.mo` |
| `LowFlow_InverseClosure 1.mo` | `Verification/LowFlow_Closure.mo` |
| `LowFlow_InverseClosure.mo` | `Verification/Core2D_RadialSourceSensitivity_EqualDr.mo` |
| `MSRE_Properties 1.mo` | `Experiments/package.order` |
| `MSRE_Properties.mo` | `LICENSE` |
| `NaturalCirculation.mo` | `Data/Nodalization/package.order` |
| `NaturalCirculation_TH 1.mo` | `Verification/LowFlow_Hydraulics.mo` |
| `NaturalCirculation_TH.mo` | `Verification/Core2D_RadialSourceSensitivity_ORNL.mo` |
| `Nus_Core 1.mo` | `Verification/package.order` |
| `Nus_Core.mo` | `.gitignore` |
| `Nus_HX.mo` | `.gitignore` |
| `Nus_MoltenSalt 1.mo` | `LICENSE` |
| `Nus_MoltenSalt.mo` | `ClosureRelations/Nus_Core.mo` |
| `O32_ReducedLoop 1.mo` | `Verification/LowFlow_Hydraulics_NoTrace.mo` |
| `O32_ReducedLoop.mo` | `Verification/Core2D_Structure.mo` |
| `O32_SinglePipe 1.mo` | `Verification/LowFlow_Hydraulics_SteadyMass.mo` |
| `O32_SinglePipe.mo` | `Verification/Core2D_TH_ZeroPower.mo` |
| `PHASE_LOG.md` | `Data/Nodalization/package.mo` |
| `PartialCoreNodalization 1.mo` | `Components/ReactorCore1D.mo` |
| `PartialCoreNodalization.mo` | `Data/Geometry.mo` |
| `PartialFuelPump 1.mo` | `README.md` |
| `PartialFuelPump.mo` | `ClosureRelations/package.mo` |
| `PartialKineticsData.mo` | `Components/package.order` |
| `PointKinetics_DNPtransport.mo` | `Functions/corePowerShape.mo` |
| `PrimarySystem.mo` | `Media/FuelSalt/Utilities/lambda_T.mo` |
| `ProductionShapeComparison.mo` | `Verification/Graphite_EnergyClosure.mo` |
| `Properties_TransitTime 1.mo` | `Verification/ORNL0378/data/Fig13_radial_temperature.csv` |
| `Properties_TransitTime.mo` | `Verification/O32_SinglePipe.mo` |
| `PumpCoastdown 1.mo` | `Data/PartialKineticsData.mo` |
| `PumpCoastdown.mo` | `Data/PrecursorGroups/U233_6group.mo` |
| `PumpCoastdown1D_R1.mo` | `Data/PrecursorGroups/U235_6group.mo` |
| `PumpCoastdown1D_RotorDynamics 1.mo` | `Data/PrecursorGroups/U233_6group.mo` |
| `PumpCoastdown1D_RotorDynamics.mo` | `Data/PrecursorGroups/package.mo` |
| `PumpCoastdown_RotorDynamics 1.mo` | `Data/PrecursorGroups/U235_6group.mo` |
| `PumpCoastdown_RotorDynamics.mo` | `Data/PrecursorGroups/package.order` |
| `PumpStartup 1.mo` | `Data/PrecursorGroups/package.mo` |
| `PumpStartup.mo` | `Data/package.mo` |
| `PumpStartup1D_R1 1.mo` | `Data/PrecursorGroups/package.order` |
| `PumpStartup1D_R1.mo` | `Data/package.order` |
| `PumpStartup1D_RotorDynamics.mo` | `Data/package.mo` |
| `PumpStartup_RotorDynamics 1.mo` | `Data/package.order` |
| `PumpStartup_RotorDynamics.mo` | `Experiments/NaturalCirculation.mo` |
| `PumpStartup_StagnantStart.mo` | `Experiments/PumpCoastdown.mo` |
| `Pump_R1_Torque.mo` | `Verification/ORNL0378/data/Fig14_axial_temperature.csv` |
| `Pump_ZeroSpeed 1.mo` | `Verification/ORNL0378/graphiteConductionDeltaT.mo` |
| `Pump_ZeroSpeed.mo` | `Verification/ORNL0378/AbsoluteNormalizationAudit.mo` |
| `README 1.md` | `Verification/package.mo` |
| `README.md` | `Media/FuelSalt/Utilities/eta_T.mo` |
| `RadialShapeVerification 1.mo` | `Verification/ORNL0378/AbsoluteNormalizationAudit.mo` |
| `RadialShapeVerification.mo` | `Verification/HX_LowFlow_Closure.mo` |
| `ReactorCore 1.mo` | `ClosureRelations/package.order` |
| `ReactorCore.mo` | `Components/BaseClasses/package.order` |
| `ReactorCore1D.mo` | `Components/CoreChannel.mo` |
| `SaltPipe.mo` | `Components/FuelPump.mo` |
| `SemiLinear_ZeroCrossing 1.mo` | `Verification/ORNL0378/package.mo` |
| `SemiLinear_ZeroCrossing.mo` | `Verification/ORNL0378/AlgebraicVerification.mo` |
| `Steady_LoopBalance 1.mo` | `Verification/ORNL0378/package.order` |
| `Steady_LoopBalance.mo` | `Verification/ORNL0378/AxialShapeVerification.mo` |
| `Transient_DriftReactivity 1.mo` | `Verification/ORNL0378/poppendiekDeltaT.mo` |
| `Transient_DriftReactivity.mo` | `Verification/ORNL0378/HistoricalData.mo` |
| `U233_6group.mo` | `Data/Nodalization/Core1D.mo` |
| `U235_6group 1.mo` | `Data/Geometry.mo` |
| `U235_6group.mo` | `Data/Nodalization/Core2D.mo` |
| `analyze_radial_source_ab 1.py` | `Systems/package.order` |
| `analyze_radial_source_ab.py` | `Verification/ORNL0378/data/Fig14_axial_temperature.csv` |
| `apply_sandbox_workarounds.sh` | `Verification/ORNL0378/graphiteConductionDeltaT.mo` |
| `axialPowerShape 1.mo` | `Verification/ORNL0378/AlgebraicVerification.mo` |
| `axialPowerShape.mo` | `Verification/Loop_Hydraulics.mo` |
| `combinedDeltaT 1.mo` | `Verification/ORNL0378/AxialShapeVerification.mo` |
| `combinedDeltaT.mo` | `Verification/Loop_Hydraulics2D.mo` |
| `coreCellVolumes 1.mo` | `docs/PHASE_LOG.md` |
| `coreCellVolumes.mo` | `Experiments/PumpCoastdown_RotorDynamics.mo` |
| `corePowerShape.mo` | `Experiments/PumpStartup.mo` |
| `cp_T 1.mo` | `Experiments/PumpCoastdown1D_RotorDynamics.mo` |
| `cp_T.mo` | `Experiments/package.mo` |
| `d_T 1.mo` | `Experiments/PumpCoastdown_RotorDynamics.mo` |
| `d_T.mo` | `Experiments/package.order` |
| `digitize_ornl0378 1.py` | `tools/analyze_radial_source_ab.py` |
| `digitize_ornl0378.py` | `Verification/ORNL0378/package.mo` |
| `download` | `Verification/Pump_ZeroSpeed.mo` |
| `driftReactivity 1.mo` | `Experiments/NaturalCirculation.mo` |
| `driftReactivity.mo` | `Experiments/PumpStartup1D_R1.mo` |
| `dymola_verification 1.mos` | `tools/apply_sandbox_workarounds.sh` |
| `dymola_verification.mos` | `Verification/ORNL0378/package.order` |
| `eta_T.mo` | `Experiments/PumpStartup.mo` |
| `graphiteConductionDeltaT 1.mo` | `Verification/ORNL0378/axialPowerShape.mo` |
| `graphiteConductionDeltaT.mo` | `Verification/LowFlow_Hydraulics_SteadyMass.mo` |
| `lambda_T 1.mo` | `Experiments/PumpStartup1D_R1.mo` |
| `lambda_T.mo` | `Functions/coreCellVolumes.mo` |
| `package (1) 1.mo` | `Verification/Analytic_DriftReactivity.mo` |
| `package (1).mo` | `ClosureRelations/package.order` |
| `package (10) 1.order` | `package.order` |
| `package (10).order` | `Data/PartialKineticsData.mo` |
| `package (11).mo` | `Experiments/PumpCoastdown1D_R1.mo` |
| `package (12) 1.order` | `ClosureRelations/Nus_Core.mo` |
| `package (12).order` | `Experiments/PumpCoastdown1D_RotorDynamics.mo` |
| `package (13) 1.mo` | `Components/BaseClasses/PartialFuelPump.mo` |
| `package (13).mo` | `Experiments/PumpStartup1D_RotorDynamics.mo` |
| `package (14) 1.order` | `Components/BaseClasses/package.mo` |
| `package (14).order` | `Experiments/PumpStartup_RotorDynamics.mo` |
| `package (15) 1.mo` | `Components/SaltPipe.mo` |
| `package (15).mo` | `Functions/corePowerShape.mo` |
| `package (16) 1.order` | `Components/package.mo` |
| `package (16).order` | `Functions/driftReactivity.mo` |
| `package (17) 1.mo` | `Data/Kinetics_U233.mo` |
| `package (17).mo` | `Functions/package.mo` |
| `package (18) 1.order` | `Data/Kinetics_U235.mo` |
| `package (18).order` | `Functions/package.order` |
| `package (20).order` | `Data/Nodalization/Core1D.mo` |
| `package (21) 1.mo` | `docs/BENCHMARK_BRANCH_ARCHITECTURE.md` |
| `package (21).mo` | `Media/FuelSalt/Utilities/cp_T.mo` |
| `package (22) 1.order` | `docs/DYMOLA_B0_BASELINE.md` |
| `package (22).order` | `Media/FuelSalt/Utilities/d_T.mo` |
| `package (23) 1.mo` | `Experiments/PumpCoastdown.mo` |
| `package (23).mo` | `Media/FuelSalt/Utilities/package.mo` |
| `package (24) 1.order` | `Experiments/PumpCoastdown1D_R1.mo` |
| `package (24).order` | `Media/FuelSalt/Utilities/package.order` |
| `package (25) 1.mo` | `Experiments/PumpStartup1D_RotorDynamics.mo` |
| `package (25).mo` | `Media/package.mo` |
| `package (26) 1.order` | `Experiments/PumpStartup_RotorDynamics.mo` |
| `package (26).order` | `Media/package.order` |
| `package (27) 1.mo` | `Experiments/PumpStartup_StagnantStart.mo` |
| `package (27).mo` | `Verification/LowFlow_InverseClosure.mo` |
| `package (28) 1.order` | `Experiments/package.mo` |
| `package (28).order` | `Verification/NaturalCirculation_TH.mo` |
| `package (29).mo` | `Verification/ORNL0378/ProductionShapeComparison.mo` |
| `package (3) 1.mo` | `Verification/ORNL0378/combinedDeltaT.mo` |
| `package (3).mo` | `Components/FuelPump_Dynamics.mo` |
| `package (30) 1.order` | `Functions/coreCellVolumes.mo` |
| `package (30).order` | `Verification/ORNL0378/RadialShapeVerification.mo` |
| `package (31) 1.mo` | `Functions/driftReactivity.mo` |
| `package (31).mo` | `Verification/ORNL0378/data/Fig04_radial.csv` |
| `package (32) 1.order` | `Functions/package.mo` |
| `package (32).order` | `Verification/ORNL0378/data/Fig13_radial_temperature.csv` |
| `package (4).order` | `Components/ReactorCore.mo` |
| `package (5) 1.mo` | `Verification/Properties_TransitTime.mo` |
| `package (5).mo` | `Data/Kinetics_U233.mo` |
| `package (6) 1.order` | `Verification/Pump_R1_Torque.mo` |
| `package (6).order` | `Data/Kinetics_U235.mo` |
| `package (7) 1.mo` | `Verification/Steady_LoopBalance.mo` |
| `package (7).mo` | `Data/Nodalization/PartialCoreNodalization.mo` |
| `package (8) 1.order` | `Verification/Transient_DriftReactivity.mo` |
| `package (8).order` | `Data/Nodalization/package.mo` |
| `package (9) 1.mo` | `package.mo` |
| `package (9).mo` | `Data/Nodalization/package.order` |
| `package 1.mo` | `Systems/PrimarySystem.mo` |
| `package 1.order` | `Systems/package.mo` |
| `package.mo` | `ClosureRelations/Nus_HX.mo` |
| `package.order` | `ClosureRelations/Nus_MoltenSalt.mo` |
| `poppendiekDeltaT 1.mo` | `Verification/ORNL0378/data/Fig04_radial.csv` |
| `poppendiekDeltaT.mo` | `Verification/O32_ReducedLoop.mo` |
| `read_omres 1.py` | `tools/digitize_ornl0378.py` |
| `read_omres.py` | `Verification/ORNL0378/poppendiekDeltaT.mo` |
| `read_omseries 1.py` | `tools/dymola_verification.mos` |
| `read_omseries.py` | `Verification/Properties_TransitTime.mo` |

## 검증 재현 절차

```bash
unzip -oq "01_Raw/code/MSRE_TRANSFORM-main (2).zip" -d /tmp/zipx
# canonical blob 해시
cd /tmp/zipx/MSRE_TRANSFORM-main && find . -type f \
  -exec sh -c 'printf "%s %s\n" "$(tr -d "\r" < "$1" | sha256sum | cut -d" " -f1)" "${1#./}"' _ {} \;
# 낱개 파일 해시 후 join
```

## 관련 페이지
- [[02_Wiki/issues/raw-code-noncanonical-files]] — 이 결과로 **resolved**
- [[02_Wiki/systems/msre/implementation/msre-transform-model]]
- [[02_Wiki/reviews/2026-09-03-inbox-raw-code-classification]]
