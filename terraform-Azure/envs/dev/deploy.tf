resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.1.3"
  namespace        = "argocd"
  create_namespace = true

  timeout = 600

  depends_on = [module.workload]
}
