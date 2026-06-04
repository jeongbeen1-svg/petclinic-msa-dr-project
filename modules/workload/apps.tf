# modules/workload/apps.tf

# 1. 펫클리닉 애플리케이션들을 담을 독립된 네임스페이스 생성
resource "kubernetes_namespace" "petclinic" {
  metadata {
    name = "petclinic"
  }
}

# 2. 배포할 마이크로서비스 목록 정의
locals {
  petclinic_services = toset([
    "config-server",
    "discovery-server",
    "api-gateway",
    "admin-server",
    "customers-service",
    "vets-service",
    "visits-service",
    "genai-service"
  ])
  
  ecr_registry = "906336681755.dkr.ecr.ap-northeast-2.amazonaws.com"
}

# 3. 헬름을 통한 일괄 배포 (공통 차트나 큐브 공식 차트가 없을 경우, 쿠버네티스 표준 마이크로서비스 형태 배포)
# 테스트용 및 범용으로 가장 많이 쓰이는 oci 기반 헬름 기본 템플릿(정석은 본인 헬름차트나 k8s_manifest 사용)
# 여기서는 이해를 돕기 위해 쿠버네티스 네이티브 리소스로 선언적인 배포 예시를 작성합니다.

resource "kubernetes_deployment_v1" "petclinic" {
  for_each = local.petclinic_services

  metadata {
    name      = each.value
    namespace = kubernetes_namespace.petclinic.metadata[0].name
    labels = {
      app = each.value
    }
  }

  spec {
    replicas = 1 # 처음엔 1대로 시작하고, 나중에 카펜터+HPA 연동 시 유연하게 조절

    selector {
      match_labels = {
        app = each.value
      }
    }

    template {
      metadata {
        labels = {
          app = each.value
        }
      }

      spec {
        container {
          image = "${local.ecr_registry}/petclinic_msa_1:${each.value}"
          name  = each.value

          # 스프링 부트 애플리케이션 내부 포트 (기본 구조에 맞춰 포트 포워딩 세팅 필요)
          port {
            container_port = each.value == "api-gateway" ? 8080 : (each.value == "config-server" ? 8888 : 8082) 
          }

          # 시스템 자원 할당 (카펜터가 이 값을 보고 노드를 동적으로 띄웁니다!)
          resources {
            limits = {
              cpu    = "500m"
              memory = "768Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }

          # Spring Cloud MSA 환경을 위한 환경 변수 주입 주석 예시
          env {
            name  = "SPRING_PROFILES_ACTIVE"
            value = "docker"
          }
        }
      }
    }
  }
}

# 4. 내부 통신을 위한 쿠버네티스 서비스(ClusterIP) 생성
resource "kubernetes_service_v1" "petclinic" {
  for_each = local.petclinic_services

  metadata {
    name      = each.value
    namespace = kubernetes_namespace.petclinic.metadata[0].name
  }

  spec {
    selector = {
      app = each.value
    }

    # 예시: apps.tf 내의 deployment와 service 포트 지정 부분 수정
  port {
    port = each.value == "api-gateway" ? 8080 : (
         each.value == "config-server" ? 8888 : (
         each.value == "discovery-server" ? 8761 : 8082)
  )
    target_port = each.value == "api-gateway" ? 8080 : (
                each.value == "config-server" ? 8888 : (
                each.value == "discovery-server" ? 8761 : 8082)
  )
}

    type = "ClusterIP" # 내부 통신용, 나중에 최외곽 api-gateway만 Ingress나 ALB로 노출
  }
}