---
type: issue
status: open
date: {{date:YYYY-MM-DD}}
systems: [msre]
tags: [beta-eff, dnp, conflict, kinetics]
---

# ⚠️ 순환 β_eff 충돌: ORNL-TM-0380 0.003617 vs 모델 ≈0.0045 (24% 차이)

## 문제 설명

| 항목 | ORNL-TM-0380 (1962, 1차) | 모델/Jeong 계열 (2021–2026) | 차이 |
|---|---:|---:|---:|
| **static** β_eff | 0.006661 | 0.006781 | +1.8% |
| **circulating** β_eff | **0.003617** | **≈0.0045** | **+24%** |
| 순환/정적 비 | 0.543 | ≈0.664 | |

정적 값은 1.8% 차이로 사실상 정합하지만, **순환 값은 24% 벌어진다.** 즉 두 계열은 "DNP가 순환으로 얼마나 손실되는가"를 상당히 다르게 예측한다.

## 발견 경위
[[02_Wiki/sources/ornl-tm-0380-effective-delayed-neutron-yields]] ingest 중 Table 2(p.17)를 이미지 판독하여 확인.

## 영향 범위
- [[03_Data/msre/kinetics/delayed-neutron-parameters]] / [[03_Data/msre/kinetics/ornl-tm-0380-effective-yields-and-transit-times]]
- [[02_Wiki/systems/msre/implementation/msre-transform-model]] — `Beta_eff`는 null transient 후 정상상태에서 구해 과도 중 고정
- [[02_Wiki/systems/msre/benchmark/pump-startup-coastdown-vs-mars]] — 반응도 크기는 β_eff에 직접 비례하므로 pcm 비교에 영향

## 확인된 차이 요인 (단, 어느 것도 원인으로 확정하지 않음)
1. **핵데이터 세트가 다름**: TM-0380은 Keepin, Wimett & Zeigler(U-235 열분열) / 모델은 Hanusek & Juan, Ann. Nucl. Energy 157 (2021) 108208.
2. **전이시간이 다름**: TM-0380 t_c 9.37 s·t_x 16.45 s vs 모델 9.96·17.69 s. 순환 손실은 전이시간에 민감하므로 이것만으로도 일부 설명 가능.
3. **중요도 가중이 다름**: 모델·Jeong은 φ*_k = 1(균일 중요도) 가정. TM-0380은 자체 중요도·플럭스 가중 계산을 수행 (θ_i 항). 균일 중요도 가정이 순환 손실을 과소평가할 여지.
4. static이 1.8%만 다른데 circulating이 24% 다르다는 점은 **차이의 원인이 기본 수율보다 순환 손실 모델 쪽에 있음**을 시사한다.

## 현재 상태
Open. **양쪽 값을 모두 보존하며 어느 것도 덮어쓰지 않는다.**

## 해결 방향 / 추가로 필요한 것
- [ ] TM-0380의 θ_i(군별 노심 방출분율) 계산 절을 정독해 중요도 가중 방식 확인.
- [ ] 모델의 전이시간을 TM-0380 값(9.37/16.45 s)으로 강제한 **민감도 케이스**를 돌려, 24% 중 전이시간이 설명하는 몫과 중요도 가정이 설명하는 몫을 분리. (단 프로젝트 규칙상 geometry를 벤치마크 값에 맞추는 것은 **명시적으로 이름붙인 민감도 케이스 안에서만** 허용)
- [ ] Hanusek & Juan (2021) 원문 확보 여부 판단.

## 관련 페이지
- [[02_Wiki/sources/ornl-tm-0380-effective-delayed-neutron-yields]]
- [[02_Wiki/issues/jeong-transit-time-value-mismatch]]
