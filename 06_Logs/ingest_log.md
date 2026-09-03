# Ingest Log

> ingest / query / lint 이력을 시간순으로 append-only 기록합니다. 형식: `## [YYYY-MM-DD] {ingest|query|lint|setup} | 요약`. 이전 이력(`wiki/log.md`)은 아래 첫 항목에 요약 이관.

## [2026-09-02] setup | LLM Wiki 구축 이력 요약 (구조 변경 전)

1. `raw/` + `wiki/` 3계층 구조 최초 생성 (범용 연구 위키).
2. MSRE 중심 Modelica/TRANSFORM 도메인 스키마로 재설계 (concept/component/equation/parameter/implementation/verification/benchmark/issue 8범주).
3. 원자력 열수력 전반 + Dymola 다중 시스템 라이브러리로 범위 확장, `wiki/systems/<system>/` 네임스페이스 도입.

## [2026-09-02] setup | 01_Raw/02_Wiki/03_Data/04_Projects/06_Logs 구조로 전면 재편

- `raw/` → `01_Raw/` (literature, code, experiments, meetings, misc), `wiki/` → `02_Wiki/`로 이름 변경 및 이관.
- **`03_Data/` 신설**: 정량값(물성치, 상관식, geometry, axial/radial distribution, benchmark 값)을 위키 서술과 분리해 독립 계층으로 관리. `03_Data/<system>/{properties,correlations,geometry,distributions,benchmark}/` 구조, `03_Data/registry.md` 마스터 테이블.
- **Provenance 분류 체계 교체**: 기존 `measured/design/literature/derived/assumption` → `ORIGINAL/DERIVED/DIGITIZED/FITTED/ASSUMED/CALIBRATED/SOFTWARE_DEFAULT/UNKNOWN` 8종으로 세분화.
- **`04_Projects/` 신설**: 연구 진행상황 문서 전용 계층. `04_Projects/msre-transform-status.md` 생성 (원본은 `01_Raw/misc/연구 주제 및 방향성.md`로 보존).
- `wiki/index.md` → 루트 `index.md`로 이동 (여러 최상위 계층을 아우르는 전체 카탈로그로 역할 확장), `wiki/log.md` → `06_Logs/ingest_log.md`로 이동.
- `wiki/parameters/registry.md` → `03_Data/registry.md`로 이관, provenance 체계 및 System 컬럼 반영.
- `CLAUDE.md` 전면 재작성: Raw 원본 수정 금지, 출처 없는 정보 추정 금지, 기존 Wiki 우선 갱신·불필요한 중복 문서 생성 금지 규칙 명문화. Source → Data → Wiki → Project 링크 체계 규정.
- `/wiki-ingest` 스킬 생성 (`.claude/skills/wiki-ingest/SKILL.md`) — 소스 1건 ingest 절차를 재사용 가능한 skill로 고정.
- `00_Inbox`의 연구노트(`연구 주제 및 방향성.md`)를 `01_Raw/misc/`로 원본 보존, `04_Projects/msre-transform-status.md`로 정리.
- `00_Inbox`에 논문 16편 확인 (MSRE/MARS/DYNASTY/TRANSFORM 관련) — ingest 대기.

## [2026-09-02] ingest | Leandro et al. 2019 — Thermal hydraulic model of the MSRE with SAM

- 원본: `00_Inbox` → `01_Raw/literature/Leandro et al 2019 - Thermal hydraulic model of the molten salt reactor experiment.pdf` (보존).
- PDF 텍스트 추출: 이 환경에 `pdftoppm`(poppler) 미설치로 Read 도구의 페이지 렌더링 불가 → `pdftotext -layout`으로 대체 추출 (텍스트만, 그림/그래프 디지타이징 불가).
- 생성: `02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic.md` (source note).
- 생성: `03_Data/msre/geometry/msre-primary-loop-geometry.md` (26개 값), `03_Data/msre/properties/msre-fuel-salt-properties-robertson1965.md` (연료염 3종+SAM FLiBe 물성), `03_Data/msre/benchmark/sam-relap5-3d-historical-primary-loop.md` (SAM/RELAP5-3D/Historical 비교 3행 확보, 4행 보류).
- 생성: `02_Wiki/systems/msre/components/{primary-loop,core,heat-exchanger,fuel-pump}.md`, `02_Wiki/systems/msre/benchmark/sam-msre-primary-loop.md`.
- 생성: `02_Wiki/issues/leandro2019-table-parsing.md` — Table 2(HX 치수 10항목) 전체 + Table 3 4행이 텍스트 추출 중 라벨-값 정렬 붕괴로 **UNKNOWN** 처리, 추정하지 않음.
- `03_Data/registry.md`, `index.md`, `04_Projects/msre-transform-status.md` 갱신.
- 미확보 1차 문헌: Robertson 1965(ORNL-TM-728), Haubenreich et al. 1964(ORNL-TM-730), Kedl 1970(ORNL-TM-3229), Kedl & McGlothlan 1968(ORNL-TM-2098), Engel & Haubenreich 1962(ORNL-TM-378) — 이 논문이 재인용한 값들의 원출처. 확보되면 Source를 1차로 교체 권장.
- **00_Inbox 잔여**: 논문 15편 ingest 대기 (다음: Application of Modelica/TRANSFORM to system modeling of the molten salt; ORNL MSRE TRANSFORM Model for thermal-Hydraulic Benchmarking; MARS 관련 3편; DYNASTY 관련 3편; graphite/multiphysics/benchmark 관련 다수).

## [2026-09-02] setup | poppler-utils 설치 및 Leandro Table 2/3 UNKNOWN 해소

- `winget install oschwartz10612.Poppler` 성공 (v25.07.0). Read 도구의 PDF 렌더링은 세션 PATH 미반영으로 여전히 실패 → `pdftoppm -png -r 200` + PNG Read 우회 경로 확립 (SKILL.md §7-1에 기록).
- Leandro 2019 Table 2(HX 치수 15항목 전체)·Table 3(미확정 4행) 이미지 육안 확인 → **UNKNOWN 2건 전부 해소**.
- Table 1·4·5는 기존 텍스트 재구성이 이미지와 일치함을 확인 (오류 없었음).
- 수정: `03_Data/msre/geometry/msre-primary-loop-geometry.md`(+16행), `03_Data/msre/benchmark/sam-relap5-3d-historical-primary-loop.md`(8행 완성), `03_Data/registry.md`, `02_Wiki/sources/leandro-2019-...md`.
- `02_Wiki/issues/leandro2019-table-parsing.md` → **resolved**.

## [2026-09-02] ingest | ORNL-TM-728 (Robertson 1965) + ORNL-TM-730 (Haubenreich et al. 1964) — 1차 자료 추적

- OSTI에서 다운로드해 `01_Raw/literature/`에 보존 (TM-728 575p/41 MB, TM-730 209p/14 MB, 스캔 OCR본).
- **범위 한정 ingest**: Leandro가 인용한 값 + 실제 모델링에 쓰이는 값만 대조 (무차별 수집 배제).
- 생성: `02_Wiki/sources/ornl-tm-728-robertson-1965.md`, `02_Wiki/sources/ornl-tm-730-haubenreich-1964.md`.
- **provenance 격상 (2차→1차)**: 설계유량(1200 gpm), core 입출구온도(1175/1225 °F), 배관 규격(5-in sched-40 INOR-8), core radius(27.7 in)·height(63 in), 연료염 3종 물성.
- **신규 1차 데이터**: 연료염 점도·열전도도·liquidus 온도, 냉각염(2차 계통) 물성, core 외부 연료체적 40 ft³, 펌프 제원(1150 rpm, 임펠러 11.5 in, 효율 80–85%)·기동 과도시간(50% 0.75 s → 100% 3 s).
- **검증**: Leandro Table 5 SI 값이 TM-728 영국단위 표(1200 °F)의 정확한 환산임을 3개 물성×3개 염에 대해 전부 확인 → 두 소스 간 충돌 없음.
- **신규 충돌 1건**: `02_Wiki/issues/pump-discharge-head-conflict.md` — Leandro 0.092 MPa vs TM-728 48.3 ft(≈0.324 MPa). 우리 모델 Dymola B0 `dp_pump` 0.301 MPa는 1차값과 정합.
- **신규 UNKNOWN 1건**: `02_Wiki/issues/graphite-heating-fraction-provenance.md` — 흑연 발열분율 6%의 1차 근거 미확인.

## [2026-09-02] ingest | `01_Raw/code/` MSRE_TRANSFORM implementation

- **canonical 확정**: `01_Raw/code/MSRE_TRANSFORM-main (2).zip` (133 파일, 패키지 v0.2.2, MSL 4.1.0 + TRANSFORM 1.1, Dymola).
- **비-canonical 판정**: 낱개 233개 파일 — `" 1"` 중복 101쌍 전부 내용 상이, HTML 문서 97개, 파일명-내용 불일치 확인(예: `Core1D.mo` 내용이 `package.order` 목록). zip 소스 130개와 (줄바꿈 정규화 후에도) 일치 0개. → `02_Wiki/issues/raw-code-noncanonical-files.md` (원본 삭제하지 않음).
- Git commit **UNKNOWN** (Download-ZIP 스냅샷, `.git` 없음).
- 생성: `02_Wiki/systems/msre/implementation/msre-transform-model.md` (구조·구현 물리·입력 provenance·가정), `02_Wiki/systems/msre/verification/dymola-b0-baseline.md`, `02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars.md`, `03_Data/msre/benchmark/transform-b0-vs-jeong-mars.md`.
- 수정(비-canonical 링크 정정): `components/{primary-loop,core,fuel-pump}.md`, `03_Data/msre/properties/...`.
- **코드 복제 없음** — 구조·물리·출처만 정리.

## [2026-09-02] ingest | Jeong et al. 2026 — Benchmarking the MARS code (NET 58, 104438)

- 원본 → `01_Raw/literature/Jeong et al 2026 - ....pdf`. **우리 TRANSFORM 모델의 직접 기반 논문.**
- 생성: `02_Wiki/sources/jeong-2026-mars-msre-benchmark.md`, `03_Data/msre/kinetics/delayed-neutron-parameters.md` (U-235/U-233 6군 β·λ, Λ, 온도계수 — Table 1–3 전체).
- 확인: β합(U-235) 0.006781 = 코드 README의 정적 β_eff 0.00678 (일치).
- **provenance 확보**: MARS 펌프 파라미터 = generic(SOFTWARE_DEFAULT), form loss·HX 전열면적 = CALIBRATED, 축방향 출력 = cosine(ASSUMED), 반경방향 = Serpent(비공개), 흑연 직접발열 = 전량 연료염 부여(ASSUMED, 저자도 한계 인정).
- **신규 충돌 1건**: `02_Wiki/issues/jeong-transit-time-value-mismatch.md` — 원 논문 τ_system 25.63 s(계산)/25.2 s(실험) vs 사내 `DYMOLA_B0_BASELINE.md` 25.70 s.
- **신규 의심 1건**: Jeong Table 2(U-233) group 1 값이 U-235와 완전 동일 — 오식 가능성, 추정 수정 없이 기록.
- **00_Inbox 잔여: 13편.**

## [2026-09-02] verify | ORNL 중복본 SHA-256 대조 — 중복 확정, 재편입 안 함

`00_Inbox`에 사용자가 추가한 ORNL PDF 중 2건이 기존 `01_Raw/literature/` 파일과 **바이트 동일**함을 SHA-256으로 확정. 별도 지식 문서 생성하지 않았고 기존 Source/Data/Wiki 링크를 그대로 유지한다.

| 파일 | SHA-256 |
|---|---|
| `00_Inbox/ORNL-TM-728.pdf` ≡ `01_Raw/literature/ORNL-TM-728 Robertson 1965 - ….pdf` | `d7ae226a64ee7d02ab97bb16ac4e55b9d7dda0e3af3e2e44d5bed12a38e2b064` |
| `00_Inbox/ORNL-TM-0730.pdf` ≡ `01_Raw/literature/ORNL-TM-730 Haubenreich et al 1964 - ….pdf` | `3d345d442706c881f0eeed6ca28f0f77c6e1f9d15e3d27ee5cd8462edc03007f` |

## [2026-09-02] verify | Git 저장소 확인 및 `01_Raw/code` 판정 **정정**

- 저장소: `https://github.com/tw9986-svg/MSRE_TRANSFORM` (branch `main`, 170 commits). HEAD = `492deecd47e1f5d51eb49d045db3ea6f64de87a7` (2026-09-02 20:11 KST).
- **zip = commit `80a8f6d7a2bee75c5810545cf95856653a39df51`** (2026-09-02 03:27 UTC) — 133/133 파일 완전 일치로 확정. → **"Git commit UNKNOWN" 해소.**
- HEAD는 zip보다 22 commit 앞서나 변경분은 `docs/PHASE_LOG.md`(+816줄)뿐 → 기존 위키 분석은 HEAD 기준으로도 유효.
- ⚠️ **이전 판정 정정**: `01_Raw/code/` 낱개 파일 **221/221이 저장소의 실제 blob과 해시 일치**. "HTML 저장본" 판정은 Modelica의 `annotation(Documentation(info="<html>` 때문에 `file`이 오탐한 것이었다. 진짜 문제는 **파일명↔내용 대응 상실 + 디렉터리 계층 소실**이며, 참조 불가라는 결론 자체는 유지.
- 코드 실제 값 대조: `U235_6group.mo`가 Jeong Table 1과 완전 일치(**verified**), 원출처는 **Hanusek & Juan, Ann. Nucl. Energy 157 (2021) 108208**로 확인. `Media/MSRE_Properties.mo`는 Robertson 상수표가 아니라 Cantor(1968)/Compere(1975) 상관식 사용 → **신규 충돌** `02_Wiki/issues/fuel-salt-property-correlation-conflict.md`.

## [2026-09-02] ingest | ORNL-TM-0378 (Engel & Haubenreich 1962) — 우선순위 1

- 원본 → `01_Raw/literature/ORNL-TM-0378 Engel and Haubenreich 1962 - ….pdf` (58p).
- 생성: `02_Wiki/sources/ornl-tm-0378-engel-haubenreich-1962.md`, `03_Data/msre/geometry/ornl-tm-0378-core-thermal-basis.md`.
- ✅ **UNKNOWN 해소**: 흑연 발열분율 6%의 근거를 **p.40 각주에서 원문 직접 확인** — "it was **assumed** that 6% …", 근거는 C. W. Nestor의 **미출간** 계산. provenance를 ORIGINAL(2차) → **ASSUMED(1차 확인)** 로 정정. `graphite-heating-fraction-provenance.md` → **resolved**.
- ✅ **우려 해소**: 열전도도 3.21 Btu(5.5557 W/m·K)도 같은 각주의 **가정값**이며 production은 1.0 W/m·K 사용 → 혼용 금지 명시.
- 🔍 **정밀화**: 온도 경계가 **세 종류**임을 확인 — reactor 1175/1225 °F vs **main-core 1177.3/1220.8 °F**(p.33). 기존 "908/936 K" 단일 기록을 분리.
- 🔍 **정밀화**: 주 노심 채널 수는 1140이 아니라 **940**(Table 2 region 2), 연료분율 0.224, 등가반경 24.76 in.
- 축방향 peak-to-average **1.3585**(π/2 아님), 최대 국부 흑연–연료 ΔT 목표 62.5 °F(Table 5).

## [2026-09-02] ingest | ORNL-TM-0380 (1962) — 우선순위 2

- 원본 → `01_Raw/literature/ORNL-TM-0380 - Prediction of Effective Yields of Delayed Neutrons in MSRE.pdf` (28p). OCR 품질이 낮아 **Table 2·p.21을 페이지 이미지로 직접 판독**.
- 생성: `02_Wiki/sources/ornl-tm-0380-effective-delayed-neutron-yields.md`, `03_Data/msre/kinetics/ornl-tm-0380-effective-yields-and-transit-times.md`.
- 1차값: actual yield 0.006405 / **static β_eff 0.006661** / core 방출분율 0.003942 / **circulating β_eff 0.003617** (Table 2, p.17).
- 1차값: **τ_core 9.37 s, τ_external 16.45 s, τ_system 25.82 s @1200 gpm**, 총 순환 연료 체적 **69.1 ft³ (1.9567 m³)**, 축방향 H = 77.7 in(코드값과 일치), f = 0.259 (p.21).
- ⚠️ **신규 충돌**: `beta-eff-circulating-discrepancy.md` — 순환 β_eff 0.003617 vs 모델 ≈0.0045(**24%**), static은 1.8%만 차이.
- 🔍 **핵심 발견**: 순환 체적비 2.0965/1.9567 = **+7.14%**, 전이시간비 27.651/25.82 = **+7.09%** — 0.05%p 이내 일치. TRANSFORM 전이시간이 긴 이유가 **체적 차이로 산술적으로 설명**됨. 단 경계 정의 확인 전까지 인과 미확정.
- **00_Inbox 잔여: 20편** (사용자 추가 ORNL 8편 포함, 중복 2건 제외).
## [2026-09-03] query | MSRE 열수력 이론 정리

- 기존 MSRE 소스·컴포넌트·구현·프로젝트 문서를 종합해 전역 열수력 이론 페이지를 작성했다.
- 보존법칙, 구성식, 노심/HX/펌프/자연순환, DNP 수송 결합 및 검증 순서를 [[02_Wiki/equations/thermal-hydraulics-foundations]]에 기록했다.

## [2026-09-03] lint | 00_Inbox 23건 · 01_Raw 계층 · 코드 인용 출처 전면 분류

전체 결과: [[02_Wiki/reviews/2026-09-03-inbox-raw-code-classification]] (내용 ingest는 아직 아님, 분류 단계).

**00_Inbox 23건 → 0건**
- 중복 5건(ORNL-TM-728/730/0378/0380/3229) MD5 바이트 동일 확정 → `00_Inbox/_duplicates/`로 격리 (삭제 안 함).
- 신규 18건 표제지를 직접 읽어 서지 확정 후 `01_Raw/literature/`로 편입, 표준 파일명 부여. 문헌 7 → 25건.
  - 1차 ORNL: TM-1070(Ball & Kerlin 1965-12 안정성), TM-1626(Prince, 순환 중 주기 측정), TM-2997(Steffy 1970-04 U-233 동특성), TM-3039(Guymon 1973-06 계통·기기 성능), ORNL-4396(MSRP 1969-02 반기보고서).
  - TRANSFORM 계열: ORNL/TM-2019/1359(de Wet & Greenwood 2019), Fischer & Bures 2024(NED 416 112768), Pfahl et al. 2026(NED 449 114790).
  - MARS 계열: Jeong et al. 2026 NET **103898**(수정 PKM 검증 — 기보유 104438과 별개 논문), Jin & Bang 2026 논문+발표자료.
  - DYNASTY 3편(Benzoni 2023 ×2, Missaglia 2025), MSFR freeze valve(Deanesi 2025) — 별개 시스템, 슬러그 미신설.
  - 기타: Amirkhosravi 2026(GeN-Foam MSRE 흑연 온도), ORNL/SPR-2020/1836(핵물질 시그니처, 우선순위 낮음), Dolan ed. 2017 단행본(⚠️ 타인 워터마크 사본).
- ORNL-TM-1626 발행연도는 OCR 품질 저하로 원문 미확인 → 파일명에 연도 넣지 않음(원칙 2).

**01_Raw 계층 정리**
- 구조 재편 잔재 `raw/`(소문자) 제거. 클리핑 2건 → `01_Raw/misc/`. (AI 대화 클리핑이므로 provenance 근거로 인용 금지.)
- `01_Raw/code/` 낱개 233개: CRLF→LF 정규화 후 SHA-256 대조 결과 **233/233이 canonical zip 133 blob과 완전 일치**.
  canonical 133 경로 중 100개는 낱개 2개가, 33개는 1개가 담음 → **고유 내용 0**. 파일명↔내용 대응 전부 복원.
  → [[02_Wiki/reviews/2026-09-03-raw-code-recovery-map]] (233행), 이슈 `raw-code-noncanonical-files` **resolved**.
  이전 "일치 0개" 판정은 줄바꿈 정규화 누락에 의한 오류였음.

**코드 내 출처 분류** → [[02_Wiki/systems/msre/implementation/code-provenance-tags]] 신설
- 코드 자체 provenance 태그 **16종·약 110개 파라미터** 전수 추출. provenance 축(PHYSICAL/REFERENCE/DERIVED/PROPERTY-DERIVED/ASSUMPTION*/NODALIZATION)과 상태 축(ACTIVE/REFERENCE ONLY/LEGACY*/DIAGNOSTIC*/BENCHMARK_DIFFERENCE/O-nn)이 한 필드에 혼재 → 위키 8종 provenance 대응표 고정.
- 인용 출처 인벤토리: 보유 7종 / 미보유 10종. 오늘 확보분 3종(ORNL/TM-2019/1359, ORNL-4396, Fischer & Bures)이 코드가 직접 인용하던 출처였음.
- ⚠️ **최우선 발견**: **ORNL-TM-2316 (Cantor 1968) 미보유** — 코드 최다 인용(91회)이자 ACTIVE 연료염 물성 4종(d/cp/η/λ)의 유일 근거. 현재 모든 밀도·인벤토리·전이시간·펌프 토크 결과가 검증 불가 상관식 위에 있음.
- 착수 가능한 미처리: Kedl ORNL-TM-3229를 **보유 중인데도** 코어 form loss가 여전히 `ASSUMED`.

**사용자 판단 대기**: ① 낱개 233개 `_noncanonical/` 격리 ② `_duplicates/` 5건 삭제 ③ DYNASTY/MSFR 슬러그 신설 ④ Dolan 단행본 커밋 여부.
