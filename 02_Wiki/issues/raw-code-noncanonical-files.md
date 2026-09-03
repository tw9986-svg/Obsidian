---
type: issue
status: resolved
date: 2026-09-02
updated: 2026-09-03
systems: [msre]
tags: [code, data-quality, canonical, provenance]
---

# `01_Raw/code/` 낱개 파일 — **canonical zip과 100 % 중복으로 확정 (resolved)**

## ✅ 최종 판정 (2026-09-03)

낱개 233개 파일과 canonical zip 내부 133개 blob을 **CRLF→LF 정규화 후 SHA-256**으로 대조한 결과:

- **낱개 233/233 전부가 canonical blob과 정확히 일치**한다.
- canonical 133 경로 중 **100개는 낱개 2개가, 33개는 낱개 1개가** 담고 있다 (100×2 + 33 = 233).
- 따라서 낱개 집합에는 **canonical zip 대비 고유 내용이 0개**다. 삭제해도 정보 손실이 없다.
- 파일명↔내용 대응도 **전부 복원되었다**: [[02_Wiki/reviews/2026-09-03-raw-code-recovery-map]] (233행 전체 맵).

`" 1"` 접미사 쌍은 "같은 파일의 다른 시점 버전"이 아니라, **트리 순서가 한두 칸 밀린 서로 다른
canonical 파일**이다. 브라우저 일괄 다운로드가 이름을 한 칸씩 어긋나게 저장한 결과로 보인다.

## 판정 이력 (2회 정정)

| 시점 | 판정 | 오류 원인 |
|---|---|---|
| 2026-09-02 (1차) | "HTML 저장본이라 내용이 가짜" | `file` 명령이 `annotation(Documentation(info="<html>…` 블록을 보고 HTML로 오탐 |
| 2026-09-02 (2차) | "내용은 진짜지만 zip과 일치 0개, 이름↔내용 대응 상실" | **CRLF→LF 정규화 누락** |
| 2026-09-03 (확정) | **zip과 233/233 완전 일치, 대응 전부 복원, 고유 내용 0** | — |

## Git commit — 확정됨

- 실제 저장소: `https://github.com/tw9986-svg/MSRE_TRANSFORM` (branch `main`)
- `01_Raw/code/MSRE_TRANSFORM-main (2).zip` = commit **`80a8f6d7a2bee75c5810545cf95856653a39df51`**
  (2026-09-02 03:27 UTC, "Predict the equal-dr thermal result before its build completes") — 133/133 일치.
- 저장소 HEAD `492deecd47e1f5d51eb49d045db3ea6f64de87a7`는 zip보다 22 commit 앞서지만,
  그 22 commit이 바꾼 것은 `docs/PHASE_LOG.md`(+816줄)뿐 → 기존 위키 분석은 HEAD 기준으로도 유효.

## 남은 조치 (사용자 승인 대기 — 이슈 자체는 resolved)

- [ ] 낱개 233개를 `01_Raw/code/_noncanonical/`로 격리할지 여부. 정보 손실이 0임이 확정되었으므로
      **격리 권장**. `01_Raw` 불변 원칙상 승인 없이 옮기지 않았다.
- [x] canonical 기준을 Git commit hash로 고정.
- [ ] 향후 코드 스냅샷은 `git clone` 또는 zip 단위로만 보관하고 commit hash를 함께 기록.

## 관련 페이지
- [[02_Wiki/reviews/2026-09-03-raw-code-recovery-map]]
- [[02_Wiki/reviews/2026-09-03-inbox-raw-code-classification]]
- [[02_Wiki/systems/msre/implementation/msre-transform-model]]
- [[02_Wiki/systems/msre/implementation/code-provenance-tags]]
