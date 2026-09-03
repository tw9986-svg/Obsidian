---
title: "‎Google Gemini"
source: "https://gemini.google.com/u/1/app/fb47e27b76715070?hl=ko&pageId=none"
author:
published:
created: 2026-09-03
description: "Google의 AI 어시스턴트인 Gemini를 만나 보세요. 글을 쓰고, 계획하고, 브레인스토밍하는 등 다양한 상황에서 도움을 받을 수 있습니다. 생성형 AI의 강력한 기능을 경험해 보세요."
tags:
  - "clippings"
---
## MSRE TRANSFORM Primary Loop 열수력 및 열전달 모델 고도화와 종합 검증 가이드라인

## 1\. 서론 및 연구 컨텍스트: Primary Loop 독립 검증의 당위성

용융염원자로(Molten Salt Reactor, MSR)의 실증 사례인 용융염원자로 실험장치(Molten Salt Reactor Experiment, MSRE)는 액체 핵연료염(Fuel-salt)이 노심 내부를 직접 순환하며 발열과 냉각을 동시에 수행하는 복합 물리 시스템이다. 이러한 계통을 Modelica/TRANSFORM 환경에서 고성능 시스템 모델로 구축하는 연구는 단순한 형상 재현이나 정상상태 온도 계산에 그쳐서는 안 되며, Primary Loop 내부의 열수력, 열전달, 지연중성자 선행핵(Delayed Neutron Precursor, DNP) 수송, 핵동역학 반응도 피드백, 그리고 순환 펌프 동역학 간의 정밀한 결합(Tight coupling) 현상을 검증 가능한 수준으로 구현하는 것을 목표로 한다.

전체 연구 프레임워크는 Stage I(Validated Primary MSRE Model)과 Stage II(Integrated MSRE System Framework)의 두 단계로 엄격히 구분하여 추진된다. 현재 집중적으로 수행 중인 Stage I은 드레인 탱크(Drain Tank) 등 비상 배출 계통을 결합하기 전에 노심(Core), 상·하부 플레넘(Upper/Lower Plenum), 1차측 배관(Primary Piping), 순환 펌프(Primary Pump), 그리고 1차 열교환기(Primary Heat Exchanger, PHX)로 구성된 Primary Loop 독립 모델의 열수력 및 열전달 정확성을 검증하는 단계이다. Primary Loop 내부에서 유체가 순환하는 수력학적 루프는 노심 하부 플레넘에서 출발하여 흑연 감속재 채널을 거쳐 노심 상부 플레넘으로 유출되며, 이후 1차측 배관을 지나 순환 펌프 입구로 들어간다. 펌프에서 가압된 유체는 1차 열교환기의 쉘측(Shell side)을 통과하며 열을 방출한 후, 다시 하부 플레넘으로 귀환하여 루프를 형성한다.

드레인 탱크 계통을 충분히 검증되지 않은 Primary Loop와 사전에 결합할 경우, 출력 오차 발생 시 그 원인이 노심 열전달, 흑연 전도, 펌프 동역학, PHX 열전달, DNP 감쇄, 2차 계통 경계 조건, 혹은 드레인 라인 및 탱크 내부 현상 중 어느 요소에서 기인했는지 오차의 원인을 분리 구명(Error Isolation)할 수 없게 된다. 따라서 하위 시스템 검증(Subsystem Validation)을 우선 수행하여 Primary Loop 자체의 불확실성을 먼저 확정한 후 Stage II 확장으로 진입해야 한다.

| 구분 | Stage I: Validated Primary Model | Stage II: Integrated MSRE Framework |
| --- | --- | --- |
| **시스템 범위** | Core, Plenums, Piping, Pump, Primary HX (Shell Side) | Primary Loop + Secondary Boundary + Drain System |
| **주요 목적** | Primary T-H, Kinetics, Pump Dynamics 오차 고정 | 계통 통합 과도상태 및 Draining 시나리오 해석 |
| **경계 조건** | PHX 2차측 등가 열적 경계 (Defined Boundary) | Secondary Loop 및 Radiator/Air Blower 완전 결합 |
| **검증 대상** | MSRE 운전 데이터 및 MARS-KS 선행 해석 결과 | 정전, 자연순환, 드레인 개시, 감쇄열 제거 |
| **오차 관리** | 계통 오차 원인 분리 (Error Isolation) 완료 | Subsystem 불확실성 전파 해석 (Uncertainty Propagation) |

## 2\. Core 2D 모델링 및 Graphite 열전달 고도화 지침

### 2.1 Graphite Volumetric Heating 및 원자료 Provenance 검증

MSRE 노심 내부 발열은 감속재 흑연(Graphite moderator)과 순환 연료염 사이에서 공간적으로 분배되어 발생한다. ORNL 원자료(ORNL-TM-0378, ORNL-4541)에 따르면, 전체 노심 열출력 $P_{\text{total}}$ 중 중성자 감속 및 감마선 흡수로 인해 흑연 감속재 내부 체적 발열(Volumetric heating)로 직접 침적되는 비율 $f_g$ 는 약 $7 \sim 8\%$ 수준으로 산정되며, 나머지 $92 \\sim 93%$의 에너지 $f_f$ 는 연료염 내부 핵분열 직후 즉시 발열된다.

$$
q_g'''(r, z) = f_g \cdot P_{\text{vol}}(r, z)
$$
 
$$
q_f'''(r, z) = (1 - f_g) \cdot P_{\text{vol}}(r, z)
$$

ORNL-TM-0378 보고서에 기록된 정격 출력(10 MWth) 및 정격 입·출력 온도 조건(입구 $1175^{\circ}\text{F} \approx 635.0^{\circ}\text{C}$, 출구 $1225^{\circ}\text{F} \approx 662.8^{\circ}\text{C}$)에서 체적 평균 온도(Bulk mean temperature)와 반응도 가중 평균 온도(Nuclear mean temperature)는 명확히 구별된다. 연료염의 Nuclear Mean 온도는 $1213^{\circ}\text{F} (656.1^{\circ}\text{C})$, Bulk Mean 온도는 $1198^{\\circ}\\text{F} (647.8^{\\circ}\\text{C})$이며, 흑연 감속재의 경우 침투 연료염이 없는 조건에서 Nuclear Mean 온도는 $1257^{\circ}\text{F} (680.6^{\circ}\text{C})$, Bulk Mean 온도는 $1226^{\\circ}\\text{F} (663.3^{\\circ}\\text{C})$이다. 2%의 연료염이 흑연 기공에 침투한 조건을 고려할 경우 흑연 Nuclear Mean 온도는 $1264^{\\circ}\\text{F}(684.4^{\\circ}\\text{C})$까지 상승한다.

Modelica/TRANSFORM 2D 노심 모델 검증 시 단순 체적 평균 온도만을 비교하는 것은 반응도 피드백 해석에 왜곡을 초래하므로, 국소 온도 분포 $T(r, z)$에 국소 중성자 수속 제곱($\Phi^2$) 기반의 가중치를 적용한 Nuclear Mean 계산 공식을 모델 내부에 구현하여 ORNL 원자료와 직접 비교해야 한다.

| 열적 평가 파라미터 | ORNL-TM-0378 원자료 기준값 | TRANSFORM 모델 구현 및 검증 파라미터 | 비고 및 검증 기준 |
| --- | --- | --- | --- |
| **정격 열출력 ($P_{\text{total}}$)** | $10.0\text{ MWth}$ | $10.0\text{ MWth}$ 입력 경계 조건 | 기준 정격 출력 |
| **노심 입구/출구 온도** | $635.0^{\circ}\text{C} / 662.8^{\circ}\text{C}$ | 노심 하부/상부 플레넘 경계 계산값 | 입출력 $\Delta T \approx 27.8^{\circ}\text{C}$ 달성 |
| **연료염 체적 발열 분율 ($f_f$)** | $92.0 \sim 93.0\%$ | Direct energy deposition in fuel nodes | 정격 출력 시 전하 축적 반영 |
| **흑연 체적 발열 분율 ($f_g$)** | $7.0 \sim 8.0\%$ | Gamma/Neutron heating rate in graphite | 공간 nodalization별 체적 가중 적용 |
| **연료염 Nuclear Mean Temp.** | $1213^{\circ}\text{F}\ (656.1^{\circ}\text{C})$ | $\int T_f \Phi^2 dV / \int \Phi^2 dV$ 계산식 노드 | 공간 가중치 적용 평가 |
| **연료염 Bulk Mean Temp.** | $1198^{\circ}\text{F}\ (647.8^{\circ}\text{C})$ | $\int \rho_f T_f dV / \int \rho_f dV$ 체적 평균 | 질량/밀도 평가용 |
| **흑연 Nuclear Mean Temp.** | $1257^{\circ}\text{F}\ (680.6^{\circ}\text{C})$ | $\int T_g \Phi^2 dV / \int \Phi^2 dV$ 계산식 노드 | 반응도 피드백 결합용 |
| **흑연 Bulk Mean Temp.** | $1226^{\circ}\text{F}\ (663.3^{\circ}\text{C})$ | $\int \rho_g T_g dV / \int \rho_g dV$ 체적 평균 | 흑연 열팽창 및 구조 평가 |

### 2.2 Radial Power Distribution: 15-Ring Graded Mesh 할당 및 Discretization Error Analysis

1D 균일 노심 모델은 반경 방향 열전도 및 흑연 온도 경사를 평형화(Averaging)하는 과정에서 주요 열물리 특성을 손실시킨다. 이를 극복하기 위해 연속적인 ORNL 반경 방향 출력 분포 프로파일을 15개의 반경 방향 링(Ring)으로 이산화한 Graded Mesh 체계를 구성한다. 반경 방향 출력 매핑 과정에서는 연속적인 ORNL 프로파일 원자료를 각 링의 면적 가중 평균(Area-weighted averaging) 기법을 통해 15-ring 소스 분포로 변환한 후, 이를 TRANSFORM Core2D 노드의 링별 체적 발열 항목($q_{g,k}'''$)에 할당하는 절차를 거친다.

반경 방향 출력 분배 시 발생하는 오차는 Nodalization Error와 Source-model Approximation Error로 구분된다. 연속적인 ORNL 원자료 프로파일을 Ring Averaging하여 15-ring에 할당할 때 발생하는 Nodalization Error는 약 $0.0354$ 수준으로 적은 반면, 단평면 J0 Bessel 함수 등으로 간소화할 때 발생하는 Source-model Error는 약 $0.1155$ 수준으로 증가하여 전체 오차 $0.1208$ 의 대부분을 차지한다. 전체 오차 체계에서 격자 이산화 오차보다 소스 모델 이산화 오차가 약 3.26배 우세하므로, 격자 밀도를 늘리는 것보다 연속 ORNL 출처 데이터를 에너지 보존(Energy Conservation) 조건으로 정밀 매핑하는 것이 검증 정확도 확보에 필수적이다.

$$
\bar{q}'''_{g,k} = \frac{1}{A_k} \int_{r_{k-1}}^{r_k} q_g'''(r) \cdot 2\pi r \, dr, \quad k = 1, 2, \dots, 15
$$
 
$$
A_k = \pi (r_k^2 - r_{k-1}^2)
$$

### 2.3 2D Graphite Radial Conduction 및 Direct Solution (\\lambda=1) 검증 지침

흑연 블록 내부의 2차원 열전도 및 대류 열전달을 기술하는 지배 방정식은 다음과 같다:

$$
\rho_g c_{p,g}(T_g) \frac{\partial T_g(r,z,t)}{\partial t} = \nabla \cdot \left( k_g(T_g) \nabla T_g(r,z,t) \right) + q_g'''(r,z) - h_v (T_g(r,z,t) - T_f(r,z,t))
$$

정상상태 조건에서는 시간 미분 항이 0이 되며, 비선형 열물성치 $k_g(T_g)$, $c\_{p,g}(T\_g)$의 결합으로 인해 수치 해석적 수렴성 문제가 발생할 수 있다.

$$
0 = \frac{1}{r} \frac{\partial}{\partial r} \left( r k_g(T_g) \frac{\partial T_g}{\partial r} \right) + \frac{\partial}{\partial z} \left( k_g(T_g) \frac{\partial T_g}{\partial z} \right) + q_g'''(r,z) - h_v (T_g(r,z) - T_f(r,z))
$$

초기 파인 메시(Fine mesh) 모델에서 비선형 수렴 실패를 극복하기 위해 연속 매개변수(Continuation parameter) $\\lambda \\in \[0, 1\]$를 유도하여 수치적 안정성을 확보하였으며, 14-ring graded mesh 구조에서 $\lambda=1$ Direct Solution에 성공하였다. 수치적 수렴을 달성한 이후에는 계산된 온도장이 실제 열물리 현상과 일치하는지 판정하는 검증 단계를 수행해야 한다.

수렴된 $\lambda=1$ 2D 흑연 온도장 결과에 대해서는 다음 세 가지 물리성 검증 Gate 항목을 확인해야 한다:

1. **최고 온도 위치 확인**: 최고 열출력이 발생하는 노심 중심축 부근($r \approx 0$, $z/L \approx 0.6 \sim 0.7$)에서 흑연 최고 온도 $T\_{g,\\max}$가 형성되는지 검증한다.
2. **반경 방향 흑연-연료염 국소 온도차 ($\Delta T_{g-f}(r)$)**: 발열 밀도가 높은 중심 링에서 $\\Delta T\_{g-f}$가 최대가 되고, 외곽 링으로 갈수록 유량 분배 효과와 결합되어 경사가 감소하는 경향을 확인한다.
3. **ORNL 실험 및 해석 데이터와의 오차 정량화**: ORNL-TM-0378에 제시된 최고 흑연 온도 및 반경 온도 분포 데이터와의 오차가 $\pm 3.0\text{ K}$ 범위 이내에 위치하는지 검증하고, 이를 벗어날 경우 열전달 계수 $h_v$ provenance를 재검토한다.

## 3\. Core Fuel-Salt 열전달 상관식 고도화 및 층류 유동 해석

### 3.1 MSRE Core Laminar Flow (Re \\approx 812) 및 High-Pr Molten Salt 특성

MSRE 노심 내부 연료 채널(Fuel channel)을 흐르는 용융염 유동의 정격 레이놀즈 수(Reynolds number)는 $Re \approx 812$ 수준으로, 전형적인 층류 유동 영역(Laminar flow regime, $Re < 2300$)에 속한다. 경수로 해석에서 흔히 사용되는 Gnielinski 또는 Dittus-Boelter 열전달 상관식은 난류 영역($Re > 4000$)에 맞춰 고안된 것이므로, 층류 영역인 MSRE 노심 내부에 직접 적용할 경우 열전달 계수를 과대평가하는 오차를 유발하게 된다.

또한 MSRE 연료염($\text{LiF-BeF}_2\text{-ZrF}_4\text{-UF}_4$)은 높은 프란틀 수(Prandtl number, $Pr \approx 8 \sim 12$)를 가진다. 난류 유동에서는 속도 경계층과 열 경계층이 거의 동시에 발달하지만, High- $Pr$ 층류 유동 조건에서는 속도 경계층에 비해 열 경계층의 발달 속도가 현저히 느리다. 따라서 노심 유입구로부터 상당한 구간 동안 열적 유입구 영역(Thermally developing region)이 형성되므로 Nusselt 수가 관 방향 거리 $x$ 에 따라 변화하는 현상을 반영해야 한다.

| 영역 및 유동 조건 | 대표 Reynolds 수 ($Re$) | 적용 불가 상관식 | 권장 적용 열전달 상관식 모델 | 물리적 이유 및 보정 요인 |
| --- | --- | --- | --- | --- |
| **Core Fuel Channel** | $Re \approx 812$ (층류) | Dittus-Boelter, Gnielinski | Graetz ($Gz$) 기반 열적 유입구 상관식 | High- $Pr$ 유체의 열 경계층 미발달 효과 반영 |
| **Obround Geometry** | Obround (변형 직사각형) | Circular Pipe $Nu=3.66 / 4.36$  \[cite: 6, 11\] | Hartnett-Kostic 형상 보정 열전달 식 | 가로세로비(Aspect ratio)에 따른 마찰 및 $Nu$ 변화 |
| **Volumetric Heating** | $q_f''' > 0$ (체적 발열) | 벽면 고정 열속 ($q_w''=\text{const}$) | 체적 발열 조건 보정 $Nu_{q}$ 상관식 | 유체 내부 발열로 인한 온도 경사 평탄화 |
| **PHX Shell-Side** | $Re \approx 1500 \sim 4000$ (천이) | 단순 Pipe 흐름 상관식 | Bell-Delaware 기법 $h_{\text{shell}}$  \[cite: 16, 17\] | Baffle 유동, Leakage/Bypass 누설류 영향 고려 |

### 3.2 Non-circular Obround Channel 및 Thermally Developing Flow 상관식 적용

MSRE 연료 채널은 단면이 원형이 아니라 흑연 가공에 적합하도록 장방형/아치형 구조(Obround cross-section)로 설계되어 있다. Obround 형상에서의 등가 수력 직경 $D_h$ 및 열적 유입구 열전달 계수를 산출하기 위해 Graetz 수($Gz$) 기반의 상관식을 유도하여 적용해야 한다.

$$
D_h = \frac{4 A_c}{P_w}
$$
 
$$
Gz = Re \cdot Pr \cdot \frac{D_h}{x}
$$

열적으로 발달 중인 층류 유동 조건에서의 Nusselt 수 상관식은 무차원 위치 $x^\* = \\frac{x/D\_h}{Re \\cdot Pr} = Gz^{-1}$의 함수로 표현된다. Obround 채널의 가로세로비(Aspect ratio $\gamma = w/t$)에 따른 완전 발달 $Nu\_{\\infty}$의 차이를 보정하기 위해 Hartnett-Kostic 형상 보정 계수를 도입한다.

$$
Nu(x) = Nu_{\infty} + \frac{C_1 \cdot Gz^{C_2}}{1 + C_3 \cdot Gz^{C_4}}
$$
 
$$
h(x) = \frac{Nu(x) \cdot k_f}{D_h}
$$

연료염 자체 체적 발열($q_f'''$)이 존재하는 조건에서는 벽면 열전달 경계조건이 일반 관유동과 상이해진다. 유체 내부에서 열이 생성되면 벽면 부근의 온도 경사가 감소하여 실효 $Nu$ 수가 수평 이동하므로, 단순 벽면 등열속 경계조건 상관식 대비 보정 계수를 산출하여 TRANSFORM 모델 내 `FuelChannel1D/2D` 의 Convective Heat Transfer 매개변수에 주입해야 한다.

## 4\. Primary Heat Exchanger (PHX) 열전달 및 수력 해석 모델링 가이드라인

### 4.1 PHX Geometry 및 Operating Parameters (Shell-side vs Tube-side)

MSRE Primary Heat Exchanger(PHX)는 1차측 연료염의 열을 2차측 냉각염(Coolant salt: $\text{LiF-BeF}_2$)으로 전달하는 U-tube Shell-and-Tube 열교환기이다. PHX의 Shell 측으로는 펌프를 통과한 고온의 연료염 유체가 유입되어 배플을 거치며 열을 방출한 후 노심 입구로 향하며, Tube 측으로는 2차측 쿨런트 염이 순환하며 열을 수송한다. 수력학적 및 열적 설계 정확도를 확보하기 위해 구조적 치수와 플러깅(Plugging) 이력을 모델에 반영해야 한다.

PHX 제작 초기에는 총 326개의 U-tube가 설치되었으나, 제작 및 초기 유량 시험 과정에서 쉘측(Shell side) 압력강하가 기준치를 초과함에 따라 외곽 U-tube 4개를 절단하고 8개 튜브 스텁을 밀봉 플러깅하였다. 따라서 실제 운전에 투입된 유효 열전달 튜브 개수는 318개이다. 이 플러깅 이력을 생략하고 326개 튜브로 모델링할 경우 열전달 면적 $A$ 가 과대 계산되어 $UA$ 값 오차를 유발한다.

| 주요 매개변수 | 명세 및 정량적 수치 | TRANSFORM 모델 반영 방식 및 주의사항 |
| --- | --- | --- |
| **형식 (Type)** | Shell-and-Tube, Cross-Baffled U-tube | Shell-side (Fuel Salt) / Tube-side (Coolant Salt) |
| **구조 재질** | Hastelloy-N (INOR-8) | 온도 가변 열전도율 $k_{\text{mat}}(T)$ 반영 |
| **원형 튜브 개수** | 총 326개 U-tubes | 플러깅 전 설계 치수 |
| **실제 유효 튜브 개수** | **318개** (4개 U-tube / 8개 stub 플러깅 완료) | **열전달 면적 계산 시 반드시 $N_t = 318$ 적용**  \[cite: 19\] |
| **튜브 외경 / 벽두께** | 外徑 $0.50\text{ in } (12.7\text{ mm})$ / 두께 $0.042\text{ in } (1.07\text{ mm})$ | Shell 및 Tube 측 수력직경 $D_h$ 산출 파라미터 |
| **Shell 내경 / 길이** | 내경 $0.41\text{ m}$ / 총 유효 길이 약 $2.5\text{ m}$ | Shell 측 유체 체적 및 재고량(Inventory) 검증용 |
| **Shell 측 유체** | Fuel Salt ($\text{LiF-BeF}_2\text{-ZrF}_4\text{-UF}_4$) | 밀도, 점성계수, 열전도율 온도 함수 결합 |
| **Tube 측 유체** | Coolant Salt ($\text{LiF-BeF}_2$, 66-34 mol%) | 2차측 등가 열적 경계 온도/유량 주입 |

### 4.2 PHX Shell-side 열전달 상관식 선정: Kern vs Bell-Delaware 평가

PHX Shell 측은 횡단 배플(Cross-baffles)이 설치되어 있어 연료염의 굴절 복합 유동이 발생한다. Shell 측 유동은 튜브 다발을 횡단하는 메인 유동(Stream B) 외에도 튜브-배플 간극 누설류(Stream A), 튜브 다발-쉘 바이패스류(Stream C), 배플-쉘 간극 누설류(Stream E) 등 복잡한 누설 및 바이패스 스트림으로 분할된다.

Shell 측 열전달 계수 $h_{\text{shell}}$ 및 압력강하 $\\Delta P\_{\\text{shell}}$를 평가하기 위해 간소화 기법인 Kern Method와 정밀 기법인 Bell-Delaware Method를 비교 평가해야 한다. Kern Method는 배플 윈도우 영역과 튜브 다발 영역의 유동을 단순화하여 열전달 계수를 과대평가하는 경향이 있는 반면, Bell-Delaware Method는 다음과 같이 유동 누설 및 바이패스 스트림에 대한 보정 계수($J$)를 도입한다:

$$
h_{\text{shell}} = h_{\text{ideal}} \cdot J_c \cdot J_l \cdot J_b \cdot J_s \cdot J_r
$$

이 식에서 $h\_{\\text{ideal}}$은 이상적인 교차 유동 조건에서의 Nusselt 수 기반 열전달 계수이며, $J_c$ 는 배플 컷(Baffle cut) 크기 및 윈도우 영역 유류 보정 계수, $J_l$ 은 튜브-배플 및 배플-쉘 간극 누설류 보정 계수, $J_b$ 는 튜브 다발-쉘 내벽 사이 바이패스 보정 계수, $J_s$ 는 배플 간격 보정 계수이다.

총괄 열전달 계수 $U$ 와 열전달 면적 $A$ 의 곱인 $UA$ 산출식은 다음과 같이 관벽 금속 전도 저항 및 열汚れ 저항(Fouling factor)을 포함하여 결합된다:

$$
\frac{1}{UA} = \frac{1}{h_{\text{shell}} A_{\text{shell}}} + \frac{\ln(r_o/r_i)}{2 \pi k_{\text{wall}} L N_t} + \frac{1}{h_{\text{tube}} A_{\text{tube}}} + R_{\text{fouling}}
$$

Bell-Delaware 기법을 적용하여 관측된 PHX 정격 10 MWth 조건에서의 계산 $UA$ 값과 입출력 온도를 MSRE 실제 운전 데이터와 비교 시 오차율이 $3.5\%$ 이내로 수렴하는지 확인해야 한다. Baffle Cut($25\%$) 및 Baffle Spacing 변경 시 압력강하 $\Delta P$ 가 급격히 변화하는 현상이 관찰되므로, 압력강하 수력 밸런스와 열전달 $UA$ 를 동시 만족하는 매개변수 집합을 확정해야 한다.

## 5\. Primary Hydraulics, Pump Rotor Dynamics 및 Transient Benchmarking

### 5.1 System Resistance Balance 및 Flow Rate (\\dot{m}) 자율 계산

TRANSFORM 모델의 Primary Hydraulics 수력 해석은 유량 $\\dot{m}$을 사용자가 외부에서 강제 주입하는 방식(Driven flow)이 아니라, 순환 펌프가 생성하는 Head와 Primary Loop 전체 배관, 노심 채널, PHX Shell 측의 유체 저항(System Resistance) 간의 동적 밸런스에 의해 자율적으로 산출되는 물리 모델(Physics-based momentum balance)로 구현되어야 한다.

순환 펌프의 모터 구동 명령에 의해 모터 토크 $\\tau\_{\\text{motor}}$가 발생하면, 이는 로터 회전 동역학 방정식에 따라 펌프 회전수 $\omega(t)$ 및 $N(t)$를 변화시킨다. 회전하는 펌프 임펠러는 펌프 양정(Pump Head)을 형성하며, 이 양정이 Primary Loop 전체의 압력강하 밸런스 방정식과 연동되어 정격 질량 유량 $\\dot{m}(t)$를 동적으로 결정한다.

$$
\sum \Delta P_{\text{loop}}(\dot{m}) = \Delta P_{\text{core}}(\dot{m}) + \Delta P_{\text{PHX}}(\dot{m}) + \Delta P_{\text{piping}}(\dot{m}) + \Delta P_{\text{plenums}}(\dot{m})
$$
 
$$
\Delta P_{\text{pump}}(\omega, \dot{m}) = \sum \Delta P_{\text{loop}}(\dot{m})
$$

정상 상태에서 펌프 회전수 $N_0$ 에 대응하는 총 압력강하와 펌프 양정이 일치하여 정격 질량 유량 $\\dot{m}\_0 \\approx 1200\\text{ gpm} \\approx 131.7\\text{ kg/s}$이 형성되도록 식을 구성한다.

### 5.2 Pump Coastdown Transient Discrepancy 원인 규명

현재 TRANSFORM 모델과 기존 MARS-KS 해석 결과 및 MSRE Coastdown 실험 데이터 간에 유의미한 차이가 발생하는 구간은 펌프 정지 과도상태(Pump trip coastdown transient)이다. 대표적으로 펌프 트립 후 $t = 10\text{ s}$ 시점에서 유량 감소 비율을 비교하면, TRANSFORM 기존 모델은 정격 유량의 약 $27.5%$를 유지하는 반면 MARS-KS 선행 해석 결과는 약 $6.57%$를 나타내어 초기 $0 \sim 20\text{ s}$ 구간에서 약 $15\%$ - point 수준의 RMSE 오차가 발생한다.

이러한 Discrepancy의 원인을 분리 규명하기 위해 펌프 로터 회전 동역학 방정식을 세부 요소별로 분석해야 한다:

$$
J \frac{d\omega(t)}{dt} = \tau_{\text{motor}}(t) - \tau_{\text{hyd}}(\omega, \dot{m}) - \tau_{\text{friction}}(\omega)
$$
- **관성모멘트 ($J$, Rotor Inertia) 평가**: 펌프 임펠러, 샤프트 및 구동 모터의 합성 회전 관성모멘트 $J$ 의 Provenance를 재검증한다. $J$ 가 과대 설정되었을 경우 Coastdown 초기에 유량 감쇠가 지나치게 느리게 진행된다.
- **유체 역학적 토크 ($\tau_{\text{hyd}}$, Fluid Dynamic Torque)**: 회전수 $\omega$ 및 펌프 통과 유량 $\\dot{m}$의 변화에 따른 토크 특성 곡선(Four-quadrant homologous curves)이 용융염 고밀도 유체 조건에 적합하게 매핑되었는지 점검한다.
- **기계적 마찰 토크 ($\tau_{\text{friction}}$, Mechanical Friction)**: 베어링 및 씰 부위의 쿨롱 마찰 및 점성 마찰 토크 항이 Low-flow regime에서 올바르게 작용하는지 확인한다.
- **Primary Loop 전체 수력 관성 ($I_{\text{hydro}} = \sum \frac{L_i}{A_i}$)**: 유체 관성 항이 과대 반영될 경우 펌프 헤드 감소에도 불구하고 유체가 지속해서 관성으로 밀려나가는 현상이 발생하므로 노심/배관/PHX의 $L/A$ 이산화 노드 수치 체계를 조정해야 한다.

## 6\. Stage I 모델 완성을 위한 Gate Criteria 및 Stage II 확장 로드맵

### 6.1 Stage I 최종 Gate Criteria (검증 허용 오차 범위 및 Metric)

Stage II(Integrated System Framework)로 진입하기 전, Primary Loop 독립 모델이 통과해야 하는 종합 Gate Criteria 및 검증 수치 기준을 아래 표와 같이 제시한다.

| 분야 (Domain) | 검증 항목 (Validation Item) | 비교 대상 기준 (Reference) | 허용 오차 범위 (Acceptable Metric) | 비고 |
| --- | --- | --- | --- | --- |
| **Geometry / Inventory** | Primary Loop Total Fuel Volume | ORNL-TM-0732 설계치 | $\pm 1.0\%$ 이내 | 재고량 및 DNP Transit time 직결 |
| **Hydraulics** | Rated Flow Rate ($\dot{m}_0$) | MSRE Exp Operating Data | $\pm 2.0\%$ 이내 ($1200 \pm 24\text{ gpm}$) | System Resistance balance 조건 |
| **Hydraulics** | Coastdown Flow Rate ($t=10\text{ s}$) | MSRE Exp Data / MARS-KS | $\pm 3.0\%$ -point 이내 | Discrepancy 개선 원인 규명 필수 |
| **Thermal** | Core Inlet / Outlet $\Delta T$ | MSRE 10 MWth 운전 데이터 | $\pm 0.5^{\circ}\text{C}$ 이내 | 입구 $635^{\circ}\text{C}$, 출구 $662.8^{\circ}\text{C}$ 기준 |
| **Thermal** | Graphite Max Local Temp ($T_{g,\max}$) | ORNL-TM-0378 2D 결과 | $\pm 3.0\text{ K}$ 이내 | 2D Graphite Direct Solution ($\lambda=1$) |
| **Thermal** | PHX Total Heat Duty ($UA$) | ORNL PHX Test Data | $\pm 3.5\%$ 이내 | Bell-Delaware 보정계수 적용 |
| **Kinetics** | Circulation Reactivity Loss ($\Delta \rho_{\text{circ}}$) | ORNL-4541 / Benchmark | $\pm 15\text{ pcm}$ 이내 | DNP Full-loop transport 유동 결합 |

### 6.2 Provenance Data Pipeline 관리 원칙

모든 모델 입력 매개변수 및 물성치는 추적 가능성(Traceability) 확보를 위해 **SOURCE / DRIVEN / ASSUMPTION / OPEN** 의 4단계 데이터 파이프라인으로 분류하여 관리한다.

RAW Provenance Database(ORNL 보고서, 논문, 실험 CSV 데이터 등)에서 도출된 기초 물성 및 기하학적 치수는 **SOURCE** 단계로 직접 등록된다. 이 SOURCE 데이터로부터 체적, 등가 수력 직경, 순환 체류 시간($\tau = V/\dot{V}$) 등의 2차 물리량이 계산되어 **DRIVEN** 단계로 분류된다. 모델링 과정에서 필요한 노드 분할 수, 경계 조건의 단순화 등 공학적 선택 사항은 **ASSUMPTION** 단계로 지정되며, 근거가 미확정되어 정밀 보정이 필요한 매개변수는 **OPEN** 단계로 관리된다. 이러한 체계를 통해 입력값의 출처와 계산 근거를 역추적 가능하도록 유지한다.

### 6.3 Stage II Integrated MSRE Framework로의 단계적 확장 전략

Stage I Gate Criteria를 완전히 충족하여 Primary Loop 모델의 불확실성이 고정된 후, 아래 제시된 단계별 확장 절차에 따라 Stage II 통합 프레임워크 구축을 진행해야 한다.

1. **2차측 열적 경계 조건 확장**: Primary Heat Exchanger의 2차측 입출력 단면에 Radiator, Air Blower 및 2차계통 FLiBe 냉각염 순환 루프를 결합하여 외기 열유출 인터페이스를 완성한다.
2. **독립 드레인 탱크(Drain Tank) 모델 구축 및 단독 검증**: 동결 밸브(Freeze Valve) 표현 모델 및 드레인 탱크 내부의 감쇄열 제거 계통(Emergency Cooling System)을 독립적으로 구성하여 단독 가열 및 냉각 성능 검증을 수행한다.
3. **Subsystem Coupling 및 서브시스템 간 전파 오차 평가**: Validated Primary Loop + Secondary System + Drain Tank System을 결합하고, 정상운전, 펌프 트립, 자연순환 전환, 드레인 밸브 용해 및 원자로 신속 비상 배출(Reactor Draining Transient) 시나리오에 대한 통합 과도상태 해석을 수행한다.

## 7\. 결론 및 지도교수 종합 요약 지침

본 연구의 현 단계는 수치적 수렴성 달성(Direct $\lambda=1$ Solution)에 머무르지 않고, 모델의 물리적 타당성(Physical Validity)을 철저히 검증하는 마무리 단계로 전환하는 시점이다.

노심 열전달 구현에 있어 층류 유동 특성($Re \approx 812$)과 High- $Pr$ 용융염 특성을 감안하여 기존의 관습적인 Dittus-Boelter correlation 사용을 전면 배제하고, Graetz 수 기반의 열적 유입구 발달 상관식 및 Obround 형상 보정을 적용해야 한다. 아울러 Primary Heat Exchanger 해석 시 4개 U-tube 플러깅 이력($N_t = 318$)을 반영하고, Bell-Delaware 기법에 의한 Baffle 누설류 및 바이패스 스트림 보정을 적용하여 $UA$ 산출 오차를 $3.5\%$ 이내로 고정해야 한다.

펌프 Coastdown 과도상태에서 제기된 MARS-KS 및 실험 데이터와의 유량 감쇠 차이(Discrepancy) 원인을 로터 관성 $J$, 유체 토크 $\tau_{\text{hyd}}$, 수력 관성 $I_{\text{hydro}}$ 항목별로 정량적 분리 규명하는 작업이 완성되는 시점이 Stage I의 완료 시점이다.

결론적으로, MSRE Primary Loop의 열수력·열전달·펌프·핵동역학을 Modelica/TRANSFORM으로 독립 검증하고 실제 운전데이터 및 선행 해석 결과와 허용 가능한 오차범위 내에서 일치하는 Primary MSRE 모델을 우선 확립한 뒤, 이를 검증된 기반 모델로 사용하여 Secondary-side boundary와 Drain Tank를 단계적으로 결합한 통합 MSRE 시스템 해석 프레임워크로 확장하는 것이 본 연구의 최종 방향이다.[mdpi.com](https://www.mdpi.com/1996-1073/15/21/8296)

[

A Review of Molten Salt Reactor Multi-Physics Coupling Models and

새 창에서 열기](https://www.mdpi.com/1996-1073/15/21/8296)[mooseframework.inl.gov](https://mooseframework.inl.gov/virtual_test_bed/msr/msre/msre_sam_model.html)

[

Molten Salt Reactor Experiment MSRE SAM Modeling | VTB - MOOSE

새 창에서 열기](https://mooseframework.inl.gov/virtual_test_bed/msr/msre/msre_sam_model.html)[researchgate.net](https://www.researchgate.net/publication/281072196_Temperature_feedbacks_of_a_thermal_molten_salt_reactor_Compromise_between_stability_and_breeding_performances)

[

(PDF) Temperature feedbacks of a thermal molten salt reactor

새 창에서 열기](https://www.researchgate.net/publication/281072196_Temperature_feedbacks_of_a_thermal_molten_salt_reactor_Compromise_between_stability_and_breeding_performances)[jstage.jst.go.jp](https://www.jstage.jst.go.jp/article/jsmeb/48/3/48_3_610/_article/-char/en)

[

Steady State Analysis of Small Molten Salt Reactor - J-Stage

새 창에서 열기](https://www.jstage.jst.go.jp/article/jsmeb/48/3/48_3_610/_article/-char/en)[media.githubusercontent.com](https://media.githubusercontent.com/media/openmsr/msr-archive/master/docs/ORNL-TM-0378.pdf)

[

Temperatures in the MSRE Core During Steady-State Power

새 창에서 열기](https://media.githubusercontent.com/media/openmsr/msr-archive/master/docs/ORNL-TM-0378.pdf)[moltensalt.org](https://moltensalt.org/references/static/downloads/pdf/ORNL-TM-0378.pdf)

[

Temperatures in the MSRE Core During Steady-State Power

새 창에서 열기](https://moltensalt.org/references/static/downloads/pdf/ORNL-TM-0378.pdf)[osti.gov](https://www.osti.gov/servlets/purl/1602185)

[

Status Report on the MSRE TRANSFORM Model for Thermal - OSTI

새 창에서 열기](https://www.osti.gov/servlets/purl/1602185)[tandfonline.com](https://www.tandfonline.com/doi/pdf/10.1080/18811248.2008.9711881)

[

Reactivity-Initiated-Accident Analysis without Scram of a Molten Salt

새 창에서 열기](https://www.tandfonline.com/doi/pdf/10.1080/18811248.2008.9711881)[osti.gov](https://www.osti.gov/servlets/purl/2224187)

[

Heat and mass Transfer Coefficients in the Molten Salt Reactor

새 창에서 열기](https://www.osti.gov/servlets/purl/2224187)[researchgate.net](https://www.researchgate.net/publication/402992866_Experimental_investigation_of_laminar_heat_transfer_in_molten_salt_flow_through_horizontal_and_vertical_pipes)

[

Experimental investigation of laminar heat transfer in molten salt

새 창에서 열기](https://www.researchgate.net/publication/402992866_Experimental_investigation_of_laminar_heat_transfer_in_molten_salt_flow_through_horizontal_and_vertical_pipes)[kns.org](https://www.kns.org/files/pre_paper/44/20A-168-%EC%9E%A5%EB%8F%99%EC%9A%B1.pdf)

[

Modification of Laminar and Transition Single Phase Heat Transfer

새 창에서 열기](https://www.kns.org/files/pre_paper/44/20A-168-%EC%9E%A5%EB%8F%99%EC%9A%B1.pdf)[researchgate.net](https://www.researchgate.net/publication/238165331_Turbulent_convective_heat_transfer_with_molten_salt_in_a_circular_pipe)

[

Turbulent convective heat transfer with molten salt in a circular pipe

새 창에서 열기](https://www.researchgate.net/publication/238165331_Turbulent_convective_heat_transfer_with_molten_salt_in_a_circular_pipe)[mdpi.com](https://www.mdpi.com/2311-5521/7/6/207)

[

CFD Analysis of Convective Heat Transfer in a Vertical Square Sub

새 창에서 열기](https://www.mdpi.com/2311-5521/7/6/207)[researchgate.net](https://www.researchgate.net/publication/279215529_Laminar_Natural_Convection_Heat_Transfer_Characteristics_of_Molten_Salt_Around_Horizontal_Cylinder)

[

Laminar Natural Convection Heat Transfer Characteristics of Molten

새 창에서 열기](https://www.researchgate.net/publication/279215529_Laminar_Natural_Convection_Heat_Transfer_Characteristics_of_Molten_Salt_Around_Horizontal_Cylinder)[researchgate.net](https://www.researchgate.net/publication/406984279_Design_and_Analysis_of_a_High-Temperature_Heat_Exchanger_for_Compressed_CO2_Energy_Storage_System)

[

(PDF) Design and Analysis of a High-Temperature Heat Exchanger

새 창에서 열기](https://www.researchgate.net/publication/406984279_Design_and_Analysis_of_a_High-Temperature_Heat_Exchanger_for_Compressed_CO2_Energy_Storage_System)[researchgate.net](https://www.researchgate.net/publication/395143594_Flow_pattern_and_Vortex_mechanisms_on_heat_transfer_performance_in_shell-and-tube_heat_exchangers)

[

Flow pattern and Vortex mechanisms on heat transfer performance

새 창에서 열기](https://www.researchgate.net/publication/395143594_Flow_pattern_and_Vortex_mechanisms_on_heat_transfer_performance_in_shell-and-tube_heat_exchangers)[researchgate.net](https://www.researchgate.net/scientific-contributions/CHEN-Yushuang-2343143235)

[

CHEN Yushuang's research works | Chinese Academy of Sciences

새 창에서 열기](https://www.researchgate.net/scientific-contributions/CHEN-Yushuang-2343143235)[moltensalt.org](https://moltensalt.org/references/static/downloads/pdf/ORNL-TM-2098.pdf)

[

Tube Vibration in MSRE Primary Heat Exchanger \[Disc 5\]

새 창에서 열기](https://moltensalt.org/references/static/downloads/pdf/ORNL-TM-2098.pdf)[moltensalt.org](https://moltensalt.org/references/static/downloads/pdf/ORNL-TM-1023.pdf)

[

ORNL-TM-1023 - the Molten Salt Energy Technologies Web Site

새 창에서 열기](https://moltensalt.org/references/static/downloads/pdf/ORNL-TM-1023.pdf)[nst.sinap.ac.cn](https://www.nst.sinap.ac.cn/article/id/3126)

[

Radionuclides in primary coolant of a fluoride salt-cooled high

새 창에서 열기](https://www.nst.sinap.ac.cn/article/id/3126)