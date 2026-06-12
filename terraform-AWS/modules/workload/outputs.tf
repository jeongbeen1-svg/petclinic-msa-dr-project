output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_ca" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "node_security_group_id" {
  value = aws_security_group.eks_nodes.id
}

output "bastion_security_group_id" {
  value = aws_security_group.bastion_sg.id
}

output "bastion_role_arn" {
  value = aws_iam_role.bastion_role.arn
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
