---
type: overview
last_updated: {{date:YYYY-MM-DD}}
---

# 원자력 열수력 / Dymola 원자로 코드 라이브러리 — 전체 개요

## 목표

원자력 열수력(nuclear thermal-hydraulics) 분야에서 Dymola를 이용한 원자로 코드 설계, 실험데이터, 논문을 통합해 나만의 참고 라이브러리를 구축한다. 여러 원자로 시스템을 다룰 수 있도록 설계하되, 시스템에 공통되는 일반 물리(개념·지배방정식)는 전역으로, 시스템 고유의 컴포넌트·모델 구현·검증·벤치마크는 시스템별 네임스페이스로, 모든 정량값은 provenance와 함께 `03_Data`에 분리 보관한다.

## 다루는 시스템

| 시스템 | 상태 | 개요 페이지 | 진행상황 |
|---|---|---|---|
| MSRE (Molten Salt Reactor Experiment) | 진행 중 | [[02_Wiki/systems/msre/overview]] | [[04_Projects/msre-transform-status]] |

새 시스템을 추가할 때는 `02_Wiki/systems/<system-slug>/` 아래 `overview.md` + `components/ implementation/ verification/ benchmark/` 서브폴더, `03_Data/<system-slug>/` 아래 `properties/ correlations/ geometry/ distributions/ benchmark/`를 만들고 이 표와 `index.md`에 등록한다. (`CLAUDE.md` 참고)

## 전역 계층 (모든 시스템 공통)

- [[02_Wiki/concepts]] — 일반 열수력/중성자학 개념 (특정 시스템에 종속되지 않는 물리)
- [[02_Wiki/equations]] — 일반 지배방정식
- [[02_Wiki/sources]] — 소스 요약 (frontmatter `systems:`로 어느 시스템에 해당하는지 태깅)
- [[02_Wiki/issues]] — 미해결 문제/모순 (frontmatter `systems:`로 태깅, 시스템 무관 이슈도 가능)
- [[03_Data/registry]] — 전체 시스템 통틀어 모든 정량값 마스터 테이블 (provenance 포함)

## 관련 페이지
- [[index]]
- [[03_Data/registry]]
- [[04_Projects/gemini-research-director]]
