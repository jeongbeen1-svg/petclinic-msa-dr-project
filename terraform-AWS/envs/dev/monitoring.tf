# # 1. 네임스페이스 생성
# resource "kubernetes_namespace" "whatap" {
#   metadata { name = "whatap-monitoring" }
# }

# # 2. 자격증명 시크릿 (라이선스 키만 여기에 변수로 넣으세요)
# resource "kubernetes_secret" "whatap_credentials" {
#   metadata {
#     name      = "whatap-credentials"
#     namespace = kubernetes_namespace.whatap.metadata[0].name
#   }
#   data = {
#     WHATAP_LICENSE = var.whatap_license # variables.tf에 정의
#     WHATAP_HOST    = "13.124.11.223/13.209.172.35"
#     WHATAP_PORT    = "6600"
#   }
# }

# # 3. 와탭 오퍼레이터 설치 (Helm)
# resource "helm_release" "whatap_operator" {
#   name       = "whatap-operator"
#   repository = "https://whatap.github.io/helm"
#   chart      = "whatap-operator"
#   namespace  = kubernetes_namespace.whatap.metadata[0].name
#   depends_on = [kubernetes_namespace.whatap]
# }