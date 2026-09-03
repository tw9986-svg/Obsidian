---
type: data
system: msre
category: kinetics
symbol: "beta_i, lambda_i, Lambda, alpha_f, alpha_g"
tags: [point-kinetics, dnp, delayed-neutron, reactivity-coefficient, u235, u233]
last_updated: {{date:YYYY-MM-DD}}
---
<!-- 저장 위치: 03_Data/msre/kinetics/ -->

# MSRE 6군 지연중성자 파라미터 및 반응도 계수 (Jeong et al. 2026, Tables 1–3)

출처: [[02_Wiki/sources/jeong-2026-mars-msre-benchmark]] Table 1–3. 이 값들은 **[[02_Wiki/systems/msre/implementation/msre-transform-model]]가 직접 사용하는 입력**이다 (`Data/PrecursorGroups/{U235_6group,U233_6group}.mo`, `Data/{Kinetics_U235,Kinetics_U233}.mo`) — 다만 코드 실제 값과의 1:1 대조는 **아직 미실시**.

Jeong 논문은 이 값들을 자신의 Ref. [9]에서 가져왔다고 명시 → 이 표 기준 provenance는 ORIGINAL(2차 인용).

**Ref.[9] 신원 확인 (2026-09-02)**: 코드 `Data/PrecursorGroups/U235_6group.mo`(HEAD)의 주석이 원출처를 명시한다 — **Hanusek and Juan, Annals of Nuclear Energy 157 (2021) 108208**. 원문은 아직 미확보이나 인용 체인은 확정됨.

**코드 값 대조 완료 (verified)**: `U235_6group.mo`의 `lambdas={0.0125,0.0318,0.1090,0.3170,1.3500,8.6400}`, `alphas={0.000208,...,0.000345}/0.006781`, `Beta=0.006781`이 아래 Table 1과 **완전 일치**. `C_nominal={43.3,97.5,25.6,24.8,1.83,0.104}`는 코드 고유 초기값(모델 파라미터).

## Table 1 — U-235 (pump startup / coastdown 시험에 사용)

| Group | Fraction β_i | Decay constant λ_i (1/s) | Half-life (s) |
|---:|---:|---:|---:|
| 1 | 0.000208 | 0.0125 | 55.452 |
| 2 | 0.001190 | 0.0318 | 21.797 |
| 3 | 0.001070 | 0.1090 | 6.3591 |
| 4 | 0.003020 | 0.3170 | 2.1866 |
| 5 | 0.000948 | 1.3500 | 0.5134 |
| 6 | 0.000345 | 8.6400 | 0.0802 |
| **합계 β** | **0.006781** | | |

합계 0.006781은 TRANSFORM README가 인용한 정적 `Beta_eff` 0.00678과 일치 (DERIVED 확인).

## Table 2 — U-233 (자연순환 시험에 사용)

| Group | Fraction β_i | Decay constant λ_i (1/s) | Half-life (s) |
|---:|---:|---:|---:|
| 1 | 0.000208 | 0.0125 | 55.452 |
| 2 | 0.000830 | 0.0323 | 21.460 |
| 3 | 0.000595 | 0.1050 | 6.6014 |
| 4 | 0.001200 | 0.2940 | 2.3576 |
| 5 | 0.000226 | 1.2400 | 0.5590 |
| 6 | 0.000192 | 10.020 | 0.0680 |
| **합계 β** | **0.003251** | | |

⚠️ **확인 필요**: U-233 group 1의 β(0.000208)·λ(0.0125)·반감기(55.452 s)가 U-235 group 1과 **완전히 동일**하다. 물리적으로 가능은 하나 우연치고는 이례적이어서 원 논문 표의 오식 가능성이 있다. **추정으로 고치지 않고 그대로 기록**하며, Ref.[9] 확보 시 대조 필요.

## Table 3 — 즉발중성자 생성시간 및 반응도 계수

| Parameter | U-235 | U-233 |
|---|---:|---:|
| Prompt neutron generation time Λ (s) | 2.4 × 10⁻⁴ | 4.0 × 10⁻⁴ |
| Fuel temp. coefficient (pcm/K) | −8.71 | −11.3 |
| Graphite temp. coefficient (pcm/K) | −6.66 | −5.81 |

## 표준 값 표 요약

| Value | Unit | Source | Page/Fig | Provenance | Confidence | Model Usage | Verification |
|---|---|---|---|---|---|---|---|
| U-235 6군 β_i, λ_i (위 표) | -, 1/s | [[02_Wiki/sources/jeong-2026-mars-msre-benchmark]] | Table 1 | ORIGINAL (2차 인용, 원출처 Jeong Ref.[9] 미확보) | high | `U235_6group.mo` | unverified (코드 대조 전) |
| U-233 6군 β_i, λ_i | -, 1/s | 〃 | Table 2 | ORIGINAL (2차) | medium (group 1 중복 의심) | `U233_6group.mo` | unverified |
| Λ = 2.4e-4 (U-235) / 4.0e-4 (U-233) | s | 〃 | Table 3 | ORIGINAL (2차) | high | `Kinetics_*.mo` | unverified |
| α_fuel = −8.71 / −11.3 | pcm/K | 〃 | Table 3 | ORIGINAL (2차) | high | 반응도 피드백 (Eq. 5) | unverified |
| α_graphite = −6.66 / −5.81 | pcm/K | 〃 | Table 3 | ORIGINAL (2차) | high | 반응도 피드백 (Eq. 5) | unverified |
| 정적 β_eff = 0.006781 (U-235 합) | - | 〃 (합산) | Table 1 | DERIVED | high | | verified (README 0.00678과 일치) |

## 관련 페이지
- [[02_Wiki/sources/jeong-2026-mars-msre-benchmark]]
- [[02_Wiki/systems/msre/implementation/msre-transform-model]]
- [[03_Data/registry]]
