---
type: data
system: msre
status: active
date: 2026-09-03
updated: 2026-09-03
tags: [properties, fuel-salt, coolant-salt, flush-salt, ornl-tm-2316, primary-source]
---

# ORNL-TM-2316 (Cantor ed., 1968) — 염 물성 전체 값

Source: [[02_Wiki/sources/ornl-tm-2316-cantor-1968]] → 원본 `01_Raw/literature/ORNL-TM-2316 Cantor ed 1968 - ….pdf`

> ⚠️ **적용 범위 경고**: 이 보고서의 7종 염 중 **MSRE 연료염(LiF-BeF₂-ZrF₄-UF₄ 65-29.17-5-0.83 mol%)은 없다.**
> F₁–F₄는 ThF₄를 함유한 MSBR single-region fuel-breeder 염이다. 아래 값을 MSRE 연료염에
> 그대로 쓰는 것은 **조성 외삽**이며, 그 자체가 [[02_Wiki/issues/fuel-salt-property-provenance-composition-applicability]]의 대상이다.

## 염 조성 (p.2 / p.46)

| Symbol | 분류 | LiF | BeF₂ | ThF₄ | UF₄ | Provenance |
|---|---|---|---|---|---|---|
| F₁ | Fuel-Breeder | 73 | 16 | 10.7 | 0.3 | ORIGINAL |
| F₂ | Fuel-Breeder | 72 | 21 | 6.7 | 0.3 | ORIGINAL |
| F₃ | Fuel-Breeder | 68 | 20 | 11.7 | 0.3 | ORIGINAL |
| F₄ | Fuel-Breeder | 63 | 25 | 11.7 | 0.3 | ORIGINAL |
| L₂B | Flush Salt ("present MSRE coolant") | 66 | 34 | — | — | ORIGINAL |
| C₁ | Coolant | NaBF₄ 92 / NaF 8 | | | | ORIGINAL |
| C₂ | Coolant | NaBF₄ 100 | | | | ORIGINAL |

liquidus 온도 열은 스캔 OCR 행 정렬이 어긋나 **UNKNOWN**으로 둔다 (추정 금지).

## 표준 항목 테이블

Source 열은 전부 [[02_Wiki/sources/ornl-tm-2316-cantor-1968]].

| Parameter | Symbol | System | Value | Unit | Page/Fig | Provenance | Confidence | Model Usage | Verification |
|---|---|---|---|---|---|---|---|---|---|
| 점도 F₁ | η | MSBR-F₁ | 0.084·exp(4340/T) | cP (T in K) | p.8 | ORIGINAL (보고서 내부는 추정, ±25 %) | high | **[[02_Wiki/systems/msre/implementation/msre-transform-model]] `eta_T` (조성 불일치 상태로 사용 중)** | conflicting |
| 점도 F₂ | η | MSBR-F₂ | 0.072·exp(4370/T) | cP | p.8 | ORIGINAL | high | — | unverified |
| 점도 F₃ | η | MSBR-F₃ | 0.077·exp(4430/T) | cP | p.8 | ORIGINAL | high | — | unverified |
| 점도 F₄ | η | MSBR-F₄ | 0.0444·exp(5030/T) | cP | p.8 | ORIGINAL | high | — | unverified |
| 점도 L₂B | η | MSRE flush | 0.116·exp(3755/T) | cP | p.8 | ORIGINAL (±15 %, 측정) | high | — | unverified |
| 점도 C₁·C₂ | η | coolant | 0.04·exp(3000/T) | cP | p.8 | ORIGINAL (±50 %) | medium | — | unverified |
| 열전도도 F₁ | k | MSBR-F₁ | 0.010 → **1.0** | W/(cm·°C) → W/(m·K) | p.11 | ORIGINAL (Rao 이론식 추정, ≥±25 %) | medium | **`lambda_T` (조성 불일치)** | conflicting |
| 열전도도 F₂ | k | MSBR-F₂ | 0.011 → 1.1 | 〃 | p.11 | ORIGINAL | medium | — | unverified |
| 열전도도 F₃ | k | MSBR-F₃ | 0.0083 → 0.83 | 〃 | p.11 | ORIGINAL | medium | — | unverified |
| 열전도도 F₄ | k | MSBR-F₄ | 0.0070 → 0.70 | 〃 | p.11 | ORIGINAL | medium | — | unverified |
| 열전도도 L₂B | k | MSRE flush | 0.010 → **1.0** | 〃 | p.11 | ORIGINAL (±10 %) | high | **`lambda_T` 후보 (F₁과 값 동일, 특정 불가)** | conflicting |
| 열전도도 C₁ | k | coolant | 0.0052 → 0.52 | 〃 | p.11 | ORIGINAL (±50 %) | low | — | unverified |
| 열전도도 C₂ | k | coolant | 0.0051 → 0.51 | 〃 | p.11 | ORIGINAL (±50 %) | low | — | unverified |
| 비열 F₁ (liq) | Cp | MSBR-F₁ | 0.34 → 1423.5 | cal/(g·°C) → J/(kg·K) | p.22 | ORIGINAL (가법성 추정, ±4 %) | high | — | unverified |
| 비열 F₂ (liq) | Cp | MSBR-F₂ | 0.39 → 1632.9 | 〃 | p.22 | ORIGINAL | high | — | unverified |
| 비열 F₃ (liq) | Cp | MSBR-F₃ | 0.33 → 1381.6 | 〃 | p.22 | ORIGINAL | high | — | unverified |
| 비열 F₄ (liq) | Cp | MSBR-F₄ | 0.33 → 1381.6 | 〃 | p.22 | ORIGINAL | high | — | unverified |
| 비열 L₂B (liq) | Cp | MSRE flush | 0.57 → 2386.5 | 〃 | p.22 | ORIGINAL (측정 2건 평균, ±3 %) | high | — | unverified |
| 비열 C₁ (liq) | Cp | coolant | 0.360 → 1507.2 | 〃 | p.22 | ORIGINAL (±2 %) | high | — | unverified |
| 비열 C₂ (liq) | Cp | coolant | 0.36 → 1507.2 | 〃 | p.22 | ORIGINAL (±2 %) | high | — | unverified |
| 밀도 F₁ | ρ | MSBR-F₁ | 3.628 − 6.6e-4·t | g/cm³ (t in °C) | p.28 | ORIGINAL (몰부피 가법성, ±3 %) | high | — | unverified |
| 밀도 F₂ | ρ | MSBR-F₂ | 3.153 − 5.8e-4·t | 〃 | p.28 | ORIGINAL | high | — | unverified |
| 밀도 F₃ | ρ | MSBR-F₃ | 3.687 − 6.5e-4·t | 〃 | p.28 | ORIGINAL | high | — | unverified |
| 밀도 F₄ | ρ | MSBR-F₄ | 3.644 − 6.3e-4·t | 〃 | p.28 | ORIGINAL | high | — | unverified |
| 밀도 L₂B | ρ | MSRE flush | 2.214 − 4.2e-4·t | 〃 | p.28 | ORIGINAL (±2 %) | high | — | unverified |
| 밀도 C₁ | ρ | coolant | 2.27 − 7.4e-4·t | 〃 | p.28 | ORIGINAL (±5 %) | medium | — | unverified |
| 밀도 C₂ | ρ | coolant | 2.26 − 7.4e-4·t | 〃 | p.28 | ORIGINAL (±5 %) | medium | — | unverified |

## 코드 값과의 대조 결과

| 코드 함수 | 코드 값 | TM-2316 대응 | 판정 |
|---|---|---|---|
| `eta_T` | 8.4e-5·exp(4340/T) Pa·s | **F₁ (p.8) 정확 일치** | 값 일치 / **조성 불일치** |
| `lambda_T` | 1.0 W/(m·K) | F₁ 또는 L₂B (둘 다 0.010 W/cm·°C) | 값 일치 / **염 특정 불가** |
| `cp_T` | 2009.66 J/kg·K = 0.48 cal/(g·°C) | **TM-2316 표에 0.48 없음** | **출처 아님 → UNKNOWN** |
| `d_T` | 2553.3 − 0.562·t kg/m³ = 2.5533 − 5.62e-4·t g/cm³ | **TM-2316 표에 없음** | **출처 아님 → UNKNOWN** |

## 관련 페이지
- [[02_Wiki/sources/ornl-tm-2316-cantor-1968]]
- [[02_Wiki/issues/fuel-salt-property-provenance-composition-applicability]]
- [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]]
- [[03_Data/registry]]
