# 펫클리닉 애플리케이션들을 담을 독립된 네임스페이스 생성
resource "kubernetes_namespace" "petclinic" {
  metadata {
    name = "petclinic"
  }
}

# 배포 리소스 정의
resource "kubernetes_deployment_v1" "petclinic" {
  for_each = local.petclinic_services

  metadata {
    name      = each.value
    namespace = kubernetes_namespace.petclinic.metadata[0].name
    labels = { app = each.value }
  }

  spec {
    replicas = 1
    selector { match_labels = { app = each.value } }

    template {
      metadata { labels = { app = each.value } }

      spec {
        container {
          image = "${local.ecr_registry}/petclinic_msa_1:${each.value}"
          name  = each.value

          # 포트 설정
          port {
            container_port = each.value == "api-gateway" ? 8080 : (each.value == "config-server" ? 8888 : 8082)
          }

          # 공통 환경 변수
          env {
            name  = "SPRING_PROFILES_ACTIVE"
            value = "docker"
          }

          dynamic "env" {
            for_each = each.value == "genai-service" ? [1] : []
            content {
              name  = "SPRING_AI_OPENAI_API_KEY"
              value_from {
                secret_key_ref {
                  name = kubernetes_secret.genai_secrets.metadata[0].name
                  key  = "SPRING_AI_OPENAI_API_KEY"
                }
              }
            }
          }

          dynamic "env" {
            for_each = each.value == "genai-service" ? [1] : []
            content {
              name  = "SPRING_AI_OPENAI_BASE_URL"
              value = "https://api.groq.com/openai"
            }
          }
          # ... 기존 env 설정 아래에 추가 ...
          dynamic "env" {
            for_each = each.value == "genai-service" ? [1] : []
            content {
              name  = "SPRING_AI_OPENAI_CHAT_OPTIONS_MODEL"
              value = "llama-3.3-70b-versatile"
            }
          }
          
        }
      }
    }
  }
}

# AI 사용을 위한 시크릿 생성
resource "kubernetes_secret" "genai_secrets" {
  metadata {
    name      = "genai-secrets"
    namespace = kubernetes_namespace.petclinic.metadata[0].name
  }

  data = {
    "SPRING_AI_OPENAI_API_KEY" = "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"
  }

  type = "Opaque"
}


# 내부 통신을 위한 쿠버네티스 서비스(ClusterIP) 생성
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

    type = "ClusterIP"
  }
}