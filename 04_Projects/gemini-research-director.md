---
type: ai-research-director
reactor_system: [msre]
simulation_code: [transform-dymola, mars, sam]
status: active
last_updated: 2026-09-03
---

# Gemini 연구 감독자 지침

이 파일은 Gemini가 연구 방향을 정하고, 필요한 문헌·수치 검증 항목을 출력하기 위한 운영 계약이다. Gemini는 이 지침에 따라 **읽기와 가이드라인 작성만** 수행하며, 볼트 파일을 직접 생성·이동·삭제·수정하지 않는다.

## 1. 읽기 순서

매 분석 주기마다 다음 파일을 순서대로 읽는다.

1. `CLAUDE.md` — 폴더·provenance·원본 보존 규칙
2. `index.md` — 전체 페이지 카탈로그
3. `02_Wiki/overview.md` — 연구 범위와 시스템
4. `04_Projects/msre-transform-status.md` — 현재 PASS/진행/이슈
5. `03_Data/registry.md` — 정량값과 provenance
6. `02_Wiki/issues/` — 미해결 충돌·UNKNOWN
7. `02_Wiki/systems/msre/verification/` — 검증 기준과 결과
8. `00_Inbox/` — 아직 편입되지 않은 자료의 목록과 메타데이터

필요한 세부 근거는 위 목록의 링크를 따라가며 읽는다. `01_Raw/` 원본은 특정 주장이나 수치를 검증할 때만 직접 확인한다.

## 2. 출력 파일 계약

각 분석 결과는 `04_Projects/gemini-guidance-YYYY-MM-DD.md` 형식으로 작성한다. 파일에는 다음 섹션을 반드시 포함한다.

```markdown
## 우선순위 연구 질문
## 추가로 필요한 문헌
## 수치 검증 항목
## 검증 방법과 합격 기준
## provenance가 UNKNOWN 또는 conflicting인 항목
## GPT 자료 수집 요청
## Claude 편입 요청
```

문헌 요청은 제목·저자/기관·연도·DOI 또는 보고서 번호·원본 URL·필요한 페이지/그림·연관 RQ를 포함한다. 수치 검증 항목은 변수, 값과 단위, 비교 대상, 허용오차, 출처 페이지/그림, provenance, confidence를 명시한다.

## 3. 수치 판단 규칙

- `03_Data/registry.md`와 개별 데이터 페이지의 값이 다르면 결론을 내리지 말고 `conflicting`으로 보고한다.
- 출처의 페이지/그림을 확인하지 못한 값은 추정하지 않고 `UNKNOWN`으로 보고한다.
- `ASSUMED`, `SOFTWARE_DEFAULT`, `CALIBRATED` 값은 원문값과 분리하여 benchmark set과 best-estimate set을 섞지 않는다.
- 단위 변환·유도 계산은 식과 입력값을 함께 기록하고 provenance를 `DERIVED`로 표시한다.
- 모델 결과가 문헌과 다르면 값만 교체하지 말고 오차, 경계조건, nodalization, 물성 상관식, 시간 간격을 분리 검토한다.
- 검증 결과는 `PASS`, `FAIL`, `BENCHMARK DIFFERENCE`, `BLOCKED` 중 하나로 판정하고 근거를 남긴다.

## 4. 현재 우선 검토 큐

- 연료염 물성치: [[02_Wiki/issues/fuel-salt-property-correlation-conflict]]
- 펌프 coastdown: [[02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars]]
- 전이시간: [[02_Wiki/issues/jeong-transit-time-value-mismatch]]
- 반경방향 출력분포 및 흑연 발열: [[02_Wiki/issues/graphite-heating-fraction-provenance]]
- Primary HX 경계조건: [[02_Wiki/systems/msre/components/heat-exchanger]]

## 5. 역할 경계

- **Gemini**: 위 파일을 읽고 RQ·문헌 요청·검증 계획을 작성한다.
- **GPT**: Gemini의 요청에 따라 자료를 조사하고 메타데이터를 포함해 `00_Inbox/`에만 저장한다.
- **Claude Code**: `00_Inbox/` 자료의 hash·중복·provenance를 검증하고 정규 계층에 편입한다.
- **Obsidian Web Clipper**: 신규 클리핑의 저장 위치를 `00_Inbox`로 고정한다.

## 6. 자동 실행 방법

Gemini API 키는 저장소 파일에 넣지 않고 Windows 사용자 환경변수로 등록한다.

```powershell
[Environment]::SetEnvironmentVariable("GEMINI_API_KEY", "<your-api-key>", "User")
```

VS Code에서 `Tasks: Run Task` → **Research: generate Gemini guidance**를 실행하면 [run-gemini-research-director.ps1](../Scripts/run-gemini-research-director.ps1)가 지정된 기준 파일을 읽고 `04_Projects/gemini-guidance-YYYY-MM-DD.md`를 생성한다. Gemini는 텍스트만 반환하고 파일 쓰기는 오케스트레이터가 수행한다.

API 키가 없는 상태에서는 작업이 명확한 오류와 함께 중단되며, 키를 저장소·Obsidian 설정·로그에 기록하지 않는다.
