---
type: data
system: msre
category: properties
symbol: "rho, mu, cp, k"
tags: [fuel-salt, coolant-salt, flibe, density, viscosity, specific-heat, thermal-conductivity]
last_updated: {{date:YYYY-MM-DD}}
---
<!-- 저장 위치: 03_Data/msre/properties/ -->

# MSRE 연료염·냉각염 물성 (Robertson 1965, ORNL-TM-728 PDF p.38)

**1차 출처 확보 완료.** 최초에는 Leandro et al.(2019) Table 4·5(2차 인용, SI 단위)로만 기록했으나, [[02_Wiki/sources/ornl-tm-728-robertson-1965]]의 원 표(영국단위, 1200 °F 기준)를 확보해 provenance를 1차로 격상하고, Leandro에 없던 **점도·열전도도·liquidus 온도·냉각염 물성**을 추가했다.

Leandro Table 5의 SI 값은 이 표의 정확한 단위환산임을 검증함 (아래 "Provenance 근거" 참조).

## 값 — 원 단위 (ORNL-TM-728 PDF p.38, 1200 °F = 922 K 기준)

| Property | Fuel salt 1 (MSRE 1) | Fuel salt 2 (MSRE 2) | Fuel salt 3 (MSRE 3) | Coolant salt (2차 계통) |
|---|---|---|---|---|
| 조성 LiF/BeF₂/ZrF₄/ThF₄/UF₄ (mol%) | 70 / 23.6 / 5 / 1 / 0.4 | 66.8 / 29 / 4 / 0 / 0.2 | 65 / 29.1 / 5 / 0 / 0.9 | 66 / 34 / – / – / – |
| Density (lb/ft³) @1200 °F | 140 | 130 | 134 | 120 (@1060 °F) |
| Viscosity (lb/ft-hr) | 18 | 17 | 20 | 24 |
| Heat Capacity (Btu/lb-°F) | 0.45 | 0.48 | 0.47 | 0.53 |
| Thermal Conductivity (Btu/hr·ft·°F) | 3.21 | 3.2 | 3.2 | 3.5 |
| Liquidus Temperature (°F) | 840 | 840 | 840 | 850 |

## 값 — SI 환산

| Value | Unit | Source | Page/Fig | Provenance | Confidence | Model Usage | Verification |
|---|---|---|---|---|---|---|---|
| MSRE 1: ρ=2242.6, μ=0.00744, cp=1884, k=5.56 | kg/m3, kg/m-s, J/kg-K, W/m-K | [[02_Wiki/sources/ornl-tm-728-robertson-1965]] | PDF p.38 | ORIGINAL (1차) | high | | verified (Leandro 2019 Table 5와 일치) |
| MSRE 2: ρ=2082.4, μ=0.00703, cp=2010, k=5.54 | 〃 | 〃 | PDF p.38 | ORIGINAL (1차) | high | | verified |
| MSRE 3: ρ=2146.5, μ=0.00827, cp=1968, k=5.54 | 〃 | 〃 | PDF p.38 | ORIGINAL (1차) | high | | verified |
| Coolant salt (LiF-BeF₂ 66-34, @1060 °F=844 K): ρ=1922.2, μ=0.00992, cp=2219, k=6.06 | 〃 | 〃 | PDF p.38 | ORIGINAL (1차) | high | 2차 계통 | unverified |
| Liquidus: 연료염 840 °F = 722.0 K, 냉각염 850 °F = 727.6 K | K | 〃 | PDF p.38 | ORIGINAL (1차) | high | | unverified |
| SAM 내장 FLiBe EOS (비교용, MSRE 실제 염 아님): ρ=1963, μ=0.00661, cp=2416 | kg/m3, kg/m-s, J/kg-K | [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]] | Table 5 | SOFTWARE_DEFAULT | high | SAM 전용 | unverified |

## Provenance 근거
- 원 표는 ORNL-TM-728 (Robertson 1965) PDF p.38의 설계 데이터 표. 1200 °F(=922.0 K) 단일 온도의 상수값이며 **온도 함수 상관식이 아님**.
- Leandro et al.(2019) Table 5와의 환산 검증 (변환계수: lb/ft³×16.0185, lb/ft-hr×4.1338e-4, Btu/lb-°F×4186.8):
  - 140 lb/ft³ → 2242.6 vs Leandro 2243 ✓ / 130 → 2082.4 vs 2082 ✓ / 134 → 2146.5 vs 2146 ✓
  - 18 lb/ft-hr → 0.007441 vs 0.00744 ✓ / 17 → 0.007027 vs 0.00703 ✓ / 20 → 0.008268 vs 0.00827 ✓
  - 0.45 Btu/lb-°F → 1884.1 vs 1883 ✓ / 0.48 → 2009.7 vs 2008 ✓ / 0.47 → 1967.8 vs 1966 ✓
  → Leandro Table 5는 이 1차 표의 단위환산임이 확인됨. 두 소스 간 **충돌 없음**.
- 열전도도·liquidus·냉각염 물성은 Leandro에 없던 항목으로 이번에 1차에서 신규 추가.

## ⚠️ 모델이 실제 쓰는 값은 이 표가 아니다 (2026-09-02 추가)

Git 저장소 HEAD의 `Media/MSRE_Properties.mo` 대조 결과, [[02_Wiki/systems/msre/implementation/msre-transform-model]]은 아래 **온도의존 상관식**을 쓴다. 위의 Robertson 1965 상수표와는 다른 값이다.

| 코드 함수 | 상태 | 식 | @922 K | 출처 |
|---|---|---|---:|---|
| `d_Cantor` | **ACTIVE** | ρ = 2553.3 − 0.562·T[°C] | 2188.65 kg/m³ | ORNL-TM-2316, Cantor (1968) |
| `eta_Cantor` | **ACTIVE** | μ = 8.4e-5·exp(4340/T[K]) | 0.0093025 Pa·s | 〃 |
| `d_Compere` | REFERENCE ONLY | ρ = 2575.0 − 0.513·T[°C] | 2242.1 kg/m³ | ORNL-TM-4865, Compere et al. (1975) |

- Robertson(2242.6) ≈ Compere(2242.1) 이지만, **ACTIVE인 Cantor는 −2.4%**.
- 점도는 Robertson 0.00744 vs Cantor 0.0093025 Pa·s로 **+25%** 차이.
- 코드 주석: `Data.Geometry` 체적은 **Compere 기준으로 유도**되었으나 매질은 Cantor로 구동됨 ("Do not mix"). → inventory·전이시간에 계통 편차 가능.

**세 계열 값을 모두 보존하며 어느 것도 덮어쓰지 않는다.** 상세·미해결 사항: [[02_Wiki/issues/fuel-salt-property-correlation-conflict]].

Cantor 값은 코드 주석이 유일 근거이므로 provenance는 ORIGINAL(2차 인용), Verification은 `conflicting`.

## 값 간 불일치 / 논의
- **열전도도 3.2 Btu/hr·ft·°F ≈ 5.5 W/m-K — 우려 해소(2026-09-02)**: 같은 값이 [[02_Wiki/sources/ornl-tm-0378-engel-haubenreich-1962]] p.40 각주에서 "**assumed** to be 3.21"로 명시되어 **가정치**임이 확인됐고, 코드 주석에 따르면 production 패키지는 **보정된 1.0 W/(m·K)** 를 사용한다. 1962/1965 vintage 값은 역사적 계산 재현 전용이며 **현대 모델에 섞지 말 것**. → [[03_Data/msre/geometry/ornl-tm-0378-core-thermal-basis]]
- 핵계산용 nominal 조성(TM-730: 70-23-5-1-1 mol%)과 TM-728의 70-23.6-5-1-0.4가 미세하게 다름 — 목적별 조성 차이로 보이나 **단정하지 않음**.

## 어디에 쓰이나
[[02_Wiki/systems/msre/components/core]], [[02_Wiki/systems/msre/components/primary-loop]]. 향후 canonical 코드의 `Media/MSRE_Properties.mo`·`Media/FuelSalt/Utilities/{d_T,cp_T,eta_T,lambda_T}.mo` 구현값과 대조 예정 ([[02_Wiki/systems/msre/implementation/msre-transform-model]]) — **아직 미대조**.

## 관련 페이지
- [[02_Wiki/sources/ornl-tm-728-robertson-1965]]
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
- [[03_Data/registry]]
