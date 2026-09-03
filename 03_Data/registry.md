# 데이터 마스터 레지스트리 (전 시스템 통합)

> `03_Data/<system>/{properties,correlations,geometry,distributions,benchmark}/`에 기록되는 **모든 정량값**은 여기에도 한 줄로 등록합니다. 값을 찾을 때 여기부터 검색하고, 상세(수식/디지타이징 방법/불일치 논의)는 링크된 데이터 페이지에서 확인합니다. ingest 시마다 갱신하세요.

## Provenance 분류

| Provenance | 의미 |
|---|---|
| `ORIGINAL` | 소스 문서에 그대로 제시된 값 (측정값/설계값 등, 저자가 직접 준 값) |
| `DERIVED` | 소스의 다른 값들로부터 수식으로 계산해 얻은 값 |
| `DIGITIZED` | 소스의 그림/그래프에서 디지타이징(픽셀 추출)한 값 |
| `FITTED` | 데이터에 곡선/상관식을 피팅해서 얻은 계수·값 |
| `ASSUMED` | 소스에 없어 연구자가 가정한 값 |
| `CALIBRATED` | 벤치마크/검증을 위해 모델을 맞추며 조정한 값 |
| `SOFTWARE_DEFAULT` | Dymola/TRANSFORM/MARS 등 코드의 기본값을 그대로 사용 |
| `UNKNOWN` | 출처를 아직 특정하지 못한 값 — 반드시 최종 보고에서 별도 플래그 |

## 마스터 테이블

| Parameter | Symbol | System | Value | Unit | Source | Page/Fig | Provenance | Confidence | Verification | 상세 페이지 |
|---|---|---|---|---|---|---|---|---|---|---|
| MSRE 1차 루프 유량 | — | msre | 0.076 | m3/s | leandro-2019-sam-msre-thermal-hydraulic | p.60 | ORIGINAL | high | unverified | [[03_Data/msre/geometry/msre-primary-loop-geometry]] |
| Core vessel 내경 | — | msre | 0.705 | m | 〃 | p.63 | ORIGINAL | high | unverified | 〃 |
| Core ring 개수 | — | msre | 4 | - | 〃 | p.63 | ORIGINAL | high | unverified | 〃 |
| Core ring 폭 | — | msre | 0.176 | m | 〃 | p.63 | DERIVED | high | unverified | 〃 |
| Fuel channel 개수 | — | msre | 1140 | - | 〃 | p.59 | ORIGINAL | high | unverified | 〃 |
| Fuel channel 합산 유동단면적 | — | msre | 0.332 | m2 | 〃 | p.63 | ORIGINAL | high | unverified | 〃 |
| Fuel channel 수력직경 | — | msre | 0.0159 | m | 〃 | p.63 | ORIGINAL | high | unverified | 〃 |
| Fuel channel 높이 | — | msre | 1.60 | m | 〃 | p.63 | ORIGINAL | high | unverified | 〃 |
| Downcomer 수력직경 | — | msre | 0.0508 | m | 〃 | p.62 | ORIGINAL | medium | unverified | 〃 |
| Downcomer 유동단면적 | — | msre | 0.116 | m2 | 〃 | p.62 | ORIGINAL | medium | unverified | 〃 |
| Lower plenum 높이 | — | msre | 0.01 | m | 〃 | p.62 | ORIGINAL | low | unverified | 〃 |
| Lower plenum 수력직경 | — | msre | 1.47 | m | 〃 | p.62 | ORIGINAL | medium | unverified | 〃 |
| Lower/Upper plenum 유동단면적 | — | msre | 1.71 | m2 | 〃 | p.62 | ORIGINAL | medium | unverified | 〃 |
| Upper plenum 높이 | — | msre | 0.249 | m | 〃 | p.62 | ORIGINAL | medium | unverified | 〃 |
| Hydraulic mockup 배관 벽두께 | — | msre | 0.0066 | m | 〃 | p.61 | ORIGINAL | medium | unverified | 〃 |
| Hydraulic mockup 배관 유동단면적 | — | msre | 0.0127 | m2 | 〃 | p.61 | ORIGINAL | medium | unverified | 〃 |
| Hydraulic mockup 배관 수력직경 | — | msre | 0.127 | m | 〃 | p.61 | ORIGINAL | medium | unverified | 〃 |
| 배관 조도 | — | msre | 1.00e-4 | m | 〃 | p.61 | **ASSUMED** | low | unverified | 〃 |
| Fuel pump 토출수두 | — | msre | 0.092 | MPa | 〃 | p.63 | ORIGINAL | high | unverified | 〃 |
| Fuel pump 유량 | — | msre | 171 | kg/s | 〃 | p.63 | ORIGINAL | high | unverified | 〃 |
| Secondary loop 유량 | — | msre | 0.054 | m3/s | 〃 | p.63 | ORIGINAL | high | unverified | 〃 |
| Secondary loop 입구온도 | — | msre | 825 | K | 〃 | p.63 | ORIGINAL | high | unverified | 〃 |
| HX 길이 | — | msre | 1.83 | m | 〃 | p.63 | ORIGINAL | medium | unverified | 〃 |
| Core 입구/출구온도(historical) | — | msre | 908 / 936 | K | 〃 | p.59 | ORIGINAL | medium | unverified | 〃 |
| Core 발열분배 (fluid/graphite) | — | msre | 94 / 6 | % | 〃 | p.59 | ORIGINAL | medium | unverified | 〃 |
| 설계/실제 운전출력 | — | msre | 10 / 8 | MWt | 〃 | p.59 | ORIGINAL | high | unverified | 〃 |
| Core 체적발열원 (SAM 모델, 100% 유체투입 가정) | — | msre | 1.88e7 | W/m3 | 〃 | p.63 | **DERIVED** | medium | unverified | 〃 |
| SAM 내장 FLiBe 물성 (ρ/μ/cp @922K) | ρ,μ,cp | msre | 1963 / 0.00661 / 2416 | kg/m3, kg/m-s, J/kg-K | 〃 | Table 5 | ORIGINAL | high | unverified | [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]] |
| MSRE 1 연료염 물성 (ρ/μ/cp @922K) | ρ,μ,cp | msre | 2243 / 0.00744 / 1883 | kg/m3, kg/m-s, J/kg-K | 〃 | Table 5 | ORIGINAL | medium | unverified | 〃 |
| MSRE 2 연료염 물성 (ρ/μ/cp @922K) | ρ,μ,cp | msre | 2082 / 0.00703 / 2008 | kg/m3, kg/m-s, J/kg-K | 〃 | Table 5 | ORIGINAL | medium | unverified | 〃 |
| MSRE 3 연료염 물성 (ρ/μ/cp @922K) | ρ,μ,cp | msre | 2146 / 0.00827 / 1966 | kg/m3, kg/m-s, J/kg-K | 〃 | Table 5 | ORIGINAL | medium | unverified | 〃 |
| SAM/RELAP5-3D/Historical Core Tin | — | msre | 905 / 908 / 908 | K | 〃 | Table 3 | ORIGINAL | high | unverified | [[03_Data/msre/benchmark/sam-relap5-3d-historical-primary-loop]] |
| SAM/RELAP5-3D/Historical Core Tout | — | msre | 933 / 936 / 936 | K | 〃 | Table 3 | ORIGINAL | high | unverified | 〃 |
| SAM/RELAP5-3D/Historical Core Velocity | — | msre | 0.23 / 0.20–0.50 / 0.18–0.61 | m/s | 〃 | Table 3 | ORIGINAL | high | unverified | 〃 |
| SAM/RELAP5-3D/Historical Inlet Pipe Velocity | — | msre | 5.87 / 5.85 / 5.85 | m/s | 〃 | Table 3 | ORIGINAL | high | unverified | 〃 |
| SAM/RELAP5-3D/Historical(측정) Downcomer Velocity | — | msre | 0.66 / 0.66 / 1.68 | m/s | 〃 | Table 3 | ORIGINAL | high | unverified (1-D 단순화 편차 논의 대상) | 〃 |
| SAM/RELAP5-3D/Historical Core Head Loss | — | msre | 1.91 / 1.78 / 1.79 | kPa | 〃 | Table 3 | ORIGINAL | high | unverified | 〃 |
| SAM/RELAP5-3D/Historical System Head Loss | — | msre | 44.9 / 44.7 / 44.8 | kPa | 〃 | Table 3 | ORIGINAL | high | unverified | 〃 |
| HX Triangular Pitch | — | msre | 0.0197 | m | 〃 | Table 2 | ORIGINAL | high | unverified | [[03_Data/msre/geometry/msre-primary-loop-geometry]] |
| HX Outer Tube Diameter | — | msre | 0.0127 | m | 〃 | Table 2 | ORIGINAL | high | unverified | 〃 |
| HX Tube Thickness | — | msre | 0.00107 | m | 〃 | Table 2 | ORIGINAL | high | unverified | 〃 |
| HX Inner Tube Diameter | — | msre | 0.0106 | m | 〃 | Table 2 | DERIVED | high | unverified | 〃 |
| HX Tube Flow Area | — | msre | 0.0279 | m2 | 〃 | Table 2 | DERIVED | high | unverified | 〃 |
| HX Baffle Spacing | — | msre | 0.305 | m | 〃 | Table 2 | ORIGINAL | high | unverified | 〃 |
| HX Outer Shell Diameter | — | msre | 0.406 | m | 〃 | Table 2 | ORIGINAL | high | unverified | 〃 |
| HX Shell Thickness | — | msre | 0.0127 | m | 〃 | Table 2 | ORIGINAL | high | unverified | 〃 |
| HX Inner Shell Diameter | — | msre | 0.381 | m | 〃 | Table 2 | DERIVED | high | unverified | 〃 |
| HX Tube Clearance | — | msre | 0.00699 | m | 〃 | Table 2 | DERIVED | high | unverified | 〃 |
| HX Shell Flow Area | — | msre | 0.0412 | m2 | 〃 | Table 2 | DERIVED | high | unverified | 〃 |
| HX Tube Hydraulic Diameter | — | msre | 0.0209 | m | 〃 | Table 2 | DERIVED | high | unverified | 〃 |
| HX Shell Hydraulic Diameter | — | msre | 0.0130 | m | 〃 | Table 2 | DERIVED | high | unverified | 〃 |
| HX Tube Surface Area Density | — | msre | 378 | m-1 | 〃 | Table 2 | DERIVED | high | unverified | 〃 |
| HX Shell Surface Area Density | — | msre | 308 | m-1 | 〃 | Table 2 | DERIVED | high | unverified | 〃 |
| Hydraulic mockup loss coefficients (6개 컴포넌트 in/out) | — | msre | Table 1 참조 (Core Rings 16.7/17.0 등) | - | 〃 | Table 1 | DERIVED | high | unverified | 〃 |
| **1차 ORNL 자료 (ORNL-TM-728 / TM-730)** | | | | | | | | | | |
| 설계 유량 | — | msre | 1200 gpm = 0.0757 | m3/s | ornl-tm-728-robertson-1965 | PDF p.28/184 | ORIGINAL(1차) | high | verified | [[03_Data/msre/geometry/msre-primary-loop-geometry]] |
| Core 입/출구 온도 | — | msre | 1175/1225 °F = 908.1/935.9 | K | 〃 | PDF p.20,38 | ORIGINAL(1차) | high | verified | 〃 |
| Fuel pump 설계점 (1150 rpm, 임펠러 11.5 in, head 48.3 ft) | — | msre | 48.3 ft ≈ 0.324 | MPa | 〃 | PDF p.184 | ORIGINAL(1차) | high | **conflicting** (Leandro 0.092 MPa) | 〃 |
| Fuel pump 기동시간 (50/75/90/100%) | — | msre | 0.75 / 1.25 / 1.75 / 3 | s | 〃 | PDF p.184 | ORIGINAL(1차) | medium | unverified | 〃 |
| 연료염 물성 3종 + 냉각염 (ρ/μ/cp/k/liquidus @1200°F) | ρ,μ,cp,k | msre | 표 참조 (예: MSRE1 2242.6 / 0.00744 / 1884 / 5.56) | SI | 〃 | PDF p.38 | ORIGINAL(1차) | high | verified (Leandro Table 5 환산 일치) | [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]] |
| Core radius / height | — | msre | 27.7 in = 0.7036 / 63 in = 1.6002 | m | ornl-tm-730-haubenreich-1964 | PDF p.15 | ORIGINAL(1차) | high | verified | [[03_Data/msre/geometry/msre-primary-loop-geometry]] |
| Core 외부 연료 체적 | — | msre | 40 ft³ = 1.133 | m3 | 〃 | PDF p.15 | ORIGINAL(1차) | high | unverified | 〃 |
| **Jeong et al. 2026 (MARS 벤치마크 원 논문)** | | | | | | | | | | |
| U-235 6군 β_i, λ_i (β합 0.006781) | β_i, λ_i | msre | Table 참조 | -, 1/s | jeong-2026-mars-msre-benchmark | Table 1 | ORIGINAL(2차, 원출처 Ref.[9]) | high | unverified | [[03_Data/msre/kinetics/delayed-neutron-parameters]] |
| U-233 6군 β_i, λ_i (β합 0.003251) | β_i, λ_i | msre | Table 참조 | -, 1/s | 〃 | Table 2 | ORIGINAL(2차) | medium (group1 오식 의심) | unverified | 〃 |
| 즉발중성자 생성시간 Λ | Λ | msre | 2.4e-4 (U235) / 4.0e-4 (U233) | s | 〃 | Table 3 | ORIGINAL(2차) | high | unverified | 〃 |
| 연료/흑연 온도계수 | α_f, α_g | msre | −8.71/−6.66 (U235), −11.3/−5.81 (U233) | pcm/K | 〃 | Table 3 | ORIGINAL(2차) | high | unverified | 〃 |
| Jeong τ_system (계산/실험보고) | — | msre | 25.63 / 25.2 | s | 〃 | §3.2 | ORIGINAL | high | **conflicting**(사내문서 25.70) | [[02_Wiki/issues/jeong-transit-time-value-mismatch]] |
| MARS 펌프 파라미터 | — | msre | generic (상세 자료 부재) | - | 〃 | §3.2 | **SOFTWARE_DEFAULT** | high | unverified | [[02_Wiki/sources/jeong-2026-mars-msre-benchmark]] |
| MARS form loss·HX 전열면적 | — | msre | 전출력 정상상태 재현하도록 조정 | - | 〃 | §3.2 | **CALIBRATED** | high | unverified | 〃 |
| **TRANSFORM Dymola B0 (자체 실행 결과)** | | | | | | | | | | |
| m_flow / Re_max / dp_pump | — | msre | 166.542 / 806.178 / 0.301 | kg/s, -, MPa | Dymola B0 (`docs/DYMOLA_B0_BASELINE.md`) | — | DERIVED (모델 출력) | high | PASS | [[02_Wiki/systems/msre/verification/dymola-b0-baseline]] |
| V_loop / M_loop | — | msre | 2.0965 / 4605 | m3, kg | 〃 | — | DERIVED | high | PASS (inventory identity) | 〃 |
| τ_core / τ_external / τ_system | — | msre | 9.96316 / 17.6879 / 27.651 | s | 〃 | — | DERIVED | high | BENCHMARK_DIFFERENCE | [[03_Data/msre/benchmark/transform-b0-vs-jeong-mars]] |
| Radial power shape (J0 대체, peak/avg 1.61) | — | msre | 25% reflector saving J0 | - | canonical 코드 README | — | **ASSUMED** (Serpent 원자료 비공개) | medium | unverified | [[02_Wiki/systems/msre/implementation/msre-transform-model]] |
| 노달화 체적 (node별) | — | msre | 전이시간 재현하도록 선택 | m3 | 〃 | — | **CALIBRATED** | medium | unverified | 〃 |
| **ORNL-TM-0378 (1962) — HISTORICAL_CALCULATION_INPUT (측정값 아님)** | | | | | | | | | | |
| 흑연 발열분율 f_graphite | — | msre | 0.06 (연료 0.94) | - | ornl-tm-0378-engel-haubenreich-1962 | p.40 각주 | **ASSUMED** (Nestor 미출간 계산) | high | verified (원문 직접) | [[03_Data/msre/geometry/ornl-tm-0378-core-thermal-basis]] |
| Main-core 입/출구 온도 | — | msre | 1177.3 / 1220.8 °F = 909.43 / 933.59 | K | 〃 | p.33 | ORIGINAL(1차) | high | verified | 〃 |
| Reactor 입/출구 온도 (main-core와 다름) | — | msre | 1175 / 1225 °F = 908.15 / 935.93 | K | 〃 | Table 4 각주 c | ORIGINAL(1차) | high | verified | 〃 |
| 주 노심 채널 수 (전체 1140 중) | — | msre | **940** | - | 〃 | Table 2 region 2 | ORIGINAL(1차) | high | verified | 〃 |
| 주 노심 연료 체적분율 / 등가 외반경 | — | msre | 0.224 / 24.76 in | -, in | 〃 | Table 2 region 2 | ORIGINAL(1차) | high | verified | 〃 |
| 축방향 peak-to-average | — | msre | 1.3585 (π/2 아님) | - | 〃 | Fig.8/Eq.4-6 | DERIVED_FROM_ORNL | medium | unverified | 〃 |
| 1962 vintage 열전도도 (연료/흑연) | k_f, k_g | msre | 3.21 / 13 Btu·hr⁻¹ft⁻¹°F⁻¹ = 5.5557 / 22.4996 | W/m-K | 〃 | p.40 각주 | **ASSUMED** | high | verified — production은 1.0 W/m-K 사용, 혼용 금지 | 〃 |
| 최대 국부 흑연–연료 ΔT (검증 목표) | — | msre | 62.5 °F = 34.7222 | K | 〃 | Table 5 | ORIGINAL(1차) | high | unverified | 〃 |
| **ORNL-TM-0380 (1962) — 1차** | | | | | | | | | | |
| Actual yield / static β_eff / circulating β_eff | Σβ_i, Σβ*_is, Σβ*_i | msre | 0.006405 / **0.006661** / **0.003617** | - | ornl-tm-0380-effective-delayed-neutron-yields | Table 2 p.17 | ORIGINAL(1차) | high | **conflicting** (모델 0.006781 / ≈0.0045) | [[03_Data/msre/kinetics/ornl-tm-0380-effective-yields-and-transit-times]] |
| 전이시간 τ_core / τ_external / τ_system | — | msre | **9.37 / 16.45 / 25.82** | s | 〃 | p.21 | ORIGINAL(1차) | high | **conflicting** (TRANSFORM 9.96/17.69/27.651) | 〃 |
| 총 순환 연료 체적 | — | msre | 69.1 ft³ = **1.9567** | m3 | 〃 | p.21 | ORIGINAL(1차) | high | conflicting (모델 2.0965, +7.14%) | 〃 |
| 축방향 분열분포 sin(πz/H), H | H | msre | 77.7 in = 1.9736 | m | 〃 | p.21 | ORIGINAL(1차) | high | verified (코드값과 일치) | 〃 |
| 노심 연료 체적분율 f (H=68.9 in 정의) | f | msre | 0.259 (96.4 ft³ 중 25.0 ft³) | - | 〃 | p.21 | ORIGINAL(1차) | high | unverified | 〃 |
| 채널 유속 (3/4 이상 채널 / 중심채널) | — | msre | 0.60 / >1.8 | ft/s | 〃 | p.21 | ORIGINAL(1차) | medium | unverified | 〃 |
| **모델이 실제 쓰는 연료염 상관식** | | | | | | | | | | |
| 밀도 `d_Cantor` (ACTIVE) | ρ(T) | msre | 2553.3 − 0.562·T[°C] → 2188.65 @922K | kg/m3 | 코드 `Media/MSRE_Properties.mo` (원출처 ORNL-TM-2316 Cantor 1968, 원문 미확보) | — | ORIGINAL(2차) | medium | **conflicting** (Robertson 2242.6) | [[02_Wiki/issues/fuel-salt-property-correlation-conflict]] |
| 점도 `eta_Cantor` (ACTIVE) | μ(T) | msre | 8.4e-5·exp(4340/T) → 0.0093025 @922K | Pa·s | 〃 | — | ORIGINAL(2차) | medium | **conflicting** (Robertson 0.00744) | 〃 |
| 밀도 `d_Compere` (REFERENCE ONLY, 체적 유도 기준) | ρ(T) | msre | 2575.0 − 0.513·T[°C] → 2242.1 @922K | kg/m3 | 〃 (원출처 ORNL-TM-4865 Compere 1975) | — | ORIGINAL(2차) | medium | Robertson과 0.02% 일치 | 〃 |

**Verification**: `unverified` / `verified` / `conflicting` / `superseded`. `verified`/`conflicting`이면 관련 [[02_Wiki/systems/msre/verification/...]] 또는 충돌 상대를 링크.
**UNKNOWN provenance 값은 절대 다른 값으로 대체 추정하지 않는다** — 그대로 UNKNOWN으로 남기고 `02_Wiki/issues/`에 등록.

## ORNL-TM-2316 (Cantor ed., 1968) — 염 물성 (2026-09-03 추가)

> ⚠️ 이 보고서의 7종 염 중 **MSRE 연료염(LiF-BeF₂-ZrF₄-UF₄)은 없다.** F₁–F₄는 ThF₄ 함유 MSBR fuel-breeder 염,
> L₂B는 flush salt, C₁·C₂는 NaBF₄ 냉각염이다. 상세: [[03_Data/msre/properties/ornl-tm-2316-salt-properties]]

| Parameter | Symbol | System | Value | Unit | Source | Page/Fig | Provenance | Confidence | Verification | 상세 페이지 |
|---|---|---|---|---|---|---|---|---|---|---|
| 점도 F₁ | η | msbr-F1 | 0.084·exp(4340/T) | cP (T in K) | ornl-tm-2316-cantor-1968 | p.8 | ORIGINAL | high | **conflicting** | [[03_Data/msre/properties/ornl-tm-2316-salt-properties]] |
| 점도 F₂ | η | msbr-F2 | 0.072·exp(4370/T) | cP | 〃 | p.8 | ORIGINAL | high | unverified | 〃 |
| 점도 F₃ | η | msbr-F3 | 0.077·exp(4430/T) | cP | 〃 | p.8 | ORIGINAL | high | unverified | 〃 |
| 점도 F₄ | η | msbr-F4 | 0.0444·exp(5030/T) | cP | 〃 | p.8 | ORIGINAL | high | unverified | 〃 |
| 점도 L₂B (flush) | η | msre-flush | 0.116·exp(3755/T) | cP | 〃 | p.8 | ORIGINAL | high | unverified | 〃 |
| 점도 C₁·C₂ | η | coolant | 0.04·exp(3000/T) | cP | 〃 | p.8 | ORIGINAL | medium | unverified | 〃 |
| 열전도도 F₁ | k | msbr-F1 | 1.0 | W/(m·K) | 〃 | p.11 | ORIGINAL | medium | **conflicting** | 〃 |
| 열전도도 F₂ | k | msbr-F2 | 1.1 | W/(m·K) | 〃 | p.11 | ORIGINAL | medium | unverified | 〃 |
| 열전도도 F₃ | k | msbr-F3 | 0.83 | W/(m·K) | 〃 | p.11 | ORIGINAL | medium | unverified | 〃 |
| 열전도도 F₄ | k | msbr-F4 | 0.70 | W/(m·K) | 〃 | p.11 | ORIGINAL | medium | unverified | 〃 |
| 열전도도 L₂B | k | msre-flush | 1.0 | W/(m·K) | 〃 | p.11 | ORIGINAL | high | **conflicting** | 〃 |
| 열전도도 C₁ | k | coolant | 0.52 | W/(m·K) | 〃 | p.11 | ORIGINAL | low | unverified | 〃 |
| 열전도도 C₂ | k | coolant | 0.51 | W/(m·K) | 〃 | p.11 | ORIGINAL | low | unverified | 〃 |
| 비열 F₁ (liq) | Cp | msbr-F1 | 1423.5 (0.34 cal/g·°C) | J/(kg·K) | 〃 | p.22 | ORIGINAL | high | unverified | 〃 |
| 비열 F₂ (liq) | Cp | msbr-F2 | 1632.9 (0.39) | J/(kg·K) | 〃 | p.22 | ORIGINAL | high | unverified | 〃 |
| 비열 F₃ (liq) | Cp | msbr-F3 | 1381.6 (0.33) | J/(kg·K) | 〃 | p.22 | ORIGINAL | high | unverified | 〃 |
| 비열 F₄ (liq) | Cp | msbr-F4 | 1381.6 (0.33) | J/(kg·K) | 〃 | p.22 | ORIGINAL | high | unverified | 〃 |
| 비열 L₂B (liq) | Cp | msre-flush | 2386.5 (0.57) | J/(kg·K) | 〃 | p.22 | ORIGINAL | high | unverified | 〃 |
| 비열 C₁ (liq) | Cp | coolant | 1507.2 (0.360) | J/(kg·K) | 〃 | p.22 | ORIGINAL | high | unverified | 〃 |
| 비열 C₂ (liq) | Cp | coolant | 1507.2 (0.36) | J/(kg·K) | 〃 | p.22 | ORIGINAL | high | unverified | 〃 |
| 밀도 F₁ | ρ | msbr-F1 | 3.628 − 6.6e-4·t | g/cm³ (t in °C) | 〃 | p.28 | ORIGINAL | high | unverified | 〃 |
| 밀도 F₂ | ρ | msbr-F2 | 3.153 − 5.8e-4·t | g/cm³ | 〃 | p.28 | ORIGINAL | high | unverified | 〃 |
| 밀도 F₃ | ρ | msbr-F3 | 3.687 − 6.5e-4·t | g/cm³ | 〃 | p.28 | ORIGINAL | high | unverified | 〃 |
| 밀도 F₄ | ρ | msbr-F4 | 3.644 − 6.3e-4·t | g/cm³ | 〃 | p.28 | ORIGINAL | high | unverified | 〃 |
| 밀도 L₂B | ρ | msre-flush | 2.214 − 4.2e-4·t | g/cm³ | 〃 | p.28 | ORIGINAL | high | unverified | 〃 |
| 밀도 C₁ | ρ | coolant | 2.27 − 7.4e-4·t | g/cm³ | 〃 | p.28 | ORIGINAL | medium | unverified | 〃 |
| 밀도 C₂ | ρ | coolant | 2.26 − 7.4e-4·t | g/cm³ | 〃 | p.28 | ORIGINAL | medium | unverified | 〃 |
| 염 조성 F₁–F₄, L₂B, C₁, C₂ | — | msbr/msre | 표 참조 | mol % | 〃 | p.2, p.46 | ORIGINAL | high | verified | 〃 |
| liquidus 온도 (7종) | T_liq | msbr/msre | — | °C | 〃 | p.2, p.46 | **UNKNOWN** | — | unverified | 〃 (OCR 행 정렬 붕괴, 추정 금지) |

### 코드 값의 provenance 재판정 (2026-09-03)

| Parameter | 코드 값 | 기존 표기 | **재판정 Provenance** | Verification | 근거 |
|---|---|---|---|---|---|
| 연료염 밀도 `d_T` | 2553.3 − 0.562·t kg/m³ | ORNL-TM-2316 | **UNKNOWN** | conflicting | TM-2316 p.28 표에 없음 |
| 연료염 비열 `cp_T` | 2009.66 J/(kg·K) | ORNL-TM-2316 | **UNKNOWN** | conflicting | TM-2316 p.22 표에 없음 |
| 연료염 점도 `eta_T` | 8.4e-5·exp(4340/T) Pa·s | ORNL-TM-2316 | ORIGINAL (**조성 외삽** — F₁값) | conflicting | TM-2316 p.8 F₁과 정확 일치 |
| 연료염 열전도도 `lambda_T` | 1.0 W/(m·K) | ORNL-TM-2316 | ORIGINAL (**조성 외삽**, F₁/L₂B 특정 불가) | conflicting | TM-2316 p.11 |

→ [[02_Wiki/issues/fuel-salt-property-provenance-composition-applicability]]
