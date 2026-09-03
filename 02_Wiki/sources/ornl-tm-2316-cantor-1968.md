---
type: source
systems: [msre, msbr]
status: ingested
date: 2026-09-03
updated: 2026-09-03
tags: [properties, fuel-salt, coolant-salt, flush-salt, ornl, primary-source]
---

# ORNL-TM-2316 — Physical Properties of Molten-Salt Reactor Fuel, Coolant, and Flush Salts

## 서지

| 항목 | 값 |
|---|---|
| 보고서 번호 | ORNL-TM-2316 |
| 제목 | Physical Properties of Molten-Salt Reactor Fuel, Coolant, and Flush Salts |
| 편집 | S. Cantor |
| 기고자 | S. Cantor, J. W. Cooke, A. S. Dworkin, G. D. Robbins, R. E. Thoma, G. M. Watson |
| 부서 | Reactor Chemistry Division, Oak Ridge National Laboratory |
| 계약 | W-7405-eng-26 |
| 발행 | **1968년 8월** (표지에서 확인) |
| 원본 | `01_Raw/literature/ORNL-TM-2316 Cantor ed 1968 - Physical Properties of Molten-Salt Reactor Fuel Coolant and Flush Salts.pdf` |
| SHA-256 | `72693db2cf2d1c32482ef09f1e26009a4f7f14da18babc661b96f18c824ad4ca` |
| MD5 | `e4dde36c67bbca11a1b6454045e1f856` |

## 이 보고서가 다루는 염 — **7종 전부** (p.2, p.46)

| Symbol | 분류 | LiF | BeF₂ | ThF₄ | UF₄ | 비고 |
|---|---|---|---|---|---|---|
| F₁ | Fuel-Breeder | 73 | 16 | 10.7 | 0.3 | mol % |
| F₂ | Fuel-Breeder | 72 | 21 | 6.7 | 0.3 | |
| F₃ | Fuel-Breeder | 68 | 20 | 11.7 | 0.3 | |
| F₄ | Fuel-Breeder | 63 | 25 | 11.7 | 0.3 | |
| L₂B | Flush Salt | 66 | 34 | — | — | "present MSRE coolant"로 표기 |
| C₁ | Coolant | NaBF₄ 92 / NaF 8 | | | | |
| C₂ | Coolant | NaBF₄ 100 | | | | |

> ⚠️ **핵심**: 이 7종 중 **MSRE 연료염(LiF-BeF₂-ZrF₄-UF₄, 65-29.17-5-0.83 mol%)은 없다.**
> F₁–F₄는 전부 **ThF₄를 함유한 MSBR single-region fuel-breeder 혼합물**이다.
> 서론(p.3)이 밝히듯 염 선정 기준은 "MSR Program의 최근 변화 — (a) 단일영역 개념,
> (b) 주로 NaBF₄인 냉각염 시험"이며, MSRE 연료염 재수록이 목적이 아니다.
>
> 보고서 전체에서 `ZrF₄`는 **본문 3곳(용해도 논의)에만** 등장하고 물성표에는 없다.

liquidus 온도 열은 스캔 OCR에서 행 정렬이 어긋나 **아직 확정하지 않았다** (원칙 2). 필요 시 p.2 이미지 재확인.

## 핵심 물성표 (전부 페이지 이미지로 직접 확인)

### 점도 (p.8, S. Cantor) — η in cP, T in K

| Salt | 식 | Uncertainty |
|---|---|---|
| **F₁** | **η = 0.084 exp(4340/T)** | ±25 % |
| F₂ | η = 0.072 exp(4370/T) | ±25 % |
| F₃ | η = 0.077 exp(4430/T) | ±25 % |
| F₄ | η = 0.0444 exp(5030/T) | ±25 % |
| L₂B | η = 0.116 exp(3755/T) | ±15 % |
| C₁, C₂ | η = 0.04 exp(3000/T) | ±50 % |

출처·방법: F₁–F₄는 LiF-BeF₂-UF₄계 점도(ref.1)와 LiF-BeF₂-ThF₄(71-16-13 mol%) 측정치로부터
**경험적으로 추정**했으며, ThF₄ 농도 효과가 UF₄와 같다고 **가정**했다. → 보고서 자체 기준으로도
F₁–F₄ 점도는 측정값이 아니라 추정값이다.

### 열전도도 (p.11, J. W. Cooke) — k in W/(cm·°C)

| Salt | k | Uncertainty | SI 환산 |
|---|---|---|---|
| **F₁** | **0.010** | ≥ ±25 % | **1.0 W/(m·K)** |
| F₂ | 0.011 | ≥ ±25 % | 1.1 |
| F₃ | 0.0083 | ≥ ±25 % | 0.83 |
| F₄ | 0.0070 | ≥ ±25 % | 0.70 |
| **L₂B** | **0.010** | ±10 % | **1.0** |
| C₁ | 0.0052 | ±50 % | 0.52 |
| C₂ | 0.0051 | ±50 % | 0.51 |

각주 a: 온도 의존성은 1차 근사로 무시 가능 (측정 불확도가 200 °C 구간의 온도 변화보다 큼).
각주 b: 네 연료염의 **상대 크기를 논하기 전에 Discussion의 caveat를 읽으라**고 명시.
F₁–F₄는 Rao 이론식(Turnbull 각색) `k = 11.9e-3·T_m^(1/2)·ρ_m^(2/3)/(M/n)^(7/6)`로 **추정**.

### 정압비열 (p.22, A. S. Dworkin) — Cp in cal/(g·°C)

| Salt | liquid | Uncertainty | SI 환산 (J/kg·K) |
|---|---|---|---|
| F₁ | 0.34 | ±4 % | 1423.5 |
| F₂ | 0.39 | ±4 % | 1632.9 |
| F₃ | 0.33 | ±4 % | 1381.6 |
| F₄ | 0.33 | ±4 % | 1381.6 |
| L₂B | 0.57 | ±3 % | 2386.5 |
| C₁ | 0.360 | ±2 % | 1507.2 |
| C₂ | 0.36 | ±2 % | 1507.2 |

F₁–F₄는 몰분율 가법성 가정 + LiF 16 / BeF₂ 24 / ThF₄ 44 cal·mol⁻¹·°C⁻¹ 기여로 **추정**.

### 액체 밀도 (p.28, S. Cantor) — ρ in g/cm³, t in °C

| Salt | 식 | Uncertainty |
|---|---|---|
| F₁ | ρ = 3.628 − 6.6×10⁻⁴ t | 3 % |
| F₂ | ρ = 3.153 − 5.8×10⁻⁴ t | 3 |
| F₃ | ρ = 3.687 − 6.5×10⁻⁴ t | 3 |
| F₄ | ρ = 3.644 − 6.3×10⁻⁴ t | 3 |
| L₂B | ρ = 2.214 − 4.2×10⁻⁴ t | 2 |
| C₁ | ρ = 2.27 − 7.4×10⁻⁴ t | 5 |
| C₂ | ρ = 2.26 − 7.4×10⁻⁴ t | 5 |

F₁–F₄는 몰부피 가법성으로 **추정** (LiF 13.411/14.142 cm³, BeF₂ 23.6/24.4, ThF₄·UF₄ 46.43/47.59 @600/800 °C).

## 우리 코드와의 대조 — **[[02_Wiki/issues/fuel-salt-property-provenance-composition-applicability]]**

MSRE_TRANSFORM `Media/FuelSalt/Utilities/`의 4개 함수는 전부 "Cantor, ORNL-TM-2316"을 출처로 명시한다.
원문과 1:1 대조한 결과:

| 코드 함수 | 코드 값 | TM-2316 원문 | 판정 |
|---|---|---|---|
| `eta_T` | `8.4e-5·exp(4340/T)` Pa·s ≡ 0.084 cP·exp(4340/T) | **F₁과 정확히 일치** (p.8) | 값 일치, **조성 불일치** |
| `lambda_T` | `1.0` W/(m·K) | F₁ 0.010 및 L₂B 0.010 W/(cm·°C)와 일치 (p.11) | 값 일치, **어느 염인지 특정 불가** |
| `cp_T` | `2009.66` J/kg·K ≡ 0.48 cal/(g·°C) | **표에 없음** (0.33/0.34/0.36/0.39/0.57만 존재) | **불일치** |
| `d_T` | `2553.3 − 0.562·t` kg/m³ ≡ 2.5533 − 5.62×10⁻⁴ t g/cm³ | **표에 없음** (2.214 ~ 3.687만 존재) | **불일치** |

즉 **4종 중 2종은 TM-2316에 존재하지 않고, 존재하는 2종도 MSRE 연료염이 아닌 MSBR 연료염(F₁)의 값**이다.
코드 주석이 `d_T`·`lambda_T`에 대해 "as used by the INL MSRE VTB/SAM fuel-salt equation of state"라고
덧붙인 점으로 보아, 실제 인용 경로는 TM-2316 직접이 아니라 **INL VTB/SAM 경유 재인용**일 가능성이 높다.
다만 INL 문서를 보유하지 않으므로 그 경로는 현재 **UNKNOWN**이며, 추정하지 않는다.

## 관련 페이지
- [[03_Data/msre/properties/ornl-tm-2316-salt-properties]] — 위 4개 표의 전체 값
- [[02_Wiki/issues/fuel-salt-property-provenance-composition-applicability]] — **open**
- [[02_Wiki/issues/fuel-salt-property-correlation-conflict]]
- [[02_Wiki/systems/msre/implementation/code-provenance-tags]]
- [[02_Wiki/systems/msre/implementation/msre-transform-model]]
