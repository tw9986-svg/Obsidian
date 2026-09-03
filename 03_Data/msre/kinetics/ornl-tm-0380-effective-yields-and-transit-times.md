---
type: data
system: msre
category: kinetics
symbol: "beta_eff, tau_c, tau_x"
tags: [delayed-neutron, beta-eff, transit-time, circulating, primary-source]
last_updated: {{date:YYYY-MM-DD}}
---
<!-- 저장 위치: 03_Data/msre/kinetics/ -->

# ORNL-TM-0380 (1962) — 유효 지연중성자 수율 및 연료 전이시간 (1차)

출처: [[02_Wiki/sources/ornl-tm-0380-effective-delayed-neutron-yields]]. 값은 **페이지 이미지로 직접 판독**해 확인 (OCR 품질이 낮아 텍스트 추출만으로는 신뢰 불가).

## Table 2 — MSRE 총 지연중성자 분율 (report p.17)

| Quantity | 기호 | Value | Source | Page | Provenance | Verification |
|---|---|---:|---|---|---|---|
| Actual yield | Σβ_i | **0.006405** | [[02_Wiki/sources/ornl-tm-0380-effective-delayed-neutron-yields]] | Table 2, p.17 | ORIGINAL(1차) | verified (이미지 판독) |
| Effective fraction, **static** | Σβ*_is | **0.006661** | 〃 | 〃 | ORIGINAL(1차) | verified |
| Fraction emitted in core, circulating | Σβ_iθ_i | **0.003942** | 〃 | 〃 | ORIGINAL(1차) | verified |
| Effective fraction, **circulating** | Σβ*_i | **0.003617** | 〃 | 〃 | ORIGINAL(1차) | verified |

원 지연중성자 수율·반감기는 **Keepin, Wimett & Zeigler**의 U-235 열중성자 분열 데이터를 사용 (report p.21, Table A-1).

### ⚠️ 모델 값과의 차이 (덮어쓰지 않고 병기)

| | ORNL-TM-0380 (1962, 1차) | 모델/Jeong 계열 |
|---|---:|---:|
| static β_eff | 0.006661 | 0.006781 (Jeong Table 1 합, 원출처 Hanusek & Juan 2021) |
| circulating β_eff | 0.003617 | ≈0.0045 (코드 `Analytic_DriftReactivity` assert 값) |

static은 1.8% 차이지만 **circulating은 24% 차이**다. 두 값은 서로 다른 핵데이터 세트(1962 Keepin vs 2021 Hanusek & Juan)와 서로 다른 전이시간·중요도 가정에서 나온 것이므로 단순 우열 판정 불가 → [[02_Wiki/issues/beta-eff-circulating-discrepancy]].

## MSRE 전이시간 — 1차 계산 (report p.21)

| Quantity | Value | 단위 | Provenance |
|---|---:|---|---|
| 노심 등가반경 R (INOR-8 can 내반경) | 27.75 in = 0.7049 m | m | ORIGINAL(1차) |
| 축방향 분열분포 sin(πz/H)의 **H = 77.7 in** | 1.9736 m | m | ORIGINAL(1차) — 코드 `z_shape_period_in=77.7`과 일치 |
| 최장 흑연 stringer 68.9 in / 채널 영역 62 in | | in | ORIGINAL(1차) |
| 단순화된 "core" 높이 H (흑연 최상단~최하단) | 68.9 in | in | ORIGINAL(1차) |
| 그 "core" 총 체적 96.4 ft³ 중 연료 **25.0 ft³** → f = **0.259** | 0.708 m³ | m3 | ORIGINAL(1차) |
| **노심 체류시간 t_c (1200 gpm)** | **9.37 s** | s | ORIGINAL(1차) |
| 노심 유속 H/t_c | 0.61 ft/s | ft/s | DERIVED(원문) |
| **총 순환 연료 체적** | **69.1 ft³ = 1.9567 m³** | m3 | ORIGINAL(1차) |
| **총 순환 시간 (system)** | **25.82 s** | s | ORIGINAL(1차) |
| **외부 루프 시간 t_x = 25.82 − 9.37** | **16.45 s** | s | DERIVED(원문) |

> 채널 유속 참고: 3/4 이상의 채널에서 0.60 ft/s이나, 중심 채널은 그 **3배 이상**이다 (반경방향 유속 편차가 큼).

## 🔍 전이시간 벤치마크 차이의 정량적 원인 (분석)

| 출처 | τ_core | τ_external | τ_system | 순환 연료 체적 |
|---|---:|---:|---:|---:|
| **ORNL-TM-0380 (1962, 1차 계산)** | 9.37 | 16.45 | **25.82** | **1.9567 m³** |
| MSRE 실험 보고값 (Jeong이 인용 [27,34]) | — | — | 25.2 | — |
| Jeong/MARS (2026) | 9.56 | 16.14 | 25.63 (사내문서엔 25.70) | — |
| **TRANSFORM B0 (Dymola)** | 9.96316 | 17.6879 | **27.651** | **2.0965 m³** |

**체적비 2.0965 / 1.9567 = 1.0714 (+7.14%)**, **전이시간비 27.651 / 25.82 = 1.0709 (+7.09%)** — 두 비가 0.05%p 이내로 일치한다.

τ = V/Q̇ 이고 유량은 양쪽 모두 정격이므로, **TRANSFORM의 전이시간이 긴 이유는 순환 연료 체적이 ORNL 1차 값보다 7.1% 크기 때문**이라는 설명이 산술적으로 성립한다. 이는 [[02_Wiki/issues/jeong-transit-time-value-mismatch]]와 [[02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars]]의 +7.6% 차이에 대한 유력한 1차 근거다.

⚠️ 단, 이는 **산술적 정합성일 뿐 인과 확정이 아니다**. 확정하려면: (a) ORNL의 69.1 ft³와 모델 `V_loop`의 **경계 정의가 같은지**(expansion tank·pump bowl·drain line 포함 여부), (b) 모델 체적이 Compere 밀도 기준으로 유도된 점([[02_Wiki/issues/fuel-salt-property-correlation-conflict]])이 어떻게 얽히는지 확인해야 한다. 그 전까지 **원인 미확정**으로 둔다.

## 관련 페이지
- [[02_Wiki/sources/ornl-tm-0380-effective-delayed-neutron-yields]]
- [[03_Data/msre/kinetics/delayed-neutron-parameters]]
- [[03_Data/msre/benchmark/transform-b0-vs-jeong-mars]]
- [[03_Data/registry]]
