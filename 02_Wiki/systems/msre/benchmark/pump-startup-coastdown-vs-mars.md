---
type: benchmark
system: msre
tags: [pump, coastdown, startup, mars, jeong, reactivity]
status: BENCHMARK_DIFFERENCE (정성 PASS / 정량 차이)
last_updated: {{date:YYYY-MM-DD}}
---
<!-- 저장 위치: 02_Wiki/systems/msre/benchmark/ -->

# Pump Startup / Coastdown — TRANSFORM vs Jeong MARS vs MSRE 실측

## 비교 대상
[[02_Wiki/systems/msre/implementation/msre-transform-model]]의 `Experiments.PumpStartup*` / `PumpCoastdown*` (Dymola B0) vs Jeong et al.(2026) MARS 결과 vs MSRE 실측 반응도.

## 조건 / Case Setup
Zero-power(≈100 W), 908 K 등온, 1 radial group × 20 axial, flux servo on, `tau_shaft` 4.0 s, `N_rated` 1160 rpm, `m_flow_nominal` 168 kg/s. Startup은 정지 상태에서 정격까지, coastdown은 정격 166.5 kg/s에서 모터 트립.

## 결과 비교
수치 전체: [[03_Data/msre/benchmark/transform-b0-vs-jeong-mars]].

- **Startup 반응도**: 1차 peak 시점은 잘 맞음 (15.4 s vs MARS 15.3 s). 25–45 s 평균 215.3 pcm vs MARS 222.4 vs 실측 227.3 pcm.
- **Coastdown 유량**: 정성적 거동 PASS, 정량은 **LARGE BENCHMARK_DIFFERENCE** — 10 s에서 TRANSFORM 27.5% vs MARS 6.57%.
- **Coastdown 반응도**: 부호·추세 PASS, 정량 차이 (vs MARS MAE 24.8 pcm, vs 실측 MAE 19.3 pcm). 흥미롭게도 **TRANSFORM이 MARS보다 실측에 더 가깝다** (MAE 19.3 < 24.8).
- **전이시간**: τ_system 27.651 s vs Jeong 25.70 s (+7.6%).

## 오차 / 편차 분석
진동주기가 양쪽 모두 각자의 τ_system을 따라가므로 (27.5↔27.651, 25.5↔25.70), startup 타이밍 차이는 **DNP 수송 결함이 아니라 hydraulic inventory/전이시간 정의 차이**로 귀결된다.

Coastdown은 다음 인과 사슬로 설명된다:

```
FLOW_ERROR → DNP_RESIDENCE_ERROR → REACTIVITY_ERROR
```

느린 유량 감쇠 → 잔류 유량 과다 → DNP가 계속 노심 밖으로 수송됨 → `Beta_eff` 회복 지연 → 유동유발 양의 반응도 지연 → 제어봉 보상이 덜 음수.

## 결론 및 오차원인 추정
**유압 coastdown 차이가 1차 원인이며, kinetics 쪽을 독립 결함으로 보거나 DNP 파라미터를 보정해 맞추는 것은 금지**(순환논증). 펌프 모델 불확실성 후보(순서 무관): 유체토크 형식 · 기계마찰 0 가정 · rotor inertia/`tau_shaft` · off-design head 특성 · 저유량 loop 저항·form loss · 운동량 형식 · 전이시간/geometry 차이 · DNP 공간가중.

로터 ODE 자체는 해석 법칙을 정확히 재현하므로 결함 후보에서 제외 ([[02_Wiki/systems/msre/verification/dymola-b0-baseline]]).

## 관련 페이지
- [[02_Wiki/systems/msre/components/fuel-pump]]
- [[03_Data/msre/benchmark/transform-b0-vs-jeong-mars]]
- [[04_Projects/msre-transform-status]]
