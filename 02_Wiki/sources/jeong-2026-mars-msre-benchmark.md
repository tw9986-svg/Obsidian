---
type: source
title: "Jeong et al. 2026 — Benchmarking the MARS code for molten salt reactor applications using MSRE transient experiments"
raw: "[[01_Raw/literature/Jeong et al 2026 - Benchmarking the MARS code for MSR applications using MSRE transient experiments]]"
source_kind: literature
systems: [msre]
date_ingested: {{date:YYYY-MM-DD}}
tags: [mars, benchmark, dnp, point-kinetics, pump-startup, coastdown, natural-circulation]
status: processed
---

# Jeong et al. 2026 — MARS 코드 MSRE 과도실험 벤치마크

## 메타데이터
- 저자: J.J. Jeong, Y.J. Cho, H.C. Lee, B. Yun
- 학술지: Nuclear Engineering and Technology **58** (2026) 104438, 10 페이지
- 원본: [[01_Raw/literature/Jeong et al 2026 - Benchmarking the MARS code for MSR applications using MSRE transient experiments]]

## 왜 중요한가
**우리 TRANSFORM 모델이 바로 이 논문의 MARS 입력모델을 Modelica로 재구현한 것이다** ([[02_Wiki/systems/msre/implementation/msre-transform-model]]). 모델의 Eq. 3–8 참조, 노달화(15 ring × 20 axial), 정격유량 168 kg/s, 전이시간 기준값, 검증 assert 값이 모두 이 논문에서 온다.

## 핵심 주장 요약
- MSRE 3개 과도실험(pump startup, pump coastdown, natural circulation)으로 MARS 코드의 용융염로 적용성을 벤치마크.
- 순환연료 특유의 DNP drift 효과를 modified point kinetics로 처리, 제어봉 반응도는 flux servo 가정으로 Eq. (7)에서 유도.
- Pump startup: 반응도 1~3차 peak가 15.3 / 40.7 / 66.2 s → 주기 약 25.5 s로 계통 전이시간과 일치. 점근 반응도 손실 226.5 pcm.

## 모델 구조 (MARS 입력모델)

| 항목 | 내용 |
|---|---|
| 노달화 규모 | 1·2차 계통 총 **387 control volumes, 400 junctions** |
| 노심 | 1140 채널 → **15 동심 radial ring × 20 axial** = 300 TH cells |
| Plena | 상·하부 plenum 각 3 axial node. **Volume 120-03(하부)·190-01(상부)을 노심에 포함** → 노심 경계 정의 |
| HX | tube-bundle + baffle. **연료염이 shell측, 냉각염이 tube측**. shell 10 vol / tube 20 vol, cross-flow 열전달 옵션 |
| Downcomer | 다차원 유동이 예상되나 수직 1-D mesh로 모델링 |
| Expansion tank | Component 260, time-dependent volume으로 계통압력 정의 |
| 경계조건 | 2차측 HX 입구 냉각염 유량·온도 실측값 부여, 출구(Comp. 330) 압력 지정 |

## 가정 (중요)

| 가정 | 성격 |
|---|---|
| **모든 핵분열 출력을 연료염에 부여** (흑연 직접발열 무시) — "code limitations" 때문 | ASSUMED. 저자도 실제와 편차 발생(연료 온도응답 과속, 흑연 평균온도 과소)을 인정하며 고출력 해석에서는 개선 필요하다고 명시. → [[02_Wiki/issues/graphite-heating-fraction-provenance]]와 직결 |
| **펌프: 상세 head/torque 특성 및 관성 자료가 없어 MARS 내장 원심펌프 모델의 generic 파라미터 사용** | SOFTWARE_DEFAULT. → coastdown 거동 차이의 유력한 원인 |
| 축방향 출력분포 = **cosine 형상 가정** | ASSUMED |
| 반경방향 출력분포 = **Serpent 계산 결과(Ref.[9], 비공개)** | ORIGINAL(비공개 자료) → 우리 모델은 J0 대체 사용 |
| 중요도 φ*_k = 1 (Eq. 4) | ASSUMED |
| 노심·펌프·배관 벽 단열 | ASSUMED |
| **form loss factor, HX 전열면적을 정상상태 전출력 조건 재현하도록 보정** | **CALIBRATED** |
| 출력분포는 과도 중 불변 | ASSUMED |

## 추출된 정량값 (→ 03_Data)

| Item | 저장 위치 | Provenance |
|---|---|---|
| 6군 지연중성자 파라미터(U-235/U-233), Λ, 온도계수 (Table 1–3) | [[03_Data/msre/kinetics/delayed-neutron-parameters]] | ORIGINAL (2차 인용, 원출처 Ref.[9]) |
| 전이시간: 계산 25.63 s vs 실험보고 25.2 s | [[03_Data/msre/benchmark/transform-b0-vs-jeong-mars]] | ORIGINAL |
| 반응도 peak 시각 15.3/40.7/66.2 s, 주기 25.5 s, 점근 손실 226.5 pcm | 〃 | ORIGINAL |

## 검증/벤치마크 결과
- Pump startup: 유량이 약 10 s에 정격 도달. **연료염 유량은 직접 측정된 값이 아니라 펌프 속도로부터 추정된 값** [34] — 벤치마크 기준값의 성격상 중요.
- 전이시간 계산값 25.63 s vs 실험보고 25.2 s (+1.7%).

## 기존 위키/데이터와의 관계
- **기존 강화**: [[03_Data/msre/benchmark/transform-b0-vs-jeong-mars]]의 MARS 열 값들이 이제 원문 출처를 갖게 됨.
- **신규**: kinetics 파라미터 일체 → [[03_Data/msre/kinetics/delayed-neutron-parameters]].
- ⚠️ **불일치 발견 (내부 문서)**: 우리 `docs/DYMOLA_B0_BASELINE.md`는 Jeong τ_system을 **25.70 s**로 적어두었으나 원 논문은 **25.63 s**(계산)/25.2 s(실험보고)이다. 0.07 s 차이지만 벤치마크 기준값이므로 정정 필요 → [[02_Wiki/issues/jeong-transit-time-value-mismatch]].
- ⚠️ Jeong의 **흑연 발열 전량 연료염 부여 가정**은 Leandro/Carbajo 계열의 94:6 분배와 다른 접근 — 두 문헌이 서로 다른 단순화를 택한 것이며 상충이라기보다 모델링 선택 차이. 우리 모델이 어느 쪽을 따르는지 명시 필요.
- ⚠️ U-233 Table 2 group 1 값이 U-235와 동일 — 오식 가능성, 추정 수정 없이 기록.

## 관련 페이지
- [[02_Wiki/systems/msre/implementation/msre-transform-model]]
- [[02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars]]
- [[03_Data/msre/kinetics/delayed-neutron-parameters]]
