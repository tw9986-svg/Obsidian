---
type: issue
status: resolved
date: {{date:YYYY-MM-DD}}
resolved: {{date:YYYY-MM-DD}}
systems: [msre]
tags: [data-quality, pdf-extraction]
---

# Leandro et al. 2019 — Table 2/3 PDF 텍스트 추출 실패 (해결됨)

## 문제 설명
`pdftotext -layout`으로 2단 레이아웃 PDF를 변환할 때 Table 2(MSRE Heat Exchanger Dimensions)와 Table 3(SAM/RELAP5-3D/Historical 비교)의 라벨-값 정렬이 깨져, 어떤 값이 어떤 파라미터에 속하는지 텍스트만으로 확정할 수 없었다. 추정 금지 원칙에 따라 해당 값들을 UNKNOWN으로 보류했었다.

## 발견 경위
[[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]] ingest 중 발견.

## 해결
2026-09-02: `winget install oschwartz10612.Poppler`로 poppler-utils 설치 → `pdftoppm -png -r 200`으로 해당 페이지(journal p.63–66)를 이미지로 렌더링해 표를 육안 확인.

- **Table 2 (HX 치수, 15항목 전체 확보)**: Triangular Pitch 0.0197 m, Outer Tube Dia 0.0127 m, Tube Thickness 0.00107 m, Inner Tube Dia 0.0106 m, Tube Flow Area 0.0279 m², Baffle Spacing 0.305 m, Outer Shell Dia 0.406 m, Shell Thickness 0.0127 m, Inner Shell Dia 0.381 m, Tube Clearance 0.00699 m, Shell Flow Area 0.0412 m², Tube Hyd Dia 0.0209 m, Shell Hyd Dia 0.0130 m, Tube Surface Area Density 378 m⁻¹, Shell Surface Area Density 308 m⁻¹. → [[03_Data/msre/geometry/msre-primary-loop-geometry]]
- **Table 3 (미확정 4행 확보)**: Inlet Pipe Velocity 5.87/5.85/5.85 m/s, Downcomer Velocity 0.66/0.66/1.68 m/s, Core Head Loss 1.91/1.78/1.79 kPa, System Head Loss 44.9/44.7/44.8 kPa. → [[03_Data/msre/benchmark/sam-relap5-3d-historical-primary-loop]]
- Table 4·5(연료염 조성/물성)와 Table 1(loss coefficient)은 텍스트 추출 시 재구성한 값이 이미지 확인 결과와 **일치**함을 확인 (오류 없었음).

## 후속 (환경)
poppler-utils가 설치되어 이후 ingest에서는 그림·표를 이미지로 직접 확인할 수 있다. 단, winget이 시스템 PATH를 갱신했어도 실행 중인 세션에는 즉시 반영되지 않으므로, Read 도구의 PDF 페이지 렌더링이 실패하면 다음 경로를 PATH에 추가해 `pdftoppm`으로 PNG를 만든 뒤 그 이미지를 읽는 우회 방법을 쓴다:
`C:\Users\<user>\AppData\Local\Microsoft\WinGet\Packages\oschwartz10612.Poppler_*\poppler-25.07.0\Library\bin`

## 관련 페이지
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
