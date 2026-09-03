---
type: verification
system: msre
tags: [dymola, baseline, cross-tool, openmodelica, hydraulics]
status: PASS (구조·해석해 검증), 벤치마크 차이는 별도
last_updated: {{date:YYYY-MM-DD}}
---
<!-- 저장 위치: 02_Wiki/systems/msre/verification/ -->

# Dymola B0 baseline — 고정 기준 결과

출처: canonical 아카이브 내 `docs/DYMOLA_B0_BASELINE.md` ([[02_Wiki/systems/msre/implementation/msre-transform-model]]).

## 도구 역할 (고정 규칙)

| 도구 | 역할 |
|---|---|
| **Dymola** | 최종 물리 확인 및 벤치마크 결과 — **authoritative** |
| **OpenModelica** | 사전검증·민감도용 cross-check 전용. OpenModelica 백엔드 크래시는 `OPENMODELICA_TOOL_LIMITATION`이며 물리 실패가 아님 |

**규칙: Dymola 기준값을 OpenModelica 결과로 대체 금지. 불일치 시 튜닝하지 말고 원인(초기화/솔버/이벤트/매질상태/동적 형식/실제 방정식 차이)부터 규명.**

## A. Loop_Hydraulics (DASSL, 0→300 s, 0 state events)

| Quantity | Dymola B0 |
|---|---:|
| `m_flow` | 166.542 kg/s |
| `Re_max` | 806.178 (**LAMINAR**) |
| `dp_pump` | 3.01271 bar (= 0.301 MPa) |
| `dp_loop_nonstatic` | 3.01272 bar |
| `dp_loop_total` | 5.8e−16 bar (≈0, 폐루프 닫힘) |
| `V_loop` | 2.0965 m³ (measured = geometry) |
| `M_loop` | 4605 kg |
| `err_inventory` | 2.22e−16 |
| `tau_core` / `tau_external` / `tau_system` | 9.96316 / 17.6879 / 27.651 s |

**판정**: steady hydraulics PASS · pressure closure PASS · inventory identity PASS · flow split PASS · core flow regime LAMINAR · transit-time accounting PASS.

> Re_max ≈ 806은 완전 층류 영역 — [[04_Projects/msre-transform-status]]의 "Gnielinski 단독 적용 부적합, laminar/transition/turbulent closure 분리 필요" 결론과 정합.

## C–D. PumpStartup1D_RotorDynamics

조건: `Q_start` 100 W · `T_start` 908 K · `t_null` 600 s · `N_rated` 1160 rpm · `m_flow_nominal` 168 kg/s · 1 radial × 20 axial · servo on · `tau_shaft` 4.0 s · `tau_motor,nom` ≈ `tau_hyd,nom` ≈ 236.11 N·m · `tau_fric` = 0.

로터 법칙 `N/N_nom = tanh(t_rel/4)` (t_rel = t − 600 s): 2 s→536.06, 4 s→883.45, 8 s→1118.27, 10 s→1144.47, final 1160 rpm.
**`STARTUP_ROTOR_ODE` PASS · `TORQUE_BALANCE` PASS.**

유량 응답: 95% ≈7.4 s, 98% ≈10.2 s, 99% ≈15.6 s, final ≈166.6 kg/s (norm 0.991), `dp_pump` final ≈3.015 bar. **Head/flow response PASS**, Loop_Hydraulics B0와 정상점 일치.

## F. PumpCoastdown1D_RotorDynamics

로터 법칙 `N/N0 = 1/(1 + t_rel/4)` — t_rel=60 s에서 72.5 rpm, 해석해 1160/(1+15)=72.5 rpm과 **정확히 일치**.
Rotor ODE PASS · motor trip PASS · torque direction PASS · head decay trend PASS.

## 결론

**로터 ODE 구현 자체는 결함 후보가 아니다** — 두 해석 법칙(tanh, 1/(1+t/τ))을 정확히 재현. 문제는 그로부터 얻어지는 물리적 펌프/계통 응답 쪽 ([[02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars]]).

## K. Cross-tool (Dymola B0 vs OpenModelica 1.27.0, Loop_Hydraulics)

`m_flow`·`Re_max`·`dp_pump`·`V_loop`·`M_loop`·`tau_*` 전부 상대차 1e−5 이하 → **`CROSS_TOOL_MATCH`**. 유일 예외 `dp_loop_gravity`(상대차 1.4e−3)는 1e5 Pa 항들이 1 Pa 잔차로 상쇄되는 수치적 cancellation이며 방정식 차이 근거가 아님 → `CROSS_TOOL_SMALL_DIFFERENCE`, 조치 없음.

## 관련 페이지
- [[02_Wiki/systems/msre/implementation/msre-transform-model]]
- [[03_Data/msre/benchmark/transform-b0-vs-jeong-mars]]
- [[02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars]]
