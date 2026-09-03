---
type: review
date: 2026-09-03
updated: 2026-09-03
reactor_system: [msre, msbr, msfr]
simulation_code: [transform-dymola, mars, mars-ks, relap5, sam, gen-foam, openfoam, dynasty]
tags: [classification, triage, inbox, raw, provenance, audit]
---

# 분류 작업 — `00_Inbox` / `01_Raw` 자료 및 코드 내 출처 (2026-09-03)

작업 범위: ① `00_Inbox` 자료 23건 분류·편입, ② `01_Raw` 계층 정리, ③ MSRE_TRANSFORM 코드가
인용하는 출처의 분류·보유 여부 감사. **본 작업은 분류(triage)이며, 개별 소스의 내용 ingest는 아직 아님.**

---

## 1. `00_Inbox` 분류 결과 (23건 → 중복 5 + 신규 18)

### 1-1. 중복 5건 — 재편입하지 않음

MD5 대조로 `01_Raw/literature/`의 기존 파일과 **바이트 동일** 확정. `00_Inbox/_duplicates/`로 격리 (삭제하지 않음).

| Inbox 파일 | 기존 보유본 | MD5 |
|---|---|---|
| `ORNL-TM-728.pdf` | ORNL-TM-728 Robertson 1965 | `d672fe4b…5935b` |
| `ORNL-TM-0730.pdf` | ORNL-TM-730 Haubenreich 1964 | `95abf4e9…b928` |
| `ORNL-TM-0378.pdf` | ORNL-TM-0378 Engel & Haubenreich 1962 | `60510ffe…a0fe` |
| `ORNL-TM-0380.pdf` | ORNL-TM-0380 유효 지연중성자 수율 | `e9ed1f94…c69` |
| `ORNL-TM-3229.pdf` | ORNL-TM-3229 Kedl 1970 | `0157a351…028d` |

### 1-2. 신규 18건 — `01_Raw/literature/`로 편입 (표준 파일명 부여)

각 PDF의 표제지를 실제로 읽어 서지사항을 확정했다 (추정 없음).

#### (A) MSRE 1차 문헌 — ORNL 원보고서 · **최우선 ingest 대상**

| 파일 | 저자/연도 | 내용 | 우리 연구와의 접점 |
|---|---|---|---|
| ORNL-TM-1070 | Ball & Kerlin, 1965-12 | Stability Analysis of the MSRE | 과도·안정성 벤치마크의 1차 근거 |
| ORNL-TM-1626 | B. E. Prince, 연도 UNKNOWN | Period Measurements on the MSRE **During Fuel Circulation**: Theory and Experiment | **순환 β_eff 실측의 원출처** → [[02_Wiki/issues/beta-eff-circulating-discrepancy]] 직결 |
| ORNL-TM-2997 | R. C. Steffy Jr., 1970-04 | Experimental Dynamic Analysis of the MSRE with U-233 Fuel | U-233 과도 실험, `Kinetics_U233` 검증 근거 |
| ORNL-TM-3039 | MSRE Staff / ed. Guymon, 1973-06 | MSRE Systems and Components Performance | 펌프·HX 실제 성능 실측 → 펌프 head 충돌 검증 |
| ORNL-4396 | MSRP, 1969-02 반기보고서 | Molten-Salt Reactor Program Semiannual Progress Report | **코드가 자연순환 HX 곡선 출처로 직접 인용** (`Experiments/NaturalCirculation.mo`) |

> ⚠️ ORNL-TM-1626의 발행연도는 스캔 OCR 품질 저하로 원문에서 **확인되지 않았다**. 통상 1966으로
> 인용되나 미검증이므로 파일명·본문에 연도를 넣지 않았다 (원칙 2).

#### (B) Modelica / TRANSFORM 계열 — 우리 모델의 직접 선행연구

| 파일 | 저자/연도 | 내용 | 접점 |
|---|---|---|---|
| ORNL/TM-2019/1359 | de Wet & Greenwood, 2019-09 | Status Report on the MSRE TRANSFORM Model | **코드가 plenum 체적 12.24/11.34 ft³의 출처로 인용** (`Data/Geometry.mo`) |
| Fischer & Bures, NED 416 (2024) 112768 | Seaborg / TUM | Application of Modelica/TRANSFORM to system modeling of the MSRE | 동일 툴체인 선행 MSRE 모델, 코드가 2회 인용 |
| Pfahl et al., NED 449 (2026) 114790 | DTU/KIT/Saltfoss/KAIST | Multi-Physics Benchmark for a Thermal MSR | **TRANSFORM이 참여 코드 중 하나**, code-to-code 검증 표준 후보 |

#### (C) MARS 계열 — 벤치마크 상대 코드

| 파일 | 저자/연도 | 내용 | 접점 |
|---|---|---|---|
| Jeong et al., NET 58 (2026) **103898** | Jeong·Lim·Ha·Cho (PNU/KAERI) | Verification of the **modified point kinetics model** in MARS for MSRs | 기보유 104438과 **다른 논문**. 3-D DNP 수송 PKM 검증 — 우리 `PointKinetics_DNPtransport`의 대응물 |
| Jin & Bang, 2026 | UNIST NTHRS | Implementation of Molten Salt Thermophysical Properties in **MARS-KS** | FLiBe/FLiNaK/NaCl-KCl-MgCl 물성 구현 + MSRE 정상상태 (오차 <1 %) |
| Jin & Bang, 2026 (발표자료) | UNIST NTHRS | Steady State Analysis of two MSRE Modules (slides, 47 p) | 위 논문의 발표본 |

#### (D) 다른 시스템 — DYNASTY(자연순환 실험장치) · MSFR

시스템 슬러그 신설이 필요한 자료. **현재는 `01_Raw/literature/`에 보존만 하고 위키 네임스페이스는 미신설.**

| 파일 | 저자/연도 | 시스템 | 접점 |
|---|---|---|---|
| Benzoni et al., Front. Energy Res. (2023) | PoliMi | DYNASTY-eDYNASTY | **DYMOLA 2023 + Modelica 1-D 자연순환** — 우리와 동일 툴체인 |
| Benzoni et al., PNE 155 (2023) 104486 | PoliMi | DYNASTY | 물 실험 캠페인 대비 1-D 모델 검증 (실험 원데이터 포함) |
| Missaglia et al., Results in Eng. 28 (2025) 107466 | PoliMi/Khalifa | DYNASTY | RELAP5 모델 (code-to-code 대조군) |
| Deanesi et al., NED 445 (2025) 114486 | PoliMi/Khalifa | MSFR | freeze valve, OpenFOAM 다물리 |

#### (E) 배경·참고

| 파일 | 비고 |
|---|---|
| Amirkhosravi et al., NED 449 (2026) 114757 | GeN-Foam 다공성 매질 **MSRE 흑연 온도** — 흑연 6 % 발열분율을 Engel & Haubenreich 1962로 인용. 축방향 MAPE 1.09 %, 흑연 평균 935.6 K vs ORNL 936.4 K. **[[02_Wiki/issues/graphite-heating-fraction-provenance]] 및 코어 온도 검증에 직결** |
| ORNL/SPR-2020/1836 (Dion et al. 2020) | MSR **핵물질 계량·시그니처** 연구. 열수력과 무관 — 우선순위 낮음 |
| Dolan (ed.) 2017, *Molten Salt Reactors and Thorium Energy* | Elsevier 단행본. ⚠️ **타인(Ji Yong Kim) 계정 워터마크가 찍힌 사본** — 인용은 가능하나 재배포 금지, git 커밋 시 주의 |

---

## 2. `01_Raw` 계층 정리

### 2-1. `raw/` (소문자) 잔재 폴더 제거

구조 재편 이전의 잔재. 클리핑 2건을 `01_Raw/misc/`로 이관하고 폴더를 제거했다.

| 이동 전 | 이동 후 |
|---|---|
| `raw/MSRE 운전모사 구성.md` | `01_Raw/misc/MSRE 운전모사 구성 (ChatGPT 대화 클리핑, 2026-09-02).md` |
| `raw/Claude Code.md` | `01_Raw/misc/Claude Code 세션 클리핑 (2026-09-02).md` |

> 두 파일 모두 **AI 대화 클리핑**이다. 연구 방향 논의 기록으로서는 가치가 있으나
> **정량값의 provenance 근거로 인용해서는 안 된다** (1차·2차 문헌이 아님).

### 2-2. `01_Raw/code/` — 낱개 233개 파일 문제 **해결**

이전 판정("낱개 파일이 zip 소스와 일치 0개, 이름↔내용 대응 상실")을 **정정한다.**
CRLF→LF 정규화 후 SHA-256 대조 결과:

- **낱개 233개 전부(233/233)가 canonical zip의 133개 blob과 정확히 일치**한다.
- canonical 133 경로 중 100개는 낱개 2개가, 33개는 낱개 1개가 담고 있다 (100×2+33 = 233).
- `" 1"` 접미사 쌍은 같은 파일의 다른 버전이 아니라, **트리 순서가 밀린 서로 다른 canonical 파일**이다.
- 즉 낱개 집합에 **canonical zip 대비 고유 내용이 0개**다.

전체 233행 복원 맵: [[02_Wiki/reviews/2026-09-03-raw-code-recovery-map]].
이전 판정의 원인은 줄바꿈 정규화 누락이었다.

**분류 결론**

| 대상 | 분류 | 조치 |
|---|---|---|
| `MSRE_TRANSFORM-main (2).zip` | **canonical** (commit `80a8f6d7…df51`) | 유지. 모든 코드 인용의 기준 |
| 낱개 `.mo`/`.md`/`.csv`/`.py` 233개 | **완전 중복** (정보 손실 없음) | ✅ **`_noncanonical/`로 격리 완료** (부록 A1) |
| `download` (확장자 없음) | 낱개 233개에 포함, `Verification/Pump_ZeroSpeed.mo` 내용 | 동상 |

### 2-3. 빈 폴더

`01_Raw/experiments/`, `01_Raw/meetings/`, `99_Attachments/`, `02_Wiki/concepts/`, `02_Wiki/equations/`는
현재 비어 있다. `01_Raw/experiments/`는 ORNL-TM-2997·ORNL-TM-1626·ORNL-4396의 실험 데이터를
디지타이징하면 채워질 자리다.

---

## 3. 코드 내 출처 분류

상세: **[[02_Wiki/systems/msre/implementation/code-provenance-tags]]**

### 3-1. 코드는 자체 provenance 태그 체계를 갖고 있다

`.mo` 도큐먼트 문자열의 `"<TAG> | 설명"` 형식으로 **16종 태그, 총 약 110개 파라미터**가 분류되어 있다.
이 어휘는 위키의 8종 provenance와 다르며, **provenance 축과 상태 축이 한 필드에 섞여 있다**:

- provenance 축 → `PHYSICAL`(10) `REFERENCE`(6) `DERIVED`(13) `PROPERTY-DERIVED`(2) `ASSUMPTION*`(14) `NODALIZATION`(7)
- 상태 축 → `ACTIVE`(10) `REFERENCE ONLY`(15) `LEGACY*`(5) `DIAGNOSTIC*`(5) `BENCHMARK_DIFFERENCE`(11) `O-24`/`O-32`(8)

`03_Data/`로 옮길 때의 대응표를 위 페이지에 고정했다.

### 3-2. 코드가 인용하는 출처의 보유 현황

| 구분 | 건수 | 비고 |
|---|---|---|
| 보유 (`01_Raw/literature/`) | 7종 | 이 중 **3종(ORNL/TM-2019/1359, ORNL-4396, Fischer & Bures)이 오늘 Inbox에서 확보됨** |
| 미보유 | 10종 | 아래 최우선 항목 포함 |

### 3-3. ⚠️ 최우선 발견 — ACTIVE 물성의 1차 출처 미보유 → **부록 A6에서 해소, 그리고 반증됨**

> 아래는 확보 이전 시점의 기록이다. 2026-09-03 원본을 확보해 대조한 결과
> **이 귀속 자체가 성립하지 않음**이 확인되었다. 결론은 **부록 A6**과
> [[02_Wiki/issues/fuel-salt-property-provenance-composition-applicability]]를 볼 것.

**ORNL-TM-2316 (S. Cantor, 1968)** 은 코드에서 **91회 인용**되는 최다 인용 출처이며,
현재 모델이 실제로 돌아가는 연료염 물성 4종 전부의 유일한 근거다:

| 함수 | 코드의 값 | 출처 |
|---|---|---|
| `d_T` | `2553.3 − 0.562·(T−273.15)` kg/m³ | Cantor ORNL-TM-2316 |
| `cp_T` | `2009.66` J/kg·K (온도 무관) | 〃 |
| `eta_T` | `8.4e-5·exp(4340/T)` Pa·s | 〃 |
| `lambda_T` | `1.0` W/m·K | 〃 |

**이 보고서가 라이브러리에 없다.** 따라서 밀도·인벤토리·전이시간·펌프 토크·drift reactivity 등
현재 모든 정량 결과가 **검증 불가능한 상관식 위에 서 있다.** 확보 최우선.

### 3-4. 즉시 착수 가능한 미처리 작업

- **Kedl ORNL-TM-3229를 보유하고 있는데도** 코어 채널 form loss가 여전히 `ASSUMED`다
  (`Core2D_RadialHydraulics.mo`, `Data/Nodalization/Core2D.mo`가 명시적으로 "아직 추출 안 됨"이라 기록).
- `PHYSICAL` 태그 10건이 "ORNL/INL hardware"라고만 적혀 있고 **페이지 번호가 없다.**
  보유 중인 ORNL-TM-728로 소급 확인 가능.
- `ASSUMPTION | no published source` 6건(다운커머 길이, 배관 3구간, 펌프 볼류트 체적·유동장)이
  loop 체적을 직접 좌우 → [[02_Wiki/issues/jeong-transit-time-value-mismatch]]의 유력 원인.

---

## 4. 후속 ingest 우선순위 (제안)

| 순위 | 대상 | 이유 |
|---|---|---|
| ~~1~~ | ~~ORNL-TM-2316 확보~~ | ✅ **완료 (부록 A6)** — 확보 결과 귀속 반증. 후속은 **INL VTB/SAM 문서 확보**로 이관 |
| **1 (신규)** | **INL MSRE VTB/SAM fuel-salt equation of state** | `d_T`·`cp_T`의 실제 출처 후보. TM-2316에 없음이 확정됨 |
| 2 | ORNL-TM-1626 (Prince) | 순환 β_eff 24 % 불일치 이슈의 1차 근거 |
| 3 | ORNL/TM-2019/1359 (de Wet & Greenwood) | 코드가 인용 중인 plenum 체적의 직접 출처 |
| 4 | ORNL-TM-3229 form loss 추출 | 보유 중, `ASSUMED` 6건 해소 |
| 5 | Amirkhosravi 2026 (GeN-Foam graphite) | 흑연 6 % 및 코어 온도 검증 대조군 |
| 6 | Jeong 2026 NET 103898 (modified PKM) | 우리 DNP 수송 구현의 검증 대조 |
| 7 | Fischer & Bures 2024 | 동일 툴체인 선행 MSRE 모델 |
| 8 | ORNL-TM-3039 / TM-2997 / TM-1070 | 펌프·HX 성능, U-233 과도, 안정성 |
| 9 | DYNASTY 3편 | `simulation_code: dynasty` 축으로 확정됨 (부록 A3) |

## 5. 사용자 판단이 필요했던 지점 — **전부 결정됨 (2026-09-03)**

| # | 항목 | 결정 |
|---|---|---|
| 1 | `01_Raw/code/` 낱개 233개 | **`_noncanonical/`로 격리** (삭제 아님, hash·복원맵 유지) → A1 |
| 2 | `00_Inbox/_duplicates/` 5건 | **유지, 현재 삭제하지 않음** → A2 |
| 3 | DYNASTY / MSFR 분류 | **MSFR → `reactor_system`, DYNASTY → `simulation_code`**, 축 혼합 금지 → A3 |
| 4 | Dolan 2017 단행본 | **PDF는 Git 제외, 로컬 Raw 보존, 서지·hash·metadata만 커밋** → A4 |

## 관련 페이지
- [[02_Wiki/reviews/2026-09-03-raw-code-recovery-map]]
- [[02_Wiki/systems/msre/implementation/code-provenance-tags]]
- [[02_Wiki/issues/raw-code-noncanonical-files]]
- [[index]]

---

# 부록 — 2026-09-03 지시사항 실행 결과

## A1. 낱개 코드 233개 격리 완료

`01_Raw/code/` 최상위 → `01_Raw/code/_noncanonical/` 이동.

- 이동 **전/후 SHA-256 233개 전부 동일** — 무결성 확인
- hash 기록 보존: `02_Wiki/reviews/2026-09-03-noncanonical-sha256.txt`
- 복원 맵 유지: [[02_Wiki/reviews/2026-09-03-raw-code-recovery-map]]
- `01_Raw/code/` 최상위에는 canonical zip 1개만 남음

## A2. 중복 PDF 5건 — `00_Inbox/_duplicates/` 유지, 삭제하지 않음

## A3. 분류 축 분리 — [[02_Wiki/classification-axes]] 신설

- **MSFR → `reactor_system`**, **DYNASTY → `simulation_code`**
- 두 축 혼합 금지 규칙 명문화, `CLAUDE.md`에도 반영
- DYNASTY는 물리적으로는 PoliMi의 자연순환 실험 루프(원자로 아님)이며,
  확보 3편이 모두 코드·모델 검증을 주제로 하므로 `simulation_code` 축에 둔다

## A4. Dolan 2017 단행본 — Git 제외, 로컬 보존

- `git rm --cached`로 추적 해제, `.gitignore`에 등록 (커밋 이력 없어 히스토리 정리 불필요)
- 로컬 파일은 `01_Raw/literature/`에 그대로 보존
- Git에는 서지·hash·metadata만: [[02_Wiki/sources/dolan-2017-molten-salt-reactors-thorium-energy]]
  (SHA-256 `ce95a25a…9a1c`, 842 p, © 2017 Elsevier)

## A5. 단일 진입점 확립

- `00_Inbox/README.md` 신설, `CLAUDE.md` 갱신
- ⚠️ **사용자 조치 필요**: Obsidian Web Clipper는 브라우저 확장이라 저장 경로가 이 저장소가 아닌
  **확장 프로그램 설정**에 있다. 저장 폴더를 `00_Inbox`로 직접 변경해야 한다.
  (저장소 안에서 바꿀 수 있는 설정은 없음을 확인 — `.obsidian/`에 clipper 설정 없음)

## A6. ORNL-TM-2316 ingest — ⚠️ **귀속 반증**

신규 확보 (SHA-256 `72693db2…d4ca`, 중복 아님). 표지에서 **1968년 8월, Reactor Chemistry Division,
S. Cantor 편집** 확인 후 `01_Raw/literature/`로 편입.

**4개 물성표를 페이지 이미지로 직접 대조한 결과, 코드의 출처 귀속이 성립하지 않는다:**

| 코드 함수 | 코드 값 | TM-2316 원문 | 판정 |
|---|---|---|---|
| `d_T` | 2553.3 − 0.562·t kg/m³ | p.28 밀도표에 **없음** (3.628/3.153/3.687/3.644/2.214/2.27/2.26만) | **UNKNOWN** |
| `cp_T` | 2009.66 J/kg·K (= 0.48 cal/g·°C) | p.22 액체 Cp에 **없음** (0.34/0.39/0.33/0.33/0.57/0.360/0.36만) | **UNKNOWN** |
| `eta_T` | 8.4e-5·exp(4340/T) Pa·s | p.8 **F₁ = 0.084 exp(4340/T)** 정확 일치 | ORIGINAL, **조성 외삽** |
| `lambda_T` | 1.0 W/(m·K) | p.11 F₁ 0.010 / L₂B 0.010 W/(cm·°C) | ORIGINAL, **염 특정 불가** |

**TM-2316이 다루는 7종 염 중 MSRE 연료염(LiF-BeF₂-ZrF₄-UF₄)은 없다.** F₁–F₄는 전부 ThF₄ 함유
MSBR fuel-breeder 염이고, ZrF₄ 함유 염은 물성표에 하나도 없다.

생성/갱신:
- [[02_Wiki/sources/ornl-tm-2316-cantor-1968]] (신규)
- [[03_Data/msre/properties/ornl-tm-2316-salt-properties]] (신규, 4개 표 전량 + 조성표)
- `03_Data/registry.md` (+28행 + 코드값 provenance 재판정표)
- [[02_Wiki/issues/fuel-salt-property-provenance-composition-applicability]] (**신규, critical, open**)
- [[02_Wiki/issues/fuel-salt-property-correlation-conflict]] (TM-2316 행 반증 표기, 확보 항목 체크)
- [[02_Wiki/systems/msre/implementation/code-provenance-tags]] (TM-2316 → 보유로 이동, INL VTB/SAM을 최우선으로 격상)

"ORNL-TM-2316 미보유" 항목은 **해소(resolved)**. 단 그 자리를 더 심각한 신규 이슈가 대체했다.
