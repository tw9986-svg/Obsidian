# 원자력 열수력 / Dymola 원자로 코드 라이브러리 — 운영 규칙

이 저장소는 "LLM Wiki" 패턴을 따르는 연구 위키입니다. 논문·보고서·코드·실험데이터를 그때그때 검색하는 게 아니라, 읽을 때마다 구조화된 마크다운 라이브러리에 통합해서 지식이 누적되도록 합니다. 세션마다 이 문서를 먼저 읽고 아래 규칙과 워크플로우를 따르세요.

## 도메인

원자력 열수력(nuclear thermal-hydraulics) 분야에서 **Dymola**를 이용한 원자로 코드 설계, 실험데이터, 논문을 통합한 개인 라이브러리. 여러 원자로 시스템을 다룰 수 있도록 설계한다. 현재 주력 시스템은 **MSRE**(Molten Salt Reactor Experiment, TRANSFORM 라이브러리 기반 모델링)이며, 이후 다른 원자로 시스템/코드가 추가될 수 있다.

위키는 논문(소스) 중심이 아니라 **physical concept, component, equation, parameter/data, implementation, verification, benchmark, issue, project(진행상황)** 중심으로 구성한다. 소스 요약(Source note)은 유지하지만, 실제 지식은 이 범주의 페이지에 통합된다.

## 핵심 운영 원칙 (반드시 준수)

1. **Raw 원본 수정 금지.** `01_Raw/`의 파일은 절대 편집·삭제·이름변경하지 않는다. 디지타이징·발췌·번역이 필요하면 새 파일(`03_Data/`, `02_Wiki/`)을 만든다.
2. **출처 없는 정보 추정 금지.** 모든 정량값·주장은 반드시 `01_Raw/`의 특정 소스(및 가능하면 page/figure)로 추적 가능해야 한다. 소스에 없는 값을 채워야 할 때는 임의로 추정하지 말고 provenance를 `ASSUMED`로 명시하고 근거(왜 그 값을 가정했는지)를 남기거나, 확실하지 않으면 `UNKNOWN`으로 두고 `02_Wiki/issues/`에 등록한다.
3. **기존 문서 우선 갱신, 불필요한 중복 생성 금지.** 새 소스를 ingest하기 전에 반드시 `index.md`와 관련 폴더를 검색해서 이미 다루는 페이지가 있는지 확인한다. 있으면 그 페이지를 갱신(행 추가, 근거 보강, 충돌 표시)하고, 없을 때만 새 페이지를 만든다. 같은 컴포넌트/개념/파라미터에 대해 유사한 페이지를 여러 개 만들지 않는다.

## 폴더 구조

- **`01_Raw/`** — 원본 소스. 불변(immutable).
  - `01_Raw/literature/` — 논문, ORNL/INL 등 보고서
  - `01_Raw/code/` — GitHub 코드 등 원본 코드 스냅샷 (예: MSRE_TRANSFORM 저장소)
  - `01_Raw/experiments/` — 운전/실험 원본 데이터
  - `01_Raw/meetings/` — 회의/미팅 녹취록·원본 메모
  - `01_Raw/misc/` — 연구노트 등 기타 원본 (예: 연구 진행상황 스냅샷)

- **`02_Wiki/`** — Claude가 소유·관리하는 서술/개념 계층. 사람은 읽기만 하고, 쓰기·상호 링크 유지는 Claude가 담당.
  - `02_Wiki/overview.md` — 라이브러리 전체 개요, 다루는 시스템 목록.
  - `02_Wiki/sources/` — 소스 1개당 요약 페이지 1개 (frontmatter `systems:`로 태깅).
  - `02_Wiki/concepts/` — 시스템 무관 일반 물리 개념 (point kinetics, DNP transport, 자연순환, residence time 등).
  - `02_Wiki/equations/` — 시스템 무관 일반 지배방정식.
  - `02_Wiki/issues/` — 미해결 문제, 모순, UNKNOWN provenance, 불확실성 (frontmatter `systems:`로 태깅).
  - `02_Wiki/reviews/` — 주기적 lint 결과.
  - `02_Wiki/systems/<system-slug>/` — 시스템 고유 서술:
    - `overview.md` — 그 시스템의 연구 목표/범위/현재 상태.
    - `components/` — 물리 컴포넌트 (core, graphite, fuel salt, primary loop, HX, pump, rotor dynamics 등).
    - `implementation/` — Dymola/TRANSFORM 모델 구현 (모델 구조, 사용 라이브러리, 코드 위치는 `01_Raw/code/` 링크).
    - `verification/` — V&V (analytic solution, code-to-code, convergence 등).
    - `benchmark/` — MARS 등 타 코드/실험데이터 대비 벤치마크.

- **`03_Data/`** — 모든 정량값을 provenance와 함께 보관하는 독립 계층. 위키 서술과 분리해서, "이 값이 어디서 왔는가"를 한 곳에서 감사(audit)할 수 있게 한다.
  - `03_Data/registry.md` — 전 시스템 통합 마스터 테이블.
  - `03_Data/<system-slug>/properties/` — 물성치 (밀도, 점도, 비열, 열전도도 등).
  - `03_Data/<system-slug>/correlations/` — 상관식 (Nusselt 상관식 등).
  - `03_Data/<system-slug>/geometry/` — Geometry 치수.
  - `03_Data/<system-slug>/distributions/` — Axial/radial power distribution 등 분포 데이터.
  - `03_Data/<system-slug>/benchmark/` — 벤치마크에 쓰인 비교값/실험값.

- **`04_Projects/`** — 연구 진행상황 문서. 시스템별 "현재 상태" 페이지 (`msre-transform-status.md` 등). 원본 연구노트는 `01_Raw/`에 보존하고, 이 페이지는 Claude가 계속 갱신하는 living document.

- **`06_Logs/`** — 기록 계층. *(05_는 의도적으로 비워둠 — 추후 필요시 정의.)*
  - `06_Logs/ingest_log.md` — ingest/query/lint 이력 (append-only, 소스 편입 세부 목록).
  - `06_Logs/daily/YYYY-MM-DD.md` — **날짜별 실제 연구 진행 기록** (아래 "Daily Research Log" 참조).

- **`index.md`** (루트) — 전체 카탈로그. 소스 편입/페이지 생성마다 갱신.

- **`CLAUDE.md`** (이 문서) — 스키마 및 운영 규칙.

### 별도로 유지되는 폴더 (Obsidian 설정에 연결됨, 경로 변경 금지)
- `01_Daily/` — 개인 데일리 로그 (Daily Notes/QuickAdd가 이 경로 참조).
- `90_Templates/` — Obsidian 템플릿: `Daily.md` + `Wiki_*.md` (02_Wiki용) + `Data_Entry.md`(03_Data용) + `Project_Status.md`(04_Projects용).
- `00_Inbox/` — **모든 신규 자료의 단일 진입점.** 다른 폴더에 직접 저장 금지 (Obsidian Web Clipper 포함).
  `00_Inbox → 자동분류 → 01_Raw / 02_Wiki / 03_Data / index / ingest_log` 경로만 사용한다.
  하위: `_duplicates/`(바이트 동일 중복, 삭제 대신 격리), `_nonresearch/`(연구자료 아님). 상세: `00_Inbox/README.md`.
- `99_Attachments/` — 이미지 등 첨부. Benchmark/verification 결과 플롯, digitization용 원본 그림 등도 여기 저장.

### Claude Code Desktop 작업 경로

Claude Code Desktop에서 **Open folder**로 `D:\Reserch`를 직접 열어 작업한다. 이 폴더가 Obsidian Vault와 동일한 실제 경로이므로 Desktop에서 생성·수정한 파일은 별도 복사나 REST API 없이 즉시 Vault에 반영된다.

- 작업 루트는 반드시 `D:\Reserch`로 지정한다. `D:\Reserch\raw` 같은 과거 경로 또는 복제 폴더를 사용하지 않는다.
- 원본은 `01_Raw/`에 보존하고, 새 자료는 `00_Inbox/`에만 저장한다.
- Desktop과 VS Code에서 같은 파일을 동시에 편집하지 않는다. 저장 충돌을 피하려면 한 번에 한 클라이언트만 편집한다.
- VS Code의 Run on Save 자동 커밋은 VS Code 저장 이벤트에만 반응한다. Desktop에서 수정한 뒤에는 VS Code에서 해당 파일을 확인·저장하거나 Git을 별도로 실행해야 한다.
- Desktop 수정도 자동 커밋하려면 VS Code 작업 `Research: watch and auto-commit`을 실행하거나 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File D:\Reserch\Scripts\watch-and-auto-commit.ps1`를 별도 터미널에서 실행한다. 감시 프로세스는 변경이 10초간 멈춘 뒤 커밋·푸시한다.

## Data 표준 항목 (03_Data 페이지 / registry.md 공통)

`03_Data/`의 모든 페이지·registry 행은 아래 필드를 포함합니다:

| Parameter | Symbol | System | Value | Unit | Source | Page/Fig | Provenance | Confidence | Model Usage | Verification |
|---|---|---|---|---|---|---|---|---|---|---|

- **Source**: `[[02_Wiki/sources/...]]` 링크 (원본은 그 소스 페이지에서 `01_Raw/`로 다시 링크됨).
- **Page/Fig**: 소스 문서 내 페이지 번호 또는 그림 번호(디지타이징의 경우).
- **Provenance** (8종 — 반드시 하나 선택):
  - `ORIGINAL` — 소스에 그대로 제시된 값
  - `DERIVED` — 다른 값으로부터 수식 계산
  - `DIGITIZED` — 그림/그래프에서 디지타이징
  - `FITTED` — 데이터에 곡선/상관식 피팅
  - `ASSUMED` — 연구자 가정값 (근거 필수)
  - `CALIBRATED` — 벤치마크/검증 과정에서 조정한 값
  - `SOFTWARE_DEFAULT` — Dymola/TRANSFORM/MARS 등의 기본값
  - `UNKNOWN` — 출처 미확정 (추정 금지 원칙에 따라 임의로 다른 값으로 대체하지 말 것)
- **Confidence**: `high` / `medium` / `low`.
- **Model Usage**: 이 값이 어느 `[[02_Wiki/systems/<system>/implementation/...]]`에서 쓰이는지.
- **Verification**: `unverified` / `verified` / `conflicting` / `superseded`.

값을 기록하는 모든 `03_Data/` 페이지는 동시에 **`03_Data/registry.md`에 한 줄을 추가/갱신**합니다.

## 링크 체계: Source → Data → Wiki → Project

- **Source** (`02_Wiki/sources/<source>.md`): 소스 1건의 메타데이터·핵심 주장 요약. 추출된 정량값은 여기서 `03_Data/`의 해당 페이지로 링크.
- **Data** (`03_Data/<system>/.../<item>.md`): 정량값 자체 + provenance. `Source`로 역참조, `Wiki`(component/implementation)에서 순참조됨.
- **Wiki** (`02_Wiki/concepts|equations|systems/<system>/components|implementation|verification|benchmark`): 개념/구현 서술. 값이 필요하면 `Data`를 링크(중복 기입 최소화), 근거가 필요하면 `Source`를 링크.
- **Project** (`04_Projects/<system>-status.md`): 현재 연구 상태. 관련 `Wiki`/`Data` 페이지를 링크하고, 이 프로젝트의 PASS/진행/이슈 상태를 서술.

새 소스를 ingest할 때마다 이 네 계층이 서로 링크되어 있는지 확인합니다.

## 페이지 규칙

- Frontmatter: `type`, `system`(시스템 고유 페이지) 또는 `systems: []`(소스/이슈), `tags`, 날짜/상태 필드. 정확한 필드는 `90_Templates/*.md` 참고.
- 본문은 한국어. 수식은 LaTeX(`$$...$$`), 원문 인용이 필요하면 짧게 병기.
- 페이지 간 링크는 `[[페이지명]]`. 아직 없는 페이지도 일단 링크해두고 lint 때 생성 여부 판단.
- 파일명은 kebab-case (예: `02_Wiki/systems/msre/components/primary-loop.md`, `03_Data/msre/properties/fuel-salt-density.md`).
- 어떤 내용이 전역(`02_Wiki/concepts`, `02_Wiki/equations`)인지 시스템별(`02_Wiki/systems/<system>/...`)인지 애매하면: **물리/수학 자체는 전역, 특정 시스템에서 그 물리가 어떻게 구현·계측되었는지(수치, geometry, 모델 구조)는 시스템별**로 분류.

## 워크플로우

### 1. Ingest — `/wiki-ingest` 스킬 사용, 소스 1건씩 처리

상세 절차는 `.claude/skills/wiki-ingest/SKILL.md`에 스킬로 고정되어 있습니다. 요약:

1. **중복 확인**: `index.md` / 관련 폴더에서 이미 다루는 페이지가 있는지 먼저 검색 (원칙 3).
2. 소스 하나를 읽고 다음을 추출: 핵심 주장, 수식, parameter/물성/geometry/분포/벤치마크 값(각각 provenance 판정), 가정, 모델 구조, 검증 결과. 어느 시스템(들)에 해당하는지 판단.
3. 원본은 `01_Raw/`에 보존 (이미 있으면 그대로 둠 — 원칙 1).
4. `02_Wiki/sources/`에 요약 페이지 생성/갱신.
5. 정량값은 `03_Data/<system>/{properties,correlations,geometry,distributions,benchmark}/`에 기록하고 `03_Data/registry.md`에 반영. **출처가 불명확하면 절대 추정하지 말고 `UNKNOWN`으로 기록** (원칙 2).
6. 서술 지식은 `02_Wiki/concepts|equations|systems/<system>/{components,implementation,verification,benchmark}/`에 통합 — 새 정보 추가 / 기존 주장 강화 / 충돌 시 명시("⚠️ [[...]]와 상충") 후 `02_Wiki/issues/`에 open issue 등록.
7. 관련 있으면 `04_Projects/<system>-status.md` 갱신.
8. `index.md` 갱신.
9. `06_Logs/ingest_log.md`에 `## [YYYY-MM-DD] ingest | 소스 제목` 항목 추가.
10. 처리 끝나면 무엇을 추출했고 어느 페이지를 어떻게 바꿨는지 요약 보고. 충돌·UNKNOWN 값·새 시스템/컴포넌트 신설처럼 판단이 필요한 지점은 여기서 확인받음.

부수 자료를 사용자가 명시적으로 "배치로 처리해줘"라고 요청하면 여러 건 묶어 처리하되, 그 경우에도 정량값의 provenance 판정과 registry 기록은 생략하지 않습니다.

### 2. Query
1. 먼저 `02_Wiki/overview.md`, 관련 있으면 `02_Wiki/systems/<system>/overview.md`, `index.md`, (정량값 질문이면) `03_Data/registry.md`를 읽어 관련 페이지 후보를 찾음.
2. 관련 페이지들을 읽고 종합해서 답변. 정량값을 인용할 때는 반드시 출처(source, page/fig, provenance, confidence, verification status)를 명시.
3. 답변이 재사용 가치가 있으면 대화로 끝내지 말고 위키/데이터 페이지로 남길지 제안.

### 3. Lint (주기적 건강검진)
요청 시 다음을 점검하고 `02_Wiki/reviews/`에 결과를 남김:
- 페이지 간 모순, 특히 `conflicting`으로 표시된 값들
- `UNKNOWN` provenance로 남아있는 값 (추가 조사 우선순위)
- 최신 소스에 의해 낡아진 주장/값 (`superseded` 후보)
- 인바운드 링크 없는 고아 페이지, 중복 생성된 유사 페이지 (원칙 3 위반 여부)
- 언급되지만 페이지가 없는 개념/컴포넌트/데이터
- `03_Data/registry.md`와 개별 데이터 페이지 간 불일치
- 전역/시스템별 분류가 잘못된 페이지

## Daily Research Log (`06_Logs/daily/YYYY-MM-DD.md`)

의미 있는 연구 작업이 끝날 때마다 그 날짜의 Daily Log를 갱신한다. `/wiki-ingest` 수행 시에도 `ingest_log.md`와 Daily Log를 **모두** 갱신하되, **Daily에는 ingest 세부 목록을 통째로 복사하지 않고 연구 진행상 핵심 결과만 요약**한다.

### 원칙
- 기존 `## 진행 기록` 항목을 **삭제·덮어쓰기 금지** (append만).
- 실제 수행한 결과만 기록. 계획·추측은 진행 기록에 넣지 않는다.
- **확인된 사실**과 **추정/UNKNOWN**을 반드시 분리.
- 중복 내용 최소화 (같은 내용을 여러 섹션에 반복하지 않음).
- 주요 수치와 PASS/FAIL/BLOCKED 판정을 포함.
- 코드·데이터·위키를 변경했으면 **파일 경로**를 적는다.
- 해결된 문제는 `## 문제점 / UNKNOWN`에서 제거하고 `## 확인된 사실` 또는 `## 변경 사항`으로 옮긴다.
- `## 다음 작업`은 항상 최신 상태로 갱신.

### 구조

```markdown
## 진행 기록
- HH:mm [영역][상태]
  - 수행:
  - 결과:
  - 다음:

## 확인된 사실
- 검증·원문·실행 결과에 근거한 사실만

## 변경 사항
- 코드 / Data / Wiki / 설정 변경 (파일 경로 포함)

## 문제점 / UNKNOWN
- 미확정 값, provenance 미확보, blocker, 원인 미확정 실패

## 결정 사항
- 연구 방향·모델링 결정과 그 근거

## 다음 작업
- [ ] 미완료 작업
```

### 계층별 역할 분리 (혼동 금지)
| 경로 | 역할 |
|---|---|
| `01_Raw` | 원본 (불변) |
| `02_Wiki` | 정리된 지식 (서술) |
| `03_Data` | 수치·상관식·geometry·distribution (provenance 포함) |
| `04_Projects` | 연구 진행 상태 (living document) |
| `06_Logs/ingest_log.md` | ingest 이력 (무엇을 편입했는가) |
| `06_Logs/daily/` | 날짜별 실제 연구 진행 기록 (그날 무엇을 했고 무엇을 알아냈는가) |

## index.md / ingest_log.md 형식
- `index.md`: 카테고리(Overview/Systems/Sources/Concepts/Equations/Data/Components/Implementation/Verification/Benchmark/Issues/Projects)별 링크 + 한 줄 요약 + 상태.
- `06_Logs/ingest_log.md`: `## [YYYY-MM-DD] {ingest|query|lint|setup} | 요약` 형식. `grep "^## \[" 06_Logs/ingest_log.md | tail -5`로 최근 이력 확인.

## 분류 축 (2026-09-03 확정)

자료는 **두 축**으로 분류하며 **서로 섞지 않는다**. 상세·slug 목록: `02_Wiki/classification-axes.md`.

- `reactor_system:` — 모델링 **대상** 원자로 (`msre`, `msbr`, `msfr` …)
- `simulation_code:` — 해석 **수단**과 그 검증 인프라 (`transform-dymola`, `mars`, `mars-ks`, `relap5`, `sam`, `gen-foam`, `openfoam`, `dynasty` …)

기존 `systems:` 필드는 `reactor_system`의 별칭으로 취급한다. `02_Wiki/systems/<slug>/` 디렉터리는
`reactor_system` 축 전용이며, `simulation_code` 전용 자료는 시스템 디렉터리를 만들지 않는다.

## Git 취급

- 저장소로 관리한다. 원본 PDF는 원칙적으로 커밋하되, **배포권이 없는 사본은 `.gitignore`로 제외**하고
  Git에는 **서지정보·SHA-256·metadata만** 남긴다 (예: `02_Wiki/sources/dolan-2017-molten-salt-reactors-thorium-energy.md`).
  파일 자체는 로컬 `01_Raw/`에 그대로 보존한다.
- 코드 스냅샷은 zip 또는 `git clone` 단위로만 보관하고 **commit hash를 함께 기록**한다.

## 아직 정해지지 않은 것
- `05_` 네임스페이스 — 의도적으로 비워둠.
- 검색 도구(qmd 등) 도입 여부 — 지금은 소규모라 `index.md` + `03_Data/registry.md`로 충분.
- Inbox 자동 감시/스케줄링 — 이번 단계에서는 구현하지 않음. 수동 `/wiki-ingest` 실행만 지원.
