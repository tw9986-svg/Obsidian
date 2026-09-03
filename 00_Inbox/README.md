# 00_Inbox — 모든 신규 자료의 **단일 진입점**

논문·보고서·코드·실험데이터·클리핑 등 **모든 신규 자료는 여기로만 들어온다.**
다른 폴더(특히 `01_Raw/`, 옛 `raw/`)에 직접 저장하지 않는다.

```
00_Inbox  →  자동분류  →  01_Raw (원본 보존)
                        →  02_Wiki (Source note / 서술)
                        →  03_Data (정량값 + provenance)
                        →  index.md · 06_Logs/ingest_log.md · 06_Logs/daily/
```

## 하위 폴더

| 폴더 | 용도 |
|---|---|
| `_duplicates/` | 기존 `01_Raw/` 보유본과 **바이트 동일**로 확인된 파일. 삭제하지 않고 격리만 한다 |
| `_nonresearch/` | 연구자료가 아닌 파일 (빈 템플릿 스텁, 편집기 부산물 등) |

## 저장 경로 설정

**Obsidian Web Clipper**는 브라우저 확장이라 저장 경로 설정이 이 저장소가 아니라
확장 프로그램 설정에 있다. 확장 설정에서 저장 폴더를 **`00_Inbox`** 로 변경한다.
이전 클리핑은 `01_Raw/misc/`에 보존하고, 새 자료만 이 폴더로 받는다.

## Gemini 분석 입력

Gemini는 [Gemini 연구 감독자 지침](../04_Projects/gemini-research-director.md)의 읽기 순서와 출력 계약을 따른다.

## Claude Code Desktop 자동 반영

Claude Code Desktop에서 `D:\Reserch`를 열고 수정한 내용까지 자동 커밋하려면 VS Code에서 `Terminal: Run Task`가 아니라 `Tasks: Run Task`를 선택해 **Research: watch and auto-commit**을 시작한다. 감시 프로세스가 실행 중인 동안 Desktop의 변경은 10초의 안정화 대기 후 GitHub `main`으로 커밋·푸시된다.

## Inbox 자동 편입 파이프라인

Claude Code CLI가 설치된 환경에서 VS Code 작업 **Research: watch and ingest Inbox**를 실행하면 `00_Inbox`의 신규 자료를 감시한다. 파일이 10초간 안정되면 Claude Code headless `/wiki-ingest`가 한 건씩 실행되어 `01_Raw`, `02_Wiki`, `03_Data`, `index.md`, 로그를 갱신한다. 처리 상태는 `.claude/state/`에 SHA-256으로 기록하며 Git에는 포함하지 않는다. CLI가 없으면 파이프라인은 오류를 표시하고 중단한다.

## 처리 원칙

- **Raw 원본 보존** — `01_Raw/`로 옮긴 뒤에는 편집·삭제·이름변경 금지
- **중복은 삭제보다 격리** — hash로 확인 후 `_duplicates/`
- **출처 미확정 값 추정 금지** — `UNKNOWN`으로 두고 `02_Wiki/issues/`에 등록
- **Source → Data → Model 추적 가능 상태 유지**

상세 절차: `.claude/skills/wiki-ingest/SKILL.md`, 분류 축: [[02_Wiki/classification-axes]]
