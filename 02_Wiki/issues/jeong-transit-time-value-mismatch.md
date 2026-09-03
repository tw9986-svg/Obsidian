---
type: issue
status: open
date: {{date:YYYY-MM-DD}}
systems: [msre]
tags: [transit-time, benchmark, data-quality]
---

# Jeong τ_system 기준값 불일치: 우리 문서 25.70 s vs 원 논문 25.63 s

## 문제 설명
Pump startup/coastdown 벤치마크의 기준값인 Jeong/MARS 계통 전이시간이 자료마다 다르게 적혀 있다.

| 출처 | τ_system |
|---|---|
| [[02_Wiki/sources/jeong-2026-mars-msre-benchmark]] 원문 (Section 3.2) | **25.63 s** (MARS 계산값) |
| 〃 원문이 인용한 실험 보고값 [27,34] | **25.2 s** |
| 우리 canonical 코드 `README.md` | 25.63 s ✓ (원문과 일치) |
| 우리 canonical 코드 `docs/DYMOLA_B0_BASELINE.md` 비교표 | **25.70 s** ✗ |

즉 우리 프로젝트 문서 두 개가 서로 다른 Jeong 기준값을 쓰고 있다.

## 1차 값 추가 확보 (2026-09-02)
[[02_Wiki/sources/ornl-tm-0380-effective-delayed-neutron-yields]] p.21에서 **ORNL 자체 계산값**을 확보했다:

| 출처 | τ_core | τ_external | τ_system | 순환 연료 체적 |
|---|---:|---:|---:|---:|
| ORNL-TM-0380 (1962, 1차 계산) | 9.37 | 16.45 | **25.82** | 69.1 ft³ = 1.9567 m³ |
| MSRE 실험 보고 (Jeong 인용 [27,34]) | — | — | 25.2 | — |
| Jeong/MARS 2026 | 9.56 | 16.14 | 25.63 (사내문서 25.70) | — |
| TRANSFORM B0 | 9.96316 | 17.6879 | 27.651 | 2.0965 m³ |

**체적비 +7.14% ≈ 전이시간비 +7.09%** — TRANSFORM의 긴 전이시간은 순환 연료 체적이 ORNL 1차 값보다 큰 것으로 산술적으로 설명된다. 다만 체적 경계 정의(expansion tank·pump bowl 포함 여부) 확인 전까지 **인과 미확정**. 상세: [[03_Data/msre/kinetics/ornl-tm-0380-effective-yields-and-transit-times]]

## 영향 범위
- [[03_Data/msre/benchmark/transform-b0-vs-jeong-mars]] — TRANSFORM 27.651 s와의 차이가 +1.951 s(25.70 기준)인지 +2.021 s(25.63 기준)인지 달라진다. 상대차 7.6% → 7.9%.
- [[02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars]]
- τ_core / τ_external도 동일하게 재확인 필요 (README는 core 9.56 / external 16.14 s, 합 25.70 s — **합이 25.70이므로 README 내부에서도 25.63과 어긋난다**).

## 현재 상태
Open. 세 값(25.63 / 25.70 / 9.56+16.14) 중 어느 것이 원 논문의 정확한 분해값인지 **추정하지 않는다.**

## 해결 방향 / 추가로 필요한 것
- Jeong 원문에서 τ_core / τ_external 분해값이 명시된 위치를 찾아 확인 (본문 Section 4.2 및 Fig. 7 주변 확인 필요 — 이번 ingest에서는 τ_system 25.63 s만 확인됨).
- 확인 후 `docs/DYMOLA_B0_BASELINE.md`(코드 저장소 문서)와 위키 데이터 페이지를 일관되게 정정.
- 정정 전까지 벤치마크 차이는 "약 +7.6~7.9%"로 폭을 두고 기술.

## 관련 페이지
- [[02_Wiki/sources/jeong-2026-mars-msre-benchmark]]
- [[03_Data/msre/benchmark/transform-b0-vs-jeong-mars]]
