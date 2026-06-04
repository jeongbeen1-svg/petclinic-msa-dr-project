resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm" # 아르고 공식 헬름 창고 주소
  chart            = "argo-cd"                              # 설치할 패키지 이름
  version          = "7.1.3"                                # 원하는 아르고 버전 콕 집기
  namespace        = "argocd"
  create_namespace = true # 방(Namespace)이 없으면 헬름이 알아서 자동으로 만들도록 지시

  # 서버 자원 부족을 예방하기 위한 헬름 전용 옵션
  # 배포 단계에서 자원이 살짝 정체되더라도 테라폼이 10분간 기다려주도록 타임아웃을 늘려줌
  timeout = 600

  # EKS 컴퓨터 노드 그룹(workload)이 100% 켜진 다음에 헬름 진입하도록 통제
  depends_on = [module.workload]
}