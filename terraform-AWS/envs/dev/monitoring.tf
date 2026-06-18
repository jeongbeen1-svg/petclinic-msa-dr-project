# 1. 네임스페이스 생성
resource "kubernetes_namespace" "whatap" {
  metadata { name = "whatap-monitoring" }
}

# 2. 자격증명 시크릿
resource "kubernetes_secret" "whatap_credentials" {
  metadata {
    name      = "whatap-credentials"
    namespace = kubernetes_namespace.whatap.metadata[0].name
  }
  data = {
    WHATAP_LICENSE = var.whatap_license
    WHATAP_HOST    = "13.124.11.223/13.209.172.35"
    WHATAP_PORT    = "6600"
  }
}

# 3. 와탭 오퍼레이터 설치 (Helm)
resource "helm_release" "whatap_operator" {
  name       = "whatap-operator"
  repository = "https://whatap.github.io/helm"
  chart      = "whatap-operator"
  namespace  = kubernetes_namespace.whatap.metadata[0].name
  depends_on = [kubernetes_namespace.whatap]
}

# 💡 4. kubectl_manifest를 통한 무검증 다이렉트 주입 (자동화 핵심)
resource "kubectl_manifest" "whatap_agent" {
  yaml_body = <<YAML
apiVersion: "monitoring.whatap.com/v2alpha1"
kind: "WhatapAgent"
metadata:
  labels:
    app.kubernetes.io/managed-by: "whatap-operator"
    app.kubernetes.io/name: "whatap"
  name: "whatap"
  namespace: "whatap-monitoring"
spec:
  secretName: "whatap-credentials"
  features:
    k8sAgent:
      customAgentImageFullName: "public.ecr.aws/whatap/kube_mon:1.8.7"
      gpuMonitoring:
        enabled: false
      masterAgent:
        enabled: true
      nodeAgent:
        enabled: true
        runtime: "containerd"
        runtimeSocketPath: "/var/run/containerd/containerd.sock"
YAML

  # 헬름 오퍼레이터가 완벽히 안착한 후 배포되도록 강제 보장
  depends_on = [helm_release.whatap_operator]
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name = module.workload.cluster_name
  addon_name   = "amazon-cloudwatch-observability"

  depends_on = [
    module.workload
  ]

  tags = merge(local.common_tags, {
    Name = "${module.workload.cluster_name}-cloudwatch-observability"
  })
}

resource "aws_cloudwatch_dashboard" "integrated_monitoring_dashboard" {
  dashboard_name = "${module.workload.cluster_name}-Integrated-Operations-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ============================================================
      # [PAGE 1 - 종합 서비스 헬스케어 & 관제 레이어 (y=0)]
      # ============================================================
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{AWS/Route53,HealthCheckId} MetricName=\"HealthCheckStatus\"', 'Average', 60)", "label": "DNS: &&-SCHEMA-REPLACEMENT-&&", "id": "dns1" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🔥 1-1. DNS (Route 53) Health Check Status (1=Healthy, 0=Unhealthy)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_Target_5XX_Count\"', 'Sum', 60)", "label": "ALB 5XX: &&-SCHEMA-REPLACEMENT-&&", "id": "alb5xx", "color": "#d62728" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🔥 1-2. ALB Target 5XX Error Rate (Critical Alert Trigger)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{ContainerInsights,ClusterName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"cluster_failed_node_count\"', 'Maximum', 60)", "label": "Failed Nodes", "id": "k8sfail", "color": "#ff7f0e" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🔥 1-3. EKS Cluster Failed Node Count (Cluster Health)"
          view   = "timeSeries"
        }
      },

      # ============================================================
      # [PAGE 2 - Ingress ALB & EKS 인프라 레이어 (y=6)]
      # ============================================================
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{AWS/ApplicationELB,TargetGroup} MetricName=\"HealthyHostCount\"', 'Average', 60)", "label": "🟢 Healthy: &&-SCHEMA-REPLACEMENT-&&", "id": "h1" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🎯 2-1. Ingress Auto-Generated Targets: Healthy Host Count"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{AWS/ApplicationELB,TargetGroup} MetricName=\"UnHealthyHostCount\"', 'Average', 60)", "label": "🔴 UnHealthy: &&-SCHEMA-REPLACEMENT-&&", "id": "uh1", "color": "#d62728" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🎯 2-2. Ingress Auto-Generated Targets: UnHealthy Host Count"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"RequestCount\"', 'Sum', 60)", "label": "Requests: &&-SCHEMA-REPLACEMENT-&&", "id": "req1" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "📈 2-3. Ingress ALB Total Request Count (Traffic Rate)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{AWS/ApplicationELB,TargetGroup} MetricName=\"TargetResponseTime\"', 'Average', 60)", "label": "Latency: &&-SCHEMA-REPLACEMENT-&&", "id": "latency1" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "⏱️ 2-4. Target Response Time per Auto-Generated Ingress Group (Average)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{ContainerInsights,ClusterName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"node_cpu_utilization\"', 'Average', 60)", "label": "Node CPU: &&-SCHEMA-REPLACEMENT-&&", "id": "ncpu" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "☸️ 2-5. EKS Worker Nodes CPU Utilization (%)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{ContainerInsights,ClusterName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"node_memory_utilization\"', 'Average', 60)", "label": "Node Mem: &&-SCHEMA-REPLACEMENT-&&", "id": "nmem" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "☸️ 2-6. EKS Worker Nodes Memory Utilization (%)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 24
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{ContainerInsights,ClusterName,Namespace} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"pod_number_of_container_restarts\"', 'Sum', 60)", "label": "Restart Count: &&-SCHEMA-REPLACEMENT-&&", "id": "podrest", "color": "#1f77b4" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "☸️ 2-7. EKS Pod Container Restart Count (Detecting CrashLoopBackOff)"
          view   = "timeSeries"
        }
      },

      # ============================================================
      # [PAGE 3 - 애플리케이션 성능 및 DB 레이어 (y=30)]
      # ============================================================
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{ContainerInsights,ClusterName,Namespace,PodName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"pod_cpu_utilization\"', 'Average', 60)", "label": "Pod CPU: &&-SCHEMA-REPLACEMENT-&&", "id": "pcpu" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🚀 3-1. Application Pods CPU Utilization (By Microservices)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 30
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{ContainerInsights,ClusterName,Namespace,PodName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"pod_memory_utilization\"', 'Average', 60)", "label": "Pod Mem: &&-SCHEMA-REPLACEMENT-&&", "id": "pmem" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🚀 3-2. Application Pods Memory Utilization (By Microservices)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 36
        width  = 8
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"CPUUtilization\"', 'Average', 60)", "label": "DB CPU: &&-SCHEMA-REPLACEMENT-&&", "id": "rdscpu" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🗄️ 3-3. Database (RDS) CPU Utilization (%)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 36
        width  = 8
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"DatabaseConnections\"', 'Average', 60)", "label": "Connections: &&-SCHEMA-REPLACEMENT-&&", "id": "rdsconn", "color": "#9467bd" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🗄️ 3-4. Database Connection Count (Connection Pool Monitor)"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 36
        width  = 8
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"ReplicationLag\"', 'Maximum', 60)", "label": "Lag Sec: &&-SCHEMA-REPLACEMENT-&&", "id": "rdslag", "color": "#e377c2" } ]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🗄️ 3-5. RDS Cross-Region Replication Lag (DR Metric)"
          view   = "timeSeries"
        }
      }
    ]
  })
}