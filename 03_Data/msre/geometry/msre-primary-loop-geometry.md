---
type: data
system: msre
category: geometry
symbol: 
tags: [primary-loop, core, downcomer, plenum, fuel-channel, pump, geometry]
last_updated: {{date:YYYY-MM-DD}}
---
<!-- 저장 위치: 03_Data/msre/geometry/ -->

# MSRE Primary Loop Geometry

[[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]에서 추출. 2026-09-02에 1차 보고서 [[02_Wiki/sources/ornl-tm-728-robertson-1965]]·[[02_Wiki/sources/ornl-tm-730-haubenreich-1964]]를 확보해 **일부 항목을 1차 provenance로 격상**했다. 아래 "1차 확인 완료" 표가 격상된 항목, 그 다음 표가 아직 2차(Leandro 경유)인 항목이다.

## 값 — 1차 확인 완료 (ORNL 원 보고서 대조)

| Value | 원 단위 (1차) | Unit(SI) | Source | Page/Fig | Provenance | Confidence | Verification |
|---|---|---|---|---|---|---|---|
| 설계 유량 0.0757 | 1200 gpm | m3/s | [[02_Wiki/sources/ornl-tm-728-robertson-1965]] | PDF p.28/184 | ORIGINAL (1차) | high | verified (Leandro 0.076과 일치) |
| Core 입구/출구 온도 908.1 / 935.9 | 1175 / 1225 °F | K | 〃 | PDF p.~20,38 | ORIGINAL (1차) | high | verified (Leandro 908/936과 일치) |
| 배관 규격: 5-in. sched-40 INOR-8 (Hastelloy-N) | 5-in. sched-40 | - | 〃 | PDF p.~35 | ORIGINAL (1차) | high | verified (Leandro 수력직경 0.127 m와 정합) |
| Fuel pump: 설계속도 1150 rpm, 임펠러 0.292 m, 설계점 developed head 14.72 m(연료염 기준 0.324 MPa), 효율 80–85% | 1150 rpm, 11-1/2 in., 48.3 ft | - | 〃 | PDF p.184 | ORIGINAL (1차) | high | **conflicting** → [[02_Wiki/issues/pump-discharge-head-conflict]] (Leandro 0.092 MPa와 상충) |
| Fuel pump 기동 과도: 50% 유량 ≈0.75 s, 75% ≈1.25 s, 90% ≈1.75 s, 100% ≈3 s | 동일 | s | 〃 | PDF p.184 | ORIGINAL (1차, 가정 모터 토크 기반 계산) | medium | unverified (신규) |
| Core radius 0.7036 | 27.7 in. | m | [[02_Wiki/sources/ornl-tm-730-haubenreich-1964]] | PDF p.15 | ORIGINAL (1차) | high | verified (Leandro 0.705와 0.0014 m 차이, 반올림) |
| Core height 1.6002 | 63 in. | m | 〃 | PDF p.15 | ORIGINAL (1차) | high | verified (Leandro 1.60과 일치) |
| Core 외부 연료 체적 1.133 | 40 ft³ | m3 | 〃 | PDF p.15 | ORIGINAL (1차) | high | unverified (신규 — inventory/transit time 검증용) |

## 값 — 아직 2차 provenance (Leandro 2019 경유, 1차 미대조)

| Value | Unit | Source | Page/Fig | Provenance | Confidence | Model Usage | Verification |
|---|---|---|---|---|---|---|---|
| ~~MSRE 1차 루프 유량 0.076~~ → 1차 표로 이동 (1200 gpm) | m3/s | — | — | superseded | — | | superseded |
| ~~Core vessel 내경 0.705~~ → 1차 표로 이동 (27.7 in.) | m | — | — | superseded | — | | superseded |
| Core ring 개수 4 | - | [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]] | p.63 | ORIGINAL | high | | unverified |
| Core ring 폭(총반경/4) 0.176 | m | 〃 (derived from 0.705/4 in paper) | p.63 | DERIVED | high | | unverified |
| Fuel channel 개수 1140 | - | 〃 (원출처 Robertson 1965) | p.59 | ORIGINAL | high | | unverified |
| Fuel channel 합산 유동단면적 0.332 | m2 | 〃 (원출처 Carbajo et al. 2017) | p.63 | ORIGINAL | high | | unverified |
| Fuel channel 수력직경 0.0159 | m | 〃 (원출처 Carbajo et al. 2017) | p.63 | ORIGINAL | high | | unverified |
| ~~Fuel channel 높이 1.60~~ → 1차 표로 이동 (core height 63 in.) | m | — | — | superseded | — | | superseded |
| Downcomer 수력직경 0.0508 | m | 〃 (원출처 Haubenreich et al. 1964) | p.62 | ORIGINAL | medium | | unverified |
| Downcomer 유동단면적 0.116 | m2 | 〃 | p.62 | ORIGINAL | medium | | unverified |
| Lower plenum 높이 0.01 | m | 〃 (원출처 Haubenreich et al. 1964, 저자가 "복잡한 유동 반영해 최소화" 표현 — 실측이라기보다 모델링 단순화 가능성 있음) | p.62 | ORIGINAL | low | | unverified |
| Lower plenum 수력직경 1.47 | m | 〃 | p.62 | ORIGINAL | medium | | unverified |
| Lower/Upper plenum 유동단면적 1.71 | m2 | 〃 | p.62 | ORIGINAL | medium | | unverified |
| Upper plenum 높이 0.249 | m | 〃 | p.62 | ORIGINAL | medium | | unverified |
| Hydraulic mockup 배관 벽두께 0.0066 | m | 〃 (원출처 Robertson 1965, Schedule 40 carbon steel) | p.61 | ORIGINAL | medium | | unverified |
| Hydraulic mockup 배관 유동단면적 0.0127 | m2 | 〃 | p.61 | ORIGINAL | medium | | unverified |
| Hydraulic mockup 배관 수력직경 0.127 | m | 〃 | p.61 | ORIGINAL | medium | | unverified |
| 배관 조도 1.00e-4 | m | 〃 (Leandro et al. 2019 저자 가정, 출처 없음) | p.61 | ASSUMED | low | | unverified |
| ⚠️ Fuel pump 토출수두 0.092 (Leandro 주장) vs 0.324 (TM-728 48.3 ft 환산) | MPa | 〃 (Leandro가 Robertson 1965로 인용) | p.63 | ORIGINAL(2차) — 값 자체 상충 | low | | **conflicting** → [[02_Wiki/issues/pump-discharge-head-conflict]] |
| Fuel pump 유량 171 | kg/s | 〃 | p.63 | ORIGINAL | high | | verified (1200 gpm × ρ=2243과 정합, 0.0762 m³/s) |
| Secondary loop 유량 0.054 | m3/s | 〃 (원출처 Robertson 1965) | p.63 | ORIGINAL | high | | unverified |
| Secondary loop 입구온도 825 | K | 〃 (원출처 Robertson 1965) | p.63 | ORIGINAL | high | | unverified |
| HX 길이 1.83 | m | 〃 (원출처 Kedl & McGlothlan 1968) | p.63 | ORIGINAL | medium | | unverified |
| ~~Core 입구/출구 온도 908 / 936~~ → 1차 표로 이동 (1175/1225 °F) | K | — | — | superseded | — | | superseded |
| ~~Core 발열 분배 94%/6%~~ → 1차 확인 완료, [[03_Data/msre/geometry/ornl-tm-0378-core-thermal-basis]]로 이동 (ORNL-TM-0378 p.40 각주, **ASSUMED**) | - | — | — | superseded | — | | superseded |
| 설계출력 10 / 실제운전출력 8 | MWt | 〃 | p.59 | ORIGINAL | high | | unverified |
| Core 체적발열원(SAM 모델, 10MWt 전량 유체투입 가정) 1.88e7 | W/m3 | 〃 (본 논문에서 10MWt÷4-ring 유체체적으로 계산) | p.63 | DERIVED | medium | Leandro 2019 SAM 모델 한정 (실제 94/6 분배 아님) | unverified |
| MSRE Hydraulic Mockup Loss Coefficients (Table 1): Inlet Horiz. Piping in/out=Not Used/0.397, Downcomer=0.496/0.869, Lower Plenum=0/0.649, Core Rings=16.7/17.0, Upper Plenum=0.447/0.985, Outlet Horiz. Piping=0.0/Not Used | - | 〃 (원출처 Todreas & Kazimi 2012 공식으로 계산) | Table 1 | DERIVED | high (이미지로 재확인) | | unverified |
| HX Triangular Pitch 0.0197 | m | 〃 (원출처 Kedl & McGlothlan 1968) | Table 2 (재확인) | ORIGINAL | high (이미지로 재확인) | | unverified |
| HX Outer Tube Diameter 0.0127 | m | 〃 | Table 2 | ORIGINAL | high | | unverified |
| HX Tube Thickness 0.00107 | m | 〃 | Table 2 | ORIGINAL | high | | unverified |
| HX Inner Tube Diameter 0.0106 | m | 〃 (Calculated, 본 논문 저자 계산) | Table 2 | DERIVED | high | | unverified |
| HX Tube Flow Area 0.0279 | m2 | 〃 (Calculated) | Table 2 | DERIVED | high | | unverified |
| HX Baffle Spacing 0.305 | m | 〃 (원출처 Kedl & McGlothlan 1968) | Table 2 | ORIGINAL | high | | unverified |
| HX Outer Shell Diameter 0.406 | m | 〃 | Table 2 | ORIGINAL | high | | unverified |
| HX Shell Thickness 0.0127 | m | 〃 | Table 2 | ORIGINAL | high | | unverified |
| HX Inner Shell Diameter 0.381 | m | 〃 (Calculated) | Table 2 | DERIVED | high | | unverified |
| HX Tube Clearance 0.00699 | m | 〃 (Calculated) | Table 2 | DERIVED | high | | unverified |
| HX Shell Flow Area 0.0412 | m2 | 〃 (Calculated) | Table 2 | DERIVED | high | | unverified |
| HX Tube Hydraulic Diameter 0.0209 | m | 〃 (Calculated) | Table 2 | DERIVED | high | | unverified |
| HX Shell Hydraulic Diameter 0.0130 | m | 〃 (Calculated) | Table 2 | DERIVED | high | | unverified |
| HX Tube Surface Area Density 378 | m-1 | 〃 (Calculated) | Table 2 | DERIVED | high | | unverified |
| HX Shell Surface Area Density 308 | m-1 | 〃 (Calculated) | Table 2 | DERIVED | high | | unverified |

## Provenance 근거
Robertson(1965, ORNL-TM-728), Haubenreich et al.(1964, ORNL-TM-730), Kedl(1970, ORNL-TM-3229), Kedl & McGlothlan(1968, ORNL-TM-2098), Carbajo et al.(2017, RELAP5-3D 논문)의 값을 Leandro et al.(2019)가 표/본문에 재인용한 것. 1차 보고서 원문은 아직 미확보 — 확보 시 Source를 1차로 교체하고 이 페이지의 Source 컬럼을 갱신할 것.

Table 1(loss coefficients)·Table 2(HX 치수)는 2026-09-02에 poppler-utils(pdftoppm) 설치 후 PDF 페이지를 이미지로 렌더링해 **육안 재확인**함 — 초기 `pdftotext` 추출 시의 라벨-값 정렬 붕괴 문제 해소 ([[02_Wiki/issues/leandro2019-table-parsing]] resolved). Table 2에서 "Kedl and McGlothlan (1968)" 출처 항목은 ORIGINAL, "Calculated" 항목은 본 논문 저자가 Lee(2010) 공식으로 계산한 값이므로 DERIVED로 분류.

## 값 간 불일치 / 논의
없음 (첫 ingest). Core 입구/출구온도(908/936K)는 "historical calculation"이지 실측이 아님을 유의 — 향후 실측 데이터 확보 시 대조 필요.

## 어디에 쓰이나
[[02_Wiki/systems/msre/components/primary-loop]], [[02_Wiki/systems/msre/components/core]], [[02_Wiki/systems/msre/components/heat-exchanger]], [[02_Wiki/systems/msre/components/fuel-pump]]

## 관련 페이지
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
- [[03_Data/registry]]
