# 인덱스 — 원자력 열수력 / Dymola 원자로 코드 라이브러리

> 소스를 편입하거나 새 페이지를 만들 때마다 이 파일을 갱신합니다. 질문에 답할 때는 먼저 [[02_Wiki/overview]]와 이 파일에서 관련 페이지를 찾은 뒤 드릴다운합니다. 정량값은 [[03_Data/registry]]를 먼저 확인합니다.

## Overview
- [[02_Wiki/overview]] — 라이브러리 전체 목표, 다루는 시스템 목록

## Systems
- [[02_Wiki/systems/msre/overview]] — MSRE (Molten Salt Reactor Experiment)
- [[04_Projects/msre-transform-status]] — MSRE 연구 진행 상황

## Sources (`02_Wiki/sources/`)
- [[02_Wiki/sources/ornl-tm-728-robertson-1965]] — **1차** ORNL 설계보고서 Part I (설계값·염 물성·펌프)
- [[02_Wiki/sources/ornl-tm-730-haubenreich-1964]] — **1차** ORNL 설계보고서 Part III (핵해석·노심 형상)
- [[02_Wiki/sources/jeong-2026-mars-msre-benchmark]] — MARS 벤치마크 원 논문 (우리 TRANSFORM 모델의 직접 기반)
- [[02_Wiki/sources/ornl-tm-0378-engel-haubenreich-1962]] — **1차** 노심 온도·출력분포 (흑연 6% 발열분율 근거)
- [[02_Wiki/sources/ornl-tm-0380-effective-delayed-neutron-yields]] — **1차** 유효 지연중성자 수율·전이시간
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]] — SAM(NEAMS) MSRE 열수력 모델

> **Source 페이지 미작성 원본 18건**이 2026-09-03 분류를 거쳐 `01_Raw/literature/`에 보존되어 있습니다.
> 목록·성격·ingest 우선순위: [[02_Wiki/reviews/2026-09-03-inbox-raw-code-classification]]

## Concepts (`02_Wiki/concepts/`, 전역 — 일반 물리)

(아직 없음 — DNP transport·point kinetics·자연순환 등 개념 페이지 신설 예정)

## Equations (`02_Wiki/equations/`, 전역)

- [[02_Wiki/equations/thermal-hydraulics-foundations]] — 보존법칙, 유동/열전달 폐쇄식, 펌프·자연순환·DNP 결합과 검증 순서

## Data (`03_Data/`)
- [[03_Data/registry]] — 전 시스템 통합 정량값 마스터 테이블 (provenance 포함)

### MSRE
- [[03_Data/msre/geometry/msre-primary-loop-geometry]] — 1차 계통 형상·설계값 (1차/2차 provenance 구분)
- [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]] — 연료염 3종+냉각염 물성 (1차)
- [[03_Data/msre/kinetics/delayed-neutron-parameters]] — 6군 지연중성자·온도계수 (Jeong Table 1–3, 코드값 대조 완료)
- [[03_Data/msre/kinetics/ornl-tm-0380-effective-yields-and-transit-times]] — **1차** β_eff(정적/순환)·전이시간·순환 체적
- [[03_Data/msre/geometry/ornl-tm-0378-core-thermal-basis]] — **1차** 노심 온도경계 3종·주노심 940채널·흑연 6%(ASSUMED)
- [[03_Data/msre/benchmark/sam-relap5-3d-historical-primary-loop]] — SAM/RELAP5-3D/Historical 비교
- [[03_Data/msre/benchmark/transform-b0-vs-jeong-mars]] — TRANSFORM B0 vs MARS vs 실측

## Components (`02_Wiki/systems/msre/components/`)
- [[02_Wiki/systems/msre/components/primary-loop]]
- [[02_Wiki/systems/msre/components/core]]
- [[02_Wiki/systems/msre/components/heat-exchanger]]
- [[02_Wiki/systems/msre/components/fuel-pump]]

## Implementation (`02_Wiki/systems/msre/implementation/`)
- [[02_Wiki/systems/msre/implementation/msre-transform-model]] — canonical 코드 구조·물리·입력 provenance·가정
- [[02_Wiki/systems/msre/implementation/code-provenance-tags]] — 코드 내 provenance 태그 16종 ↔ 위키 8종 대응표, 인용 출처 인벤토리·보유 현황

## Verification (`02_Wiki/systems/msre/verification/`)
- [[02_Wiki/systems/msre/verification/dymola-b0-baseline]] — Dymola B0 고정 기준값 + cross-tool 비교

## Benchmark (`02_Wiki/systems/msre/benchmark/`)
- [[02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars]] — pump 과도 벤치마크 (BENCHMARK_DIFFERENCE)
- [[02_Wiki/systems/msre/benchmark/sam-msre-primary-loop]] — SAM 참고 기준선

## Issues (`02_Wiki/issues/`)
- [[02_Wiki/issues/fuel-salt-property-correlation-conflict]] — **open** · 모델 ACTIVE 상관식(Cantor 1968) vs 설계값(Robertson 1965) 밀도 −2.4%·점도 +25%, 체적은 Compere 기준 유도
- [[02_Wiki/issues/beta-eff-circulating-discrepancy]] — **open** · 순환 β_eff ORNL 0.003617 vs 모델 ≈0.0045 (24%)
- [[02_Wiki/issues/jeong-transit-time-value-mismatch]] — **open** · τ_system 25.2/25.63/25.70/25.82/27.651 s (체적 +7.14%가 유력 원인)
- [[02_Wiki/issues/pump-discharge-head-conflict]] — **open** · Leandro 0.092 MPa vs ORNL 48.3 ft(≈0.324 MPa), 모델 0.301 MPa는 1차와 정합
- [[02_Wiki/issues/raw-code-noncanonical-files]] — ✅ resolved · 낱개 233개가 canonical zip과 233/233 일치, 파일명↔내용 대응 전부 복원, 고유 내용 0
- [[02_Wiki/issues/graphite-heating-fraction-provenance]] — ✅ resolved · TM-0378 p.40 각주, **ASSUMED**(Nestor 미출간)
- [[02_Wiki/issues/leandro2019-table-parsing]] — ✅ resolved (poppler 설치로 표 복구)

## Reviews (`02_Wiki/reviews/`)
- [[02_Wiki/reviews/2026-09-03-inbox-raw-code-classification]] — Inbox 23건 · Raw 계층 · 코드 인용 출처 분류 (2026-09-03)
- [[02_Wiki/reviews/2026-09-03-raw-code-recovery-map]] — 낱개 코드 233개 → canonical 경로 복원 맵 (233행)

## Projects (`04_Projects/`)
- [[04_Projects/msre-transform-status]] — MSRE TRANSFORM 연구 진행 상황
- [[04_Projects/gemini-research-director]] — Gemini가 읽을 파일·문헌 요청·수치 검증 출력 계약

## Logs (`06_Logs/`)
- `06_Logs/ingest_log.md` — ingest 이력
- `06_Logs/daily/` — 날짜별 연구 진행 기록
