---
type: issue
status: resolved
date: {{date:YYYY-MM-DD}}
resolved: {{date:YYYY-MM-DD}}
systems: [msre]
tags: [graphite, provenance, volumetric-heating]
---

# 흑연 발열분율(6%, f_graphiteHeating ≈ 0.06)의 1차 출처 — 해결됨

## 문제였던 것
"MSRE 발열의 94%는 연료염, 6%는 흑연"이 모델에 직접 쓰이는데 provenance가 2차 인용 체인(Leandro 2019 → Carbajo et al. 2017 → "historical calculations (Haubenreich et al., 1964)")에 머물러 있었다. ORNL-TM-730에서는 기호 γ의 정의만 확인되고 수치는 찾지 못했다.

## 해결 (2026-09-02)
원출처는 **TM-730이 아니라 [[02_Wiki/sources/ornl-tm-0378-engel-haubenreich-1962]] (ORNL-TM-0378) p.40 각주**였다. 원문 직접 확인:

> "In these calculations, it was **assumed** that 6% of the reactor power [is generated in the graphite]" — 근거는 **C. W. Nestor의 미출간(unpublished) 감마/중성자 발열 계산**.

### provenance 정정
- 이전: `ORIGINAL (2차 인용)` / confidence medium
- 확정: **`ASSUMED`** / confidence high (원문 직접 확인)
- **성격**: 측정값이 아니라 **미출간 계산에 근거한 가정치**다. 모델 문서와 논문에 인용할 때 반드시 이 성격을 병기해야 한다.

같은 각주에서 열전도도도 "were **assumed** to be 3.21 and 13 Btu/hr·ft·°F"로 가정값임이 확인되었다 (연료 5.5557 / 흑연 22.4996 W/m·K, 1962 vintage).

기록 위치: [[03_Data/msre/geometry/ornl-tm-0378-core-thermal-basis]]

## 남은 후속 (별도 추적)
- Jeong의 MARS 모델은 코드 한계로 **발열 100%를 연료염에 부여**하고 흑연 직접발열을 무시한다 ([[02_Wiki/sources/jeong-2026-mars-msre-benchmark]]). 우리 TRANSFORM 모델이 6% 분배를 쓰는지, Jeong처럼 0%를 쓰는지 — **벤치마크 비교 시 이 차이가 정합되는지 확인 필요**. (코드 `Verification/Graphite_EnergyClosure.mo` 확인 대상)

## 관련 페이지
- [[02_Wiki/sources/ornl-tm-0378-engel-haubenreich-1962]]
- [[02_Wiki/systems/msre/components/core]]
