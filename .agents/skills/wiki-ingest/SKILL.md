---
name: wiki-ingest
description: 원자력 열수력/Dymola 원자로 코드 라이브러리에 소스 1건(논문/보고서/코드/실험데이터/연구노트)을 편입한다. 00_Inbox 또는 01_Raw에서 소스를 찾아 핵심 주장·수식·정량값(provenance 포함)을 추출하고, 01_Raw(보존)/02_Wiki(서술)/03_Data(값)/04_Projects(진행상황)에 나누어 기록한 뒤 index.md와 06_Logs/ingest_log.md를 갱신한다. 새 논문이나 자료를 위키에 넣어달라는 요청, "ingest해줘", "위키에 편입해줘" 같은 요청에 사용.
---

# /wiki-ingest — 소스 1건 편입

이 스킬은 `AGENTS.md`에 정의된 원자력 열수력/Dymola 라이브러리의 ingest 절차를 실행한다. **먼저 `AGENTS.md`를 읽고 핵심 운영 원칙(Raw 원본 수정 금지 / 출처 없는 정보 추정 금지 / 기존 문서 우선 갱신·중복 생성 금지)을 확인한 뒤 아래 절차를 따른다.**

## 인자

- `args`로 특정 파일 경로/제목이 주어지면 그 소스를 처리한다.
- `args`가 없으면 `00_Inbox/`를 확인해서 아직 `02_Wiki/sources/`에 대응하는 요약 페이지가 없는 파일 중 하나를 골라 처리 대상으로 삼고, 어떤 파일을 골랐는지 먼저 밝힌다.
- 여러 파일이 있으면 기본은 **1건만** 처리한다 (한 번의 `/wiki-ingest` 호출 = 소스 1건). 사용자가 "여러 개", "전부", "배치로"라고 명시하면 여러 건을 연달아 처리하되, 각 소스마다 아래 절차를 빠짐없이 반복한다.

## 절차

### 0. 중복/기존 지식 확인
- `index.md`를 읽고, 이 소스가 다루는 시스템/컴포넌트/개념에 대해 이미 있는 `02_Wiki/`, `03_Data/` 페이지를 찾는다. (원칙 3 — 불필요한 중복 문서 생성 금지)
- 대상 시스템이 없는 시스템이면(예: MSRE가 아닌 다른 원자로), 사용자에게 새 시스템 네임스페이스(`02_Wiki/systems/<slug>/`, `03_Data/<slug>/`)를 만들지 확인한다.

### 1. 소스 확인 및 보존
- 파일이 `00_Inbox/`에 있으면 내용에 따라 `01_Raw/{literature,code,experiments,meetings,misc}/`로 옮긴다 (PDF 논문/보고서 → `literature`, 코드 저장소 → `code`, 실험 원자료 → `experiments`, 회의록 → `meetings`, 연구노트 등 → `misc`).
- 이미 `01_Raw/`에 있으면 그대로 둔다. **`01_Raw/`의 파일 내용은 절대 수정하지 않는다.**

### 2. 읽고 추출
소스를 읽고 다음을 추출한다 (PDF는 필요한 만큼 페이지 범위를 나눠 읽는다):
- 핵심 주장/결론
- 수식 (기호, 유도, 전제)
- 정량값: 물성치, 상관식 계수, geometry 치수, axial/radial distribution, benchmark 비교값 등. **값마다 반드시 provenance를 판정**한다 — `ORIGINAL / DERIVED / DIGITIZED / FITTED / ASSUMED / CALIBRATED / SOFTWARE_DEFAULT / UNKNOWN` 중 하나. 근거가 불충분해 판정이 애매하면 **추정하지 말고 `UNKNOWN`으로 기록**한다 (원칙 2).
- 모델 구조/가정
- 검증·벤치마크 결과
- 어느 시스템(들)에 해당하는지 (시스템 무관 일반 이론이면 `systems: []`)

### 3. Source note 생성/갱신
- `90_Templates/Wiki_Source.md` 템플릿으로 `02_Wiki/sources/<slug>.md` 생성 (이미 있으면 갱신).
- `raw:` 필드로 `01_Raw/`의 원본을 링크.

### 4. Data로 정량값 기록
- 추출한 정량값을 `03_Data/<system>/{properties,correlations,geometry,distributions,benchmark}/`에 기록.
  - 간단한 단일값이면 `03_Data/registry.md`에 한 줄만 추가해도 됨.
  - 여러 소스에 걸쳐 값이 갈리거나(충돌), 디지타이징처럼 방법론 설명이 필요하거나, 여러 컴포넌트가 공유하는 값이면 `90_Templates/Data_Entry.md`로 독립 페이지 생성.
  - 기존에 같은 파라미터의 값이 이미 기록돼 있으면, 새 페이지를 만들지 말고 **기존 페이지/registry 행을 갱신**한다. 값이 다르면 두 값을 모두 남기고 "⚠️ [[소스A]] vs [[소스B]]: X vs Y" 형태로 충돌을 명시한 뒤, 해소되지 않으면 `02_Wiki/issues/`에 등록.
  - `03_Data/registry.md`에도 항상 한 줄 반영.

### 5. Wiki로 서술 통합
- 시스템 무관 일반 물리는 `02_Wiki/concepts/`, `02_Wiki/equations/`에 통합 (새 페이지는 기존에 없을 때만).
- 시스템 고유 내용은 `02_Wiki/systems/<system>/{components,implementation,verification,benchmark}/`에 통합.
- 값 자체는 다시 쓰지 않고 `03_Data/...`를 링크. 서술 페이지에서 근거가 필요하면 `02_Wiki/sources/...`를 링크.
- 충돌·모순 발견 시 명시하고 `02_Wiki/issues/`에 등록.

### 6. Project 갱신
- 관련 있으면 `04_Projects/<system>-status.md`를 갱신 (해당 소스로 인해 어느 단계 상태가 바뀌었는지).
- 연구노트/진행상황 문서 자체가 소스인 경우, `90_Templates/Project_Status.md`로 새로 만들거나 기존 status 페이지를 갱신.

### 7. 인덱스/로그 갱신 (둘 다 필수)
- `index.md`에 새 페이지들을 등록 (카테고리별).
- `06_Logs/ingest_log.md`에 `## [YYYY-MM-DD] ingest | <소스 제목>` 항목 추가 — 생성/수정된 파일, 새로 등록된 데이터 수, UNKNOWN 개수, 발견된 충돌을 나열 (세부 목록은 여기에).
- `06_Logs/daily/YYYY-MM-DD.md` 갱신 — `AGENTS.md`의 "Daily Research Log" 구조를 따른다. **ingest 세부 목록을 복사하지 말고 연구 진행상 핵심 결과만 요약**: 무엇을 알아냈는지(확인된 사실), 무엇이 바뀌었는지(파일 경로), 새 UNKNOWN·충돌·provenance 변경. 기존 `## 진행 기록` 항목은 절대 덮어쓰지 않고 append.

### 7-1. PDF 표·그림 읽기
`pdftotext`는 2단 레이아웃 표에서 라벨-값 정렬이 깨질 수 있다. 표·그림 값을 쓸 때는 페이지를 이미지로 렌더링해 육안 확인할 것. Read 도구의 PDF 렌더링이 안 되면 PATH에 poppler를 추가해 우회:
`C:\Users\<user>\AppData\Local\Microsoft\WinGet\Packages\oschwartz10612.Poppler_*\poppler-*\Library\bin` → `pdftoppm -png -r 200 -f <p> -l <p> in.pdf out` 후 PNG를 Read.

### 8. 보고
소스 1건 처리가 끝나면 다음만 요약해서 보고한다 (사용자가 명시적으로 요청한 보고 형식):
- 생성/수정된 파일 목록
- `UNKNOWN` provenance로 남은 값
- 충돌(conflicting)로 표시된 데이터
- 추가 확인이 필요한 사항 (새 시스템 생성 여부, 애매한 분류 등)

세부 내용을 전부 나열하지 말고 이 4가지 범주로만 압축해서 보고한다.

## 자동 호출
- `Scripts/watch-and-ingest-inbox.ps1`가 `00_Inbox`의 안정화된 파일을 감지하면 이 절차를 headless Codex로 호출할 수 있다.
- 자동 호출도 기본 원칙, 소스 1건 처리, provenance 기록, 로그 갱신을 생략하지 않는다.
