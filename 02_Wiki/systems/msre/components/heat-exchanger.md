---
type: component
system: msre
tags: [heat-exchanger, secondary-loop]
last_updated: {{date:YYYY-MM-DD}}
sources: [leandro-2019-sam-msre-thermal-hydraulic]
---
<!-- 저장 위치: 02_Wiki/systems/msre/components/ -->

# MSRE Heat Exchanger (1차-2차 열교환기)

## 개요 / 역할
U-tube 형식, 1차측 shell / 2차측 tube, 둘 다 Hastelloy-N. 수평 배치, 길이 1.83 m. 1차측(연료염)에서 2차측(coolant salt)으로 열을 전달해 core 발열을 계통 밖으로 방출.

## Geometry
세부 형상 치수(triangular pitch, tube/shell 직경·두께, baffle spacing 등)는 원 논문 Table 2에 있으나 PDF 텍스트 추출 실패로 미기록 — [[02_Wiki/issues/leandro2019-table-parsing]] 참고. 길이 1.83 m만 확보 ([[03_Data/msre/geometry/msre-primary-loop-geometry]]).

## 물성 / 파라미터
1차측 온도강하 936→908 K(28 K), 2차측 온도상승 825→866 K(41 K, historical) — SAM 결과는 825→882 K(16 K 오프셋). Secondary loop 유량 0.054 m³/s.

## 지배 물리 / 관련 개념
열교환기 열전달 (surface area density, 열전달계수 — 이 논문에서는 "expected ΔT를 맞추도록 조정"한 값이라 상관식 기반이 아님, CALIBRATED에 해당).

## 모델링 구현
아직 없음. Secondary loop는 이 논문에서도 "단순화된 열침(heat sink)"으로만 모델링됨 — 전체 2차 계통은 미포함.

## 관련 페이지
- [[02_Wiki/systems/msre/components/primary-loop]]
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
- [[02_Wiki/issues/leandro2019-table-parsing]]
