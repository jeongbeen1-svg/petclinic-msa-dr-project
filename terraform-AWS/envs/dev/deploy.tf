resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm" # 아르고 공식 헬름 창고 주소
  chart            = "argo-cd"                              # 설치할 패키지 이름
  version          = "7.1.3"                                # 원하는 아르고 버전 콕 집기
  namespace        = "argocd"
  create_namespace = true # 방(Namespace)이 없으면 헬름이 알아서 자동으로 만들도록 지시

  # 서버 자원 부족을 예방하기 위한 헬름 전용 옵션
  # 노드 그룹 생성 직후 Pod 스케줄링과 Helm hook이 안정화될 시간을 넉넉히 둠
  timeout       = 1200
  wait_for_jobs = true

  # 강제 업데이트 및 재설치 옵션
  force_update    = true
  recreate_pods   = true # 기존 Pod 재생성
  cleanup_on_fail = true
  wait            = true # 배포 완료 대기

  # EKS 컴퓨터 노드 그룹(workload)이 100% 켜진 다음에 헬름 진입하도록 통제
  depends_on = [module.workload]
}
