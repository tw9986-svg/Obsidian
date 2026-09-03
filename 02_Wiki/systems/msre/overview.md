---
type: system-overview
system: msre
last_updated: {{date:YYYY-MM-DD}}
---

# MSRE (Molten Salt Reactor Experiment) — 시스템 개요

## 연구 목표

MSRE 설계·운전 데이터를 기반으로 molten-salt reactor 시스템을 Dymola/Modelica(TRANSFORM)로 모델링하고, MARS 및 실험데이터와의 benchmark를 통해 검증한다. 모든 모델 입력값은 원자료·가정값·계산값·코드 기본값의 provenance를 확보한다.

## 범위

- MSRE 설계·운전 데이터
- Molten-salt 물성
- Core 열수력, graphite/fuel 열전달, 체적발열
- Point kinetics 및 DNP(delayed neutron precursor) transport
- Pump hydraulics / rotor dynamics
- Primary loop / heat exchanger, residence time, pressure drop, 자연순환
- 1D/2D 모델링
- MARS 및 실험데이터 benchmark, verification/validation
- 모델 가정·불확실성·오차원인

## 하위 페이지

- [[02_Wiki/systems/msre/components]] 이하 — 물리 컴포넌트
- [[02_Wiki/systems/msre/implementation]] 이하 — Dymola/TRANSFORM 모델 구현
- [[02_Wiki/systems/msre/verification]] 이하 — V&V
- [[02_Wiki/systems/msre/benchmark]] 이하 — MARS/실험데이터 벤치마크
- `03_Data/msre/{properties,correlations,geometry,distributions,benchmark}/` — MSRE 정량값 (provenance 포함, [[03_Data/registry]]에도 등록)
- [[04_Projects/msre-transform-status]] — 현재 연구 진행 상황

## 현재 상태

[[04_Projects/msre-transform-status]] 참고 (요약: Core1D TH, primary-loop steady hydraulics, DNP full-loop transport, circulation reactivity, pump rotor standalone, Core1D/Core2D structural verification PASS. Pump startup/coastdown 오차, 2D radial nodalization, axial/radial power distribution 원자료 재현, graphite 2D conduction 진행 중.)

## 핵심 미해결 이슈

(`02_Wiki/issues/`에서 `system: msre` 태그된 페이지 참고)

## 관련 페이지
- [[02_Wiki/overview]]
