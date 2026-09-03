---
type: reference
status: active
date: 2026-09-03
updated: 2026-09-03
tags: [taxonomy, classification, frontmatter, schema]
---

# 분류 축 (Classification Axes)

자료·페이지는 **서로 다른 두 축**으로 분류한다. 이 둘을 하나의 `systems:` 필드에 섞지 않는다.

## 축 정의

### `reactor_system:` — 실제 원자로 시스템

모델링 **대상**이 되는 물리적 원자로 개념/플랜트.

| slug | 이름 | 비고 |
|---|---|---|
| `msre` | Molten Salt Reactor Experiment | 현재 주력 |
| `msbr` | Molten Salt Breeder Reactor | ORNL-TM-2316의 F₁–F₄ 염이 여기 속함 |
| `msfr` | Molten Salt Fast Reactor | freeze valve 등 |

### `simulation_code:` — 시뮬레이션 코드·툴체인 및 그 검증 인프라

해석 **수단**, 그리고 그 수단을 검증하기 위한 실험장치·벤치마크.

| slug | 이름 | 비고 |
|---|---|---|
| `transform-dymola` | Modelica/TRANSFORM on Dymola | 우리 코드 |
| `mars` | MARS | 벤치마크 상대 |
| `mars-ks` | MARS-KS | 물성 확장판 |
| `relap5` | RELAP5 | |
| `sam` | SAM (NEAMS) | |
| `gen-foam` | GeN-Foam | |
| `openfoam` | OpenFOAM | |
| `dynasty` | DYNASTY / eDYNASTY | 자연순환 루프 — 코드 검증용 실험 인프라로 분류 |

> 📌 **DYNASTY 분류 근거**: DYNASTY는 물리적으로는 PoliMi의 자연순환 실험 루프(원자로가 아님)다.
> 확보한 3편이 모두 **모델·코드 검증**(DYMOLA/Modelica 1-D, RELAP5)을 주제로 하므로
> `simulation_code` 축에 둔다. 원자로 시스템 축에는 올리지 않는다.

## 혼합 금지 규칙

1. `reactor_system` 값을 `simulation_code`에 넣지 않는다. 그 반대도 금지.
2. 한 자료가 두 축에 모두 걸리면 **두 필드에 각각** 기재한다.
   예: Jeong et al. 2026 → `reactor_system: [msre]`, `simulation_code: [mars]`
3. 기존 `systems:` 필드는 **`reactor_system`의 별칭**으로 취급한다.
   신규 페이지는 두 축을 명시적으로 쓴다.
4. 디렉터리 `02_Wiki/systems/<slug>/` 는 **`reactor_system` 축 전용**이다.
   `simulation_code` 전용 자료는 시스템 디렉터리를 만들지 않고
   `02_Wiki/sources/` + 해당 reactor_system의 `benchmark/`·`verification/`에 붙인다.

## 현재 보유 자료의 축 배정

| 자료 | reactor_system | simulation_code |
|---|---|---|
| ORNL-TM-728 / 730 / 0378 / 0380 / 1070 / 1626 / 2997 / 3039 / 3229 / 4396 | `msre` | — |
| ORNL-TM-2316 (Cantor 1968) | `msbr`, `msre`(flush salt L₂B만) | — |
| Jeong et al. 2026 (104438, 103898) | `msre` | `mars` |
| Jin & Bang 2026 (논문·발표자료) | `msre` | `mars-ks` |
| Leandro et al. 2019 | `msre` | `sam` |
| ORNL/TM-2019/1359 (de Wet & Greenwood) | `msre` | `transform-dymola` |
| Fischer & Bures 2024 | `msre` | `transform-dymola` |
| Pfahl et al. 2026 (벤치마크) | `msre`(thermal MSR) | `transform-dymola`, 외 다수 |
| Amirkhosravi et al. 2026 | `msre` | `gen-foam` |
| Benzoni 2023 ×2, Missaglia 2025 | — | `dynasty`, `transform-dymola` / `relap5` |
| Deanesi et al. 2025 | `msfr` | `openfoam` |
| ORNL/SPR-2020/1836 | `msre` | — |
| Dolan (ed.) 2017 | `msre`, `msbr`, `msfr` | — |

## 관련 페이지
- [[02_Wiki/overview]]
- [[02_Wiki/reviews/2026-09-03-inbox-raw-code-classification]]
- [[index]]
