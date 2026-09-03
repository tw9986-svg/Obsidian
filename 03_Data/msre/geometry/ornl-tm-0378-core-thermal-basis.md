---
type: data
system: msre
category: geometry
symbol: 
tags: [core, graphite, temperature, power-distribution, historical]
last_updated: {{date:YYYY-MM-DD}}
---
<!-- 저장 위치: 03_Data/msre/geometry/ -->

# ORNL-TM-0378 (1962) 노심 열해석 기준값 — HISTORICAL_CALCULATION_INPUT

출처: [[02_Wiki/sources/ornl-tm-0378-engel-haubenreich-1962]]. **이 보고서의 값은 어느 것도 측정값이 아니다** — 유동 모델 + 핵 출력분포 + 열계산의 조합이다. 코드도 `Verification/ORNL0378/HistoricalData.mo`에서 같은 경고를 달고 현대 물성 패키지와 분리해 보관한다.

아래 값은 **코드 전사본과 원문 텍스트를 각각 대조**해 확인한 것이다.

## 발열 분배 — ⚠️ 측정값 아님

| Value | Unit | Source | Page/Fig | Provenance | Confidence | Model Usage | Verification |
|---|---|---|---|---|---|---|---|
| 흑연 발열분율 f_graphite = **0.06** (연료염 0.94), 연료 침투 0% 조건 | - | [[02_Wiki/sources/ornl-tm-0378-engel-haubenreich-1962]] | p.40 각주 | **ASSUMED** (원문: "it was assumed that 6% of the reactor power…", 근거는 C. W. Nestor의 **미출간** 감마/중성자 발열 계산) | high (원문 직접 확인) | `f_graphiteHeating` | **verified** — 원문 직접 확인 |

> 이 값이 **측정치가 아니라 가정치**라는 점이 확정됨. 기존에 Leandro→Carbajo→"historical calculations" 경로로 2차 인용되던 것의 실제 뿌리.

## 온도 경계 — 세 가지 서로 다른 정의 (혼용 금지)

| Value | 원 단위 | Unit | Source | Page | Provenance | Verification |
|---|---|---|---|---|---|---|
| Reactor inlet 908.1500 | 1175 °F | K | 〃 | Table 4 각주 c | ORIGINAL(1차) | verified |
| Reactor outlet 935.9278 | 1225 °F | K | 〃 | Table 4 각주 c | ORIGINAL(1차) | verified |
| **Main-core inlet 909.4278** | 1177.3 °F | K | 〃 | p.33 | ORIGINAL(1차) | verified — **노심 전용 모델이 써야 할 경계** |
| **Main-core outlet (mixed-mean) 933.5944** | 1220.8 °F | K | 〃 | p.33 | ORIGINAL(1차) | verified |
| Nuclear mean fuel temperature | 1213 °F | °F | 〃 | p.1 요약 | ORIGINAL(1차) | verified |
| dT_peripheral_below = 1.2778 / dT_peripheral_above = 2.3334 | | K | 〃 | (차이) | DERIVED | 진단용 전용 |

> **중요**: 지금까지 위키에 908/936 K로 기록해 온 값은 **reactor** in/out이며, **main core** 경계는 909.43/933.59 K로 다르다. 주변부(peripheral) 영역에서 아래 1.28 K, 위 2.33 K를 추가로 얻기 때문. 노심만 모델링할 때 908/936을 쓰면 이 차이만큼 계통 오차가 들어간다.

## 주 노심(main core) 형상 — ⚠️ 채널 수 1140이 아님

| Value | Unit | Source | Page | Provenance | Verification |
|---|---|---|---|---|---|
| **주 노심 채널 수 940** (전체 1140 중. 주변부 region 1/3/4 = 12/108/78) | - | 〃 | Table 2, region 2 (p.448행 본문에서도 "Region 2 has 940 fuel channels" 확인) | ORIGINAL(1차) | **verified** |
| 주 노심 연료 체적분율 0.224 | - | 〃 | Table 2, region 2 | ORIGINAL(1차) | verified |
| 주 노심 등가 외반경 24.76 in = 0.6289 m | m | 〃 | Table 2, region 2 | ORIGINAL(1차) | verified |
| 주 노심 상단 z = 64.59 in (해석 영역 0 ≤ z ≤ 64.6 in) | in | 〃 | p.19, p.32 | ORIGINAL(1차) | unverified (코드 전사 기준) |
| V_fuel,mainCore = 0.577707 m³ (35,253.8 in³) | m3 | 〃 | Table 3 (regions N+M+J+L) | DERIVED_FROM_ORNL | unverified |
| V_graphite,mainCore = 1.981812 m³ (120,937.6 in³) | m3 | 〃 | Table 3 | DERIVED_FROM_ORNL | unverified |
| Q_mainCore = 8706 kW = 10 MW의 87.06% (J+L+M+N = 8287+159+192+68 kW) | kW | 〃 | Table 4 | DERIVED_FROM_ORNL | unverified |

## 축방향 출력 형상 B(z)

| Value | Unit | Source | Page | Provenance |
|---|---|---|---|---|
| 형상 인자 주기 77.7 in, 오프셋 4.36 in | in | 〃 | Fig. 8 / Eq. (4)–(6) | ORIGINAL(1차, 코드 전사) |
| axial peak-to-average = **1.3585** (0 ≤ z ≤ 64.6 in의 B(z)에서 계산) | - | 〃 | 〃 | DERIVED_FROM_ORNL — **π/2가 아님** (π/2는 양단에서 sine이 0이 되는 p.35의 이상화 균일노심 값) |

## 1962년 vintage 물성 — ⚠️ 현대값과 다름

| Value | 원 단위 | SI | Source | Page | Provenance |
|---|---|---|---|---|---|
| 연료염 열전도도 k_f | 3.21 Btu/hr·ft·°F | 5.5557 W/m·K | 〃 | p.40 각주 | **ASSUMED** (원문: "were assumed to be 3.21 and 13…") |
| 흑연 열전도도 k_g | 13 Btu/hr·ft·°F | 22.4996 W/m·K | 〃 | p.40 각주 | **ASSUMED** |

> **해소된 우려**: [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]]에서 "열전도도 5.5 W/m·K가 현대 측정값과 다를 수 있다"고 플래그했던 건이 확인됐다. 코드 주석에 따르면 production 패키지는 **보정된 1.0 W/(m·K)** 를 쓰며, 3.21 Btu 값은 1962년 계산 재현 전용이다. 두 값을 섞지 말 것.

## 검증 목표값

| Value | 원 단위 | SI | Source | Page | Provenance |
|---|---|---|---|---|---|
| 최대 국부 흑연–연료 온도차 (연료침투 0%) | 62.5 °F | 34.7222 K | 〃 | Table 5 | ORIGINAL(1차) — **평균이 아니라 최대 국부값** |

## 역사적 방정식용 등가 형상 (Eq. 13 이하)

| Value | Unit | Source | Page | 주의 |
|---|---|---|---|---|
| 연료채널 등가반경 r_w = 0.0095667 (= 0.37664 in, **유동면적 등가**) | m | 〃 | p.38 | **수력반경이 아님.** production 모델의 Dh/2 = 0.0079253 m로 20.71% 작고, r_w는 Eq.(13)에 **제곱으로** 들어감 |
| 흑연 stringer 등가반경 r_s = 0.9935 in | in | 〃 | p.39 | 단면적 등가 원기둥 |
| 슬래브 근사 반두께 0.8 in | in | 〃 | p.39 | |
| S/V: 등가원기둥 2.01 / 실제 1.84 / 슬래브 1.25 | 1/in | 〃 | p.39 | 1.84가 보간 대상 |

## 관련 페이지
- [[02_Wiki/sources/ornl-tm-0378-engel-haubenreich-1962]]
- [[02_Wiki/systems/msre/components/core]]
- [[02_Wiki/systems/msre/implementation/msre-transform-model]]
- [[03_Data/registry]]
