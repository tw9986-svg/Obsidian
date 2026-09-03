---
type: component
system: msre
tags: [pump, coastdown]
last_updated: {{date:YYYY-MM-DD}}
sources: [leandro-2019-sam-msre-thermal-hydraulic]
---
<!-- 저장 위치: 02_Wiki/systems/msre/components/ -->

# MSRE Fuel Pump

## 개요 / 역할
1차 루프 순환펌프. 토출수두 0.092 MPa로 171 kg/s 유량을 순환시킨다 (Robertson 1965). LOF(loss-of-flow) 사고 해석 시 pump coastdown이 주요 시나리오.

## Geometry / 파라미터
[[03_Data/msre/geometry/msre-primary-loop-geometry]] 참고.

**1차(ORNL-TM-728)**: 설계속도 1150 rpm, 임펠러 11-1/2 in.(0.292 m), 설계유량 1200 gpm에서 developed head 48.3 ft(≈0.324 MPa), 효율 80–85%. 기동 과도(계산): 50% 유량 ≈0.75 s, 75% ≈1.25 s, 90% ≈1.75 s, 100% ≈3 s.

⚠️ Leandro et al.(2019)의 discharge head 0.092 MPa와 상충 → [[02_Wiki/issues/pump-discharge-head-conflict]]. 우리 모델의 Dymola B0 `dp_pump` = 0.301 MPa는 1차값과 정합.

Leandro의 LOF 해석에 쓰인 coastdown curve는 Gao et al.(2010) 범용 곡선 차용 — MSRE 고유 실측 곡선 아님.

## 지배 물리 / 관련 개념
Pump affinity law (Q∝N, H∝N², P∝N³), rotor dynamics (모터토크–유체토크–마찰토크–관성).

## 모델링 구현
[[02_Wiki/systems/msre/implementation/msre-transform-model]] — `Components/{FuelPump,FuelPump_Dynamics}.mo`, `Components/BaseClasses/PartialFuelPump.mo`, `Experiments/{PumpStartup*,PumpCoastdown*}.mo`, `Verification/{Pump_R1_Torque,Pump_ZeroSpeed}.mo`.

로터 법칙 검증: startup `N/N_nom = tanh(t_rel/4)`, coastdown `N/N0 = 1/(1+t_rel/4)` — 둘 다 해석해와 정확히 일치(PASS). 단, coastdown **유량** 감쇠는 MARS 대비 크게 느림 → [[02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars]].

가정: `tau_shaft` 4.0 s, 유체토크 ≈ ω·|ω|, coulomb·viscous 마찰 0, off-design 특성 미검증.

## 관련 페이지
- [[02_Wiki/systems/msre/components/primary-loop]]
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
- [[04_Projects/msre-transform-status]]
