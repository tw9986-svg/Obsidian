---
type: project-status
system: msre
raw: "[[01_Raw/misc/연구 주제 및 방향성]]"
last_updated: {{date:YYYY-MM-DD}}
---

# MSRE TRANSFORM 연구 진행 상황

> [[01_Raw/misc/연구 주제 및 방향성]] (원본, 불변)을 기반으로 정리·갱신하는 현재 상태 페이지. 원본은 특정 시점 스냅샷이고, 이 페이지는 이후 ingest/진행에 따라 계속 갱신됩니다.

## 연구 목표

- MSRE 열수력·동특성의 Dymola/TRANSFORM 기반 모델링
- MARS(Jeong) 모델 및 MSRE 실험데이터와의 benchmark
- 1D 모델 검증 → 2D 노달화 확장 → 정격출력 운전 및 과도상태 해석
- 각 모델 입력값의 원자료·가정값·계산값·코드 기본값 provenance 확보 ([[03_Data/registry]])

## 단계별 상태

| 단계 | 내용 | 상태 |
|---|---|---|
| 기초 데이터 구축 | MSRE geometry, 연료염 물성(밀도/점도/비열/열전도도), ORNL/INL/MARS 문헌 확보 | 진행 |
| 1D Core 열수력 | 축방향 노달화, 연속·질량·에너지 보존, 축방향 체적발열, inlet/outlet T·ΔP 검증 | **PASS** |
| Primary Loop | Core–piping–pump–HX 구성, component volume/fuel inventory, pressure loss, transit time | Steady hydraulics **PASS** / Inventory·transit-time identity **PASS** / Jeong transit-time **BENCHMARK DIFFERENCE** |
| DNP (Delayed Neutron Precursor) | 생성·붕괴·유동수송, core 밖 precursor transport, analytic vs numerical | Full-loop transport **PASS** / Circulation reactivity **PASS** |
| Pump 모델 | Motor–hydraulic–friction torque, rotor ODE, affinity law (Q∝N, H∝N², P∝N³), τ_shaft=4s | **PASS** (standalone) |
| Pump Startup/Coastdown Benchmark | Jeong MARS + 실험데이터 digitization vs Dymola | 진행 — coastdown 유량감소곡선 TRANSFORM–MARS 차이 확인 |
| Core 2D 확장 | 1D→radial×axial, 15 radial ring, equal-channel/equal-area 검토, Core1D–Core2D structural identity | 구조 검증 **PASS** |
| Power Distribution 검증 | axial/radial source shape 문헌 추적, ORNL figure digitization, peak/volume-normalized 구분 | 진행 — 원자료 재현 정확도가 핵심 이슈 |
| Graphite 열전달 | Fuel/graphite 에너지방정식 분리, volumetric heating, f_graphiteHeating ≈ 0.06, axial/radial conduction | 구조·source distribution 검증 단계 |
| 정격출력 모델링 | Zero-power 구조검증 우선 → 8–10 MW 정상운전 → secondary HX thermal boundary → feedback | 계획 단계 |

## 현재 핵심 이슈

- **Pump coastdown 유량 감쇠 차이** (LARGE BENCHMARK_DIFFERENCE): 10 s에서 TRANSFORM 27.5% vs MARS 6.57%. 인과사슬 `FLOW_ERROR → DNP_RESIDENCE_ERROR → REACTIVITY_ERROR`. 단 반응도는 TRANSFORM이 MARS보다 실측에 더 근접(MAE 19.3 vs 24.8 pcm). → [[02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars]]
  - 참고: Jeong의 MARS 모델도 펌프는 **generic 파라미터**(상세 자료 부재) — 기준값 자체의 불확실성 요인 ([[02_Wiki/sources/jeong-2026-mars-msre-benchmark]])
- **전이시간 +7.6~7.9%** (TRANSFORM 27.651 s vs Jeong 25.63~25.70 s). 기준값 자체가 문서마다 불일치 → [[02_Wiki/issues/jeong-transit-time-value-mismatch]]
- **Radial power distribution**: 원 논문은 비공개 Serpent 결과 사용, 우리 모델은 J0(25% reflector saving, peak/avg 1.61) 대체 = **ASSUMED**
- **흑연 발열분율 6%**의 1차 근거 미확보 → [[02_Wiki/issues/graphite-heating-fraction-provenance]]
- **펌프 수두 문헌 충돌** → [[02_Wiki/issues/pump-discharge-head-conflict]] (모델 값 0.301 MPa는 1차와 정합, 조치 불필요)
- **코드 canonical/commit 문제** → [[02_Wiki/issues/raw-code-noncanonical-files]]

## 완료 / 진행 중 / 이후 (요약)

**완료**: Property baseline, Geometry baseline, Core1D TH, Primary-loop steady hydraulics, Inventory/transit time, DNP full-loop transport, Circulation reactivity, Pump rotor standalone, Core1D/Core2D structural verification.

**진행 중**: Pump startup/coastdown 오차 개선, 2D radial nodalization 검증, Axial/radial power distribution 원자료 재현, Graphite volumetric heating 및 2D conduction 검증.

**이후**: Fuel–graphite heat-transfer coupling, 2D full-core thermal analysis, 8–10 MW steady-state benchmark, Natural circulation, 고출력 transient benchmark, 실험데이터/MARS/TRANSFORM 종합 비교, 모델 입력값 전체 provenance database 구축.

## 연구 진행 흐름

문헌·원자료 확보 → 물성치·Geometry 정리 → 1D Core TH → Primary Loop → DNP/Reactivity → Pump Dynamics → Startup/Coastdown Benchmark → 2D Core Nodalization → Axial/Radial Source 검증 → Graphite Heating/Conduction → Fuel–Graphite Coupling → 정격출력 MSRE Benchmark → Natural Circulation/고출력 Transient

## 외부 벤치마크 기준선

- [[02_Wiki/systems/msre/benchmark/sam-msre-primary-loop]] — NEAMS SAM 코드의 MSRE primary loop 결과 (SAM vs RELAP5-3D vs historical calculation). TRANSFORM 자체 결과는 아직 미포함이나, 향후 TRANSFORM 결과를 이 기준선과 3자 비교할 수 있음.

## 관련 페이지
- [[02_Wiki/systems/msre/overview]]
- [[03_Data/registry]]
- [[01_Raw/misc/연구 주제 및 방향성]] (원본)
