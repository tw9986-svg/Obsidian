---
type: source
title: "Engel & Haubenreich 1962 — ORNL-TM-0378, Temperatures in the MSRE Core During Steady-State Power Operation"
raw: "[[01_Raw/literature/ORNL-TM-0378 Engel and Haubenreich 1962 - Temperatures in the MSRE Core During Steady-State Power Operation]]"
source_kind: report
systems: [msre]
date_ingested: {{date:YYYY-MM-DD}}
tags: [ornl, primary-source, core-temperature, power-distribution, graphite]
status: partial
---

# ORNL-TM-0378 (Engel & Haubenreich 1962) — 정상출력 운전 시 MSRE 노심 온도

## 메타데이터
- 저자/기관: J. R. Engel, P. N. Haubenreich, Oak Ridge National Laboratory
- 발행: 1962, 58 페이지 (스캔 OCR본)
- 원본: [[01_Raw/literature/ORNL-TM-0378 Engel and Haubenreich 1962 - Temperatures in the MSRE Core During Steady-State Power Operation]]
- 중복본: `00_Inbox/ORNL-TM-0378.pdf` (동일 파일, 별도 ingest 안 함)

## 왜 중요한가
1. **Leandro가 인용한 908/936 K의 원출처**이며, 실제로는 **세 가지 서로 다른 온도 경계 정의**가 있음을 밝혀준다.
2. **흑연 발열분율 6%의 1차 근거**가 여기 있다 (p.40 각주).
3. 우리 코드에 `Verification/ORNL0378/` 전용 패키지가 있을 만큼 축·반경 방향 출력분포 검증의 기준 문서다.

## 문서의 성격 (중요)
이 보고서는 **유동 모델 + 핵 출력분포 + 열계산**의 조합이며, **수록된 값 중 측정값은 없다**. 코드도 이 값들을 `HISTORICAL_CALCULATION_INPUT`로 분류해 현대 물성 패키지와 격리한다. 값을 인용할 때 반드시 이 성격을 병기할 것.

## 원문 직접 확인한 핵심 사항

| 항목 | 원문 근거 | 확인 |
|---|---|---|
| "it was assumed that **6%** of the reactor power [is generated in the graphite]" — 근거는 **C. W. Nestor의 미출간 계산** | p.40 각주 | ✅ 원문 확인 → **ASSUMED** |
| 연료·흑연 열전도도 "were assumed to be **3.21 and 13** Btu/hr·ft·°F" | p.40 각주 | ✅ 원문 확인 → **ASSUMED** |
| Reactor 입/출구 **1175 / 1225 °F** | Table 4 각주 c, p.929행 본문 | ✅ |
| **Main-core** 입구 **1177.3 °F**, mixed-mean 출구 1220.8 °F | p.33 | ✅ — reactor 경계와 다름 |
| Nuclear mean fuel temperature **1213 °F** | 요약 p.1 | ✅ |
| Region 2(주 노심) = **940 fuel channels**, 연료분율 0.224, 등가반경 24.76 in | Table 2 및 본문 | ✅ — 전체 1140개 중 940개만 주 노심 |
| 최대 국부 흑연–연료 온도차 **62.5 °F** (연료침투 0%) | Table 5 | ✅ |

값 전체: [[03_Data/msre/geometry/ornl-tm-0378-core-thermal-basis]]

## 기존 위키/데이터와의 관계

- ✅ **UNKNOWN 해소**: [[02_Wiki/issues/graphite-heating-fraction-provenance]] — 6%의 1차 근거 확인, provenance를 ORIGINAL(2차) → **ASSUMED(1차 확인)** 으로 정정.
- ✅ **우려 해소**: 연료염 열전도도 5.5 W/m·K는 1962년 **가정값**이며, production 패키지는 보정된 1.0 W/m·K를 쓴다 (코드 주석 기준).
- ⚠️ **정밀화 필요**: 기존에 "Core 입구/출구 908/936 K"로 단일 기록했던 것을 **reactor 경계 vs main-core 경계**로 분리해야 함. 노심 전용 모델은 909.43/933.59 K를 써야 한다.
- ⚠️ **채널 수 구분**: 위키의 "fuel channel 1140개"는 **압력용기 전체** 기준이며, 주 노심은 940개다. 열수력 노달화(15 ring × 20 axial)가 어느 쪽을 대상으로 하는지 확인 필요.
- 축방향 peak-to-average = 1.3585 (π/2 아님) — 현재 진행 중인 축방향 출력분포 재현 작업의 기준값.

## 아직 안 본 부분
58페이지 중 위 항목 위주로만 대조. Fig. 4(반경 분포)·Fig. 13/14(반경·축 온도) 그림 판독값은 코드의 `tools/digitize_ornl0378.py`가 생성한 CSV(`Verification/ORNL0378/data/`)로 존재하며, **그 값들은 DIGITIZED provenance로 별도 관리 대상** — 아직 위키에 미편입.

## 관련 페이지
- [[03_Data/msre/geometry/ornl-tm-0378-core-thermal-basis]]
- [[02_Wiki/systems/msre/components/core]]
- [[02_Wiki/systems/msre/implementation/msre-transform-model]]
