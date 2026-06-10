output "module" {
  value = {
    network = module.network
    # platform = module.platform
    workload = module.workload
  }
}

# Karpenter 컨트롤러 ARN 노출
output "karpenter_controller_role_arn" {
  value = aws_iam_role.karpenter_controller.arn
}
output "ca_role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn
}

output "node_group_name" {
  value = aws_eks_node_group.system.id
}