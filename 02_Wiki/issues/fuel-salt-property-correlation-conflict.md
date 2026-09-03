---
type: issue
status: open
date: 2026-09-02
updated: 2026-09-03
systems: [msre]
tags: [properties, conflict, provenance, density, viscosity]
---

# ⚠️ 연료염 물성: 설계값(1965) vs 모델이 실제 쓰는 상관식(1968/1975) 충돌

## 문제 설명
지금까지 위키에 기록된 연료염 물성은 **ORNL-TM-728 (Robertson 1965)의 1200 °F 상수값**이었다. 그러나 실제 [[02_Wiki/systems/msre/implementation/msre-transform-model]] 코드(`Media/MSRE_Properties.mo`, HEAD 기준)는 **다른 출처의 온도의존 상관식**을 쓴다.

### 밀도 @922 K (=1200 °F) 비교

| 출처 | 식 / 값 | 922 K에서 | 성격 |
|---|---|---:|---|
| **ORNL-TM-728 Robertson (1965)** MSRE 1 | 140 lb/ft³ (상수) | **2242.6** kg/m³ | 설계보고서 값 |
| **ORNL-TM-4865 Compere et al. (1975)** = 코드 `d_Compere` | ρ = 2575.0 − 0.513·T[°C] | **2242.1** kg/m³ | REFERENCE ONLY (비활성) |
| ~~ORNL-TM-2316 Cantor (1968)~~ = 코드 `d_Cantor` | ρ = 2553.3 − 0.562·T[°C] | **2188.65** kg/m³ | **ACTIVE (모델이 실제 사용)** · ⚠️ **2026-09-03 귀속 반증됨 — 하단 참조** |

- Robertson(1965)과 Compere(1975)는 **0.5 kg/m³(0.02%) 차이로 사실상 일치**.
- 그러나 모델이 실제 쓰는 Cantor(1968)는 이들보다 **53.5 kg/m³ (−2.4%) 낮다.**
- Cantor 기준 다른 온도: 908 K에서 2196.51, 936 K에서 2180.78 kg/m³.

### 점도 @922 K 비교

| 출처 | 값 @922 K | 차이 |
|---|---:|---|
| ORNL-TM-728 Robertson (1965) MSRE 1 | 18 lb/ft-hr = **0.00744** Pa·s | 기준 |
| 코드 `eta_Cantor` = 8.4e-5·exp(4340/T[K]) | **0.0093025** Pa·s | **+25%** |

## 더 중요한 내부 정합성 문제
코드 문서 스스로 다음을 명시한다 (`d_Compere` 주석):

> "**This is no longer the correlation the medium uses**: the fuel salt now runs on `d_Cantor`. It is kept because `Properties_TransitTime`와 `Analytic_DriftReactivity`가 명시적으로 호출하고, **`Data.Geometry`의 체적들이 이 상관식(Compere)에 대해 유도되었기 때문**이다. **Do not mix it with the Cantor set.**"

즉 **노달화 체적은 Compere 밀도로 유도되었는데 매질은 Cantor로 구동**된다. 두 밀도가 2.4% 다르므로, 질량 inventory·전이시간(τ = M/ṁ)에 계통적 편차가 들어갈 수 있다. 현재 미해결 이슈인 [[02_Wiki/issues/jeong-transit-time-value-mismatch]] 및 τ_system +7.6~7.9% 차이와 **직접 연관 가능성**이 있다.

Cantor를 택한 이유는 코드에 명시돼 있다: "더 잘 검증되어서가 아니라, **같은 1차 출처에서 나온 cp·μ·k 세트가 함께 있기 때문**."

## 발견 경위
Git 저장소 HEAD의 `Media/MSRE_Properties.mo`를 [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]]와 대조하던 중.

## 영향 범위
- [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]] — 설계값(Robertson)과 모델 사용값(Cantor)이 다름을 반영함
- [[02_Wiki/systems/msre/implementation/msre-transform-model]]
- [[03_Data/msre/benchmark/transform-b0-vs-jeong-mars]] — 전이시간·inventory (V_loop 2.0965 m³, M_loop 4605 kg)
- [[02_Wiki/systems/msre/verification/dymola-b0-baseline]]

## 현재 상태
Open. **어느 값도 덮어쓰지 않고 세 계열(Robertson 1965 / Cantor 1968 / Compere 1975)을 모두 보존**한다. 어느 것이 "옳은지" 단정하지 않는다 — 조성이 서로 다르고(Robertson MSRE1 = 70-23.6-5-1-0.4, Cantor = 65.0-29.17-5.0-0.83, Compere = 65-29.1-5-0.9 mol%) 측정 연도도 다르므로, 단순 우열이 아니라 **어느 조성·어느 시점의 염을 모델링하는가**의 문제다.

## 해결 방향 / 추가로 필요한 것
- [ ] Robertson MSRE1(70-23.6-5-1-0.4, Th 함유)과 Cantor/Compere(65-29.x-5-0.x, Th 없음)의 **조성 차이**를 먼저 확정. 서로 다른 염이면 "충돌"이 아니라 "다른 대상"이다. → Robertson의 MSRE 3(65-29.1-5-0-0.9)이 Compere 조성과 사실상 동일해 보임: 134 lb/ft³ = 2146.5 vs Compere @922K 2242.1 → **이 경우 오히려 95.6 kg/m³ 차이**로 더 벌어짐. 확인 필요.
- [ ] 체적(Compere 기준 유도) vs 매질(Cantor) 혼용이 τ_system·inventory에 주는 영향 정량화. 코드의 `Verification/Properties_TransitTime.mo`가 이미 이를 다루는지 확인.
- [x] ORNL-TM-2316(Cantor 1968) 원문 확보 완료 (2026-09-03) — **귀속 반증됨**, 아래 참조.
- [ ] ORNL-TM-4865(Compere 1975) 원문 확보 — 여전히 미확보, 코드 주석이 유일 근거(2차).

## ⚠️ 2026-09-03 갱신 — ORNL-TM-2316 귀속이 반증되었다

원본을 확보해 4개 물성표를 **페이지 이미지로 직접 대조**한 결과:

- **`d_Cantor` = 2553.3 − 0.562·t 는 ORNL-TM-2316에 존재하지 않는다.** 이 보고서의 밀도표(p.28)는
  3.628 / 3.153 / 3.687 / 3.644 / 2.214 / 2.27 / 2.26 g/cm³ 계열 7식뿐이다.
- **`cp` 0.48 cal/(g·°C) (= 2009.66 J/kg·K)도 존재하지 않는다** (p.22 액체 Cp는 0.33~0.57만).
- 존재하는 것은 `eta` 0.084·exp(4340/T) (p.8 **F₁**) 와 `lambda` 0.010 W/(cm·°C) (p.11 **F₁ 또는 L₂B**) 뿐이며,
  **둘 다 MSRE 연료염이 아니라 ThF₄ 함유 MSBR 연료염(F₁ = LiF-BeF₂-ThF₄-UF₄ 73-16-10.7-0.3)의 값**이다.
- ORNL-TM-2316의 물성표에는 **ZrF₄ 함유 염 자체가 없다.**

따라서 "조성이 서로 다르므로 우열이 아니라 대상의 문제"라는 이 이슈의 진단은 유지되지만,
**Cantor 계열에 붙어 있던 조성 표기(65.0-29.17-5.0-0.83)와 출처 자체가 TM-2316에서 온 것이 아니다.**
후속 추적은 [[02_Wiki/issues/fuel-salt-property-provenance-composition-applicability]]에서 다룬다.

## 관련 페이지
- [[02_Wiki/issues/fuel-salt-property-provenance-composition-applicability]] — **후속 이슈 (critical)**
- [[02_Wiki/sources/ornl-tm-2316-cantor-1968]]
- [[03_Data/msre/properties/ornl-tm-2316-salt-properties]]
- [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]]
- [[02_Wiki/sources/ornl-tm-728-robertson-1965]]
