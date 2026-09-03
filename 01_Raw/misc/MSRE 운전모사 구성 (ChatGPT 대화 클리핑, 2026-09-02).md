---
title: "MSRE 운전모사 구성"
source: "https://chatgpt.com/c/6a9626fe-7034-83e8-9310-2671ea2f8fab"
author:
published:
created: 2026-09-02
description: "ChatGPT conversation with 9 messages"
tags:
  - "clippings"
---
MSRE 정격 출력 운전 모사할때, Secondary HX만 모사하고 흑연 열전달은 열 구조체만 만들어놓은 상태로 drain tank 구조와 붕괴열 붙여서 모사하는 방향

---

그 방향 자체는 가능하지만, **정격출력 모사 단계에 drain tank·붕괴열까지 바로 붙이는 순서는 비효율적**. 정격출력 benchmark와 drain/shutdown transient를 분리하는 구조가 더 적절함.

### 권장 구성

| 단계 | 모델 구성 | 판단 |
| --- | --- | --- |
| **1\. 정격출력 정상상태** | Core + graphite thermal structure + Primary loop + Pump + HX + secondary-side boundary | **우선** |
| **2\. 정격출력 과도상태** | 위 모델 + kinetics + 온도피드백 | 이후 |
| **3\. Shutdown / coastdown** | 위 모델 + decay heat | 이후 |
| **4\. Drain transient** | 위 모델 + drain line + freeze valve/plug + drain tank + drain-tank heat removal | 마지막 |

MSRE 자체도 연료염 → primary heat exchanger → 비핵연료 coolant salt → radiator 구조. 따라서 처음부터 secondary loop 전체를 상세 모델링할 필요 없이 **HX secondary side를 정격조건 boundary로 주는 방식** 은 정격출력 core/primary-loop benchmark 목적에 충분히 타당함. [^1]

---

## 1\. 지금 가장 먼저 수정할 부분: graphite

현재

```
Fuel salt
   │
   │ fission heat
   ▼
Core fluid

Graphite
[thermal structure만 존재]
```

라면 정격출력 열수력 모델로는 아직 불완전한 상태.

MSRE에서는 연료염에서만 열이 생긴 것이 아니라 graphite와 Hastelloy-N 구조물에서도 gamma, beta, neutron irradiation에 의한 내부발열 존재. ORNL의 MSRE thermal-hydraulic 자료에서도 이를 명시. [^2]

특히 과도응답에서는 graphite 영향 무시 곤란. 당시 MSRE 자료에서 graphite의 열용량과 fuel–graphite 열전달 때문에 graphite thermal response time이 약 **180 s** 수준으로 평가됨. [^3]

따라서 최소 구성:

```
Fuel salt control volume
        ↕ hA(Tfuel − Tgraphite)
Graphite thermal structure
        +
graphite internal heat generation
```

즉,

Graphite:

정도의 coupling 필요.

**열 구조체만 만들어 놓고 fluid와 연결하지 않은 상태** 라면 실제 graphite 열관성 효과 부재.

---

## 2\. 정격출력에서 drain tank는 필요 없음

정격운전 시:

```
Drain tank
   X
Primary circulation loop
```

정상적으로 격리된 저장계통.

MSRE drain tank 목적:

- 연료염 배출
- shutdown/storage
- decay heat 제거
- maintenance
- abnormal/transient 대응

등. ORNL에서도 MSRE drain tank를 core에서 제거된 fuel salt를 저장하는 안전/정비 계통으로 설명하며 passive decay-heat removal 필요성을 별도로 다룸. [^4]

따라서

**8–10 MW 정격 정상상태 검증에서 drain tank를 붙여도 주요 benchmark 결과 개선 거의 없음.**

반대로 모델 복잡도만 증가:

- 추가 inventory
- drain line 압력손실
- valve/freeze plug logic
- 중력 drainage
- tank level
- tank heat loss
- decay heat distribution
- salt solidification 문제

등.

---

## 3\. 붕괴열도 정격출력 benchmark에서 바로 추가할 필요 없음

여기서 중요한 주의점.

예를 들어 모델에

```
Q_core = 8e6 W
```

를 **reactor thermal power** 로 주고 있다면

에 decay heat를 다시

형태로 추가하면 **double counting 가능성**.

정격출력에서는 에너지 발생을

처럼 일관된 power partition으로 정의해야 함.

반면 reactor trip 후:

이후에도

이므로 decay heat model의 중요성 급증.

즉 decay heat 모델의 주요 목적:

```
Rated operation
     ↓
SCRAM
     ↓
Fission power 급감
     ↓
Decay heat 잔존
     ↓
Pump coastdown / natural circulation
     ↓
Drain
     ↓
Drain tank decay heat removal
```

이 영역.

---

## 현재 MSRE 모델에 가장 적절한 개발 순서

내가 현재 구조라면 다음 순서 선택.

```
① Core full-power TH
│
├─ fuel volumetric heating
├─ axial power distribution
├─ graphite thermal structure
├─ fuel ↔ graphite heat transfer
└─ graphite/structure heating
          ↓
② Primary loop
│
├─ pump
├─ piping
├─ inventory / residence time
└─ ΔP
          ↓
③ Primary HX
│
└─ Secondary side
      └─ Tin, m_dot 또는 heat-removal boundary
          ↓
④ Rated steady-state validation
│
├─ Core Tin
├─ Core Tout
├─ ΔTcore
├─ HX Tin/Tout
├─ loop temperatures
├─ pressure loss
└─ energy balance
          ↓
⑤ Coupled kinetics / temperature feedback
          ↓
⑥ Pump transient
          ↓
⑦ Decay heat
          ↓
⑧ Natural circulation
          ↓
⑨ Drain line + Drain tank
          ↓
⑩ Drain-tank decay heat removal
```

### 따라서 현재 우선순위

**Drain tank보다 graphite coupling이 훨씬 먼저.**

특히 정격출력 실험값과 비교하려는 목적이라면

여기까지 먼저 고정.

그리고 이 모델에서 **8 MW 또는 10 MW steady-state의 에너지 보존과 온도장 재현 여부 확인**.

그 다음

구조가 가장 논리적.

특히 ORNL 자료상 graphite 내부발열과 graphite–fuel 열전달은 실제 MSRE의 full-power thermal response 일부였기 때문에, **graphite를 단순 adiabatic thermal mass로 남겨놓고 drain tank부터 구현하는 것은 물리적 우선순위가 뒤바뀐 상태** 로 봐야 함. [^2]

현재 목표가 **“1D 정격출력 + secondary HX boundary → MSRE 실험데이터 비교”** 라면, drain tank는 해당 benchmark 범위 밖으로 두는 구성이 가장 깔끔함.

---

이 논문 내용 검토

---

이 논문은 **네가 지금 고민하는 “MSRE 정격출력에서 graphite volumetric heating + fuel–graphite 열전달을 어떻게 넣을지”에 직접적으로 참고 가치가 큼.** 다만 그대로 복제하기보다는, **전력분배 방법론은 강하게 참고 / 열전달 상관식은 비판적으로 재검토** 가 적절함.

## 1\. 논문이 실제로 한 것

논문의 핵심 목적 자체가 MSRE graphite temperature 예측. GeN-Foam에서 neutronics–thermal hydraulics를 결합하고, ORNL의 graphite 온도 데이터를 benchmark로 사용. 평균 graphite 온도 935.6 K, ORNL 값 936.4 K 수준의 일치, radial MAPE 0.62%, axial MAPE 1.09% 제시.

모델 구조의 핵심:

```
Neutronics
   ↓
spatial power density Q'''
   ↓
────────────────────────
Fuel salt       Graphite
fluid energy    solid energy
equation        equation
────────────────────────
       ↕
    convection
       ↕
────────────────────────
Thermal-hydraulics
```

다만 실제 graphite stringer 1140개를 하나씩 CFD로 만든 방식 아님.

**core 전체를 porous medium으로 homogenization**:

- graphite volume fraction ≈ 0.775
- fuel volume fraction ≈ 0.225
- 1140 equivalent passages
- 실제 개별 graphite channel geometry 대신 single cylindrical porous core

적용.

이 부분은 네 1D equivalent-channel TRANSFORM 접근과 철학적으로 상당히 가까움.

---

## 2\. 가장 중요한 부분: graphite에는 reactor power의 6%

논문은 ORNL-TM-0378을 직접 근거로

적용.

조건:

10 MW reference condition에서 graphite power는 gamma + neutron heating에 의해 총 reactor power의 6%.

따라서 10 MW라면

나머지를 단순히

로 둘 수 있는 1차 모델 구성 가능.

네 모델 관점에서는 이전에 이야기한 6.5%보다 **이 논문을 직접 따를 경우 6%가 명확함**.

따라서 benchmark용 baseline:

가 깔끔함.

단, 여기서 주의.

이건 **material heat-deposition fraction**.

축방향 power shape와 별개.

즉

가 있으면

같은 구조.

---

## 3\. Graphite를 단순 thermal mass로 처리한 게 아님

이 논문에서 상당히 참고할 만한 부분.

Graphite 내부를 lumped nodes로 쪼갠 뒤

형태로 계산.

여기서

- : graphite sub-node volume
- : neutronics에서 전달되는 volumetric power density
- : 각 graphite node의 power fraction
- : node 사이 thermal conductance

즉 개념상:

```
Graphite center
    │
    │ H1
    ▼
Graphite inner node
    │
    │ H2
    ▼
Graphite surface
    │
    │ convection
    ▼
Fuel salt
```

구조.

이게 네 모델에서 **graphite thermal structure를 만드는 근거로 매우 유용함.**

---

## 4\. 특히 좋은 방법론: graphite conductance를 별도 고해상도 모델에서 추출

논문은 graphite thermal resistance를 임의의 하나로 끝내지 않음.

단일 graphite stringer를:

1. SALOME CAD
2. OpenFOAM fine model
3. graphite volumetric heating
4. boundary temperature 922 K
5. convection
6. , , 계산

한 뒤 그 결과로 **reduced lumped model의 thermal conductance** 산출.

이 접근은 상당히 좋은 reduced-order modelling 방법.

즉

```
실제 3D graphite geometry
        ↓
고해상도 conduction calculation
        ↓
effective thermal resistance
        ↓
H1, H2, ...
        ↓
1D system model
```

구조.

네 TRANSFORM에서는 CFD까지 반드시 재현할 필요 없이

또는 equivalent cylindrical wall로 reduction 가능.

하지만 논문 방식의 핵심은

> **graphite 내부 온도구배를 없애지 않고 reduced thermal resistance로 보존**

한다는 점.

---

## 5\. 네 모델에서 따라서 적용할 부분

현재

```
fuel CV
graphite thermal structure
```

까지 있다면 다음 연결.

각 axial node :

### Fuel volumetric heating

### Graphite volumetric heating

그리고 graphite 내부:

fuel:

구조.

이 부분은 논문의 방법론과 정합적.

---

## 6\. 그런데 논문의 열전달 상관식은 그대로 가져오면 안 됨

여기가 가장 중요한 비판점.

논문 Table 6의 heat-transfer correlation:

즉 사실상 **Dittus–Boelter 형태**.

문제:

Dittus–Boelter는 기본적으로 **fully developed turbulent internal flow** 용.

그런데 네가 실제 MSRE channel geometry로 계산한 정격 조건은 대략

수준.

즉 laminar.

따라서

를 네 1D actual-channel 모델에 그대로 적용하는 것은 적절하지 않음.

---

## 7\. 왜 이 논문은 turbulent correlation을 쓸 수 있었는가

논문 모델이 실제 개별 channel model이 아니라 **porous-medium homogenized core** 라는 점 중요.

실제:

```
1140 individual obround channels
```

가 아니라

```
single porous cylindrical core
```

처리.

또 thermal-hydraulic closure 자체도:

- porous
- RANS
- Blasius drag
- Dittus-Boelter-type heat transfer

구조.

즉 이 논문의 Reynolds number와 네가 계산한

에서 사용하는 **actual channel hydraulic diameter 기반 Reynolds number를 동일하게 해석하면 안 됨**.

논문 자체도 core velocity를 약

로 예측하고 ORNL 0.2133 m/s와 0.84% 오차라고 보고.

하지만 velocity가 맞는 것과 microscopic wall heat-transfer closure가 맞는 것은 별개.

---

## 8\. 그래서 이 논문의 좋은 점과 약한 점 분리

| 항목 | 평가 | 네 모델 적용 |
| --- | --- | --- |
| Graphite 6% power | **강한 근거** | 적용 권장 |
| Graphite volumetric heating | **강한 근거** | 적용 권장 |
| Fuel/graphite 별도 energy equation | **강한 방법론** | 적용 권장 |
| Graphite thermal resistance | **강한 방법론** | 적용 권장 |
| Porous homogenization | 유효 | 1D equivalent model 참고 |
| ORNL graphite temperature validation | 매우 유용 | benchmark target |
| Dittus-Boelter | **주의 필요** | 그대로 적용 비권장 |
| porous | CFD-specific | TRANSFORM 불필요 |
| Blasius pressure loss | 주의 | 현재 실제 channel ΔP 모델 우선 |
| full 3D neutronics | 고충실도 | 1D benchmark에는 과도 |

---

## 9\. 이 논문에서 바로 가져와야 하는 검증값

논문은 10 MW design condition에서:

ORNL reference:

제시.

또 Table 9:

| 변수 | GeN-Foam | ORNL |
| --- | --- | --- |
| Fuel inlet | 908.51 K | 908.15 K |
| Fuel outlet | 936.003 K | 935.921 K |
| Graphite mean | 935.61 K | 936.42 K |

그리고 graphite matrix top 약 167 cm:

ORNL:

수준.

네 full-power model 검증값으로 상당히 유용.

---

## 10\. 특히 Fig. 14, 15가 중요

논문의 단순 평균온도만 보면 안 됨.

페이지 10의 Fig. 14:

**radial graphite temperature**

중앙부가 높은 온도, 외측으로 갈수록 감소.

Fig. 15:

**axial graphite temperature**

하부 약 925 K → 상부 방향으로 지속 증가 → 상단 근처 약 970 K 이상.

즉 graphite temperature를

하나로 처리하는 것은 정격상태 bulk energy balance에는 가능하지만, graphite feedback까지 고려하려면 불충분.

논문도 radial MAPE 0.62%, axial MAPE 1.09%를 별도로 검증.

네 1D에서는 radial profile은 포기하더라도 **axial** 는 반드시 남기는 게 맞음.

---

## 11\. 네 1×20 모델과 가장 자연스러운 대응

논문의 3D porous model을 그대로 복제할 필요 없음.

네 경우:

```
axial node 1
 fuel ── convection ── graphite

axial node 2
 fuel ── convection ── graphite

...

axial node 20
 fuel ── convection ── graphite
```

각 node:

그리고 graphite를 가능하면 radial 2–3 lump:

```
Graphite bulk / center
       │ Hcond
Graphite surface
       │ hA
Fuel
```

이렇게.

그러면 논문의 핵심 물리를 상당 부분 보존하면서 1D system-code 계산량 유지 가능.

---

## 12\. Surface heat transfer에 대해서는 논문보다 ORNL 원자료를 우선해야 함

이 논문이 graphite power fraction과 temperature benchmark에는 강함.

반면

는 네 actual-channel 1D 모델의 closure로 쓰기에는 물리적 충돌 존재.

따라서 네 모델은:

이면 laminar/developing correlation,

transition blending,

turbulent correlation

구조 유지가 더 타당.

특히 현재 MSRE 조건에서 높은 , 긴 thermal entrance length를 고려하면

같은 developing-flow 모델이 더 적절.

---

## 13\. 이 논문에서 하나 더 주의할 점

논문은 power deposition을 neutronics와 직접 coupled.

즉

가 Serpent/GeN-Foam neutron field에서 나옴. GeN-Foam은 fluid temperature, density, structural temperature를 thermal-hydraulics와 주고받는 구조.

반면 네 모델이 현재 prescribed axial shape라면:

형태.

따라서 논문과 완전히 같은 model fidelity는 아님.

하지만 **정격 정상상태 1D benchmark 목적이라면 문제 없음**.

오히려 지금 단계에서 full neutronics spatial calculation까지 넣는 것은 불필요.

---

## 결론

이 논문을 네 모델에 적용할 때 핵심만 뽑으면:

그리고 각 axial node에 동일한 normalized spatial power shape를 우선 적용:

graphite:

fuel:

이 구조가 가장 직접적인 적용.

다만 논문의

는 **네 actual-channel TRANSFORM 모델에서는 그대로 채택하지 않는 것이 맞음**. 이 논문은 porous-medium RANS 모델이고, 네 모델은 실제 MSRE channel , wetted perimeter, 을 직접 보존하는 구조라 closure regime 자체가 다름.

따라서 이번 논문에서 얻은 가장 큰 수정 방향은 **“graphite thermal structure 존재”에서 끝내지 말고, 6% independent volumetric heating + 내부 conduction + fuel과의 surface convection까지 실제 energy path로 연결** 하는 것. 이게 정격출력 모델의 우선 수정사항.

---

다음 단계는 **Phase 46B — , 절대 출력밀도 유도 사슬 복원** 으로 잡는 것이 맞음. 지금 axial 계산으로 넘어가면 안 됨. 핵심은 nomenclature의 `P = relative specific power` 와 Eq.(13)–(17)의 차원 요구사항 사이 불일치를 원문 Appendix/정규화 관계로 해소하는 것.

아래 프롬프트 그대로 Claude Code에 전달.

```
[담당: Claude Code] — Phase 46B.
ORNL-TM-0378의 P_f / P_g absolute local power-density scale 복원.

목적:
Phase 46에서 BLOCKED된 Table 5,
0% permeation case의

ΔT_g-f,max = 62.5°F = 34.7222 K

재현에 필요한 P_f, P_g의 절대값 또는 유도 사슬을
ORNL-TM-0378 원문 내부에서 끝까지 추적.

이번 단계도 production code 수정 금지.
Verification/ORNL0378의 기존 Phase 46 구현은
근거가 확인된 경우에만 수정.

============================================================
0. 현재 고정된 사실
============================================================

Phase 46에서 다음은 이미 PASS 또는 원문 근거 확보:

- Eq.(13) transcription
- Eq.(14)-(16) transcription
- Eq.(17)/(18) transcription
- r_w = equal-flow-area circular channel radius
- q_w = P_g / (S/V)_actual 관계는 p.39에서 유도 가능
- Eq.(16) coefficient SI/unit audit PASS
- main-core Tin = 909.4278 K
- historical k_f = 5.5557 W/m/K
- historical k_g = 22.4996 W/m/K
- graphite heating = 6% reactor power
- main-core fuel fraction = 0.224
- main-core channels = 940
- B(z) axial shape 확보

현재 유일한 핵심 blocker:

P_f, P_g가 Eq.(13)-(17)에 들어갈 때의
ABSOLUTE LOCAL SPECIFIC POWER 정의 및 normalization.

Phase 46에서 사용한 임시 shortcut:

P_f = 0.94 Q / V_fuel × peaking
P_g = 0.06 Q / V_graphite × same peaking

은 Table 5 ΔT를 2.33배 과대예측했으므로
Case B 정의로 사용 금지.

============================================================
1. 가장 먼저 nomenclature 재검토
============================================================

ORNL-TM-0378 nomenclature 전체에서 다음 기호를 다시 추적:

P
P_f
P_g
Q
Q_f
Q_g
P_m
Q_m
A(r)
B(z)
F
f
V_fc
V_gc
q_w
T'_f
T'_g

각 기호마다 표 작성:

symbol
exact wording
dimension according to wording
dimension required by equation
first occurrence
equations used
possible normalization relation

특히:

P = "relative specific power"

Q = "equivalent specific power (absolute)"

라고 되어 있다면
P와 Q 사이 변환식이 보고서 어딘가 존재하는지 반드시 찾을 것.

단순 typo라고 결론내리지 말 것.

============================================================
2. Appendix를 우선 추적
============================================================

본문보다 Appendix의 계산 절차를 우선적으로 따라갈 것.

Phase 45에서 확인한 Eq.(a15)가
given ΔT를 사용해 power density를 역산한다는 점을 출발점으로:

Eq.(a1)부터 마지막 식까지
계산 사슬을 순서대로 읽고 다음을 찾을 것.

A. absolute total power를 넣는 최초 위치
B. relative spatial distribution에 scale factor를 곱하는 위치
C. maximum specific power 정의
D. average specific power 정의
E. equivalent specific power Q의 계산식
F. P_f / P_g가 absolute quantity로 바뀌는 단계

Appendix equations를 단편적으로 검색하지 말고
계산 알고리즘 순서를 복원.

최종적으로 다음 형태 중 무엇인지 판정:

Q_abs(r,z) = C × P_relative(r,z)

또는

P_abs(r,z) = P_m × A(r) × B(z)

또는 다른 형태.

============================================================
3. Fig.4 / Fig.8 normalization 추적
============================================================

Fig.4 radial distribution와
Fig.8 axial distribution이 각각

- absolute
- relative
- peak-normalized
- average-normalized

중 무엇인지 정확히 확인.

현재 B(z)는 형상만 확보되어 있음.

다음 수치 계산:

B_max
B_average over main-core
B_peak/B_average

그리고 radial factor A(r)에 대해서도 동일:

A_max
A_area-weighted average
A at r = 7 in
A(7in)/A_average

가능하면

P(r,z) = A(r)B(z)

가 어떤 normalization으로 정의됐는지 원문 문장 확보.

중요:
Fig.14 hottest radial position = r=7 in이므로
Table 5 maximum ΔT에 들어가는 P_f,max가
단순 whole-core global maximum인지,
r=7 in / 특정 z에서의 local maximum인지 구분.

============================================================
4. Table 5 자체의 계산경로 역추적
============================================================

Table 5의 0% permeation row를
단순 target으로만 보지 말고
어떤 식과 어떤 입력으로 계산됐는지 본문 preceding/following paragraphs 추적.

다음 질문에 답할 것:

1. 62.5°F는 Eq.(17) 결과인가?
2. Eq.(18)을 사용한 결과인가?
3. maximum P_f, P_g가 어디서 왔는가?
4. maximum radial/axial factors가 별도 입력됐는가?
5. 6% graphite power가 local P_g/P_f ratio로 변환되는 식이 있는가?
6. fuel/graphite volume fraction이 이 변환에 들어가는가?

============================================================
5. 6% graphite power 해석 재검토
============================================================

"6% of reactor power generated in graphite"를

P_g/P_f = 0.06/0.94

로 직접 해석하지 말 것.

volume 차이 때문에 local volumetric power density ratio는 다를 수 있음.

다음 관계를 원문에서 찾을 것:

∫ P_g dV_g / Q_total = 0.06

∫ P_f dV_f / Q_total = 0.94

인지,

또는 local deposition ratio가 따로 정의되어 있는지.

특히 main core만 보면
reactor 전체 10 MW 중 일부 power가 peripheral region에 존재하므로

0.94 × 10 MW

가 main-core fuel power라는 가정은 금지.

이 점이 Phase 46 shortcut 2.33배 오류의 가장 유력한 원인 후보 중 하나.

단, 원문 확인 전 확정 금지.

============================================================
6. reactor power vs main-core power 분리
============================================================

반드시 다음 세 레벨을 구분:

Q_reactor_total
Q_mainCore_total
Q_local(r,z)

Phase 45에서 reactor-level boundary와
main-core boundary가 이미 다르다는 사실 확인됨.

같은 방식으로 power도:

10 MW reactor total
≠
main-core deposited power

일 가능성을 우선 검토.

ORNL-TM-0378에서
main core가 reactor total power 중 몇 %를 갖는지
직접 또는 유도 가능한 수치 탐색.

특히 regions 1/2/3/... 별
power fractions,
fission fractions,
volume fractions,
channel counts,
equivalent core regions

관련 Table/Figure 검색.

Phase 46에서 발견한:

main core = 940 channels
peripheral = 12 / 108 / 78 channels

정보와 연결.

============================================================
7. Eq.(18)의 역할 집중 분석
============================================================

Eq.(17)과 Eq.(18)의 차이를 정확히 설명.

특히 Eq.(18)이

- P_g와 P_f의 relation을 제거하는 식인지
- total local power 하나로 환원하는 식인지
- 6% graphite fraction을 이미 내장한 식인지
- normalized relative power를 absolute power로 바꾸는 식인지

확인.

Phase 46에서 Eq.(18)을 transcription했지만
이번에는 algebraic derivation 관점에서 역으로 전개.

Eq.(18)을 Eq.(13)-(17)에서 직접 재유도해서
원문과 일치하는지 확인.

============================================================
8. dimensional audit 강화
============================================================

각 식에 대해 단위표 작성.

Eq.(13):
[P_f]
[r_w²]
[k_f]
[q_w/(P_f r_w)]

Eq.(16):
[P_g]
[9.97e-4 ft²]
[k_g]

Eq.(17)
Eq.(18)

결과 단위가 °F 또는 K가 되기 위해
P_f/P_g의 실제 dimension이 무엇이어야 하는지 명시.

만약 nomenclature의 "relative specific power"와
equation dimension이 충돌하면:

SOURCE_TEXT_CONFLICT

로 기록.

하지만 먼저 다음 가능성을 확인:

- P symbol에 hidden dimensional scale 존재
- relative = relative spatial distribution이지만 numerical variable은 dimensional
- Q가 normalization constant
- nomenclature typo
- appendix에서 별도 conversion

근거 없이 하나 선택 금지.

============================================================
9. 역산은 diagnostic으로만 허용
============================================================

Table 5 목표 34.7222 K로부터
필요한 P_f,max를 역산하는 것은 허용.

단 용도는:

DIAGNOSTIC_ONLY

절대 provenance input으로 사용 금지.

두 방식 계산:

A. q_w와 P_g/P_f 관계까지 포함해 simultaneous solve
B. graphite term과 fuel term을 분리해 required P_f 계산

출력:

P_f_required
P_g_required
q_w_required
ΔT_g
ΔT_f

그리고 이 값이 원문에서 추적한
main-core local power density와 일치하는지 비교.

일치하면 provenance chain 확인의 보조 증거.
불일치하면 원인 추적.

============================================================
10. 현재 shortcut 오류 분해
============================================================

현재 임시값:

P_f,max = 62.0593 MW/m3
P_g,max = 1.14345 MW/m3
ΔT_total = 81.0591 K

목표:
34.7222 K

왜 2.33배 차이나는지
다음 후보를 각각 정량 평가:

A. reactor total 10 MW를 main core 10 MW로 처리
B. 0.94/0.06 global fraction 해석 오류
C. radial peaking normalization 오류
D. axial peaking normalization 오류
E. fuel volume denominator 오류
F. main-core 940ch vs total 1140ch domain 오류
G. P vs Q symbol interpretation 오류
H. Eq.(18)에서 이미 포함된 factor 중복

한 번에 여러 값을 바꾸지 말 것.

각 후보에 대해:
"이 수정 하나만 적용하면 ΔT가 얼마로 바뀌는가"
민감도 표 작성.

이것은 calibration이 아니라
오류원인 분리용 diagnostic.

============================================================
11. main-core geometry 독립 검증
============================================================

Table 2 기반:

main-core channels = 940
fuel volume fraction = 0.224

를 사용해 main-core fuel volume을 독립 계산.

현재 repository production geometry와 혼동 금지.

다음 계산:

A_total_mainCore
V_mainCore
V_fuel_mainCore
V_graphite_mainCore

그리고 ORNL의 V_fc가 존재하면
직접 비교.

relative error 보고.

============================================================
12. 구현 수정 규칙
============================================================

현재 Verification/ORNL0378 코드 중
NOT_SOURCED 임시 입력은 유지 가능하되
절대로 default historical input으로 승격하지 말 것.

근거가 새로 확보되면:

NOT_SOURCED
→ DERIVED_FROM_ORNL
또는
→ PRIMARY_SOURCE_CONFIRMED

로 변경.

production code는 계속 수정 금지.

============================================================
13. 완료 조건
============================================================

Phase 46B PASS 조건:

[ ] P/Q 관계 확인 또는 SOURCE_TEXT_CONFLICT로 명시

[ ] relative/absolute specific power dimensional issue 판정

[ ] main-core absolute power scale 확보

[ ] P_f local absolute scale 확보

[ ] P_g local absolute scale 확보

[ ] q_w absolute value provenance 확보

[ ] Table 5 62.5°F 재현

[ ] tuning 없음

[ ] 역산값을 provenance로 사용하지 않음

[ ] current 2.33× discrepancy 원인 설명

[ ] production unchanged

만약 원문 전체를 끝까지 추적했음에도
absolute scale을 복원할 수 없다면:

HISTORICAL_SOURCE_INCOMPLETE

로 판정하고
Case B를 "fully specified"에서
"closure specified / absolute power normalization unresolved"
로 정확히 강등.

억지로 SPECIFIED 유지 금지.

============================================================
14. 최종 보고 형식
============================================================

A. P/Q nomenclature 판정

B. Appendix 계산 사슬

C. spatial normalization:
   radial A(r)
   axial B(z)

D. reactor total → main-core → local power chain

E. P_f/P_g absolute values

F. dimensional audit

G. reverse-calculated diagnostic values

H. 2.33× discrepancy decomposition

I. Table 5 reproduction

J. Case B status:
   SPECIFIED / PARTIALLY_SPECIFIED /
   HISTORICAL_SOURCE_INCOMPLETE

K. Phase 47 진행 가능 여부

결과 보고 후 대기.
```

현재 가장 중요한 의심점은 **10 MW 전체 reactor power를 바로 main-core fuel/graphite volume에 나눈 것**. 이미 main core가 940채널이고 reactor inlet과 main-core inlet도 다르다는 사실이 확인됐으므로, `reactor total → main-core deposited power → local \(A(r)B(z)\)` 라는 중간 normalization이 빠졌을 가능성을 우선 검증할 가치가 큼.

다만 아직 가설. Phase 46B에서 원문 계산 사슬로 확인하기 전에는 2.33배 오차의 원인으로 확정하면 안 됨.

---

**\[담당: Claude Code\]** — Phase 46B. 먼저 결정적 구조 관찰: ΔT의 두 항이 **모두 전력에 선형** 이므로(Eq 13의 `2q_w/(P_f r_w)` 는 스케일 불변) 2.33배는 **순수 스케일 인자** 입니다. 원문에서 그 인자를 찾습니다:

Searched for peaking ratios and read Table 4

Table 4의 지역들이 정확히 10,000 kw로 합산되며 **region J = 8287 kw (82.87 %)** 입니다. 그러나 **Table 2는 지역을 1–5로, Table 4는 D–S로** 표기합니다 — 서로 다른 분할일 수 있습니다. 확인합니다:

Found the region definition scheme

**Table 3 = "Nineteen-Region Core Model Used in EQUIPOISE Calculations"** — Table 4의 문자 D–S가 이 19-지역 모델입니다. Fig. 4는 " **in the Plane of Maximum Slow Flux** ". 두 곳을 읽습니다:

실행됨 명령 1개, 읽기 6e13f57e-ORNLTM0378.pdf

**결정적 발견 — Table 3, region J:** radius 3.00–27.75 in, z 5.50–64.59 in, **fuel 22.5 % / graphite 77.5 %**. 이것이 Amirkhosravi 0.775/0.225의 **확정 출처** 입니다. 이제 Fig 4의 반경 분포를 읽습니다:

실행됨 명령 1개, 읽기 6e13f57e-ORNLTM0378.pdf

p.19가 결정적입니다: **z=0은 하부 흑연바 배열 바닥**, 주노심 상단이 **64.59 in** — 즉 주노심은 **N+M+J** 이지 J만이 아닙니다. 그리고 **7 in from centerline이 축방향 최대 위치**. 전체 사슬을 재계산합니다:

Full power chain and reverse diagnostic

2.33배를 단일 인자별로 분해합니다 (§10 — calibration 아닌 원인 분리):

Decompose the 2.33x discrepancy

원문 p.19가 결정적입니다: *"The distortion of the flux at the center of the reactor also* ***precludes the use of a simple analytic expression to describe the radial distribution*** \*."\* — 반경 인자는 원문에 **수치로 존재하지 않습니다.** 코드를 갱신하고 기록합니다:

실행됨 명령 3개

**\[담당: Claude Code\]** — Phase 46B 완료. production 무수정, tuning 없음. 커밋·push 완료.

### A. P/Q — SOURCE\_TEXT\_CONFLICT

p.49는 `P` = **relative**, `Q` = **absolute** 인데 Eq(13)(16)(17)은 절대값이 필요하고, **둘 사이 변환식이 보고서 어디에도 없습니다.** 오타로 단정하지 않고 conflict로 기록했습니다. 다만 실무상 무해합니다 — relative 해석은 Eq(18)에 적용되고, Eq(13)–(17)은 p.40의 *"applying the appropriate specific powers"* 즉 절대값입니다.

### B·C. 사슬 복원 — 주노심 정의가 틀렸습니다

p.19 원문: *"The reference plane... is the bottom of the horizontal array of graphite bars... the top of the main portion of the core is at* ***64.59 in*** \*."\*

→ 주노심은 Table 3의 **N + M + J + L** 이지 J 단독이 아닙니다.

| regionr \[in\]z \[in\]fuel %V \[in³\]kw |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- |
| N stringers | 0–27.75 | 0–2.00 | 23.7 | 4,838 | 68 |
| M core | 2.94–27.75 | 2.00–5.50 | 22.5 | 8,372 | 192 |
| **J core** | 3.00–27.75 | 5.50–64.59 | **22.5** | 141,281 | **8,287** |
| L central | 0–2.94 | 2.00–64.59 | 25.6 | 1,700 | 159 |

```
V_fuel = 0.577707 m³   V_graphite = 1.981812 m³   Q_mainCore = 8,706 kw (87.06 %)
```

**Region J의 22.5/77.5가 Amirkhosravi 0.775/0.225의 확정 출처입니다.**

**축방향**: B(z)는 양단에서 0이 아니므로 peak/avg = **1.3585**, `π/2` 가 **아닙니다** (그건 p.35의 이상화 노심).  
**반경방향**: p.19 — *"the central flux distortion* ***precludes the use of a simple analytic expression*** *to describe the radial distribution."* → **원문에 반경 인자 수치가 없습니다.**

### G·H. 2.33배 분해 — 스케일 오차임을 증명

`2q_w/(P_f r_w) = 0.053697` 은 **스케일 불변** 이므로 두 항 모두 전력에 선형 → 순수 스케일 오차:

| 단일 수정인자ΔT \[K\] |  |  |
| --- | --- | --- |
| A 전력 J → N+M+J+L | 1.05056 | 85.158 |
| B 연료체적 → Table 3 | 0.79054 | 64.081 |
| C 축방향 π/2 → 1.3585 | 0.86485 | 70.104 |
| **D 반경 2.3163 → 1.3785** | **0.59513** | **48.241** |
| 넷 모두 | 0.42746 | 34.650 |

**지배 오차는 D** 입니다. 두 이상화 인자 모두 p.35의 균일 원통형 노심(경계에서 0, 주변부 없음)에 속하며 MSRE는 **둘 다 아닙니다.**

### I. Table 5 — 재현 아님

모델은 34.7221 K를 반환하지만 **반경 인자 1.3785가 목표에서 역산된 값** 이므로 **구성상 순환** 입니다. 코드에서 `radialPeakToAverage` 에 `NOT_SOURCED AS A NUMBER` 태그를 달고, 목표는 여전히 **보고만 하고 assert하지 않습니다.**

독립 확립된 것: 폐포식, 기하, 체적, 주노심 전력, 축방향 인자, `P_g/P_f`, `q_w`.  
없는 것: 보고서가 **수치로 싣지 않기로 한** 한 개의 상수.

### J. Case B 상태 — 강등

```
Phase 45: SPECIFIED
현재    : PARTIALLY_SPECIFIED
          - closure specified and verified
          - absolute power normalization UNRESOLVED (Fig. 4에 의존)
```

억지로 SPECIFIED 유지하지 않았습니다. `HISTORICAL_SOURCE_INCOMPLETE` 는 **과장** 이라 쓰지 않았습니다 — 보고서가 불완전한 게 아니라 반경 분포를 **그림으로** 제시한 것이고, Fig 4 digitization은 정당한 다음 단계입니다.

### K. Phase 47 — 형상은 정당, 절대수준은 아님

Eq(18)이 ΔT를 국소 전력에 비례시키므로 **프로파일 형상은 이미 완전히 결정** 되어 있고, 없는 것은 곱셈 상수 하나뿐입니다. 두 선택지:

1. **Fig. 4 digitization** — 마지막 `NOT_SOURCED` 를 판독오차 명시한 figure-derived 값으로 전환. Table 5가 **진짜 시험** 이 됩니다.
2. **형상 정규화 axial model** — `ΔT(z)/ΔT_max` 를 Fig. 14와 비교, 절대수준은 열어둠. 추가 자료 불필요.

관문 판정은 사용자 영역이므로 어느 쪽으로 갈지 지시를 기다립니다.

---

다음 단계는 **1번, Fig. 4 digitization 우선** 이 맞음.

이유는 단순함. 현재 Case B의 미해결 항목은 사실상 **반경 peak-to-average 하나** 뿐이고, 이 값이 절대 , , 따라서 Eq.(13)–(18)의 절대 를 결정. 반면 2번의 normalized axial model은 형상만 검증하므로, 지금 남은 핵심 blocker를 해결하지 못함.

현재 상태를 요약하면:

```
이미 닫힌 것
- historical closure Eq.13–18
- historical geometry
- main-core domain
- main-core power = 8.706 MW
- fuel / graphite volume
- axial B(z)
- axial peak/average = 1.3585
- q_w relation
- graphite 6% heating

남은 것
- radial power distribution scale
- radial peak-to-average
        ↓
- absolute local P_f,max / P_g,max
        ↓
- Table 5 ΔTmax 독립 재현
```

따라서 **Fig. 4를 digitize해서 마지막 scale factor를 figure-derived provenance로 바꾸는 것** 이 가장 강한 다음 단계.

중요한 점은 현재 역산된

를 “정답”으로 보고 Fig. 4를 맞추면 안 된다는 것.

반대로:

순서로 계산한 뒤 마지막에 Table 5의

와 비교해야 실제 validation이 됨.

### 다음 Claude Code 지시

```
[담당: Claude Code] — Phase 46C.
ORNL-TM-0378 Fig.4 radial power distribution digitization 및
Case B absolute normalization closure.

목적:
현재 PARTIALLY_SPECIFIED인 HISTORICAL_ORNL0378_CALCULATION의
마지막 미확정 입력인 radial power factor를
Fig.4에서 독립적으로 추출.

중요:
- Table 5의 62.5°F를 이용해 radial factor 역산 금지
- 기존 diagnostic value 1.3785를 digitization target으로 사용 금지
- production code 수정 금지
- Fig.4에서 읽은 값에는 반드시 FIGURE_DERIVED provenance 부여
- digitization uncertainty 명시

============================================================
1. Fig.4 정의 재확인
============================================================

원문 Fig.4 제목, 축, normalization, radial coordinate,
표시된 curve의 정확한 물리량 확인.

특히 다음 판정:

- relative fuel fission density인지
- total specific power인지
- maximum slow-flux plane인지
- peak-normalized인지
- centerline-normalized인지
- average-normalized인지

Fig.4의 y-axis normalization 정의를 원문에서 먼저 확정.

============================================================
2. Fig.4 digitization
============================================================

Fig.4를 이미지 기준으로 digitize.

가능하면 최소 15–20개 radial points.

저장:

r_in
r_m
relativePowerRaw

원본 figure 좌표의 판독오차를 추정.

예:
r uncertainty
power uncertainty

명시.

수치 추출은 이미지 판독으로 수행하고
Table 5 결과를 보면서 점을 조정하지 말 것.

============================================================
3. radial normalization
============================================================

Fig.4가 peak-normalized distribution이면
area/volume weighted average를 계산하여

f_r,peak/avg

유도.

axisymmetric main-core 기준:

< A(r) >
=
∫ A(r) 2πr dr / ∫ 2πr dr

단,
central region / annular region / heterogeneous volume fraction 때문에
원문의 region structure가 필요한 경우
Table 3 geometry를 사용.

단순 0–R 원통 적분을 먼저 가정하지 말 것.

Fig.4의 distribution domain과
Table 3의 N/M/J/L regions를 대응시킨 뒤 적분.

============================================================
4. r = 7 in 값 확인
============================================================

원문에서 hottest radial position이
r = 7 in으로 확인됐으므로

A(7 in)

을 digitized curve에서 직접 추출.

다음 둘을 구분:

A_peak
A(r=7 in)

둘이 같은지 확인.

같다고 사전 가정 금지.

============================================================
5. absolute power chain 복원
============================================================

독립 digitization 결과만 사용:

Q_reactor = 10 MW
        ↓
Q_mainCore = 8.706 MW
        ↓
V_fuel_mainCore
V_graphite_mainCore
        ↓
radial factor from Fig.4
axial factor B(z)
        ↓
P_f(r,z)
P_g(r,z)
        ↓
q_w
        ↓
Eq.13–18
        ↓
ΔT_g-f(r,z)

Phase 46B에서 사용한
NOT_SOURCED radialPeakToAverage = 1.3785
는 계산 경로에서 제거.

비교용 diagnostic으로만 남길 것.

============================================================
6. Table 5 독립 재현
============================================================

Fig.4-derived radial factor로
0% permeation case의 maximum local ΔT 계산.

목표값은 마지막에만 비교:

ORNL Table 5:
62.5°F = 34.7222 K

출력:

radialPeakToAverage_figure
axialPeakToAverage
P_f,max
P_g,max
q_w,max
ΔT_graphite
ΔT_fuel
ΔT_total
error_K
error_percent

여기서 PASS/FAIL 판정.

============================================================
7. uncertainty propagation
============================================================

Fig.4 digitization에는 판독오차 존재.

최소한:

radial factor lower
radial factor nominal
radial factor upper

로 ΔT 범위 계산.

예:

ΔT_min
ΔT_nominal
ΔT_max

ORNL 34.7222 K가 이 uncertainty band 안에 들어오는지 확인.

점 하나를 조정하여 target을 맞추는 행위 금지.

============================================================
8. provenance classification
============================================================

radial factor:

FIGURE_DERIVED
SOURCE: ORNL-TM-0378 Fig.4

로 분류.

PRIMARY_SOURCE_CONFIRMED numerical table 값으로 표현 금지.

Table 5와 일치하더라도
figure reading uncertainty 유지.

============================================================
9. Case B 판정
============================================================

Fig.4 digitization으로 absolute scale이 닫히면:

Case B =
SPECIFIED_WITH_FIGURE_DERIVED_RADIAL_NORMALIZATION

정도로 분류.

단순 SPECIFIED보다 provenance 특성 표시 권장.

Table 5를 독립적으로 재현하면:

HISTORICAL_CALCULATION_REPRODUCED

별도 verification status 부여 가능.

============================================================
10. Phase 47 gate
============================================================

다음 조건 만족 후에만 axial absolute model 진행:

[ ] Fig.4 independent digitization
[ ] radial normalization provenance 확보
[ ] P_f/P_g absolute scale 확보
[ ] Table 5 independent comparison 수행
[ ] no circular calibration
[ ] uncertainty quantified

Table 5 결과가 불일치하면
axial absolute model로 넘어가지 말고 원인 분석.

============================================================
11. 최종 보고
============================================================

A. Fig.4 physical definition
B. digitized points
C. normalization method
D. radial peak/average
E. r=7 in factor
F. digitization uncertainty
G. absolute P_f/P_g
H. Table 5 reproduction
I. discrepancy
J. Case B final status
K. Phase 47 gate decision

보고 후 대기.
```

판정은 명확함:

그 다음 Table 5가 독립적으로 맞으면 historical Case B가 실제로 닫힘. 이후에야 absolute axial graphite temperature profile로 넘어가는 게 순서상 맞음.

---

읽기6e13f57e-ORNLTM0378.pdf

image

**Fig. 4 판독 완료.** y축이 **"FRACTION OF MAX. VALUE"** — peak-normalized임이 확정됐고, 곡선 정점이 **r ≈ 7 in** 으로 p.19의 "7 in from the vertical centerline"과 독립적으로 일치합니다. 먼저 반경 인자만 계산합니다:

Digitize Fig 4 and compute radial factor

**독립 판독 결과가 역산값과 일치하지 않습니다.** Fig.4에서 얻은 반경 인자는 **1.6859** 이고, Phase 46B의 역산값은 1.3785 — 22 % 차이입니다. Table 5를 계산합니다:

Computed Table 5 with figure-derived radial factor

**Table 5 재현 실패** — +22.30 %, 목표가 판독 불확실도 band **밖** 입니다. §10에 따라 axial로 넘어가지 않고 원인을 분석합니다. 가장 유력한 후보를 정량화합니다:

Tested whether the fuel radial domain explains the gap

반경 도메인은 배제됐습니다. 마지막 후보 — 원문이 **자체 channel 치수** 를 제시하는지 확인합니다 (제 `r_w` 는 repo의 현대 기하에서 유도한 값입니다):

Checked if TM-0378 states its own channel geometry

**`r_w`** \*\* 독립 확인됨\*\*: line 449가 region 2에 "total cross-sectional area of **1880 in²**, fuel fraction **0.224** " → 채널당 0.448 in² → `r_w` = 0.37763 in, 제 값과 **0.26 %** 차이. 원인에서 배제됩니다. 코드를 갱신하고 기록합니다:

실행됨 명령 2개

**\[담당: Claude Code\]** — Phase 46C 완료. production 무수정. **역산값을 판독 목표로 쓰지 않았고**, 온도 계산 전에 그림만 먼저 읽었습니다.

### A. Fig.4 정의

y축 **"FRACTION OF MAX. VALUE"** → **peak-normalized** 확정. 평면은 p.19의 *"contains the maximum value of the flux, 35 in. above the bottom of the main part of the core"*. Slow Flux와 Fuel Fission Density 두 곡선은 거의 일치.

### B–E. 판독 및 반경 인자

30점 판독. 주요 특징: `A(0)=0.912`, **r≈2.9에서 0.885로 함몰** (p.19의 제어봉 thimble 왜곡), **`A(7)=1.000`** \*\* 정점\*\*, `A(27.75)=0.135`.

가중은 단순 0–R 원통이 **아니라** Table 3 지역 구조를 사용했습니다:

```
<A> = ∫A(r)w(r)dr / ∫w(r)dr,  w(r)=2πr·Σ_regions(Δz × fuel fraction)
```

`<A> = 0.593144   →   radialPeakToAverage = 1.6859   [FIGURE_DERIVED]`

**`A_peak` \*\*\*\*과 \*\*\*\* `A(7 in)` \*\*\*\*은 같은 점** 임을 그림에서 확인(가정 아님). 판독 정점이 7 in에 떨어진 것은 p.19와 Fig.14의 "7 in from centerline"을 **독립 재현** 한 것으로, 판독의 실질적 교차검증입니다.

### F. 판독 불확실도

±0.02(눈금 반 칸) 섭동 → **1.634 ~ 1.745**.

### G–H. Table 5 — NOT REPRODUCED

```
P_f,max = 32.4437 MW/m³   P_g,max = 0.60367 MW/m³   q_w = 8333.3 W/m²
```

`ΔT_g = 2.4840 K   ΔT_f = 39.9810 K   ΔT_total = 42.4650 K`

`ORNL Table 5     = 34.7222 K`

`오차 = +7.7427 K (+22.30 %)`

`판독 band 41.148 ~ 43.949 K  →  목표는 band 밖`

Phase 46B의 일치는 (그때 명시한 대로) 순환이었고, **독립 판독은 22 % 초과** 합니다.

### I. 원인 분석 — 3개 후보 배제

1. **반경 도메인**: 배제. 좁힐수록 `<A>` 는 오르지만 `V_fuel` 이 더 줄어 **반대 방향** 으로 악화(27.75→+22.3 %, 24.76→+33.1 %).
2. **`r_w`**: 원문 자체 수치로 확인 — p.14 "940 channels, total cross-sectional area **1880 in²**, fuel fraction **0.224** " → 채널당 0.448 in² → `r_w` =0.37763 in, 사용값과 **0.26 %**. 배제이며 동시에 p.38의 등가유동면적 해석을 **독립 확증**.
3. **0.94 분할**: 약 **1 %**. 배제.

**원문 내부 17 % 불일치 발견**: Table 2(수력, 940ch, r\_eq 24.76)와 Table 3(중성자, r 3.00–27.75, 22.5 %)이 주노심 연료체적을 0.443471 vs 0.520916 m³로 다르게 줍니다. **두 표는 같은 노심의 서로 다른 이산화이며 호환되지 않습니다.**

**남은 22 %는 미설명** 입니다. `P_f,max` 가 32.44가 아니라 26.53 MW/m³여야 하는데, 추적한 어떤 입력도 그 값을 주지 않습니다.

### J. Case B — 의도적으로 승격 안 함

```
PARTIALLY_SPECIFIED
```

`  closure ......................... specified and verified`

`  absolute normalization .......... FIGURE_DERIVED but NOT VALIDATED`

`SPECIFIED_WITH_FIGURE_DERIVED_RADIAL_NORMALIZATION` 은 정규화가 작동한다는 주장이 되는데 **22 % 빗나갑니다.** `HISTORICAL_CALCULATION_REPRODUCED` 도 **부여하지 않았습니다.**

코드는 1.6859를 `FIGURE_DERIVED` 로 쓰고, 1.3785는 `radialPeakToAverage_reverseDerived` 로 **사슬에서 제거한 채 DIAGNOSTIC으로만** 남겨 격차가 보이게 했습니다.

### K. Phase 47 게이트 — NO-GO

지시사항 §10대로, 불일치 시 axial로 넘어가지 않고 원인 분석에 머물렀습니다. 지금 절대 axial 모델을 만들면 **22 % 수준 오차가 전 노드로 전파** 됩니다.

남은 조사 순서: ① Eq(13)의 `P_f` 가 연료 핵분열 밀도가 맞는지 ② 보고서의 `ΔT_m` 이 `A(r)B(z)` 곱의 최댓값인지 다른 정의인지 ③ `Q_mainCore` 를 Table 4(중성자)가 아니라 Table 2(수력) 기준으로 구성해야 하는지.

한편 **형상 정규화 axial 모델** 은 이 중 무엇도 필요 없습니다 — Eq(18)이 ΔT를 국소 전력에 비례시키므로 `ΔT(z)/ΔT_max` 는 이미 완전히 결정되어 Fig.14와 비교 가능합니다.

관문 판정은 사용자 영역이므로 대기합니

---

현재 판정은 명확함. **Phase 47 절대 axial 모델은 계속 NO-GO**, 다음 단계는 **Phase 46D — 22.3% 불일치의 정의/정규화 원인 추적** 이 우선임.

형상 정규화 axial model은 별도 보조 검증으로는 가능하지만, 지금 바로 진행하면 핵심 blocker를 우회하는 셈. 먼저 아래 3개를 원문 기준으로 닫는 편이 맞음.

```
① Eq.(13)의 P_f가 정확히 어떤 power density인지
② Table 5의 ΔT_m이 어떤 위치·정의의 maximum인지
③ thermal calculation의 power normalization이 Table 2/3/4 중 무엇을 사용하는지
```

특히 현재 22.3% 차이는 단순 digitization 오차가 아니라 **모델 정의 불일치 가능성** 이 큼.

아래 프롬프트 권장.

```
[담당: Claude Code] — Phase 46D.
ORNL-TM-0378 Table 5의 ΔT_m 정의와 Eq.(13)-(18) power normalization 사슬 재추적.

목적:
Phase 46C에서 Fig.4 독립 digitization을 사용했을 때

ΔT_calc = 42.4650 K
ΔT_Table5 = 34.7222 K

로 +22.30% 불일치한 원인을
원문 정의/계산 사슬 수준에서 규명.

이번 단계에서:
- production 수정 금지
- radial factor tuning 금지
- Table 5 목표로 입력 역산 금지
- normalized axial model 구현도 보류
- 먼저 historical calculation definition을 끝까지 추적

============================================================
0. 현재 확정 상태
============================================================

확정:

Fig.4:
- y = FRACTION OF MAX. VALUE
- peak-normalized
- peak at r≈7 in
- figure-derived radial peak/average = 1.6859
- uncertainty band 1.634–1.745

axial:
- B(z)=sin[(pi/77.7)(z+4.36)]
- peak/average = 1.3585

main-core:
- Q = 8.706 MW
- Table 3 N+M+J+L
- fuel / graphite volumes 계산 완료

thermal closure:
- Eq.13
- Eq.14–16
- Eq.17/18
- q_w relation
- historical k_f, k_g
모두 확보.

현재 결과:

P_f,max = 32.4437 MW/m3
P_g,max = 0.60367 MW/m3
ΔT_g = 2.4840 K
ΔT_f = 39.9810 K
ΔT_total = 42.4650 K

Table 5:
34.7222 K

22.30% 초과.

============================================================
1. Eq.(13)의 P_f 정의를 끝까지 추적
============================================================

가장 우선.

nomenclature만 보지 말고
Eq.(13) 유도 직전/직후와 Appendix까지 추적.

질문:

P_f는 정확히

A. fuel fission power density
B. total deposited heat in fuel
C. equivalent specific power
D. local reactor specific power
E. fuel-volume-normalized local heat generation
F. 다른 보정이 포함된 effective power density

중 무엇인가?

특히 다음을 분리:

fission energy generation
gamma/neutron deposition
fuel heating
graphite heating

Eq.(13)의 P_f가
"94% of reactor power deposited in fuel"와 직접 연결 가능한지 확인.

원문에서 직접 식 또는 문장 없으면
직접 연결 금지.

============================================================
2. Eq.(18)을 algebraic하게 재유도
============================================================

Eq.(13)
Eq.(16)
Eq.(17)
→ Eq.(18)

직접 symbolically 재유도.

목표:

Eq.(18)이 어떤 변수들을 제거했고
어떤 ratio를 이미 포함하는지 확인.

특히 확인:

- P_g/P_f가 이미 Eq.(18)에 흡수됐는가
- 6% graphite fraction이 이미 coefficient에 포함됐는가
- q_w substitution이 어떤 power definition을 가정하는가
- fuel/graphite volume ratio가 이미 들어가는가

만약 Phase 46C 계산에서
Eq.(18)에 이미 들어간 factor를 다시 적용했다면
double counting 가능성 평가.

============================================================
3. Table 5의 ΔT_m 정의 재검토
============================================================

Table 5 heading, footnote, preceding/following paragraph를
PDF 이미지로 직접 읽고 exact transcription.

ΔT_m의 m이 nomenclature상 "maximum in reactor"라는 사실만으로
바로

max[A(r)B(z)]

라고 해석하지 말 것.

확인할 것:

ΔT_m가

- maximum local Tg' - Tf'
- maximum at r=7 in
- maximum over main-core only
- maximum using nuclear mean temperatures
- maximum evaluated at a reference plane
- maximum of an analytic approximation
- maximum after transverse averaging

중 정확히 무엇인지.

Table 5 계산 위치의 r,z가 명시돼 있는지도 추적.

============================================================
4. Fig.4와 Table 5가 같은 power field를 쓰는지 확인
============================================================

핵심 질문:

Fig.4의 "Fuel Fission Density"

와

Eq.(13)의 P_f

가 같은 field인가?

같다고 가정하지 말 것.

Fig.4는 neutronic fission-density shape일 수 있고,
Eq.(13)은 thermal deposited-power density일 수 있음.

만약 gamma/neutron transport 때문에
local heat deposition shape가 fission shape와 다르면
radial factor 1.6859를 Eq.(13)에 직접 적용하면 안 됨.

원문에서 다음 용어 검색:

heat deposition
power density
fission density
specific power
equivalent specific power
gamma heating
neutron heating
thermal power distribution

각 용어의 연결관계 표 작성.

============================================================
5. Table 4의 8706 kW가 thermal source인지 neutronic source인지 판정
============================================================

현재 main-core 8.706 MW는
Table 4 region powers의 합.

그 값이:

- actual deposited thermal power
- fission power
- equivalent power
- normalized neutronic source

중 무엇인지 확인.

Table 4 제목과 footnote를 정확히 읽고
Eq.(13)-(18) thermal calculation에 직접 쓰였다는 근거가 있는지 찾을 것.

없으면:

Q_mainCore=8.706 MW

를 thermal normalization에 사용하는 현재 경로를
DERIVED_BUT_NOT_LINKED_TO_EQ13

으로 강등.

============================================================
6. Table 2 vs Table 3 geometry 문제 해소
============================================================

현재:

Table 2 hydraulic representation
vs
Table 3 nineteen-region neutronic representation

에서 fuel volume 약 17% 차이.

이 차이가 중요한 이유:
P_f = Q/V 형태에서 직접 절대 출력밀도에 영향.

원문에서 thermal calculation이 어느 geometry를 썼는지 추적.

질문:

- Eq.(13)의 equivalent circular channel은 Table 2 기반인가?
- P_f normalization volume은 Table 2 fuel volume인가?
- radial power distribution은 Table 3 기반인가?
- thermal model에서 neutronic power를 hydraulic channel model로 transfer할 때
  별도 mapping factor가 존재하는가?

이 mapping이 있으면
현재 22% 차이의 핵심 후보.

============================================================
7. 940 channels와 1140 channels 재검토
============================================================

main-core channel count 940
vs total equivalent passages 1140

를 단순 오류로 보지 말 것.

각 숫자의 domain 명확화:

940:
어떤 region?
실제 main-core thermal channels?

1140:
full-size equivalent passages?
peripheral passages 포함?
different hydraulic representation?

Eq.(13) thermal calculation에서 사용한 actual number가 무엇인지 원문 확인.

============================================================
8. local-to-average normalization chain 작성
============================================================

최종적으로 다음 사슬을 하나의 식으로 작성:

Q_reactor
→ Q_region
→ average power density
→ radial factor
→ axial factor
→ P_f(r,z)
→ P_g(r,z)
→ q_w
→ ΔT

각 arrow마다:

SOURCE
EQUATION
TABLE/FIGURE
UNIT
ASSUMPTION

표시.

근거 없는 arrow가 하나라도 있으면
그 위치가 현재 blocker.

============================================================
9. reverse diagnostic은 비교용만
============================================================

Table 5를 만족하려면 필요한

P_f,max ≈ 26.53 MW/m3

를 계속 diagnostic으로 유지.

새로 규명한 historical chain의 P_f,max와 비교:

P_f_historical / P_f_required

출력.

하지만 required value로 input 수정 금지.

============================================================
10. discrepancy factor 분석
============================================================

현재:

42.4650 / 34.7222
= 약 1.2230

즉 필요한 scale correction:

S_required ≈ 0.8177

원문에서 발견되는 conversion/mapping factor 중
약 0.818에 해당하는 것이 있는지 확인.

예:

- fuel deposition fraction
- thermal/fission conversion
- geometry mapping ratio
- volume mapping ratio
- region weighting
- channel mapping

단,
숫자가 비슷하다는 이유만으로 원인 확정 금지.

============================================================
11. 코드 변경 규칙
============================================================

Verification/ORNL0378에서
원문 정의가 잘못 구현된 것이 확인된 경우에만 수정.

단순히 Table 5에 맞추기 위한 수정 금지.

현재 FIGURE_DERIVED radial factor 1.6859는 유지.

reverse-derived 1.3785는 diagnostic only 유지.

============================================================
12. Phase 46D 완료 조건
============================================================

다음 중 하나로 종료.

A. RESOLVED

- Eq.13 P_f definition 확정
- thermal power normalization 사슬 완전 복원
- Table 5 독립 재현
- 22.3% 원인 설명

또는

B. SOURCE_MAPPING_UNRESOLVED

- closure는 확정
- neutronic→thermal power mapping이 원문에서 불충분
- Table 5 absolute reproduction 불가
- normalized shape verification만 가능

억지로 RESOLVED 판정 금지.

============================================================
13. Phase 47 gate
============================================================

절대 axial model:

RESOLVED일 때만 GO.

SOURCE_MAPPING_UNRESOLVED이면:

absolute axial = NO-GO

단,
normalized axial shape verification은
별도 Phase로 허용 가능.

이 경우 결과는 반드시:

SHAPE_ONLY_VERIFICATION

으로 명명하고
absolute graphite temperature validation으로 표현 금지.

============================================================
14. 최종 보고 형식
============================================================

A. Eq.13 P_f exact meaning
B. Eq.18 derivation
C. Table 5 ΔT_m exact definition
D. Fig.4 fission density vs thermal power relation
E. Table 4 power meaning
F. Table 2 ↔ Table 3 mapping
G. 940 vs 1140 domain
H. complete normalization chain
I. unexplained arrow, if any
J. 22.3% discrepancy root cause
K. Case B status
L. Phase 47 GO/NO-GO

보고 후 대기.
```

현재 특히 의심할 가치가 큰 부분은 **Fig.4의 “Fuel Fission Density”를 Eq.(13)의 thermal 와 동일하게 둔 것** 과 **Table 3 neutronic volume을 Table 2 thermal channel 식에 직접 결합한 것**. 둘 다 아직 동일 물리량/동일 discretization이라는 보장이 없음.

따라서 지금은 `1.6859가 틀렸다` 가 아니라 **1.6859는 Fig.4의 fission-density radial factor로는 독립적으로 유효하지만, 그것이 Eq.(13)의 thermal radial factor인지 미확정** 이라고 보는 게 가장 정확함.

[^1]: [ornl.gov](https://www.ornl.gov/news/msres-50th?utm_source=chatgpt.com)

[^2]: [info.ornl.gov](https://info.ornl.gov/sites/publications/Files/Pub133245.pdf?utm_source=chatgpt.com)

[^3]: [info.ornl.gov](https://info.ornl.gov/sites/publications/Files/Pub209949.pdf?utm_source=chatgpt.com)

[^4]: [info.ornl.gov](https://info.ornl.gov/sites/publications/Files/Pub197043.pdf?utm_source=chatgpt.com)