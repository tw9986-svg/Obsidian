---
type: source
title: "ORNL-TM-0380 (1962) — Prediction of Effective Yields of Delayed Neutrons in MSRE"
raw: "[[01_Raw/literature/ORNL-TM-0380 - Prediction of Effective Yields of Delayed Neutrons in MSRE]]"
source_kind: report
systems: [msre]
date_ingested: {{date:YYYY-MM-DD}}
tags: [ornl, primary-source, delayed-neutron, beta-eff, transit-time]
status: partial
---

# ORNL-TM-0380 (1962) — MSRE 유효 지연중성자 수율 예측

## 메타데이터
- 기관: Oak Ridge National Laboratory
- 발행: 1962, 28 페이지 (스캔 OCR본 — OCR 품질 낮아 **수치는 페이지 이미지로 판독**)
- 원본: [[01_Raw/literature/ORNL-TM-0380 - Prediction of Effective Yields of Delayed Neutrons in MSRE]]

## 왜 중요한가
순환연료 원자로의 핵심 물리인 **DNP drift로 인한 유효 지연중성자분율 감소**를 MSRE에 대해 1962년에 직접 계산한 1차 문서. 우리 모델의 `Beta_eff`(정적 vs 순환)와 전이시간의 **독립적 1차 대조 기준**을 제공한다.

## 핵심 확인 사항 (이미지 직접 판독)

### 유효 지연중성자 분율 (Table 2, p.17)
- Actual yield Σβ_i = 0.006405
- **Static** effective Σβ*_is = **0.006661**
- Fraction emitted in core (circulating) Σβ_iθ_i = 0.003942
- **Circulating** effective Σβ*_i = **0.003617**

요약(p.1)의 반올림 표현: 총 수율 0.0064, 정적/순환 유효수율 0.0067 / 0.0036.

### MSRE 전이시간 (p.21)
- 노심 체류시간 **t_c = 9.37 s** @1200 gpm, 유속 0.61 ft/s
- 총 순환 연료 체적 **69.1 ft³ (1.9567 m³)**, 총 순환시간 **25.82 s**
- 외부루프 **t_x = 16.45 s**
- 축방향 분열분포 sin(πz/H), **H = 77.7 in** (코드의 `z_shape_period_in`과 일치)
- 단순화된 "core": 흑연 최상단~최하단 H = 68.9 in, 총 96.4 ft³ 중 연료 25.0 ft³ → f = 0.259
- 반경방향 유속 편차: 3/4 이상 채널이 0.60 ft/s인데 **중심 채널은 3배 이상**

값 전체: [[03_Data/msre/kinetics/ornl-tm-0380-effective-yields-and-transit-times]]

### 사용된 핵데이터
지연중성자 수율·반감기는 **Keepin, Wimett & Zeigler**의 U-235 열중성자 분열 데이터 (p.21, Table A-1).

## 기존 위키/데이터와의 관계

- 🔍 **중요 발견**: TRANSFORM의 순환 연료 체적(2.0965 m³)이 ORNL 1차 값(1.9567 m³)보다 **7.14% 크고**, 전이시간 차이(+7.09%)와 산술적으로 일치 → 전이시간 벤치마크 차이의 유력한 원인. 단 경계 정의 확인 전까지 **원인 미확정** 유지. → [[03_Data/msre/kinetics/ornl-tm-0380-effective-yields-and-transit-times]]
- ⚠️ **신규 충돌**: circulating β_eff — TM-0380 0.003617 vs 모델 ≈0.0045 (**24% 차이**). static도 0.006661 vs 0.006781. → [[02_Wiki/issues/beta-eff-circulating-discrepancy]]
- ✅ **기존 값 확인**: 축방향 형상 파라미터 H = 77.7 in이 코드 전사값과 일치.
- 전이시간 후보값이 이제 4종: 25.2(실험 보고) / 25.63~25.70(Jeong MARS) / **25.82(ORNL 1차 계산)** / 27.651(TRANSFORM) → [[02_Wiki/issues/jeong-transit-time-value-mismatch]]에 반영.

## 아직 안 본 부분
28페이지 중 Table 2·p.21 데이터 절 위주. 군별 β*_i 상세(Table 1), θ_i 계산 방법, 중요도 가중 유도는 미정독 — DNP transport 모델의 중요도 가정(φ*=1)을 검토할 때 필요.

## 관련 페이지
- [[03_Data/msre/kinetics/ornl-tm-0380-effective-yields-and-transit-times]]
- [[03_Data/msre/kinetics/delayed-neutron-parameters]]
