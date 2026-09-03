---
type: component
system: msre
tags: [primary-loop, downcomer, plenum, hydraulic-mockup]
last_updated: {{date:YYYY-MM-DD}}
sources: [leandro-2019-sam-msre-thermal-hydraulic]
---
<!-- 저장 위치: 02_Wiki/systems/msre/components/ -->

# MSRE Primary Loop

## 개요 / 역할
MSRE의 1차 계통. 연료염(fuel salt)이 fuel pump → downcomer → lower plenum → core(1140개 fuel channel) → upper plenum → heat exchanger(1차측) → pump로 순환하며, core에서 발생한 열을 HX를 통해 secondary loop로 전달한다. 배관은 Hastelloy-N, core 구조는 흑연(graphite). Cover gas로 계통압력 유지(~0.1 MPa).

Hydraulic mockup은 MSRE와 동일 geometry를 갖되 가열이 없는 물 실험 설비로, 압력강하/유속 검증에 쓰였다 (Kedl 1970). Hydraulic mockup 배관은 carbon steel, 실제 MSRE는 Hastelloy-N — 재질만 다르고 형상은 동일.

## Geometry
Downcomer(3-D annulus, 1-D로 단순화해 모델링), lower/upper plenum, core vessel(내경 0.705 m, 4-ring), fuel channel(1140개), hydraulic mockup 배관(Schedule 40) 등 세부 치수는 [[03_Data/msre/geometry/msre-primary-loop-geometry]] 참고.

## 물성 / 파라미터
Fuel salt 물성(밀도/점도/비열, 3종 조성 vs SAM 내장 FLiBe)은 [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]].

## 지배 물리 / 관련 개념
- 자연순환/강제순환 1-D 배관 유동 (질량·운동량·에너지 보존)
- Pump coastdown에 의한 loss-of-flow(LOF) 과도현상

## 모델링 구현
[[02_Wiki/systems/msre/implementation/msre-transform-model]] — `Systems/PrimarySystem.mo`(1차 루프 전체, HX 2차측은 경계조건), `Verification/Loop_Hydraulics.mo`(정상 유압 검증). 검증 결과: [[02_Wiki/systems/msre/verification/dymola-b0-baseline]] (m_flow 166.542 kg/s, V_loop 2.0965 m³, τ_system 27.651 s, Re_max 806 → 층류).

## 관련 페이지
- [[02_Wiki/systems/msre/components/core]]
- [[02_Wiki/systems/msre/components/heat-exchanger]]
- [[02_Wiki/systems/msre/components/fuel-pump]]
- [[02_Wiki/systems/msre/benchmark/sam-msre-primary-loop]]
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
