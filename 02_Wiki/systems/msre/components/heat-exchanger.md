---
type: component
system: msre
tags: [heat-exchanger, shell-and-tube, secondary-loop, thermal-hydraulics]
last_updated: 2026-09-05
sources: [leandro-2019-sam-msre-thermal-hydraulic]
---
<!-- 저장 위치: 02_Wiki/systems/msre/components/ -->

# MSRE Heat Exchanger (1차-2차 열교환기)

## 개요 / 역할
U-tube 형식, 1차측 shell / 2차측 tube, 둘 다 Hastelloy-N. 수평 배치, 길이 1.83 m. 1차측(연료염)에서 2차측(coolant salt)으로 열을 전달해 core 발열을 계통 밖으로 방출.

## Geometry
HX 형상값은 Leandro et al. (2019) Table 2를 이미지로 재확인해 [[03_Data/msre/geometry/msre-primary-loop-geometry]]에 보존했다.

| 항목 | 값 | Provenance |
|---|---:|---|
| HX 길이 | 1.83 m | ORIGINAL |
| Triangular pitch | 0.0197 m | ORIGINAL |
| Tube 외경 / 두께 / 내경 | 0.0127 / 0.00107 / 0.0106 m | ORIGINAL / DERIVED |
| Tube 유동면적 | 0.0279 m2 | DERIVED |
| Baffle spacing | 0.305 m | ORIGINAL |
| Shell 외경 / 두께 / 내경 | 0.406 / 0.0127 / 0.381 m | ORIGINAL / DERIVED |
| Tube / shell hydraulic diameter | 0.0209 / 0.0130 m | DERIVED |
| Tube / shell surface-area density | 378 / 308 m-1 | DERIVED |

세부 값의 기준 출처, 페이지/표, 검증상태는 데이터 페이지를 우선한다.

## 물성 / 파라미터
- 1차측: MSRE fuel salt, 설계 유량 약 0.0757 m3/s(약 171 kg/s).
- 2차측: cooling salt, 유량 0.054 m3/s, 입구온도 825 K.
- Historical 기준: 1차측 936 -> 908 K, 2차측 825 -> 866 K.
- SAM 결과: core 입출구 905/933 K로 historical 대비 약 3 K 오프셋.

정량값의 출처와 provenance는 [[03_Data/msre/geometry/msre-primary-loop-geometry]] 및 [[03_Data/msre/benchmark/sam-relap5-3d-historical-primary-loop]]를 참조한다.

## 지배 물리 / 관련 개념
### 열전달

$$
Q = UA\Delta T_{lm}
$$

`U`는 tube-side 대류, tube wall 전도, shell-side 대류 및 오염저항을 합친 overall heat-transfer coefficient이다. 보정값을 사용하기 전에 양측의 `Re`, `Pr`, `Nu`와 벽면 열저항을 분리해 기록해야 한다.

### 유동 및 압력손실

- tube-side와 shell-side의 질량·운동량 보존
- tube bundle의 유효 유동면적과 hydraulic diameter
- baffle에 의한 shell-side 횡류 및 국부손실
- 저 Reynolds 수에서 층류/천이 상관식 적용
- HX 압력손실이 pump operating point와 natural circulation driving force에 미치는 영향

`Gnielinski`와 같은 난류 상관식은 적용범위 확인 없이 단독 사용하지 않는다.

## 모델링 구현
현재 TRANSFORM `PrimarySystem`은 HX 2차측 전체 계통을 해석하지 않고 경계조건/열침으로 단순화한다. 따라서 primary-loop hydraulic baseline에는 사용 가능하지만, HX 열전달 자체의 독립 검증은 미완료다.

구현 확장 순서:
1. HX 1차측/2차측 노드와 벽면 열용량 분리
2. Table 2 형상값으로 유동면적과 열전달 면적 재현
3. 양측 온도의존 물성 적용
4. 층류/천이/난류 열전달 및 압력손실 closure 명시
5. 2차측 경계조건과 full secondary loop case 비교
6. 정상상태 열수지, 압력손실, 자연순환 응답 순서로 검증

## 관련 페이지
- [[02_Wiki/systems/msre/components/primary-loop]]
- [[02_Wiki/sources/leandro-2019-sam-msre-thermal-hydraulic]]
- [[02_Wiki/systems/msre/benchmark/sam-msre-primary-loop]]
- [[03_Data/msre/geometry/msre-primary-loop-geometry]]
- [[03_Data/msre/benchmark/sam-relap5-3d-historical-primary-loop]]
- [[02_Wiki/systems/msre/implementation/msre-transform-model]]
