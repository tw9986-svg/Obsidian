---
type: issue
status: open
date: {{date:YYYY-MM-DD}}
systems: [msre]
tags: [pump, conflict, provenance]
---

# ⚠️ Fuel pump 수두 값 충돌: Leandro 0.092 MPa vs ORNL-TM-728 48.3 ft

## 문제 설명
[[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]는 SAM 모델 입력으로 "fuel pump with discharge head of **0.092 MPa** … at a rate of 171 kg/s, **per Robertson (1965)**"를 제시한다 (journal p.63–64).

그러나 1차 출처 [[02_Wiki/sources/ornl-tm-728-robertson-1965]] (PDF p.184)는 다음과 같이 기술한다:
> "at the design speed of 1150 rpm and design flow rate of 1200 gpm the developed head is **48.3 ft**. The pump efficiency under these conditions is 80–85%."

또한 PDF p.~28에서 "1200 gpm at a discharge head of **49 ft**", 다른 곳에서 "a head of **48.5 ft**"로도 언급된다 (보고서 내부에서도 48.3 / 48.5 / 49 ft로 미세하게 다름 — 설계값 vs 실측 프로토타입 성능 차이로 추정되나 단정하지 않음).

**단위 환산 대조** (연료염 ρ = 140 lb/ft³ = 2242.6 kg/m³, TM-728 PDF p.38):
- 48.3 ft × 0.3048 = 14.72 m → Δp = ρgh = 2242.6 × 9.807 × 14.72 = **0.324 MPa** (≈ 47 psi)
- Leandro의 0.092 MPa는 같은 염 기준으로 환산하면 **4.18 m (13.7 ft)** 에 해당.

즉 두 값은 약 3.5배 차이가 나며, 단순 단위환산으로 설명되지 않는다.

## 발견 경위
1차 ORNL 자료 추적 중 ([[02_Wiki/sources/ornl-tm-728-robertson-1965]] ingest).

## 영향 범위
- [[02_Wiki/systems/msre/components/fuel-pump]]
- [[03_Data/msre/geometry/msre-primary-loop-geometry]] (Fuel pump 토출수두 항목 — 현재 두 값 병기, Verification=conflicting)
- 향후 TRANSFORM pump 모델의 수두 입력값 및 pump startup/coastdown 벤치마크 ([[04_Projects/msre-transform-status]]의 현재 핵심 이슈)

## 현재 상태
Open. 어느 쪽이 맞는지 **추정하지 않음**. 가능한 설명 후보(모두 미검증):
1. Leandro가 SAM 모델 경계조건으로 loop 압력손실(Table 3의 system head loss 44.9 kPa)에 맞춘 값을 넣고 출처만 Robertson으로 표기했을 가능성 → 그렇다면 provenance는 ORIGINAL이 아니라 CALIBRATED에 가까움.
2. 서로 다른 물리량(전양정 vs 특정 구간 차압)을 지칭했을 가능성.
3. 단순 환산/표기 오류.

## 우리 TRANSFORM 모델과의 대조 (2026-09-02 추가)
[[02_Wiki/systems/msre/verification/dymola-b0-baseline]]의 Dymola B0 결과에서 정상운전 시 **`dp_pump` = 3.01271 bar = 0.301 MPa**이다.

- ORNL-TM-728 1차값 환산 0.324 MPa 대비 **−7%** (동일 자릿수, 정합)
- Leandro의 0.092 MPa 대비 **3.3배** (불일치)

즉 **우리 모델은 1차 ORNL 값과 정합하며, Leandro의 0.092 MPa 쪽이 이례적**이다. 따라서 모델 입력을 바꿀 필요는 현재 없으며, 이 이슈는 "Leandro 논문의 인용값 성격 규명" 문제로 축소된다.

## 해결 방향 / 추가로 필요한 것
- TM-728 Fig. 5.24(pump hydraulic performance) 페이지를 이미지로 확인해 설계점 수두를 정확히 재확인.
- Leandro의 0.092 MPa가 실제로는 SAM 경계조건용으로 조정된 값(CALIBRATED)인지 확인 — 확인되면 해당 값의 provenance를 ORIGINAL→CALIBRATED로 정정.
- 모델 입력으로는 계속 1차 계열 값(≈0.30–0.32 MPa)을 사용.

## 관련 페이지
- [[02_Wiki/sources/ornl-tm-728-robertson-1965]]
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
