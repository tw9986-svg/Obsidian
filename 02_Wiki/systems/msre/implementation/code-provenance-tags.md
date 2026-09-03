---
type: implementation
system: msre
status: active
date: 2026-09-03
updated: 2026-09-03
tags: [provenance, code, audit, transform, dymola]
---

# 코드 내 출처 태그 체계와 위키 provenance 대응

MSRE_TRANSFORM 코드는 Modelica 도큐먼트 문자열 안에 **자체 provenance 태그**를 갖고 있다
(`"<TAG> | 설명"` 형식). 이 태그 체계는 위키의 8종 provenance(`CLAUDE.md`)와 **어휘가 다르므로**,
`03_Data/`에 값을 옮길 때는 아래 대응표로 번역한다.

canonical 기준: `01_Raw/code/MSRE_TRANSFORM-main (2).zip`
= commit `80a8f6d7a2bee75c5810545cf95856653a39df51`. 관련: [[02_Wiki/systems/msre/implementation/msre-transform-model]].

## 1. 코드 태그 → 위키 provenance 대응표

| 코드 태그 | 출현 수 | 의미 (코드 기준) | 위키 provenance | 비고 |
|---|---|---|---|---|
| `PHYSICAL` | 10 | ORNL/INL 하드웨어 실측·설계 치수 | `ORIGINAL` | 1차 문헌 재확인 필요 (아래 §3) |
| `REFERENCE` | 6 | 외부 문헌이 제시한 값 그대로 | `ORIGINAL` | 인용 문헌이 2차면 `ORIGINAL(2차)`로 표기 |
| `DERIVED` | 13 | 다른 파라미터로부터 수식 계산 | `DERIVED` | 직접 대응 |
| `PROPERTY-DERIVED` | 2 | 물성 상관식을 특정 온도에서 평가한 값 | `DERIVED` | 기반 상관식(Cantor)을 함께 명시 |
| `ASSUMPTION` | 8 | 연구자 가정, 출처 없음 | `ASSUMED` | 직접 대응 |
| `ASSUMPTION/DERIVED` | 2 | 가정값으로부터 계산 | `ASSUMED` | 근거 사슬이 가정에서 시작 |
| `ASSUMPTION/DERIVED FROM REFERENCE` | 2 | 문헌값을 가정된 방식으로 분할 | `ASSUMED` | 분할 규칙이 가정 |
| `ASSUMPTION/OPEN` | 2 | 가정이면서 미해결 항목 | `ASSUMED` + issue 등록 | |
| `NODALIZATION` | 7 | 이산화 선택 (노드 수, peaking factor 등) | `ASSUMED` | 물리값 아님, 수치 선택 |
| `ACTIVE` | 10 | 현재 결과를 만드는 계산 경로 | (provenance 아님) | **상태 플래그** |
| `REFERENCE ONLY` | 15 | 비교용, 활성 계산에 미연결 | (provenance 아님) | **상태 플래그** |
| `LEGACY` / `LEGACY REFERENCE ONLY` / `LEGACY/DEPRECATED` / `LEGACY DIAGNOSTIC` | 5 | 폐기됨, 연결 없음 | `superseded` | Verification 컬럼에 기록 |
| `DIAGNOSTIC` / `DIAGNOSTIC ONLY` | 5 | 출력 진단용 파생량 | `DERIVED` | |
| `BENCHMARK_DIFFERENCE` | 11 | 참조 코드/논문 대비 상대오차 | (provenance 아님) | **벤치마크 지표** |
| `OPEN / TO BE REVIEWED` | 1 | 재검토 대상 | `UNKNOWN` | issue 등록 대상 |
| `O-24` / `O-32` / `PARTIAL_GEOMETRY_BASELINE` | 9 | 열린 이슈 번호 라벨 | (provenance 아님) | **이슈 추적 라벨** |

> **핵심**: 코드 태그는 provenance 축(`PHYSICAL/REFERENCE/DERIVED/ASSUMPTION/NODALIZATION`)과
> 상태 축(`ACTIVE/REFERENCE ONLY/LEGACY/DIAGNOSTIC/BENCHMARK_DIFFERENCE/O-nn`)이 **한 필드에 섞여 있다.**
> 위키로 옮길 때는 provenance와 Verification 상태를 분리해 기록한다.

## 2. 태그된 파라미터가 있는 파일

| 파일 | 태그 개수 | 성격 |
|---|---|---|
| `Data/Geometry.mo` | 46 | 형상·인벤토리·펌프 진단값의 provenance 본체 |
| `Verification/Properties_TransitTime.mo` | 22 | 밀도 상관식별 전이시간 비교 (ACTIVE vs REFERENCE ONLY) |
| `Verification/Analytic_DriftReactivity.mo` | 9 | drift reactivity 해석해 대조 |
| `Data/Nodalization/PartialCoreNodalization.mo` | 6 | 이산화 파라미터 |
| `Verification/Steady_LoopBalance.mo` | 3 | 전이시간 벤치마크 차이 |
| `Verification/{LowFlow_*,O32_*,SemiLinear_*,BaseClasses/IdealPressureRise}.mo` | 7 | O-24 / O-32 이슈 실험 |

## 3. 코드가 인용하는 외부 출처 인벤토리

`.mo` 파일 전체에서 인용 토큰을 추출해 집계했다 (인용 횟수 = 문자열 출현 수).

### 3-1. 보유함 (`01_Raw/literature/`)

| 출처 | 코드 인용 | 코드에서 쓰이는 곳 | Source 페이지 |
|---|---|---|---|
| Jeong et al. 2026, NET 58 104438 | 78 | 벤치마크 기준 전체, MARS 노드 대응, Table 1–3 kinetics | [[02_Wiki/sources/jeong-2026-mars-msre-benchmark]] |
| ORNL-TM-0378 (Engel & Haubenreich 1962) | 53+17 | `Verification/ORNL0378/*` 전체 — 축/반경 출력형상, 온도 검증 | [[02_Wiki/sources/ornl-tm-0378-engel-haubenreich-1962]] |
| **ORNL-TM-2316 (Cantor ed. 1968)** | **91** | ACTIVE 연료염 물성 4종 (`d_T`, `cp_T`, `eta_T`, `lambda_T`) | [[02_Wiki/sources/ornl-tm-2316-cantor-1968]] — **2026-09-03 확보 · ⚠️ 귀속 반증됨** |
| ORNL/TM-2019/1359 (de Wet & Greenwood 2019) | 5 | 상·하부 plenum 체적 (`REFERENCE`) | ⚠️ 미작성 — **2026-09-03 신규 확보** |
| ORNL-TM-3229 (Kedl 1970) | 5 | 채널별 form loss — **아직 미추출**, `ASSUMED`로 대체 중 | ⚠️ 미작성 |
| ORNL-4396 (MSRP 반기보고서, 1969) | 2 | 자연순환 실험 HX 열제거 곡선 (미재현) | ⚠️ 미작성 — **2026-09-03 신규 확보** |
| ORNL-TM-380 (Haubenreich) | 1 | `driftReactivity` Eq. 8 근거 | [[02_Wiki/sources/ornl-tm-0380-effective-delayed-neutron-yields]] |
| Fischer & Bures 2024 | 2 | TRANSFORM 선행 MSRE 모델 | ⚠️ 미작성 — **2026-09-03 신규 확보** |

### 3-2. 미보유 — **확보 우선순위 순**

| 출처 | 코드 인용 | 왜 중요한가 | 우선순위 |
|---|---|---|---|
| **INL MSRE VTB/SAM fuel-salt equation of state** | 다수 | ⚠️ **최우선으로 격상 (2026-09-03).** TM-2316 확보 후 `d_T`·`cp_T`가 그 보고서에 **없음**이 확정되면서, 코드 주석이 함께 지목한 이 INL 문서가 두 값의 실제 출처일 가능성이 가장 높아졌다. `PHYSICAL` 하드웨어 치수·배관 5 in의 근거로도 인용됨 | **최우선** |
| ORNL-TM-4865 (Compere 1975) | 22 | Phase 2–3에서 쓰다 폐기한 밀도 상관식. `REFERENCE ONLY`지만 [[02_Wiki/issues/fuel-salt-property-correlation-conflict]]의 한 축 | 높음 |
| Hanusek & Juan, Ann. Nucl. Energy 157 (2021) 108208 | 2 | 6군 지연중성자 β·λ의 **원출처** (Jeong Table 1은 재인용) | 높음 |
| Jeong & Cho, NET 58 (2026) 104160 | 1 | `driftReactivity` Eq. 8의 이론 근거 | 중간 |
| ORNL-4865 (원보고서) | 5 | plenum 체적 12.24 / 11.34 ft³의 **원출처** (현재 TM-2019/1359 경유 재인용) | 중간 |
| Poppendiek & Palmer, ORNL-1395 (1953) / ORNL-1701 (1954) | 2 | `poppendiekDeltaT` 벽면 온도차 상관식 | 중간 |
| ORNL-TM-3832 | 1 | 냉각염(2차 계통) 물성 Table 3 | 낮음 |
| Gnielinski, Int. Chem. Eng. 16 (1976) 359 | 32+9 | 코어·HX Nusselt 상관식. 표준 상관식이라 교과서로 대체 가능 | 낮음 |
| Serpent 반경 출력 tabulation (Jeong 논문 내부) | 13 | 비공개. 코드는 J0 + 25 % reflector saving 형상으로 **대체(ASSUMED)** | 확보 불가 |

## 4. 이 감사로 드러난 판단 필요 지점

1. **`PHYSICAL` 태그 10건이 "ORNL/INL hardware"라고만 적혀 있고 보고서·페이지 번호가 없다.**
   `01_Raw/literature/`에 ORNL-TM-728(설계 Part I)이 있으므로 페이지 단위로 소급 확인 가능.
   확인 전까지 `03_Data/` 이관 시 provenance는 `ORIGINAL`, confidence `medium`으로 둔다.
2. ~~ACTIVE 물성 4종의 1차 출처(ORNL-TM-2316)가 라이브러리에 없다.~~ → **2026-09-03 확보 완료. 결과는 더 나쁘다:**
   원문 대조 결과 `d_T`·`cp_T`는 TM-2316에 **존재하지 않고**, `eta_T`·`lambda_T`는 존재하지만
   **MSRE 연료염이 아니라 ThF₄ 함유 MSBR 연료염 F₁의 값**이다. TM-2316의 7종 염 중 ZrF₄ 함유 염은 없다.
   → [[02_Wiki/issues/fuel-salt-property-provenance-composition-applicability]] (**critical, open**).
3. **`ASSUMPTION | no published source` 6건**(다운커머 길이, 배관 3구간 길이, 펌프 볼류트 체적·유동장)이
   loop 체적과 전이시간을 직접 좌우한다. [[02_Wiki/issues/jeong-transit-time-value-mismatch]]의 유력 원인 후보.
4. **Kedl ORNL-TM-3229를 보유하고 있는데도 form loss가 아직 `ASSUMED`다.** 추출 가능한 미처리 작업.

## 관련 페이지
- [[02_Wiki/systems/msre/implementation/msre-transform-model]]
- [[02_Wiki/reviews/2026-09-03-inbox-raw-code-classification]]
- [[02_Wiki/reviews/2026-09-03-raw-code-recovery-map]]
- [[03_Data/registry]]
