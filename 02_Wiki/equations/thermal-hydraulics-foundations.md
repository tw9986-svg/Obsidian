---
type: equation
systems: [msre]
tags: [thermal-hydraulics, conservation-laws, molten-salt, modelica]
last_updated: 2026-09-03
sources:
  - [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
  - [[02_Wiki/sources/jeong-2026-mars-msre-benchmark]]
---

# 원자로 열수력 이론 기초 — MSRE 적용

이 문서는 MSRE TRANSFORM 모델에 필요한 열수력 이론을 **보존법칙 → 구성식/폐쇄식 → 컴포넌트 모델 → 결합·검증** 순서로 정리한다. 일반 방정식은 모든 계통에 적용할 수 있고, MSRE의 형상·물성·경계조건은 관련 데이터 페이지를 참조한다.

## 1. 해석 범위와 기본 가정

- 1차 계통은 연료염, 2차 계통은 냉각염으로 구성된 단상 액체 계통으로 취급한다.
- 배관·노심·플레넘·열교환기는 1-D control volume/junction으로 이산화한다. 다운커머의 실제 3-D 혼합은 1-D 근사이므로 검증 대상이다.
- 각 control volume은 평균 압력, 온도, 엔탈피, 조성을 갖는다. 노심은 필요에 따라 축방향 1-D 또는 radial x axial 2-D로 세분한다.
- 연료염 물성은 온도의존 상관식과 설계 상수표가 서로 다를 수 있으므로, 모델에 실제 사용한 물성과 기준 물성을 섞지 않는다. [[03_Data/msre/properties/msre-fuel-salt-properties-robertson1965]]

## 2. 핵심 보존방정식

### 2.1 질량 보존

일반 형태:

$$
\frac{\partial \rho}{\partial t}+\nabla\cdot(\rho\mathbf{u})=\dot{m}_v
$$

1-D control volume의 경계형:

$$
\frac{d(\rho V)}{dt}=\sum \dot{m}_{in}-\sum \dot{m}_{out}+\dot{m}_{gen}
$$

비압축성 정상상태에서는 각 직렬 구간의 질량유량이 같고, 분기에서는 유량 합이 보존되어야 한다.

### 2.2 운동량 보존

1-D 평균 유동의 대표식:

$$
\frac{d(\rho V u)}{dt}
=\sum \dot{m}_{in}u_{in}-\sum \dot{m}_{out}u_{out}
-A\Delta p+\rho V g_z-\Delta p_{fric}A-\Delta p_{form}A
$$

마찰 및 국부손실은 다음처럼 분리한다.

$$
\Delta p_{fric}=f\frac{L}{D_h}\frac{\rho u^2}{2},\qquad
\Delta p_{form}=K\frac{\rho u^2}{2}
$$

계통 정상상태에서는 펌프 수두와 전체 마찰·형상손실 및 정수두의 합이 평형을 이룬다. `f`와 `K`는 형상 및 유동영역에 맞는 값이어야 한다.

### 2.3 에너지 보존

엔탈피 기반 대표식:

$$
\frac{d(\rho V h)}{dt}
=\sum \dot{m}_{in}h_{in}-\sum \dot{m}_{out}h_{out}
+\dot{Q}_{vol}+\dot{Q}_{wall}
+V\frac{dp}{dt}
$$

저압 단상 액체의 1차 근사에서는 압력일 항을 작게 볼 수 있지만, 과도해석에서 압력·밀도 변화가 무시 가능한지는 모델 가정으로 명시해야 한다. 온도와 엔탈피의 관계는

$$
dh=c_p(T,p)\,dT+\left[v-T\left(\frac{\partial v}{\partial T}\right)_p\right]dp
$$

로 연결한다.

노심 체적발열은

$$
\dot{Q}_{vol}=q'''V
$$

이며, 연료염과 흑연에 분배되는 열원은 별도 항으로 둔다. MSRE 자료의 94% 연료염/6% 흑연은 측정값이 아니라 ORNL-TM-0378 p.40 각주의 가정이고, 일부 MARS/SAM 모델은 100%를 연료염에 부여한다. 따라서 benchmark에서 발열 분배를 명시해야 한다. [[02_Wiki/systems/msre/components/core]]

## 3. 필요한 구성식과 무차원수

### 3.1 상태·물성

모델은 최소한 다음을 일관되게 제공해야 한다.

$$
\rho=\rho(T,p),\quad \mu=\mu(T),\quad c_p=c_p(T),\quad k=k(T)
$$

액체 금속이 아닌 용융염에서는 점도 변화가 압력강하와 펌프 토크에 크게 영향을 줄 수 있다. Robertson 설계표는 922 K 부근의 상수값이고, canonical TRANSFORM 모델은 Cantor 계열 온도의존식을 ACTIVE로 사용하므로 두 계열을 혼용하지 않는다. [[02_Wiki/issues/fuel-salt-property-correlation-conflict]]

### 3.2 유동영역 판정

$$
Re=\frac{\rho uD_h}{\mu},\qquad
Pr=\frac{c_p\mu}{k}
$$

Reynolds 수에 따라 층류, 천이, 난류의 마찰계수와 열전달 상관식을 분기한다. 현재 MSRE Core1D 기준은 저 Reynolds 수 영역으로 확인되었으므로, 난류용 Gnielinski 상관식 하나만 적용하면 안 된다. [[04_Projects/msre-transform-status]]

### 3.3 대류 열전달

벽면 열유속은

$$
q''=hA_s(T_w-T_b),\qquad Nu=\frac{hD_h}{k}
$$

로 정의한다. `Nu`는 유동영역, 경계조건(일정 벽온/열유속), 입구효과, 형상에 따라 선택한다. 노심 채널과 HX shell/tube는 동일 상관식을 자동 공유하지 말고 각각의 수력직경·표면적·유동방향을 사용한다.

### 3.4 부력과 자연순환

밀도차가 있는 폐회로에서 구동 정수두는

$$
\Delta p_{buoy} = g\oint \rho(z)\,dz
$$

로 표현할 수 있고, 정상 자연순환 조건은

$$
\Delta p_{buoy}+\Delta p_{pump}
=\Delta p_{fric}+\Delta p_{form}
$$

이다. 자연순환에서는 온도장과 유량이 서로를 결정하므로 물성, 열원, 열침 경계조건을 함께 검증해야 한다. 현재 자연순환은 냉각염 입구 실측곡선이 확보되기 전까지 assert로 차단되어 있다. [[02_Wiki/systems/msre/implementation/msre-transform-model]]

## 4. 주요 컴포넌트 이론

### 4.1 노심과 흑연

연료염 에너지와 흑연 에너지를 분리하면 대표적인 국부 모델은

$$
\rho_f c_{p,f}\frac{\partial T_f}{\partial t}
+\rho_f c_{p,f}u\frac{\partial T_f}{\partial z}
=q'''_f-h_{fg}a_s(T_f-T_g)
$$

$$
\rho_g c_{p,g}\frac{\partial T_g}{\partial t}
=k_g\nabla^2T_g+q'''_g+h_{fg}a_s(T_f-T_g)
$$

이다. 여기서 `a_s`는 연료염-흑연 접촉면적/체적이다. 2-D 모델에서는 흑연의 radial/axial 전도를 보존하고, 출력분포 오차와 노달화 오차를 분리해 평가한다.

### 4.2 열교환기

대향류 또는 교차류 HX의 전체 열수지는

$$
\dot{Q}=\dot{m}_h(h_{h,in}-h_{h,out})
=\dot{m}_c(h_{c,out}-h_{c,in})
$$

이며, 단순화한 전열 모델은

$$
\dot{Q}=UA\Delta T_{lm}
$$

을 사용한다. `U`는 막·벽·오염 저항을 포함한 유효값이다. MSRE SAM 모델에서 일부 열전달 면적/계수는 정상상태 온도차 재현을 위해 CALIBRATED 되었으므로, 상관식 기반 값과 구분한다. [[02_Wiki/systems/msre/components/heat-exchanger]]

### 4.3 펌프와 로터 동역학

회전축의 운동방정식:

$$
J\frac{d\omega}{dt}=\tau_{motor}-\tau_{hydraulic}-\tau_{friction}
$$

유량·수두·동력의 affinity law는 같은 펌프 형상에서

$$
Q\propto N,\qquad H\propto N^2,\qquad P\propto N^3
$$

이다. 그러나 coastdown에서는 저유량 영역의 펌프 곡선, 관성, 역류 및 마찰 모델이 결과를 좌우하므로 affinity law만으로 검증할 수 없다. 현재 로터 ODE 자체는 PASS이나, 유량 coastdown은 MARS와 큰 차이가 남아 있다. [[02_Wiki/systems/msre/components/fuel-pump]]

## 5. 열수력-중성자학 결합

MSRE에서는 DNP가 노심 밖 연료염과 함께 이동하므로 point kinetics의 전구체를 단순히 노심에 고정하면 안 된다. 각 전구체군에 대해

$$
\frac{\partial C_i}{\partial t}
+\nabla\cdot(\mathbf{u}C_i)
=\beta_i\frac{P}{\Lambda}
-\lambda_i C_i
$$

를 적용하고, 노심 유효량과 전체 계통 수송량을 연결한다. 반응도는 연료·흑연 온도 피드백과 외부 반응도를 포함한다.

열수력 결합 시의 순서는 다음과 같다.

1. 유량과 온도장으로 `u`, `T`, 물성을 계산한다.
2. 해당 온도장으로 반응도 피드백을 계산한다.
3. 출력과 DNP 생성·붕괴·수송을 갱신한다.
4. 새 체적발열을 에너지 방정식에 되먹임한다.

현재 DNP full-loop transport와 circulation reactivity는 analytic 결과와 비교해 PASS 상태다. [[02_Wiki/systems/msre/implementation/msre-transform-model]]

## 6. 검증 순서와 필수 지표

모델을 복잡하게 만들기 전에 다음 항목을 순서대로 확인한다.

1. **보존성**: 각 control volume의 질량·에너지 잔차와 DNP 총량.
2. **정상 유압**: 펌프 수두 = 마찰손실 + 형상손실 + 정수두, 계통 유량 및 `Delta p`.
3. **노심 열수지**: `Q_core = m_flow*cp*DeltaT`와 연료염/흑연 열원 분배.
4. **전이시간**: `tau = V_inventory/m_flow`; 체적 경계와 전이시간 정의를 함께 기록한다.
5. **무차원수**: 각 구간의 `Re`, `Pr`, `Nu` 및 상관식 적용 영역.
6. **과도 응답**: pump startup/coastdown, natural circulation, 온도 peak와 시간척도.
7. **공간 수렴성**: Core1D → Core2D에서 총 열량, 평균온도, 압력강하가 일관되는지 확인한다.

현재 연구에서 우선 해결할 이론·구현 항목은 저유량 펌프 폐쇄식, 2-D 출력분포, 흑연 전도 및 fuel-graphite 열전달 결합, 자연순환 경계조건이다. [[04_Projects/msre-transform-status]]

## 관련 페이지

- [[02_Wiki/systems/msre/components/primary-loop]]
- [[02_Wiki/systems/msre/components/core]]
- [[02_Wiki/systems/msre/components/heat-exchanger]]
- [[02_Wiki/systems/msre/components/fuel-pump]]
- [[02_Wiki/systems/msre/implementation/msre-transform-model]]
- [[02_Wiki/systems/msre/verification/dymola-b0-baseline]]
- [[03_Data/registry]]
