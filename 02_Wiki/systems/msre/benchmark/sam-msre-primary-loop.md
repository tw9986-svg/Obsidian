---
type: benchmark
system: msre
tags: [sam, relap5-3d, primary-loop, hydraulic-mockup]
status: reference (외부 코드간 비교, TRANSFORM 미포함)
last_updated: {{date:YYYY-MM-DD}}
---
<!-- 저장 위치: 02_Wiki/systems/msre/benchmark/ -->

# SAM MSRE 모델 vs 측정값/RELAP5-3D/Historical Calculation

## 비교 대상
NEAMS SAM 코드로 구축한 (1) MSRE hydraulic mockup 모델 vs Kedl(1970) 측정값, (2) MSRE primary loop 모델 vs historical calculation(Engel & Haubenreich 1962) 및 RELAP5-3D(Carbajo et al. 2017). **TRANSFORM/Dymola 결과는 포함되지 않음** — 이 페이지는 향후 TRANSFORM 결과를 놓을 3자 비교의 참고 기준선(reference baseline)으로 사용.

## 조건 / Case Setup
- Hydraulic mockup: 무가열 물 실험, 유량 range 스윕, 압력강하 비교.
- Primary loop: FLiBe(SAM 내장) 및 MSRE 실제 연료염 3종([[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]])으로 정상상태 core/HX 축방향 온도profile 비교. LOF(pump coastdown) 과도해석 데모(중성자학 미결합).

## 결과 비교
값 상세: [[03_Data/msre/benchmark/sam-relap5-3d-historical-primary-loop]].
- Hydraulic mockup 압력강하: SAM이 측정값과 6% 이내 일치.
- Core Tin/Tout: SAM 905/933 K, RELAP5-3D·Historical 908/936 K (Δ3K).
- Core velocity: SAM 0.23 m/s, RELAP5-3D 0.20–0.50 m/s, Historical range 0.18–0.61 m/s.
- Downcomer 하부 유속: SAM 0.66 m/s vs Kedl(1970) 측정 1.68 m/s — SAM이 3-D 유동을 1-D로 단순화한 데서 오는 과소예측으로 저자가 해석.

## 오차 / 편차 분석
- Core 온도 3K 오프셋: 저자는 HX 근사(열전달계수를 ΔT 맞춤용으로 조정) 및 SAM FLiBe EOS와 실제 MSRE 염 물성 차이를 원인으로 지목.
- Downcomer 유속 과소예측: 3-D annulus를 1-D pipe로 단순화한 모델링 한계 (CFD 필요하다고 저자가 명시).

## 결론 및 오차원인 추정
Primary loop 1-D 모델링 접근 자체는 타당(RELAP5-3D와도 근접)하나, downcomer처럼 본질적으로 3-D인 영역은 1-D 근사의 한계가 뚜렷함. 우리 TRANSFORM 모델에서도 동일한 downcomer/plenum 3-D 단순화가 있다면 유사한 과소예측 가능성 있음 — 향후 TRANSFORM 결과 확보 시 이 페이지에 3열로 추가 비교.

## 관련 페이지
- [[02_Wiki/systems/msre/components/primary-loop]]
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
- [[04_Projects/msre-transform-status]]
