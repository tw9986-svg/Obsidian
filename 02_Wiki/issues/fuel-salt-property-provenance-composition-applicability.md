---
type: issue
status: open
priority: critical
date: 2026-09-03
updated: 2026-09-03
systems: [msre]
tags: [properties, fuel-salt, provenance, composition, cantor, ornl-tm-2316]
---

# Fuel-salt property provenance / composition applicability

## 요약

MSRE_TRANSFORM의 연료염 물성 4종은 코드 주석에서 전부 **"LiF-BeF₂-ZrF₄-UF₄ (65.0-29.17-5.0-0.83 mol%),
from S. Cantor, ORNL-TM-2316 (1968)"** 로 출처가 명시되어 있다.
2026-09-03 ORNL-TM-2316 원본을 확보해 **페이지 이미지로 4개 물성표 전부를 직접 대조**한 결과,
이 귀속이 성립하지 않는다.

## 확인된 사실 (전부 원문 페이지 이미지 확인)

### (1) ORNL-TM-2316에는 MSRE 연료염이 없다

보고서가 다루는 염은 7종뿐이며(p.2, p.46), **ZrF₄를 함유한 염은 물성표에 하나도 없다**:

| Symbol | LiF | BeF₂ | ThF₄ | UF₄ |
|---|---|---|---|---|
| F₁ | 73 | 16 | 10.7 | 0.3 |
| F₂ | 72 | 21 | 6.7 | 0.3 |
| F₃ | 68 | 20 | 11.7 | 0.3 |
| F₄ | 63 | 25 | 11.7 | 0.3 |
| L₂B (flush) | 66 | 34 | — | — |
| C₁ | NaBF₄ 92 / NaF 8 | | | |
| C₂ | NaBF₄ 100 | | | |

F₁–F₄는 전부 **ThF₄ 함유 MSBR single-region fuel-breeder 염**이다. 서론(p.3)이 염 선정 기준을
"단일영역 개념 + NaBF₄ 냉각염 시험"이라고 명시한다. MSRE 연료염 재수록이 목적이 아니다.

### (2) 4종 중 2종은 원문에 **존재하지 않는다**

| 코드 함수 | 코드 값 | TM-2316 원문 | 판정 |
|---|---|---|---|
| `d_T` | `2553.3 − 0.562·(T−273.15)` kg/m³ ≡ ρ = 2.5533 − 5.62×10⁻⁴ t g/cm³ | p.28 밀도표는 3.628 / 3.153 / 3.687 / 3.644 / 2.214 / 2.27 / 2.26 뿐 — **2.5533 없음** | **출처 아님** |
| `cp_T` | `2009.66` J/kg·K ≡ 0.48 cal/(g·°C) | p.22 액체 Cp는 0.34 / 0.39 / 0.33 / 0.33 / 0.57 / 0.360 / 0.36 뿐 — **0.48 없음** | **출처 아님** |

### (3) 나머지 2종은 값은 맞지만 **다른 염의 값**이다

| 코드 함수 | 코드 값 | TM-2316 원문 | 판정 |
|---|---|---|---|
| `eta_T` | `8.4e-5·exp(4340/T)` Pa·s ≡ 0.084 cP·exp(4340/T) | p.8 **F₁ = 0.084 exp(4340/T)** — 정확 일치 | 값 일치 / **조성 불일치** (F₁ = LiF-BeF₂-ThF₄-UF₄ 73-16-10.7-0.3) |
| `lambda_T` | `1.0` W/(m·K) | p.11 **F₁ 0.010** 및 **L₂B 0.010** W/(cm·°C) — 둘 다 1.0 W/m·K | 값 일치 / **어느 염인지 특정 불가**, 어느 쪽이든 MSRE 연료염 아님 |

### (4) 원문 기준으로도 F₁–F₄ 물성은 측정값이 아니라 **추정값**이다

- 점도: LiF-BeF₂-UF₄계 + LiF-BeF₂-ThF₄(71-16-13) 측정치로부터 경험적 추정, ThF₄ 효과 = UF₄ 효과라 **가정**. ±25 %
- 열전도도: Rao 이론식(Turnbull 각색)으로 추정. ≥±25 %. 원문 각주 b가 "네 연료염의 상대 크기를 논하기 전에 Discussion의 caveat를 읽으라"고 경고
- 비열: 몰분율 가법성 가정. ±4 %
- 밀도: 몰부피 가법성. ±3 %

### (5) 실제 인용 경로는 TM-2316 직접이 아닐 가능성이 높다

`d_T`·`lambda_T`·`eta_T` 주석은 "as used by the **INL MSRE VTB/SAM fuel-salt equation of state**"를
함께 적고 있다. 즉 코드 → INL VTB/SAM → (INL이 Cantor로 귀속) 이라는 **재인용 사슬**로 보인다.
**INL VTB/SAM 문서를 보유하지 않으므로 이 경로는 UNKNOWN이며, 추정하지 않는다.**

## 영향 범위

`d_T`가 활성 밀도이므로 아래 값이 전부 이 미확정 상관식 위에 있다:

- `Data/Geometry.mo`: `d_fuel_ref` (908 K에서 2196.5143 kg/m³), loop 인벤토리, `V_dot_nominal`
- `Verification/Properties_TransitTime.mo`: τ_core / τ_loop / τ_system 전부
- `Components/FuelPump_Dynamics.mo`: 수력 토크 236.11 N·m, 축동력 22.95 kW, 관성 7.775 kg·m²
- `Verification/Analytic_DriftReactivity.mo`: drift reactivity (τ에 직접 의존)

→ [[02_Wiki/issues/jeong-transit-time-value-mismatch]] 및
[[02_Wiki/issues/fuel-salt-property-correlation-conflict]]와 직접 연결된다.

## 판정

- 코드의 `eta_T`, `lambda_T` → provenance **ORIGINAL (조성 외삽)**, Verification **conflicting**
- 코드의 `d_T`, `cp_T` → provenance **UNKNOWN** (TM-2316이 출처가 아님이 확정됨)
- **원칙 2에 따라 어떤 값도 임의로 교체하지 않는다.**

## 해결 방향

- [ ] **INL MSRE VTB/SAM fuel-salt equation of state 문서 확보** — `d_T`·`cp_T`의 실제 1차 출처를 여기서 찾을 가능성이 가장 높다
- [ ] MSRE 연료염(LiF-BeF₂-ZrF₄-UF₄)의 1차 물성 출처 확정. 보유 중인 **ORNL-TM-728(Robertson 1965)** 이 설계 물성표를 갖고 있으므로 우선 대조 → [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]]
- [ ] `cp_T` 0.48 cal/(g·°C)의 출처 추적. MSRE 설계값 0.47 cal/(g·°C) 계열과의 관계 확인
- [ ] 확정 후 `Media/FuelSalt/Utilities/*.mo`의 출처 주석을 실제 출처로 정정 (코드 변경은 사용자 승인 후)
- [ ] 조성 외삽이 불가피하다면, provenance를 `ASSUMED`로 격하하고 근거(왜 F₁ 값을 MSRE 염에 쓰는가)를 명시

## 관련 페이지
- [[02_Wiki/sources/ornl-tm-2316-cantor-1968]]
- [[03_Data/msre/properties/ornl-tm-2316-salt-properties]]
- [[02_Wiki/issues/fuel-salt-property-correlation-conflict]]
- [[02_Wiki/issues/jeong-transit-time-value-mismatch]]
- [[02_Wiki/systems/msre/implementation/code-provenance-tags]]
