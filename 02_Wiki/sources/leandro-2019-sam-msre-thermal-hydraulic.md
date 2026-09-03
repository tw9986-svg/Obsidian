---
type: source
title: "Leandro et al. 2019 — Thermal hydraulic model of the MSRE with the NEAMS system analysis module (SAM)"
raw: "[[01_Raw/literature/Leandro et al 2019 - Thermal hydraulic model of the molten salt reactor experiment]]"
source_kind: literature
systems: [msre]
date_ingested: {{date:YYYY-MM-DD}}
tags: [sam, benchmark, primary-loop, hydraulic-mockup]
status: processed
---

# Leandro et al. 2019 — Thermal hydraulic model of the MSRE with SAM

## 메타데이터
- 저자/기관: Adrian M. Leandro, Florent Heidet, Rui Hu, Nicholas R. Brown (Penn State / Argonne National Laboratory)
- 학술지: Annals of Nuclear Energy 126 (2019) 59–67
- 원본: [[01_Raw/literature/Leandro et al 2019 - Thermal hydraulic model of the molten salt reactor experiment]]

## 핵심 주장 요약
- ORNL의 공개 문헌에서 MSRE 시스템코드 모델링용 정보를 최초로 한 곳에 집대성 (1-D primary loop 기술서).
- SAM으로 (1) MSRE hydraulic mockup(물 실험, 무가열) 모델과 (2) MSRE 실제 primary loop(가열, FLiBe) 모델 두 가지를 구축.
- Hydraulic mockup: SAM 압력강하 결과가 측정값과 6% 이내로 일치.
- Primary loop: SAM 냉각재 온도가 historical calculation과 정성적으로 일치하나 core inlet/outlet 각각 3 K 오프셋 존재.
- FLiBe 대신 실제 MSRE 3종 연료염 물성을 적용하면 온도 profile이 달라짐 (밀도·점도 상승, 비열 감소).
- LOF(pump coastdown) 과도해석 데모 — DNP가 loop 전체를 순환하며 추적 가능함을 시사, 중성자학 결합 필요성 제기.
- 본 논문 자체가 여러 1차 ORNL 보고서(Robertson 1965 = ORNL-TM-728, Haubenreich et al. 1964 = ORNL-TM-730, Kedl 1970 = ORNL-TM-3229, Kedl & McGlothlan 1968 = ORNL-TM-2098, Engel & Haubenreich 1962 = ORNL-TM-378)의 값을 종합 인용한 2차 출처. 값의 원출처는 아래 각 항목에 병기.

## 추출된 수식
없음 (본 논문은 SAM 내장 상관식/EOS를 사용하고 별도 수식 유도는 제시하지 않음. FLiBe EOS 식은 Hu 2017 SAM Theory Manual 참조로만 언급 — 별도 미확보).

## 추출된 정량값 (→ 03_Data)

| Item | 저장 위치 | Provenance |
|---|---|---|
| MSRE primary loop geometry (core/downcomer/plenum/channel/pipe) | [[03_Data/msre/geometry/msre-primary-loop-geometry]] | ORIGINAL (2차 인용, 원출처 병기) |
| MSRE 연료염 3종 물성 (밀도/점도/비열 @922K) | [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]] | ORIGINAL |
| SAM vs RELAP5-3D vs Historical 벤치마크 비교값 (Table 3, 8행 전체) | [[03_Data/msre/benchmark/sam-relap5-3d-historical-primary-loop]] | ORIGINAL |
| HX 형상치수 (Table 2, 15항목) | [[03_Data/msre/geometry/msre-primary-loop-geometry]] | ORIGINAL(측정/보고) + DERIVED(저자 계산) |
| Hydraulic mockup loss coefficients (Table 1) | [[03_Data/msre/geometry/msre-primary-loop-geometry]] | DERIVED (Todreas & Kazimi 공식 계산) |
| Core 체적발열 1.88e7 W/m³ (SAM 모델 가정, 10 MWt 전량 유체 투입 기준) | [[03_Data/msre/geometry/msre-primary-loop-geometry]] | DERIVED |

## 표 추출 품질 (해결됨)
초기 `pdftotext` 추출 시 2단 레이아웃 때문에 Table 2·3의 라벨-값 정렬이 깨져 일부 값을 UNKNOWN으로 보류했으나, poppler-utils 설치 후 PDF 페이지를 이미지로 렌더링해 **전 항목 확인 완료** → [[02_Wiki/issues/leandro2019-table-parsing]] (resolved). Table 1·4·5는 텍스트 기반 재구성이 이미지 확인 결과와 일치했음.

## Geometry
MSRE core vessel 내경 0.705 m, 4 core ring (ring 두께 0.176 m), fuel channel 1140개 (합산 유동단면적 0.332 m², 수력직경 0.0159 m, 높이 1.60 m), downcomer/plenum 치수 등 — 상세는 [[03_Data/msre/geometry/msre-primary-loop-geometry]].

## 가정
- SAM 모델은 core power 100%를 유체에 투입 가정 (실제 MSRE는 94% 유체/6% 흑연 분배, Carbajo et al. 2017 인용).
- Hydraulic mockup pipe roughness 1.00e-4 m — 저자 가정값(ASSUMED), 출처 없음.
- LOF pump coastdown curve는 Gao et al. (2010) 곡선을 차용 (MSRE 고유 실측 아님).

## 모델 구조 (해당 시)
SAM(NEAMS System Analysis Module) 1-D pipe/branch/junction 노달화. Hydraulic mockup과 primary loop 두 모델. Volumetric heat source로 core 가열 구현, U-tube HX + 단순화된 secondary loop.

## 검증/벤치마크 결과 (해당 시)
- Hydraulic mockup 압력강하: 측정값 대비 6% 이내.
- Primary loop core Tin/Tout: SAM 905/933 K vs historical(Engel & Haubenreich 1962) 908/936 K (Δ3K, ΔT는 32K vs historical 28K 근사 일치).
- RELAP5-3D(Carbajo et al. 2017)와도 Tin/Tout 908/936 K로 SAM과 근접 (Table 3, 단 일부 행은 파싱 미확정).

## 기존 위키/데이터와의 관계
- 새로 추가: MSRE geometry, 연료염 물성 3종, SAM 벤치마크 결과 — 이 라이브러리 최초 ingest이므로 충돌 없음.
- 기존 주장 강화: 없음 (첫 소스).
- ⚠️ 충돌: 없음.
- 등록된 issue: [[02_Wiki/issues/leandro2019-table-parsing]] (표 파싱 실패, Table 2 전체 + Table 3 일부 행 UNKNOWN)

## 관련 페이지
- [[02_Wiki/systems/msre/components/primary-loop]]
- [[02_Wiki/systems/msre/components/core]]
- [[02_Wiki/systems/msre/components/heat-exchanger]]
- [[02_Wiki/systems/msre/components/fuel-pump]]
- [[02_Wiki/systems/msre/benchmark/sam-msre-primary-loop]]
- [[04_Projects/msre-transform-status]]
