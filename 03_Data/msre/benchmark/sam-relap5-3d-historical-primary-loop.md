---
type: data
system: msre
category: benchmark
symbol: 
tags: [sam, relap5-3d, benchmark, primary-loop]
last_updated: {{date:YYYY-MM-DD}}
---
<!-- 저장 위치: 03_Data/msre/benchmark/ -->

# SAM vs RELAP5-3D vs Historical Calculation — MSRE Primary Loop (Leandro et al. 2019, Table 3)

Leandro et al.(2019) Table 3 전체. 초기 `pdftotext` 추출 시 라벨-값 정렬이 깨져 4행을 UNKNOWN으로 보류했으나, 2026-09-02 poppler-utils 설치 후 PDF 페이지 이미지 렌더링으로 **전 행 확인 완료**.

컬럼 성격 구분: **SAM**과 **RELAP5-3D**는 각 코드의 계산 결과(모델 출력), **Historical Calculations**는 MSRE 당시 계산값(Engel & Haubenreich 1962; hydraulic mockup 항목은 Kedl 1970 측정값). MSRE 실측 데이터는 hydraulic mockup 관련 항목(Downcomer Velocity 1.68 m/s 등)에 한정됨.

## 값

| Value | Unit | Source | Page/Fig | Provenance | Confidence | Model Usage | Verification |
|---|---|---|---|---|---|---|---|
| Core Coolant Tin: SAM 905 / RELAP5-3D 908 / Historical 908 | K | [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]] | Table 3 | ORIGINAL | high | | unverified |
| Core Coolant Tout: SAM 933 / RELAP5-3D 936 / Historical 936 | K | 〃 | Table 3 | ORIGINAL | high | | unverified |
| Coolant Flow Rate: SAM 0.076 / RELAP5-3D 0.077 / Historical 0.076 | m3/s | 〃 | Table 3 | ORIGINAL | high | | unverified |
| Core Velocity: SAM 0.23 / RELAP5-3D 0.20–0.50 / Historical 0.18–0.61 | m/s | 〃 | Table 3 | ORIGINAL | high | | unverified |
| Inlet Pipe Velocity: SAM 5.87 / RELAP5-3D 5.85 / Historical 5.85 | m/s | 〃 | Table 3 | ORIGINAL | high (이미지 재확인) | | unverified |
| Downcomer Velocity: SAM 0.66 / RELAP5-3D 0.66 / Historical(=Kedl 1970 측정) 1.68 | m/s | 〃 | Table 3 | ORIGINAL | high (이미지 재확인) | | unverified |
| Core Head Loss: SAM 1.91 / RELAP5-3D 1.78 / Historical 1.79 | kPa | 〃 | Table 3 | ORIGINAL | high (이미지 재확인) | | unverified |
| System Head Loss: SAM 44.9 / RELAP5-3D 44.7 / Historical 44.8 | kPa | 〃 | Table 3 | ORIGINAL | high (이미지 재확인) | | unverified |

## Provenance 근거
전 행이 Leandro et al.(2019) Table 3에 그대로 제시된 값(ORIGINAL). Tin/Tout/Core Velocity는 본문 서술과도 교차검증됨. 나머지 4행은 PDF 페이지 이미지(pdftoppm 200 dpi, journal p.65)를 직접 확인해 기록.

## 값 간 불일치 / 논의
- **Downcomer Velocity**: SAM(0.66)·RELAP5-3D(0.66) vs 측정값(1.68 m/s) — 2.5배 차이. 저자는 downcomer가 실제로 3-D annulus 유동인데 두 코드 모두 1-D로 단순화했기 때문으로 해석. 우리 TRANSFORM 모델도 동일한 1-D 단순화를 쓴다면 같은 편차가 예상됨 → [[02_Wiki/systems/msre/benchmark/sam-msre-primary-loop]]에서 추적.
- Core/System Head Loss는 세 값이 1% 이내로 근접 (Core 1.78–1.91 kPa, System 44.7–44.9 kPa).

## 어디에 쓰이나
[[02_Wiki/systems/msre/benchmark/sam-msre-primary-loop]], [[04_Projects/msre-transform-status]] (TRANSFORM 결과와의 3자 비교 기준선)

## 관련 페이지
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
- [[02_Wiki/issues/leandro2019-table-parsing]] (resolved)
- [[03_Data/registry]]
