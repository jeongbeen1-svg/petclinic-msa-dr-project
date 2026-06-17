# 네임스페이스를 별도 리소스로 정의
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm" # 아르고 공식 헬름 창고 주소
  chart            = "argo-cd"                              # 설치할 패키지 이름
  version          = "7.1.3"                                # 원하는 아르고 버전 콕 집기
  # namespace        = "argocd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false

  # 서버 자원 부족을 예방하기 위한 헬름 전용 옵션
  # 배포 단계에서 자원이 살짝 정체되더라도 테라폼이 10분간 기다려주도록 타임아웃을 늘려줌
  timeout = 600

  # 강제 업데이트 및 재설치 옵션
  force_update  = true
  recreate_pods = true # 기존 Pod 재생성
  wait          = true # 배포 완료 대기

  # EKS 컴퓨터 노드 그룹(workload)이 100% 켜진 다음에 헬름 진입하도록 통제
  depends_on = [
    module.workload
    kubernetes_namespace.argocd
  ]
}


# resource "helm_release" "karpenter" {
#   name             = "karpenter"
#   repository       = "oci://public.ecr.aws/karpenter"
#   chart            = "karpenter"
#   version          = "1.0.0" # 설치하려는 정확한 버전으로 변경하세요
#   namespace        = "karpenter"
#   create_namespace = true

#   # values 블록을 사용하여 설정을 한 번에 전달 (오류 방지)
#   values = [
#     yamlencode({
#       settings = {
#         clusterName = module.workload.cluster_name
#       }
#       serviceAccount = {
#         annotations = {
#           "eks.amazonaws.com/role-arn" = module.workload.karpenter_controller_role_arn
#         }
#       }
#     })
#   ]

#   depends_on = [module.workload]
# }

# workload/autoscaler.tf

resource "kubernetes_namespace" "kube_system" {
  metadata {
    name = "kube-system"
  }
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.37.0"
  # namespace  = "kube-system"
  namespace  = kubernetes_namespace.kube_system.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      autoDiscovery = {
        clusterName = module.workload.cluster_name
      }
      awsRegion = "ap-northeast-2"
      rbac = {
        serviceAccount = {
          create = true
          name   = "cluster-autoscaler"
          annotations = {
            # 여기서 직접 IAM Role의 ARN을 주입합니다.
            # 모듈 호출 단계를 거치지 않고 리소스에서 직접 가져오면 확실합니다.
            "eks.amazonaws.com/role-arn" = module.workload.ca_role_arn
          }
        }
      }
      extraArgs = {
        "balance-similar-node-groups"   = true
        "skip-nodes-with-system-pods"   = false
        "v"                             = 4
        "stderrthreshold"               = "info"
        "cloud-provider"                = "aws"
        "skip-nodes-with-local-storage" = false
        "expander"                      = "least-waste"
        # 테스트용 속도 개선 옵션
        "scan-interval"                    = "10s"
        "scale-down-unneeded-time"         = "1m"
        "scale-down-delay-after-add"       = "1m"
        "scale-down-utilization-threshold" = "0.5"
      }

    })
  ]

  depends_on = [
    module.workload
    kubernetes_namespace.kube_system
  ]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  # namespace  = "kube-system"
  namespace  = kubernetes_namespace.kube_system.metadata[0].name
  version    = "3.12.0"
  create_namespace = false

  # values 속성을 사용하여 설정을 YAML 형식으로 정의
  values = [
    <<-EOF
    args:
      - --kubelet-insecure-tls
    EOF
  ]

  depends_on = [
    module.workload
    kubernetes_namespace.kube_system
  ]
}

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  # namespace        = "external-secrets"
  namespace        = kubernetes_namespace.external_secrets.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      installCRDs = true
      serviceAccount = {
        create = true
        name   = "external-secrets-sa"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.workload.iam_role_arn
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.external_secrets]
}