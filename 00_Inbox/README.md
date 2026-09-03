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

## 저장 경로 설정 (사용자 조치 필요)

**Obsidian Web Clipper**는 브라우저 확장이라 저장 경로 설정이 이 저장소가 아니라
확장 프로그램 설정에 있다. 확장 설정에서 저장 폴더를 **`00_Inbox`** 로 변경할 것.
(이전에는 `raw/`로 저장되고 있었고, `raw/` 폴더는 2026-09-03에 제거되었다.)

## 처리 원칙

- **Raw 원본 보존** — `01_Raw/`로 옮긴 뒤에는 편집·삭제·이름변경 금지
- **중복은 삭제보다 격리** — hash로 확인 후 `_duplicates/`
- **출처 미확정 값 추정 금지** — `UNKNOWN`으로 두고 `02_Wiki/issues/`에 등록
- **Source → Data → Model 추적 가능 상태 유지**

상세 절차: `.claude/skills/wiki-ingest/SKILL.md`, 분류 축: [[02_Wiki/classification-axes]]
