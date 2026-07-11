# ☁️ Spring PetClinic 기반 클라우드 인프라 자동화 & DR 구축 프로젝트

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)

> 단일 클라우드 장애 시에도 서비스 연속성을 보장하기 위해, AWS를 Active 리전으로, Azure를 Warm Standby 리전으로 구성한 멀티클라우드 DR(재해복구) 아키텍처 구축 프로젝트입니다. 4인 팀 프로젝트로 진행했으며, **EKS·애플리케이션 배포**를 담당했습니다.

---

## 📋 목차

- [프로젝트 개요](#-프로젝트-개요)
- [아키텍처 설계](#-아키텍처-설계-architecture)
- [단계별 구축 과정](#-단계별-구축-과정-implementation-steps)
- [부하 테스트 및 오토스케일링 튜닝](#-부하-테스트-및-오토스케일링-튜닝)
- [보안 및 관리 전략](#-보안-및-관리-전략)
- [프로젝트 성과 및 배운 점](#-프로젝트-성과-및-배운-점)
- [트러블슈팅](#-트러블슈팅)
- [팀 구성](#-팀-구성)

---

## 📌 프로젝트 개요

Spring PetClinic 애플리케이션을 기반으로, **AWS Active + Azure Warm Standby** 구조의 멀티클라우드 DR 아키텍처를 설계 및 구축했습니다. 특정 클라우드 리전 또는 프로바이더 전체 장애 상황에서도 서비스 중단을 최소화하는 것을 목표로, IaC 기반 인프라 자동화와 GitOps 기반 배포 파이프라인을 함께 구축했습니다.

| 항목 | 내용 |
|---|---|
| **목표 SLA** | 99.95% |
| **RTO (목표 복구 시간)** | 2~4시간 |
| **RPO (목표 복구 시점)** | 1분 이내 |
| **팀 구성** | 4인 팀 |
| **담당 영역** | EKS 클러스터 구성 및 애플리케이션(APP) 배포 |
| **Primary Region** | AWS `ap-northeast-2` (Seoul) |

---

## 🏗 아키텍처 설계 (Architecture)
<img width="721" height="733" alt="최종프로젝트 아키텍처 다이어그램" src="https://github.com/user-attachments/assets/20be33cd-e988-4e33-86d4-1b7675014207" />


### Key Architectural Decisions

- **트래픽 진입 및 DR 전환**: Route53 → CloudFront를 통해 AWS(Active)로 우선 라우팅하고, 장애 시 Azure(DR)로 Failover. CloudFront 오류 발생 시 S3 정적 페이지로 즉시 대체 응답
- **Active-Standby 멀티클라우드 구조**: AWS EKS가 운영 트래픽을 처리하고, Azure(AKS·Application)는 Warm Standby로 최소 리소스 상태를 유지하다 장애 시 전환
- **네트워크 격리**: 서비스(EKS/Application)·DB는 Private Subnet에 배치, Bastion·NAT만 통해 관리 접근 허용. AWS ↔ Azure 간은 Site-to-Site VPN으로 연결
- **시크릿 및 인증서 관리**: AWS Secrets Manager·ACM, Azure Key Vault로 클라우드별 민감정보를 분리 관리하고, Terraform State는 S3로 중앙화
- **DB 실시간 복제 (AWS DMS CDC)**: RDS(Aurora)와 Azure MySQL Flexible Server 간 CDC 방식 실시간 복제로 **RPO 1분 이내** 달성
- **통합 모니터링**: CloudWatch Container Insights(AWS)와 Whatap(클러스터 전반)으로 메트릭을 수집해 오토스케일링 정책 튜닝의 근거로 활용

---

## 🛠 단계별 구축 과정 (Implementation Steps)

### STEP 1. IaC 기반 인프라 설계 (Terraform)

- AWS/Azure 양쪽 클라우드 인프라를 Terraform으로 코드화하여 재현 가능한 환경 구성
- `tfvars` 구조화 및 민감 변수(Sensitive Variables) 분리, CI/CD 파이프라인에서의 `-input=false` 옵션 적용

### STEP 2. EKS 클러스터 구성 및 애플리케이션 배포 (AWS – 담당 영역)

- EKS 클러스터 구성 및 kubeconfig/SSM 세션 기반 접근 환경 구축
- IAM Access Entry 기반 클러스터 접근 권한 관리
- Spring PetClinic 마이크로서비스(api-gateway, visits, genai 등)를 ECR 이미지 기반으로 EKS에 배포
- `amazon-cloudwatch-observability` EKS Addon을 통한 Container Insights 연동

### STEP 3. AKS 클러스터 구성 (Azure Warm Standby)

- Azure Kubernetes Service(AKS)에 동일한 PetClinic 애플리케이션을 Warm Standby 형태로 배포
- config-server의 Git 참조 브랜치 이슈(`"azure"` → `"main"`) 수정으로 설정값 정상 동기화
- `deploy-azure-db.sh` 스크립트와 `envsubst`를 활용해 Azure Key Vault의 시크릿을 배포 매니페스트에 주입
- Azure MySQL Flexible Server 연동

### STEP 4. GitOps 파이프라인 구축 (ArgoCD)

- GitHub Actions로 IaC 기반 인프라 구축 및 배포 자동화 
- ArgoCD를 통해 매니페스트 업데이트 자동화 및 배포

### STEP 5. 데이터 복제 및 트래픽 전환 구성

- AWS DMS를 이용한 CDC 기반 실시간 DB 복제 파이프라인 구성 (RPO ≤ 1분)
- Route53 가중치 라우팅 및 장애조치(Failover) 라우팅 정책 구성 및 검증

---

## 📈 부하 테스트 및 오토스케일링 튜닝

JMeter를 활용해 EKS 환경에서 반복적인 부하 테스트를 수행하며 HPA(Horizontal Pod Autoscaler) 및 Cluster Autoscaler(CA) 정책을 데이터 기반으로 튜닝했습니다.

| 서비스 | Min | Max | CPU 임계치 |
|---|---|---|---|
| `api-gateway` | 3 | 6 | 60% |
| `visits` | 2 | 5 | 70% |
| `genai` | 1 | 5 | 70% |

- **부하 테스트 결과**: 500 동시 사용자 / 590TPS 기준 노드 스펙 `m5.large`로 확정
- **오류율 개선**: 반복 튜닝을 통해 오류율 **약 7% → 약 4%**로 감소
- **RDS 인스턴스 선정**: `t3.medium`이 500 동시 사용자까지 안정적으로 대응함을 부하 테스트로 검증
- **HikariCP 커넥션 풀**: pool-size `20`으로 튜닝하여 DB 커넥션 병목 완화

---

## 🚨 보안 및 관리 전략

- **ESO(External Secrets Operator) + IRSA**: AWS Secrets Manager의 시크릿을 IAM Role for Service Account(IRSA) 기반으로 안전하게 EKS 파드에 주입
- **Azure Key Vault 연동**: Azure 측 민감 정보는 Key Vault에서 관리하고 배포 시점에 동적으로 주입
- **AWS 자격 증명 노출 대응**: 프로젝트 진행 중 실제 AWS Credential 노출 사고가 발생하여, 즉시 키 로테이션(Key Rotation)을 수행하고 Git 히스토리에서 민감 정보를 제거한 클린 저장소로 재구성

---

## 📊 프로젝트 성과 및 배운 점

- **DR 아키텍처 실증**: AWS Active 리전 장애를 가정한 시나리오에서 Route53 Failover를 통한 Azure Standby 전환 검증
- **RPO 1분 이내 달성**: DMS CDC 기반 실시간 복제로 이기종 클라우드 DB 간 데이터 정합성 확보
- **데이터 기반 오토스케일링**: 부하 테스트 결과를 근거로 서비스별 HPA 정책을 차등 설계하여 오류율 개선
- **CI/CD 운영 경험**: ArgoCD를 통한 선언적 배포 관리로 애플리케이션 매니페스트 업데이트 자동화
- **보안 사고 대응 경험**: 실제 자격 증명 노출 사고를 직접 대응하며 시크릿 관리와 Git 히스토리 정리의 중요성을 체득

---

## 🔧 트러블슈팅

- Terraform teardown 시 AWS/Azure 양측 데이터 소스 조회 실패 및 State Lock 이슈 디버깅
- Azure Provider 인증 누락 시 `localhost`로 폴백되는 이슈 원인 분석 및 해결
- config-server의 프로파일 브랜치 참조 오류로 인한 설정값 미반영 문제 해결
- Git 브랜치 히스토리 재작성을 통한 민감 정보(Credential) 완전 제거

---

## 👥 팀 구성

- 4인 팀 프로젝트
- 본인 담당: **EKS 클러스터 구성 및 애플리케이션(APP) 배포**

---
## 🔗 관련 리포지토리
- [config-server (fork)]([깃허브링크](https://github.com/jeongbeen1-svg/spring-petclinic-microservices-config)) — APP config-server 연동을 위해 프로파일 브랜치 구조 수정
- [k8s manifests / GitOps]([깃허브링크](https://github.com/jeongbeen1-svg/dr-project-application)) — EKS/AKS 배포 매니페스트, ArgoCD Application 정의

## 🔗🔗 관련 링크

- GitHub Organization: `bespin-multi-cloud-3-aws`
- 상세 구축 로그 및 포트폴리오: [Notion 바로가기]([https://giddy-dryer-b71.notion.site/395fb705849380a1a2d1ec683ac19df9](https://giddy-dryer-b71.notion.site/36cfb705849380a0aa58f1173239d09f?pvs=74))
