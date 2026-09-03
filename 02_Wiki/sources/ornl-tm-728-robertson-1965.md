---
type: source
title: "Robertson 1965 — ORNL-TM-728, MSRE Design and Operations Report Part I: Description of Reactor Design"
raw: "[[01_Raw/literature/ORNL-TM-728 Robertson 1965 - MSRE Design and Operations Report Part I Description of Reactor Design]]"
source_kind: report
systems: [msre]
date_ingested: {{date:YYYY-MM-DD}}
tags: [ornl, primary-source, design-data, salt-properties, pump]
status: partial
---

# ORNL-TM-728 (Robertson 1965) — MSRE Design and Operations Report Part I

## 메타데이터
- 저자/기관: R. C. Robertson, Oak Ridge National Laboratory, Reactor Division
- 발행: 1965년 1월, Contract No. W-7405-eng-26
- 분량: 575 페이지 (스캔 OCR본, OCR 품질 낮음 — 수치는 페이지 이미지로 재확인 권장)
- 출처: OSTI https://www.osti.gov/servlets/purl/4654707
- 원본: [[01_Raw/literature/ORNL-TM-728 Robertson 1965 - MSRE Design and Operations Report Part I Description of Reactor Design]]

## 편입 범위 (partial)
**전체 정독이 아니라, [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]가 이 보고서를 근거로 인용한 값 및 현재 모델링에 실제 사용되는 값만 대조·추출**했다 (무차별 수집 배제). 이후 필요한 항목이 생기면 그때 해당 부분만 추가 ingest.

## 핵심 확인 사항 (1차 확인)
- **설계 유량 1200 gpm** (= 0.0757 m³/s) — Leandro의 0.076 m³/s와 일치.
- **연료염 입구/출구 온도 1175 °F / 1225 °F** (= 908.1 K / 935.9 K) — Leandro의 908/936 K와 일치.
- **배관: 5-in. sched-40 INOR-8**(=Hastelloy-N) — Leandro의 수력직경 0.127 m(5인치)과 정합.
- **연료염·냉각염 조성 및 물성 표 (PDF p.38)** — Leandro Table 4·5가 이 표의 단위환산임을 확인. 상세: [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]].
- **펌프: 설계속도 1150 rpm, 임펠러 11-1/2 in., 설계유량 1200 gpm에서 developed head 48.3 ft, 효율 80–85%** (PDF p.184). ⚠️ Leandro가 "Robertson (1965)"를 근거로 제시한 discharge head 0.092 MPa와 상충 → [[02_Wiki/issues/pump-discharge-head-conflict]].
- **펌프 기동 과도 (신규 1차 데이터)**: 가정된 모터 가속토크 기준으로 전유량의 50%가 약 3/4초, 75%가 1-1/4초, 90%가 1-3/4초, 100%가 약 3초에 도달 (PDF p.184). → 현재 진행 중인 pump startup 벤치마크에 직접 관련.

## 추출된 정량값 (→ 03_Data)

| Item | 저장 위치 | Provenance |
|---|---|---|
| 연료염 3종 + 냉각염 물성(밀도/점도/비열/열전도도/liquidus) | [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]] | ORIGINAL (1차) |
| 설계유량, 입출구온도, 배관 규격, 펌프 제원·기동시간 | [[03_Data/msre/geometry/msre-primary-loop-geometry]] | ORIGINAL (1차) |

## 기존 위키/데이터와의 관계
- **provenance 격상**: 기존에 Leandro 2019(2차)를 Source로 기록했던 값들 중 유량·온도·염 물성을 이 1차 보고서로 교체.
- **⚠️ 충돌 발견**: 펌프 discharge head — [[02_Wiki/issues/pump-discharge-head-conflict]].
- 신규 추가: 점도·열전도도·liquidus 온도, 냉각염(2차 계통 염) 물성, 펌프 기동 과도 시간.

## 아직 안 본 부분
575페이지 중 극히 일부만 대조함. Core geometry 상세(채널 치수, 흑연 stringer 배열), HX 상세, drain tank, 계측 등은 필요 시 추가 ingest.

## 관련 페이지
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
- [[02_Wiki/systems/msre/components/fuel-pump]]
- [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]]
