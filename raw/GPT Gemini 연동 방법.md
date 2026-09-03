---
title: "GPT Gemini 연동 방법"
source: "https://chatgpt.com/c/6a98e84a-ed20-83ee-86d4-cb6c8f765bae"
author:
published:
created: 2026-09-03
description: "ChatGPT conversation with 4 messages"
tags:
  - "clippings"
---
## ==연구 프레임워크 및 시스템 아키텍처 개요==

==공학 심층 연구 과정에서 대형 언어 모델(LLM)을 단일 주체로 활용하여 자료 조사, 판단, 데이터베이스(DB) 수정까지 일괄 수행하게 할 경우, 모델의 환각(Hallucination) 현상, 컨텍스트 윈도우 오염, 지식베이스 스키마 파괴 등 상호 간섭 오류가 발생한다. 이러한 문제를 방지하기 위해서는 연구 작업의 상위 의사결정, 외부 데이터 수집, 구조화 데이터 생성 및 DB 관리 작업을 명확히 분리하고, 이를 하나의 단일 진실 공급원(Single Source of Truth, SSOT)인 옵시디언(Obsidian) 볼트(Vault)로 수렴시키는 오케스트레이션 구조가 필수적이다.==

==본 연구 체계는 최상단에 연구 질문 및 미결 이슈(Research Questions / Open Issues) 레이어를 배치하고, 하위에 Gemini, GPT, Claude Code의 세 가지 대형 언어 모델을 배치하여 기능적으로 완전 분리된 피드백 루프를 형성한다. Gemini는 전체 연구의 방향성을 설정하고 기존 지식과의 갭(Gap)을 식별하는 연구 감독자(Research Director) 역할을 맡는다. GPT는 지정된 연구 질문에 맞춰 학술 논문, 국립연구소 보고서 등 외부 정량 데이터를 탐색하는 외부 데이터 수집가(Data Scout) 역할을 수행한다. Claude Code는 수집된 원자료의 무결성 검증, 해시 생성, 서지 정보 정리, 프로비넌스(Provenance, 출처 이력) 태깅, 옵시디언 내부 Wiki 및 인덱스 갱신을 전담하는 데이터베이스 관리자(Database Curator) 역할을 맡는다.==

==전체 워크플로우는 상위 연구 질문 정의, 데이터 수집, 수집 데이터의 인박스(Inbox) 투입, 자동화 DB 편입, 최상위 지식베이스 반영, 재분석 및 모델링 결정의 단계로 순환한다. 이러한 분리형 아키텍처는 데이터 관리의 결정론적 정확성을 보장함과 동시에 용융염원자로 실험(Molten-Salt Reactor Experiment, MSRE)과 같은 복잡한 열수력·핵특성 연계 해석 연구를 안정적으로 확장할 수 있는 기반을 제공한다.==   

## ==최상위 연구 프레임워크: Research Questions 및 Open Issues 레이어==

==장기적이고 유기적인 공학 연구를 유지하기 위해서는 수집되는 모든 데이터와 생성되는 파라미터가 명확한 연구 질문에 귀속되어야 한다. 최상위 레이어인 Research Questions (RQ) 및 Open Issues 레이어는 도메인 특화 문제를 독립적인 개체로 관리하여, 특정 인프라나 모델에 귀속되지 않고 다양한 연구 과제(MSRE, MSBR, 차세대 용융염원자로 등)로 확장될 수 있도록 설계된다.==

==MSRE 연구 프로젝트에 적용되는 주요 최상위 RQ 항목과 각 항목별 관리 파라미터 및 핵심 검증 대상은 아래 표와 같이 체계화된다.==

| RQ ID연구 질문 명칭관련 물리 파라미터 / 이슈주요 블로커 및 검증 목표타겟 출력물 (Target Output) |  |  |  |
| --- | --- | --- | --- |
| **RQ-001** | Fuel property provenance | 밀도 *ρ*(*T*), 점성도 *μ*(*T*), 열전도도 *k*, 정압열용량 *cp*​ |  |

==역사적 측정 데이터(ORNL-TM-2316)와 시스템 코드(TRANSFORM, SAM) 단순화 물성치 간 불일치 원인 규명==

==Benchmark Property Set 대 Physical Best-Estimate Set 분리 정의==

| **RQ-002** | Graphite volumetric heating | 체적 발열 비율, 감속재 감마 가열, 내부 발열 분포 |  |
| --- | --- | --- | --- |

==흑연 감속재 블록 내부 발열 비율의 온도 피드백 영향성 정량화==

| 3D 노심 열수력 모델 결합용 체적 발열 프로파일 노드 |  |  |  |
| --- | --- | --- | --- |
| **RQ-003** | Core radial power distribution | 반경방향 출력 분배, 국선 중성자 플럭스 프로파일 |  |

==감속재 채널별 융염 유량 배분 및 국소 출력이 출구 온도에 미치는 영향 평가==

| 채널별 유량-출력 정합성 매트릭스 |  |  |  |
| --- | --- | --- | --- |
| **RQ-004** | Pump coastdown discrepancy | 펌프 관성 모멘트, 유량 감소 곡선, 마찰 손실 계수 |  |

==1차계 정격 유량 감소 과도 응답 시 측정 유량과 해석 모델 간의 편차 해석==

| 1차계 주펌프 과도응답 수식 모델 |  |  |  |
| --- | --- | --- | --- |
| **RQ-005** | Primary HX boundary validation | 껍질/관 측 전열계수, 오염 계수, Hastelloy-N 열전도도 |  |

==중간열교환기(IHX) 전열 성능의 경계 조건 적절성 검증 및 전열관 두께별 열저항 평가==

==IHX 유효 전열 면적 및 전열계수 보정 모델==

==Gemini는 상기 RQ 항목들의 우선순위를 지정하고 연구 진행 상황에 따라 신규 이슈를 발굴하거나 완결된 이슈를 닫는 역할을 담당한다. GPT와 Claude Code는 각 작업 주기에서 현재 활성화된 RQ 번호를 태그로 공유함으로써 지식베이스 내부의 모든 문서가 특정 RQ와 하이퍼링크로 연결되도록 보장한다.==

## ==모델별 역할 분담 및 데이터 경계 정의==

==역할의 모호성을 제거하기 위해 각 대형 언어 모델의 입출력 범위 및 인터페이스 경계를 엄격히 설정한다. 외부 데이터 조사를 수행하는 GPT와 로컬 지식베이스 관리를 담당하는 Claude Code 사이의 경계 설정은 전체 자동화 파라미터의 무결성을 결정짓는 핵심 요소이다.==

==전체 워크플로우의 순환 구조는 연구 질문 수립, 데이터 탐색, 인박스 수집, 정제 및 DB 반영, 재분석의 단계로 구성된다. 최상단에서 미해결 연구 질문이 주어지면 Gemini가 심층 분석을 거쳐 필요한 문헌과 검증 항목을 정의한다. 이 지침을 전달받은 GPT는 외부 논문, ORNL 보고서, INL 규격 데이터를 탐색하여 메타데이터가 첨부된 원자료 형태로 `00_Inbox` 폴더에 투입한다. `00_Inbox`를 감시하는 Claude Code는 파일 해시 계산, 중복 검사, 서지 정리, 프로비넌스 연결을 거쳐 지식베이스의 정규 폴더로 정문화한다. 정제된 지식베이스를 바탕으로 Gemini가 다시 피드백을 수행하여 연구 방향성을 업데이트하는 연속적 순환 체계를 형성한다.==   

### ==Gemini: 연구 감독자 (Research Director)==

==Gemini는 현재 확보된 근거 자료를 바탕으로 미해결 연구 질문을 도출하고, 다음 단계의 심층 조사가 필요한 항목을 결정한다. 옵시디언 볼트 전체의 논리적 갭을 파악하여 다음 모델링 단계(Modelling Phase)로 나아가기 위한 필요 문헌과 수치 검증 항목을 서술형 가이드라인으로 출력한다. Gemini는 옵시디언 볼트에 직접 파일 삭제, 생성, 수정 명령을 내리지 않으며, 오직 '연구 방향 설정' 및 '질문 생성' 레벨에서 동작한다.==

### ==GPT: 외부 데이터 수집가 (Data Scout)==

==GPT는 Gemini가 제시한 요구사항에 따라 ORNL, INL 등 해외 연구소 보고서, 학술 논문, 데이터베이스를 조사한다. GPT가 수행하는 작업의 최종 결과물은 옵시디언 볼트 내의 `00_Inbox` 폴더에 임시 파일로 저장되는 수준으로 제한된다. GPT가 수집하는 데이터 표준 구조는 서지 메타데이터(정확한 제목, 저자, 발행기관, 연도, DOI/Report Number, 원본 URL)와 활용성 메타데이터(자료 필요성 사유, 연관 모델 파라미터 및 RQ 연결 정보)로 엄격히 제한된다. GPT는 파일명의 최종 확정, 폴더 이동, 옵시디언 태그 부여, 내부 백링크(Backlink) 생성과 같은 DB 커밋(Commit) 권한을 갖지 않으므로 외부 검색 시 발생하는 비구조화 데이터가 지식베이스를 오염시키는 현상을 차단한다.==   

### ==Claude Code: 데이터베이스 관리자 (Database Curator)==

==Claude Code는 `00_Inbox`에 수집된 임시 자료를 검증하고, 이를 옵시디언 SSOT 체계로 수용하는 모든 무결성 제어 작업을 전담한다. 파일 무결성 측면에서는 수집된 파일의 SHA-256 해시를 계산하여 기존 볼트 내 중복 데이터 존재 여부를 판별한다. 디렉토리 구조 정형화 측면에서는 정규화 규칙에 따른 파일명 변경 및 `01_Raw`, `02_Source` 폴더로의 이관을 처리한다. 서지 정보 및 프로비넌스 관리 측면에서는 YAML 프론트매터 가공과 출처 태그 부여를 전담한다. 지식 네트워크 연결 측면에서는 연관 RQ 노트, 파라미터 노트, 로그 파일 간의 하이퍼링크 및 역링크 구조를 완성한다.==   

==이러한 명확한 역할 분담을 통해 단일 LLM에 의존할 때 발생하는 무분별한 파일 생성 및 옵시디언 내 고립 노트(Orphan Notes) 양산을 방지할 수 있다.==

## ==파이프라인 자동화 구현 기술 및 연동 방안==

==구상한 워크플로우를 실제 로컬 환경에서 자동화하기 위해서는 옵시디언의 통신 인터페이스, Claude Code의 비인터랙티브 실행 모드, 그리고 파이프라인을 구동하는 오케스트레이션 스크립트의 유기적 결합이 필요하다.==   

### ==Obsidian Local REST API 및 MCP 연동==

==옵시디언 볼트를 프로그래밍 방식으로 조작하기 위해 `obsidian-local-rest-api` 플러그인을 활용한다. 이 플러그인은 로컬 포트(HTTPS 27124 또는 HTTP 27123)를 통해 보안 인증이 적용된 RESTful API 및 Model Context Protocol (MCP) 서버 인터페이스를 제공한다.==   

==API는 파일 및 디렉토리의 CRUD 작업뿐만 아니라, 메타데이터 검색, 태그 조회, 백링크 추출, 대용량 노트의 부분 수정(PATCH Method) 기능을 지원한다. 특히 PATCH 엔드포인트는 Markdown Patch 2.0 사양을 지원하여 노트 전체를 다시 쓰지 않고 특정 헤더나 프론트매터 키, 블록 항목만을 정밀하게 갱신할 수 있다. 동시성 제어를 위해 버전 토큰 기반의 `ifMatch` 무결성 검증을 수행하여 race condition에 의한 데이터 유실을 방지한다.==   

==Claude Code는 CLI 수준에서 HTTP MCP 엔드포인트를 기본 지원하므로, 아래 명령어 예시와 같이 MCP 서버를 등록하여 옵시디언 내부 도구에 직접 접근할 수 있도록 설정한다.==   

==`claude mcp add --transport http obsidian https://127.0.0.1:27124/mcp/ --header "Authorization: Bearer <YOUR_API_KEY>"`==

### ==Claude Code Headless 모드를 통한 스크립트 자동화==

==Claude Code의 비인터랙티브 헤드리스 모드(Headless Mode)인 `-p` (`--print`) 플래그를 이용하면 단말기 터미널의 개입 없이 파이썬 또는 쉘 스크립트 기반의 자동화 파이프라인을 구축할 수 있다. `--allowedTools` 옵션과 `--output-format json` 옵션을 결합하면, 인박스 감시 도중 수집된 데이터를 수신하여 자동으로 볼트 정제를 수행하고 그 결과를 구조화된 JSON 형태로 반환받을 수 있다.==   

==자동화 파이프라인의 각 단계별 연동 기술, 입출력 포맷 및 수행 방법의 세부 사양은 아래 표와 같다.==

| 단계연동 주체 및 도구입력 데이터 포맷수행 내용 및 도구 호출 방식출력 데이터 포맷 |  |  |  |  |
| --- | --- | --- | --- | --- |
| **1\. RQ 정의** | Gemini Deep Research | 현재 지식베이스 상태 (Markdown 요약) | RQ 레이어 분석, 기존 지식 갭 탐색, 부족한 데이터 도출 및 질문 생성 | 연구 방향성 가이드라인 (`.md`) |
| **2\. 자료 수집** | GPT (Data Scout) | Gemini 가이드라인 (`.md`) |  |  |

==학술 DB, ORNL 보고서 검색, 규격화된 표준 메타데이터 생성==

| 메타데이터 포함 원자료 (`00_Inbox/*.md`) |  |  |  |
| --- | --- | --- | --- |
| **3\. 데이터 검증** | Claude Code CLI (Headless) | `00_Inbox` 파일 |  |

==`claude -p` 실행, SHA-256 해시 계산, 중복 체크 및 서지 메타데이터 검증==

==파싱된 JSON 결과값 (`.json`)==

| **4\. Vault DB 정제** | Claude Code via Local REST API | 검증된 JSON 메타데이터 |  |
| --- | --- | --- | --- |

==Local REST API (`PUT /vault/*`, `PATCH /vault/*`) 호출, 백링크 및 프로비넌스 생성==

==정문화된 원본 및 소스 노트 (`01_Raw/`, `02_Source/`)==

| **5\. 재분석 레포트** | Gemini Deep Research | 업데이트된 지식베이스 (REST API 추출) | 프로비넌스 매트릭스 재분석, 모델링 파라미터 불확실성 평가 및 다음 RQ 신규 정의 | 갱신된 RQ 지침 및 모델링 지침 (`.md`) |
| --- | --- | --- | --- | --- |

==파이프라인 구동 시 로컬 오케스트레이터(Python Watchdog 등)가 `00_Inbox` 폴더를 상시 감시한다. 신규 문서가 감지되면 다음 예시 명령어와 같이 헤드리스 Claude Code가 트리거되어 DB 편입 프로세스가 비동기로 실행된다.==   

==`claude -p "Process and ingest all metadata files in 00_Inbox according to vault schema rules. Update provenance matrix and linked RQs." --allowedTools "Read,Edit,Bash,mcp__obsidian__*" --output-format json`==

==이 구성을 통해 인간의 개입을 최소화하면서도 지식베이스의 정합성과 참조 투명성을 완벽하게 유지할 수 있다.==

## ==MSRE Fuel-Salt Property 사례 실증 연구==

==본 멀티 LLM 구축 파이프라인의 유효성을 검증하기 위해, MSRE의 핵심 분석 대상인 1차계 연료염(Fuel Salt) 물성치 데이터 관리 문제에 본 체계를 적용한다.==   

==MSRE의 연료염은 LiF-BeF2​-ZrF4​-UF4​ (65.0−29.1−5.0−0.9 mole %) 조성의 용융 불화물염이다. 수십 년간 축적된 역사적 문서(ORNL-TM-2316 등)와 최근의 전산 해석 모델(INL TRANSFORM, MOOSE SAM) 사이에는 열수력 물성치의 수식 표현 및 정량적 수치에 미세한 차이가 존재한다.==   

==Gemini는 지식베이스를 검토한 후 다음 이슈를 발굴하고 RQ-001 하위에 수집 지침을 작성한다. 즉, MSRE 정격 운전 조건(650∘C/923.15K)에서 계산된 열수력 물성치에 대해 역사적 실험 데이터(Cantor 1968, ORNL-TM-2316) 원본과 INL TRANSFORM Modelica 코드에 이식된 인허가용 단순화 물성치 간의 분리 작업이 필요함을 정의한다.==   

==상기 지침을 전달받은 GPT는 외부 데이터를 탐색하여 ORNL-TM-2316, ORNL-4658, ORNL-4865 및 INL TRANSFORM 기술 보고서의 관련 섹션을 발췌한다. 이후 표준 형식에 맞추어 메타데이터와 물리 수식을 서술한 후 `00_Inbox/ORNL_TM_2316_Inflow.md` 파일로 투입한다.==   

==Claude Code는 `00_Inbox` 내의 파일 수집을 감지하여 PDF 및 텍스트 해시를 계산하고, 중복이 없음을 확인한 후 메타데이터 파싱 및 프로비넌스 태깅을 수행한다. 이후 옵시디언 Local REST API를 통해 볼트 내에 물성별 노드를 생성하고 프로비넌스 매트릭스 노드를 업데이트한다.==   

==MSRE 1차계 연료염의 주요 물성치에 대해 출처 문서별로 수집 및 분류된 데이터의 대조 결과는 아래 표와 같이 정리되어 지식베이스에 안착된다.==

| 물성 항목 (Property)수학적 수식 및 대표값적용 온도 범위 및 조건출처 문서 (Provenance)시스템 코드 및 모델 반영 현황 |  |
| --- | --- |
| **밀도 (*****ρ*****)** |  |

==*ρ*(*T*)=2553.3−0.562⋅*T*\[kg/m3\] (*T* in K)==

==813 K∼973 K (434∘C∼700∘C)==

==ORNL-TM-2316 (Cantor, 1968)==

==SAM MSRE VTB 모델 및 TRANSFORM 1차계 기본값 편입==

| **밀도 (*****ρ*****, 변형)** |  |
| --- | --- |

==*ρ*\=2241\[kg/m3\] (단순화 고정값)==

==650∘C 정격 운전점 기준==

==INL-TRANSFORM (2020)==

==과도 해석 단순화 노드에 사용됨==

| **점성도 (*****μ*****)** |  |
| --- | --- |

==*μ*(*T*)=8.4×10−5⋅exp(4340/*T*)\[Pa⋅s\]==

======\[cite: 1, 4\]======

==813 K∼973 K==

==\[cite: 5\]==

======ORNL-TM-2316======

==SAM / TRANSFORM 동적 점성도 수식==

| **정압열용량 (*****cp*****​)** |  |
| --- | --- |

==*cp*​=2009.66\[J/(kg⋅K)\]==

\[cite: 1, 4\]

====전 온도 영역 상수 처리====

ORNL-TM-2316

==SAM Baseline 물성치 세트==

| **정압열용량 (*****cp*****​, 대체)** |  |
| --- | --- |

==*cp*​=1927\[J/(kg⋅K)\]==

==\[cite: 2\]==

==유량 상태 노드 평가용==

==TRANSFORM Modelica==

==TRANSFORM 1차계 특정 노드 적용==

| **열전도도 (*****k*****)** |  |
| --- | --- |

==*k*\=1.0\[W/(m⋅K)\]==

\[cite: 1, 4\]

전 온도 영역 상수 처리

ORNL-TM-2316

==SAM / TRANSFORM 표준 세트==

| **열전도도 (*****k*****, 대체)** |  |
| --- | --- |

==*k*\=4.76\[W/(m⋅K)\] (등가 열전도율)==

==대류 열전달 보정 계수 포함==

==TRANSFORM Flow Distributor==

==TRANSFORM 유량 배분기 전열 노드==

==Claude Code에 의해 프로비넌스가 정리된 테이블을 바탕으로 Gemini는 최종 수치 해석적 판단을 내린다. 단순화 고정값(*cp*​=1927 J/(kg⋅K))을 적용했을 때의 노심 피드백 반응도와 온도 세기 응답 편차를 확인하기 위해, '벤치마크 평가용 물성치 세트(Benchmark Property Set)'와 '최적 추정 물리 물성치 세트(Physical Best-Estimate Set)'로 모델 파라미터를 분리하여 시뮬레이션을 수행하도록 작업 지침을 생성한다.==   

==이 실증 사례는 데이터 수집부터 정리, 해석 방향 수정까지의 전체 연구 지식 흐름이 명확한 추적성(Traceability)을 확보한 상태에서 자동화될 수 있음을 증명한다.==

## ==결론 및 지식 관리 시스템의 확장성==

==본 연구에서 제시한 멀티 LLM 연동 오케스트레이션 및 최상위 연구 질문(RQ) 중심 구조는 단일 LLM을 사용할 때 발생하는 환각 문제와 DB 무결성 파손 문제를 근본적으로 해결한다. 각 LLM의 역할을 연구 감독(Gemini), 데이터 수집(GPT), DB 관리(Claude Code)로 명확히 분리하고, 옵시디언을 Local REST API 및 MCP 통신 기반의 SSOT로 채택함으로써 데이터 관리의 안정성과 유연성을 동시에 확보하였다.==   

==MSRE 연료염 물성치 관리 사례에서 입증된 바와 같이, 이 아키텍처는 고전 문헌 데이터와 현대 전산 코드 간의 불일치를 명확히 식별하고, 수용 여부를 엄격한 프로비넌스 매트릭스 하에서 결정론적으로 제어할 수 있게 한다.==   

==이러한 지식베이스 자동화 프레임워크는 MSRE 프로젝트에 국한되지 않으며, 독자적인 RQ 레이어를 상위에 자유롭게 교체 설정함으로써 다양한 원자력 공학 및 첨단 에너지 도메인으로 확장이 가능하다.==

==소형 모듈러 원자로(SMR) 개발 연구 분야에서는 가압경수로 기반 SMR의 피동 안전계통 검증, 자연순환 유량 특성 파라미터 및 계통 과도 응답 특성 데이터베이스 구축에 직접 활용될 수 있다. 고온가스로(HTGR) 열유체 해석 분야에서는 헬륨 기체 냉각재 물성치 식별, 흑연 피복 입자 연료(TRISO) 전열 특성 및 열붕괴율 프로비넌스 추적 연구에 적용 가능하다. 소듐고속로(SFR) 노심 해석 분야에서는 소듐-물 반응 화학 데이터, 액체 금속 열전도도 수식 검증 및 다중 물리 코드 연계 데이터 인덱싱에 차용할 수 있다.==

==결론적으로, 최상위 RQ 레이어를 중심에 두고 역할이 정밀히 분리된 멀티 LLM 시스템과 옵시디언 REST API/MCP 연동 기법을 도입하는 것은, 복잡한 독자 기술 생태계를 수용하고 지속 가능한 공학 지식베이스를 구축하는 데 있어 높은 안정성과 확장성을 제공하는 정석적인 시스템 프레임워크이다.==   

[image](https://mooseframework.inl.gov/virtual_test_bed/msr/msre/msre_sam_model.html)

**[mooseframework.inl.gov](https://mooseframework.inl.gov/virtual_test_bed/msr/msre/msre_sam_model.html)**

[Molten Salt Reactor Experiment MSRE SAM Modeling | VTB - MOOSE](https://mooseframework.inl.gov/virtual_test_bed/msr/msre/msre_sam_model.html)

[새 창에서 열기](https://mooseframework.inl.gov/virtual_test_bed/msr/msre/msre_sam_model.html) ([image](https://t0.gstatic.com/faviconV2?client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL&url=https%3A%2F%2Fmooseframework.inl.gov%2Fvirtual_test_bed%2Fmsr%2Fmsre%2Fmsre_sam_model.html))

[image](https://www.osti.gov/servlets/purl/1602185)

**[osti.gov](https://www.osti.gov/servlets/purl/1602185)**

[Status Report on the MSRE TRANSFORM Model for Thermal - OSTI](https://www.osti.gov/servlets/purl/1602185)

[새 창에서 열기](https://www.osti.gov/servlets/purl/1602185) ([image](https://t0.gstatic.com/faviconV2?client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL&url=https%3A%2F%2Fwww.osti.gov%2Fservlets%2Fpurl%2F1602185))

[image](https://www.osti.gov/servlets/purl/4492893)

**[osti.gov](https://www.osti.gov/servlets/purl/4492893)**

[RECEIVED BY OAK RIDGE NATIONAL LABORATORY ... - OSTI](https://www.osti.gov/servlets/purl/4492893)

[새 창에서 열기](https://www.osti.gov/servlets/purl/4492893) ([image](https://t0.gstatic.com/faviconV2?client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL&url=https%3A%2F%2Fwww.osti.gov%2Fservlets%2Fpurl%2F4492893))

[image](https://mooseframework.inl.gov/virtual_test_bed/msr/msre/msre_description.html)

**[mooseframework.inl.gov](https://mooseframework.inl.gov/virtual_test_bed/msr/msre/msre_description.html)**

[Molten Salt Reactor Experiment MSRE Description | VTB - MOOSE](https://mooseframework.inl.gov/virtual_test_bed/msr/msre/msre_description.html)

[새 창에서 열기](https://mooseframework.inl.gov/virtual_test_bed/msr/msre/msre_description.html) ([image](https://t0.gstatic.com/faviconV2?client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL&url=https%3A%2F%2Fmooseframework.inl.gov%2Fvirtual_test_bed%2Fmsr%2Fmsre%2Fmsre_description.html))

[image](https://en.wikipedia.org/wiki/Molten-Salt_Reactor_Experiment)

**[en.wikipedia.org](https://en.wikipedia.org/wiki/Molten-Salt_Reactor_Experiment)**

[Molten-Salt Reactor Experiment - Wikipedia](https://en.wikipedia.org/wiki/Molten-Salt_Reactor_Experiment)

[새 창에서 열기](https://en.wikipedia.org/wiki/Molten-Salt_Reactor_Experiment) ([image](https://t0.gstatic.com/faviconV2?client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL&url=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FMolten-Salt_Reactor_Experiment))

[image](https://github.com/coddingtonbear/obsidian-local-rest-api/releases)

**[github.com](https://github.com/coddingtonbear/obsidian-local-rest-api/releases)**

[Releases · coddingtonbear/obsidian-local-rest-api - GitHub](https://github.com/coddingtonbear/obsidian-local-rest-api/releases)

[새 창에서 열기](https://github.com/coddingtonbear/obsidian-local-rest-api/releases) ([image](https://t0.gstatic.com/faviconV2?client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL&url=https%3A%2F%2Fgithub.com%2Fcoddingtonbear%2Fobsidian-local-rest-api%2Freleases))

[image](https://community.obsidian.md/plugins/rest-api)

**[community.obsidian.md](https://community.obsidian.md/plugins/rest-api)**

[REST API - Obsidian Plugin](https://community.obsidian.md/plugins/rest-api)

[새 창에서 열기](https://community.obsidian.md/plugins/rest-api) ([image](https://t0.gstatic.com/faviconV2?client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL&url=https%3A%2F%2Fcommunity.obsidian.md%2Fplugins%2Frest-api))

[image](https://github.com/coddingtonbear/obsidian-local-rest-api)

**[github.com](https://github.com/coddingtonbear/obsidian-local-rest-api)**

[GitHub - coddingtonbear/obsidian-local-rest-api](https://github.com/coddingtonbear/obsidian-local-rest-api)

[새 창에서 열기](https://github.com/coddingtonbear/obsidian-local-rest-api) ([image](https://t0.gstatic.com/faviconV2?client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL&url=https%3A%2F%2Fgithub.com%2Fcoddingtonbear%2Fobsidian-local-rest-api))

[image](https://www.buildthisnow.com/blog/guide/development/claude-code-headless-mode)

**[buildthisnow.com](https://www.buildthisnow.com/blog/guide/development/claude-code-headless-mode)**

[Claude Code Headless Mode | Build This Now](https://www.buildthisnow.com/blog/guide/development/claude-code-headless-mode)

[새 창에서 열기](https://www.buildthisnow.com/blog/guide/development/claude-code-headless-mode) ([image](https://t0.gstatic.com/faviconV2?client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL&url=https%3A%2F%2Fwww.buildthisnow.com%2Fblog%2Fguide%2Fdevelopment%2Fclaude-code-headless-mode))

[image](https://context7.com/coddingtonbear/obsidian-local-rest-api)

**[context7.com](https://context7.com/coddingtonbear/obsidian-local-rest-api)**

[Local REST API (coddingtonbear/obsidian-local-rest-api) | Context7](https://context7.com/coddingtonbear/obsidian-local-rest-api)

[새 창에서 열기](https://context7.com/coddingtonbear/obsidian-local-rest-api) ([image](https://t0.gstatic.com/faviconV2?client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL&url=https%3A%2F%2Fcontext7.com%2Fcoddingtonbear%2Fobsidian-local-rest-api))

[image](https://github.com/elizaOS/eliza/issues/3503)

**[github.com](https://github.com/elizaOS/eliza/issues/3503)**

[Help with Obsidian Plugin · Issue #3503 · elizaOS/eliza - GitHub](https://github.com/elizaOS/eliza/issues/3503)

[새 창에서 열기](https://github.com/elizaOS/eliza/issues/3503) ([image](https://t0.gstatic.com/faviconV2?client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL&url=https%3A%2F%2Fgithub.com%2FelizaOS%2Feliza%2Fissues%2F3503))

[image](https://github.com/openmsr/msr-archive/blob/master/ocr/ORNL-4865.txt)

**[github.com](https://github.com/openmsr/msr-archive/blob/master/ocr/ORNL-4865.txt)**

[msr-archive/ocr/ORNL-4865.txt at master - GitHub](https://github.com/openmsr/msr-archive/blob/master/ocr/ORNL-4865.txt)

[새 창에서 열기](https://github.com/openmsr/msr-archive/blob/master/ocr/ORNL-4865.txt) ([image](https://t0.gstatic.com/faviconV2?client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL&url=https%3A%2F%2Fgithub.com%2Fopenmsr%2Fmsr-archive%2Fblob%2Fmaster%2Focr%2FORNL-4865.txt))

[image](https://publish.obsidian.md/hub/02+-+Community+Expansions/02.05+All+Community+Expansions/Plugins/obsidian-local-rest-api)

[새 창에서 열기](https://publish.obsidian.md/hub/02+-+Community+Expansions/02.05+All+Community+Expansions/Plugins/obsidian-local-rest-api) ([image](https://t1.gstatic.com/faviconV2?url=https://publish.obsidian.md/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))

[image](https://github.com/coddingtonbear/obsidian-local-rest-api/blob/main/package.json)

[새 창에서 열기](https://github.com/coddingtonbear/obsidian-local-rest-api/blob/main/package.json) ([image](https://t1.gstatic.com/faviconV2?url=https://github.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))

[image](https://coddingtonbear.github.io/obsidian-local-rest-api/)

[새 창에서 열기](https://coddingtonbear.github.io/obsidian-local-rest-api/) ([image](https://t2.gstatic.com/faviconV2?url=https://coddingtonbear.github.io/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))

[image](https://obsidianvaulthub.com/plugins/obsidian-local-rest-api)

[새 창에서 열기](https://obsidianvaulthub.com/plugins/obsidian-local-rest-api) ([image](https://t1.gstatic.com/faviconV2?url=https://obsidianvaulthub.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))

[image](https://github.com/coddingtonbear/obsidian-local-rest-api/discussions/132)

[새 창에서 열기](https://github.com/coddingtonbear/obsidian-local-rest-api/discussions/132) ([image](https://t1.gstatic.com/faviconV2?url=https://github.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))

[image](https://www.mindstudio.ai/blog/claude-code-headless-mode-autonomous-agents)

[새 창에서 열기](https://www.mindstudio.ai/blog/claude-code-headless-mode-autonomous-agents) ([image](https://t1.gstatic.com/faviconV2?url=https://www.mindstudio.ai/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))

[image](https://www.ans.org/news/2026-05-19/article-8053/ornl-completes-challenging-molten-salt-property-measurements/)

[새 창에서 열기](https://www.ans.org/news/2026-05-19/article-8053/ornl-completes-challenging-molten-salt-property-measurements/) ([image](https://t0.gstatic.com/faviconV2?url=https://www.ans.org/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))

[image](https://moltensalt.org/references/static/downloads/pdf/)

[새 창에서 열기](https://moltensalt.org/references/static/downloads/pdf/) ([image](https://t3.gstatic.com/faviconV2?url=https://moltensalt.org/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))

[image](https://moltensalt.org/references/static/downloads/pdf/ORNL-TM-4174.pdf)

[새 창에서 열기](https://moltensalt.org/references/static/downloads/pdf/ORNL-TM-4174.pdf) ([image](https://t3.gstatic.com/faviconV2?url=https://moltensalt.org/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))

[image](https://www.gstatic.com/lamda/images/immersives/google_logo_icon_2380fba942c84387f09cf.svg)

[image](https://context7.com/coddingtonbear/obsidian-local-rest-api)

([image](https://t2.gstatic.com/faviconV2?url=https://context7.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://publish.obsidian.md/hub/02+-+Community+Expansions/02.05+All+Community+Expansions/Plugins/obsidian-local-rest-api)

([image](https://t1.gstatic.com/faviconV2?url=https://publish.obsidian.md/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://community.obsidian.md/plugins/rest-api)

([image](https://t2.gstatic.com/faviconV2?url=https://community.obsidian.md/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://github.com/coddingtonbear/obsidian-local-rest-api/blob/main/package.json)

([image](https://t1.gstatic.com/faviconV2?url=https://github.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://coddingtonbear.github.io/obsidian-local-rest-api/)

([image](https://t2.gstatic.com/faviconV2?url=https://coddingtonbear.github.io/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://github.com/coddingtonbear/obsidian-local-rest-api)

([image](https://t1.gstatic.com/faviconV2?url=https://github.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://obsidianvaulthub.com/plugins/obsidian-local-rest-api)

([image](https://t1.gstatic.com/faviconV2?url=https://obsidianvaulthub.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://github.com/coddingtonbear/obsidian-local-rest-api/releases)

([image](https://t1.gstatic.com/faviconV2?url=https://github.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://github.com/elizaOS/eliza/issues/3503)

([image](https://t1.gstatic.com/faviconV2?url=https://github.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://github.com/coddingtonbear/obsidian-local-rest-api/discussions/132)

([image](https://t1.gstatic.com/faviconV2?url=https://github.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://www.buildthisnow.com/blog/guide/development/claude-code-headless-mode)

([image](https://t0.gstatic.com/faviconV2?url=https://www.buildthisnow.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://www.mindstudio.ai/blog/claude-code-headless-mode-autonomous-agents)

([image](https://t1.gstatic.com/faviconV2?url=https://www.mindstudio.ai/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))

[image](https://www.gstatic.com/lamda/images/immersives/google_logo_icon_2380fba942c84387f09cf.svg)

[image](https://mooseframework.inl.gov/virtual_test_bed/msr/msre/msre_sam_model.html)

([image](https://t0.gstatic.com/faviconV2?url=https://mooseframework.inl.gov/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://mooseframework.inl.gov/virtual_test_bed/msr/msre/msre_description.html)

([image](https://t0.gstatic.com/faviconV2?url=https://mooseframework.inl.gov/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://en.wikipedia.org/wiki/Molten-Salt_Reactor_Experiment)

([image](https://t2.gstatic.com/faviconV2?url=https://en.wikipedia.org/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://www.osti.gov/servlets/purl/1602185)

([image](https://t2.gstatic.com/faviconV2?url=https://www.osti.gov/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://www.osti.gov/servlets/purl/4492893)

([image](https://t2.gstatic.com/faviconV2?url=https://www.osti.gov/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://www.ans.org/news/2026-05-19/article-8053/ornl-completes-challenging-molten-salt-property-measurements/)

([image](https://t0.gstatic.com/faviconV2?url=https://www.ans.org/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://moltensalt.org/references/static/downloads/pdf/)

([image](https://t3.gstatic.com/faviconV2?url=https://moltensalt.org/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://github.com/openmsr/msr-archive/blob/master/ocr/ORNL-4865.txt)

([image](https://t1.gstatic.com/faviconV2?url=https://github.com/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))[image](https://moltensalt.org/references/static/downloads/pdf/ORNL-TM-4174.pdf)

([image](https://t3.gstatic.com/faviconV2?url=https://moltensalt.org/&client=BARD&type=FAVICON&size=256&fallback_opts=TYPE,SIZE,URL))

최종 안내 준비