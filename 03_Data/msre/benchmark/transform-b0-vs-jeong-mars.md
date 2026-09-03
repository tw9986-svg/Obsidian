---
type: data
system: msre
category: benchmark
symbol: 
tags: [transform, mars, jeong, coastdown, startup, transit-time, reactivity]
last_updated: {{date:YYYY-MM-DD}}
---
<!-- 저장 위치: 03_Data/msre/benchmark/ -->

# TRANSFORM B0 vs Jeong/MARS vs MSRE 실측 — 수치표

출처: canonical 아카이브 `docs/DYMOLA_B0_BASELINE.md` ([[02_Wiki/systems/msre/implementation/msre-transform-model]]). TRANSFORM 열은 사용자의 Dymola 실행 결과(DERIVED — 모델 출력), MARS 열은 Jeong et al.(2026) 보고값, Measured 열은 MSRE 실험값.

## 전이시간 (transit time)

| Quantity | Jeong/MARS | TRANSFORM B0 | 차이 |
|---|---:|---:|---:|
| `tau_core` | 9.56 s | 9.96316 s | +0.40 s |
| `tau_external` | 16.14 s | 17.6879 s | +1.55 s |
| `tau_system` | 25.70 s ⚠️ | 27.651 s | **+1.951 s (+7.6%)** |

⚠️ Jeong 기준값 자체가 자료마다 다름: 원 논문은 계산 **25.63 s**, 실험보고 25.2 s이고 우리 `README.md`도 25.63 s인데 `DYMOLA_B0_BASELINE.md` 비교표만 25.70 s다 → [[02_Wiki/issues/jeong-transit-time-value-mismatch]]. 정정 전까지 차이는 **+7.6 ~ +7.9%** 폭으로 읽을 것.

`JEONG_TRANSIT_TIME = BENCHMARK_DIFFERENCE`. **규칙: geometry를 Jeong 값에 강제로 맞추지 않는다** (명시적으로 이름붙인 Jeong-equivalent 민감도 케이스 내부에서만 허용).

## PumpStartup 반응도

| Feature | TRANSFORM B0 | Jeong/MARS | MSRE 실측 |
|---|---:|---:|---:|
| 1st peak | 15.4 s, 258.9 pcm | 15.3 s | |
| 1st minimum | 29.2 s, 198.7 pcm | | |
| 2nd peak | 42.9 s, 231.0 pcm | 40.7 s | |
| 3rd peak | 70.4 s, 223.8 pcm | 66.2 s | |
| 진동주기 | ≈27.5 s | ≈25.5 s | |
| 25–45 s 평균 | ≈215.3 pcm | 222.4 pcm | 227.3 pcm |
| 150 s | ≈220.9 pcm | 226.5 pcm (asymptotic) | |

**구조적 관찰**: 두 모델 모두 진동주기가 계통 전이시간을 따라감 (TRANSFORM 27.5 s vs τ_system 27.651 s / Jeong 25.5 s vs 25.70 s) → startup peak timing 차이는 **hydraulic inventory·전이시간 정의** 문제이지 명백한 DNP 수송 결함이 아님.

## PumpCoastdown 정규화 유량 [%]

| t [s] | TRANSFORM | MARS | Estimated |
|---:|---:|---:|---:|
| 1 | 78.9 | 80.3 | 95.7 |
| 2 | 65.5 | 54.7 | 81.4 |
| 4 | 48.8 | 29.7 | 42.0 |
| 5 | 43.3 | 22.4 | 27.8 |
| 10 | 27.5 | 6.57 | 7.03 |
| 15 | 20.0 | 2.20 | 4.66 |
| 20 | 15.7 | 0.97 | 3.81 |
| 30 | 10.9 | 0.27 | — |
| 40 | 8.34 | ≈0 | — |
| 50 | 6.71 | ≈0 | — |
| 60 | 5.61 | ≈0 | — |

**LARGE `BENCHMARK_DIFFERENCE`** — TRANSFORM이 2 s 이후 현저히 느리게 감쇠. **DNP 파라미터를 이 유량 차이 보상용으로 보정 금지.**

## PumpCoastdown 반응도 [pcm]

| t [s] | TRANSFORM | MARS | 실측 |
|---:|---:|---:|---:|
| 5 | −46.6 | −65.6 | −56.6 |
| 10 | −90.2 | −118.9 | −114.0 |
| 20 | −134.6 | −165.6 | −158.5 |
| 30 | −156.7 | −186.4 | −172.1 |
| 40 | −170.6 | −198.7 | −187.2 |
| 50 | −180.4 | −207.1 | −200.5 |
| 60 | −187.8 | −212.8 | −206.2 |

TRANSFORM vs MARS: MAE ≈24.8 pcm, RMSE ≈25.8 pcm. TRANSFORM vs 실측: MAE ≈19.3 pcm, RMSE ≈20.0 pcm.

**인과 사슬**: `FLOW_ERROR → DNP_RESIDENCE_ERROR → REACTIVITY_ERROR` (느린 유량 감쇠 → 잔류 유량 과다 → DNP가 계속 노심 밖으로 수송 → `Beta_eff` 회복 지연 → 유동유발 양의 반응도 발생 지연 → 필요 제어봉 보상이 MARS·실측보다 덜 음수). **유압 coastdown 차이가 규명되기 전까지 Fig. 8 차이를 독립적 kinetics 결함으로 취급 금지.**

## 해석해 검증값 (Verification 모델)

| Value | Provenance | 비고 |
|---|---|---|
| drift reactivity 228.4 pcm (해석, Eq. 8) vs 226.5 pcm (Jeong 시뮬레이션) | ORIGINAL (Jeong 2026) | `Analytic_DriftReactivity`가 assert |
| 순환 `Beta_eff` ≈ 0.0045 vs 정적 0.00678 | ORIGINAL (Jeong 2026) | 〃 |
| 자연순환 유량 1.46 / 4.45 kg/s | ORIGINAL (Jeong 2026) | 〃 |
| Transient가 Eq. 8 점근값에 안착 (tolerance 8 pcm; Jeong MARS는 해석값 대비 1.9 pcm 낮음) | ORIGINAL | `Transient_DriftReactivity` |

## 값 성격 요약 (provenance)

| 항목 | Provenance |
|---|---|
| TRANSFORM B0 결과 전부 | DERIVED (사용자 Dymola 실행 결과) |
| Jeong/MARS 열, 실측 열, Eq.8 해석값 | ORIGINAL (Jeong et al. 2026 — **원문 아직 미ingest**, `00_Inbox/Benchmarking the MARS code...pdf`) |
| 정격 `m_flow_nominal` 168 kg/s | ORIGINAL (Jeong 기준). ⚠️ ORNL-TM-728 설계값 1200 gpm(≈171 kg/s)과 약 1.8% 차이 |

## 관련 페이지
- [[02_Wiki/systems/msre/verification/dymola-b0-baseline]]
- [[02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars]]
- [[03_Data/registry]]
