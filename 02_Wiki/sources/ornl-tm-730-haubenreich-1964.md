---
type: source
title: "Haubenreich et al. 1964 — ORNL-TM-730, MSRE Design and Operations Report Part III: Nuclear Analysis"
raw: "[[01_Raw/literature/ORNL-TM-730 Haubenreich et al 1964 - MSRE Design and Operations Report Part III Nuclear Analysis]]"
source_kind: report
systems: [msre]
date_ingested: {{date:YYYY-MM-DD}}
tags: [ornl, primary-source, nuclear-analysis, core-geometry, kinetics]
status: partial
---

# ORNL-TM-730 (Haubenreich et al. 1964) — MSRE Design and Operations Report Part III: Nuclear Analysis

## 메타데이터
- 저자/기관: P. N. Haubenreich, J. R. Engel, B. E. Prince, H. C. Claiborne, Oak Ridge National Laboratory
- 발행: 1964
- 분량: 209 페이지 (스캔 OCR본)
- 출처: OSTI https://www.osti.gov/servlets/purl/4114686
- 원본: [[01_Raw/literature/ORNL-TM-730 Haubenreich et al 1964 - MSRE Design and Operations Report Part III Nuclear Analysis]]

## 편입 범위 (partial)
[[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]가 인용한 geometry 값과 현재 모델링에 쓰이는 항목만 대조 (무차별 수집 배제).

## 핵심 확인 사항 (1차 확인)
- **Core radius 27.7 in. (= 0.7036 m), core height 63 in. (= 1.600 m)** — Leandro의 0.705 m / 1.60 m와 일치 (반경은 반올림 차이 0.0014 m).
- **Fuel volume external to core: 40 ft³ (= 1.133 m³)** — **신규 1차 데이터**. 현재 진행 중인 primary-loop inventory / fuel transit time 검증(및 Jeong MARS 대비 transit-time BENCHMARK DIFFERENCE)에 직접 관련.
- 참조 노달화 계산의 nominal 연료염 조성: LiF-BeF₂-ZrF₄-ThF₄-UF₄ = 70-23-5-1-1 mol% (핵계산용 nominal, Robertson TM-728의 70-23.6-5-1-0.4와 미세하게 다름 — 계산 목적별 조성 차이로 보이며 단정하지 않음).
- 흑연 발열분율은 기호 γ("Fraction of heat produced in graphite")로 정의되어 있으나, **수치(6%)는 이번 대조에서 1차 확인 실패** — 여전히 2차(Leandro→Carbajo) provenance 유지.

## 추출된 정량값 (→ 03_Data)

| Item | 저장 위치 | Provenance |
|---|---|---|
| Core radius / height, fuel volume external to core | [[03_Data/msre/geometry/msre-primary-loop-geometry]] | ORIGINAL (1차) |

## 기존 위키/데이터와의 관계
- provenance 격상: core 반경·높이를 1차로 교체.
- 신규 추가: core 외부 연료 체적 40 ft³.
- 미해결: 흑연 발열분율 6%의 1차 근거 미확인 → [[02_Wiki/issues/graphite-heating-fraction-provenance]].

## 아직 안 본 부분
209페이지 중 일부만 대조. Point kinetics 파라미터(β, λ, 지연중성자군), 온도계수, nuclear average temperature 정의, 축/반경 방향 출력분포 등은 **현재 연구의 핵심 주제**이므로 다음 단계에서 별도 정독 ingest 권장.

## 관련 페이지
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
- [[02_Wiki/systems/msre/components/core]]
- [[03_Data/msre/geometry/msre-primary-loop-geometry]]
