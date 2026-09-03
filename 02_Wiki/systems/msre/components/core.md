---
type: component
system: msre
tags: [core, graphite, fuel-channel]
last_updated: {{date:YYYY-MM-DD}}
sources: [leandro-2019-sam-msre-thermal-hydraulic]
---
<!-- 저장 위치: 02_Wiki/systems/msre/components/ -->

# MSRE Core

## 개요 / 역할
1140개의 평행 fuel channel이 흑연(graphite) moderator/stringer로 둘러싸인 구조. 연료염이 채널을 따라 상승하며 핵반응으로 가열되고, 발열의 대부분(94%, historical calc)은 유체에, 나머지(6%)는 흑연에 직접 축적된다. 설계출력 10 MWt, 실제운전 8 MWt.

## Geometry
노심 반경 27.7 in(0.7036 m), 높이 63 in(1.6002 m) — 1차 ORNL-TM-730. Fuel channel 합산 유동단면적 0.332 m², 수력직경 0.0159 m. 상세는 [[03_Data/msre/geometry/msre-primary-loop-geometry]].

⚠️ **채널 수 구분 (ORNL-TM-0378 Table 2)**: 압력용기 전체 1140개 중 **주 노심(main core, region 2)은 940개**이고 나머지 12/108/78개는 주변부(region 1/3/4)다. 주 노심 연료 체적분율 0.224, 등가 외반경 24.76 in, 상단 z = 64.59 in. → [[03_Data/msre/geometry/ornl-tm-0378-core-thermal-basis]]

⚠️ **온도 경계 세 종류 (혼용 금지)**: reactor 입/출구 908.15/935.93 K(1175/1225 °F) vs **main-core 입/출구 909.43/933.59 K**(1177.3/1220.8 °F). 주변부에서 아래 1.28 K, 위 2.33 K를 추가로 얻기 때문. 노심 전용 모델은 main-core 경계를 써야 한다.

## 물성 / 파라미터
연료염 물성: [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]] — ⚠️ 모델이 실제 쓰는 상관식은 Cantor(1968)이며 설계표와 다름 ([[02_Wiki/issues/fuel-salt-property-correlation-conflict]]).

**발열 분배**: 흑연 6% / 연료염 94% — ORNL-TM-0378 p.40 각주의 **가정치**(Nestor 미출간 계산), 측정값 아님. Jeong MARS 모델은 코드 한계로 100%를 연료염에 부여, Leandro SAM 모델도 100% 가정 → 세 접근이 다르므로 벤치마크 시 정합 확인 필요.

체적발열 1.88e7 W/m³은 Leandro SAM 모델 한정값(DERIVED).

## 지배 물리 / 관련 개념
- 체적발열 (fuel/graphite 분배), 흑연 전도
- 축방향 출력 형상: ORNL-TM-0378 B(z), peak-to-average **1.3585** (π/2 아님)
- Point kinetics / DNP transport → [[02_Wiki/systems/msre/implementation/msre-transform-model]]

## 모델링 구현
[[02_Wiki/systems/msre/implementation/msre-transform-model]] — `Data/Nodalization/{Core1D,Core2D}.mo`(1D: 1 ring×20 axial, nV_core=22 / 2D: 15 ring×20 axial, nV_core=302), `Data/Geometry.mo`, `Functions/corePowerShape.mo`, `Components/{ReactorCore,CoreChannel}.mo`. Core1D TH는 PASS ([[02_Wiki/systems/msre/verification/dymola-b0-baseline]]).

## 관련 페이지
- [[02_Wiki/systems/msre/components/primary-loop]]
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
- [[04_Projects/msre-transform-status]]
