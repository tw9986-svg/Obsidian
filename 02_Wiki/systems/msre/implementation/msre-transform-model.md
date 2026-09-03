---
type: implementation
system: msre
tags: [dymola, transform, modelica, point-kinetics, dnp]
tool: Dymola/TRANSFORM
status: active
last_updated: {{date:YYYY-MM-DD}}
---
<!-- 저장 위치: 02_Wiki/systems/msre/implementation/ -->

# MSRE TRANSFORM 모델 (Modelica/Dymola)

## Canonical 소스

| 항목 | 내용 |
|---|---|
| **Canonical 기준** | Git 저장소 **https://github.com/tw9986-svg/MSRE_TRANSFORM** (branch `main`, 총 170 commits) |
| 분석 기준 commit | `80a8f6d7a2bee75c5810545cf95856653a39df51` (2026-09-02 03:27 UTC) — `01_Raw/code/MSRE_TRANSFORM-main (2).zip`이 이 commit과 **133/133 완전 일치** |
| 저장소 HEAD | `492deecd47e1f5d51eb49d045db3ea6f64de87a7` (2026-09-02 20:11 KST, 위 commit보다 22 앞섬). 그 22 commit이 바꾼 것은 `docs/PHASE_LOG.md`(+816줄)뿐 — `Media/`·`Data/`·`README.md`·`docs/DYMOLA_B0_BASELINE.md` 동일하므로 **이 페이지 내용은 HEAD 기준으로도 유효** |
| 패키지 버전 | `0.2.2` (README 기재) |
| 의존성 | Modelica Standard Library 4.1.0, TRANSFORM 1.1, Dymola (`__Dymola_` experiment annotation 사용) |
| 라이선스 | BSD 3-Clause |
| ⚠️ 비-canonical | `01_Raw/code/`의 낱개 파일 233개는 GitHub **웹페이지 저장본/내용 불일치 파일**이므로 참조 금지 → [[02_Wiki/issues/raw-code-noncanonical-files]] |

**코드 본문은 이 위키에 복제하지 않는다.** 아래는 구조·물리·입력출처·가정만 정리한 것이며, 실제 코드는 위 아카이브를 연다.

## 무엇을 재현하는 모델인가

이 모델은 **MARS 입력모델의 Modelica 재구현**이다. 원 논문:

> J.J. Jeong, Y.J. Cho, H.C. Lee, B. Yun, *Benchmarking the MARS code for molten salt reactor applications using MSRE transient experiments*, Nuclear Engineering and Technology **58** (2026) 104438.

→ 해당 논문 원본이 `00_Inbox/Benchmarking the MARS code for molten salt reactor applications using.pdf`에 있으며 **아직 ingest 전**. 이 모델의 수식 번호(Eq. 3–8) 참조는 모두 그 논문 기준.

## 패키지 구조 (canonical 아카이브 기준)

| 패키지 | 내용 |
|---|---|
| `Media` | MSRE 연료염(LiF-BeF₂-ZrF₄-UF₄)·2차 냉각염 물성. `FuelSalt_U235`/`FuelSalt_U233`은 6개 DNP군을 **trace substance**로 추가 |
| `Data` | 전구체군 데이터(논문 Table 1–2), U-235/U-233 kinetics, `Geometry` 노달화 레코드, `Nodalization/{Core1D,Core2D}` |
| `Functions` | `driftReactivity`(Eq. 8), `coreCellVolumes`, `corePowerShape` |
| `ClosureRelations` | `Nus_MoltenSalt`, `Nus_Core`, `Nus_HX` — 용융염 채널 Nusselt 상관식 |
| `Nuclear` | `PointKinetics_DNPtransport` — modified point kinetics |
| `Components` | `SaltPipe`, `CoreChannel`, `ReactorCore`, `ReactorCore1D`, `FuelPump`, `FuelPump_Dynamics` |
| `Systems` | `PrimarySystem` — 1차 루프 전체 (HX 2차측은 경계조건) |
| `Experiments` | `PumpStartup*`, `PumpCoastdown*`, `NaturalCirculation` |
| `Verification` | analytic 결과에 assert하는 자기검증 모델 다수 + `ORNL0378/`(출력분포 디지타이징 검증) |
| `tools` | `digitize_ornl0378.py`, `analyze_radial_source_ab.py`, `read_omres.py`, `dymola_verification.mos` |

## 구현된 물리

- **Modified point kinetics + DNP transport**: 통상 전구체 balance 대신 1차 계통 전체에 대한 DNP **수송 방정식**(논문 Eq. 3). Modelica에서는 6개 DNP군을 연료염 매질의 trace substance로 선언해 TRANSFORM 유체 컴포넌트가 자동 수송하게 하고, 생성·붕괴항은 `InternalTraceGen` closure로 공급.
- 유효 노심 전구체 수 `C_i(t)` (Eq. 4, importance·flux weighting 포함)
- 유효 지연중성자분율 `Beta_eff` (Eq. 6): null transient 후 정상상태에서 구해 과도 중 고정
- 반응도 모델 (Eq. 5): 연료·흑연 온도 피드백 + 외부 반응도
- 이상 제어봉(flux servo) 반응도 (Eq. 7): zero-power 펌프 시험에 사용
- 정상상태 drift reactivity 해석해 (Eq. 8) → `MSRE.Functions.driftReactivity`

## 노달화

`MSRE.Data.Geometry`: 1140개 연료채널을 **15개 동심 radial ring × 20 axial 노드**, + lower plenum 3, upper plenum 3, downcomer 10, HX 10(측당), 연결배관. 논문을 따라 lower plenum 마지막 노드와 upper plenum 첫 노드를 노심에 포함시켜 **`nV_core = 15×20 + 2 = 302`**.

`Core1D`는 같은 채널을 1개 등가 radial group × 20 axial로 축약(`nV_core = 22`). 코드 주석에 따르면 이 축약은 **hydraulic 축약이지 물리적 축약이 아니며**, `f_radial = {1.0}`은 MSRE에 대한 가정이 아니라 radial profile 해상도를 포기한 것.

## 입력 데이터 출처 (provenance)

| 입력 | 출처/성격 |
|---|---|
| 연료염 물성 | **대조 완료**: 코드는 Robertson(1965) 상수표가 아니라 `Media/MSRE_Properties.mo`의 온도의존 상관식을 사용 — ACTIVE = `d_Cantor`(ORNL-TM-2316, 1968) ρ=2553.3−0.562·T[°C], `eta_Cantor` μ=8.4e-5·exp(4340/T). REFERENCE ONLY = `d_Compere`(ORNL-TM-4865, 1975). ⚠️ **체적은 Compere 기준 유도, 매질은 Cantor 구동** → [[02_Wiki/issues/fuel-salt-property-correlation-conflict]] |
| Kinetics 파라미터 | **대조 완료 (verified)**: `Data/PrecursorGroups/U235_6group.mo`의 λ·α·Beta=0.006781이 Jeong Table 1과 완전 일치. 원출처는 코드 주석상 Hanusek & Juan, Ann. Nucl. Energy 157 (2021) 108208 → [[03_Data/msre/kinetics/delayed-neutron-parameters]] |
| 채널 수 1140, 활성 높이 1.626 m, HX 16-in shell·163 tubes·24.1 m² | 문서화된 MSRE 하드웨어 치수 (ORIGINAL). ⚠️ 활성높이 1.626 m는 ORNL-TM-730의 core height 63 in(1.600 m)과 다름 — active vs total 구분 가능성, 미확인 |
| 컴포넌트 체적 (node-by-node) | **CALIBRATED** — 공개된 MSRE 자료에 node별 체적 분해가 없어, 보고된 전이시간(core 9.56 s / external 16.14 s / system 25.63 s @168 kg/s)을 재현하도록 선택됨. 모두 노출 파라미터이고 추정 항목은 레코드에 명시돼 있음 |
| Radial power shape | **ASSUMED** — 논문은 비공개 Serpent 계산을 사용. 이 모델은 25% reflector saving을 가진 J0 형상(radial peak-to-average 1.61)으로 대체. Serpent 값 확보 시 `Geometry.f_radial` 교체 필요 |
| Natural circulation 경계조건 | 미확보 — 냉각염 입구온도 곡선이 그 과도의 forcing function인데 공개 데이터가 없어, `useMeasuredBoundaryCondition` + 디지타이징 실측 데이터 공급 전까지 시뮬레이션을 **assert로 차단**해 둠 (곡선을 지어내고 결과를 맞추는 순환논증 방지) |

## 가정 / 단순화

- Pump: `tau_shaft` 4.0 s, 유체토크 ≈ ω·|ω|, 운전점 의존성 단순화, coulomb·viscous 마찰 0, off-design 특성 미검증(정격점만 검증)
- HX 2차측은 경계조건으로만 부여 (전체 2차 계통 미모델링)
- `Beta_eff`는 정상상태에서 구해 과도 중 상수 취급

## 알려진 한계

- Pump coastdown 유량 감소가 MARS 대비 현저히 느림 (LARGE BENCHMARK_DIFFERENCE) → [[02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars]]
- 전이시간이 Jeong/MARS 대비 +7.6% → 위 benchmark 페이지
- Radial power shape가 대체값(J0)이라 ORNL 원자료 재현이 미완 → [[02_Wiki/issues/graphite-heating-fraction-provenance]]와 별개 이슈로 추적 필요

## 검증 상태

[[02_Wiki/systems/msre/verification/dymola-b0-baseline]] 참고 (Dymola B0가 authoritative baseline, OpenModelica는 사전검증용).

## 관련 페이지
- [[02_Wiki/systems/msre/components/primary-loop]] · [[02_Wiki/systems/msre/components/core]] · [[02_Wiki/systems/msre/components/fuel-pump]]
- [[03_Data/msre/benchmark/transform-b0-vs-jeong-mars]]
- [[04_Projects/msre-transform-status]]
