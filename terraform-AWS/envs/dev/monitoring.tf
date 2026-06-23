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

      # 1-1. DNS 헬스체크 - singleValue (현재 상태 숫자로 한눈에)
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 6
        height = 4
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/Route53,HealthCheckId} MetricName=\"HealthCheckStatus\"', 'Average', 60)", "label" : "DNS: &&-SCHEMA-REPLACEMENT-&&", "id" : "dns1" }]
          ]
          period = 60
          region = "us-east-1"
          title  = "🔥 1-1. DNS (Route 53) Health Check Status (1=Healthy, 0=Unhealthy)"
          view   = "singleValue"
        }
      },

      # 1-2. ALB 응답코드 분포 - bar (비율/분포에 적합)
      {
        type   = "metric"
        x      = 6
        y      = 0
        width  = 12
        height = 4
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_Target_2XX_Count\"', 'Sum', 60)", "label" : "2XX: &&-SCHEMA-REPLACEMENT-&&", "id" : "alb2xx", "color" : "#2ca02c" }],
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_Target_4XX_Count\"', 'Sum', 60)", "label" : "4XX: &&-SCHEMA-REPLACEMENT-&&", "id" : "alb4xx", "color" : "#ff7f0e" }],
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_Target_5XX_Count\"', 'Sum', 60)", "label" : "5XX: &&-SCHEMA-REPLACEMENT-&&", "id" : "alb5xx", "color" : "#d62728" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🎯 1-2. ALB Target Response Code Distribution (2XX/4XX/5XX)"
          view   = "bar"
        }
      },

      # 1-3. EKS 실패 노드 수 - singleValue (현재 상태 숫자로 한눈에)
      {
        type   = "metric"
        x      = 18
        y      = 0
        width  = 6
        height = 4
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{ContainerInsights,ClusterName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"cluster_failed_node_count\"', 'Maximum', 60)", "label" : "Failed Nodes", "id" : "k8sfail", "color" : "#ff7f0e" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🔥 1-3. EKS Cluster Failed Node Count (Cluster Health)"
          view   = "singleValue"
        }
      },

      # ============================================================
      # [PAGE 2 - Ingress ALB & EKS 인프라 레이어 (y=4)]
      # ============================================================

      # 2-1. 헬시 호스트 수 - singleValue
      {
        type   = "metric"
        x      = 0
        y      = 4
        width  = 6
        height = 4
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,TargetGroup} MetricName=\"HealthyHostCount\"', 'Average', 60)", "label" : "🟢 Healthy: &&-SCHEMA-REPLACEMENT-&&", "id" : "h1" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🎯 2-1. Ingress Auto-Generated Targets: Healthy Host Count"
          view   = "singleValue"
        }
      },

      # 2-2. 언헬시 호스트 수 - singleValue
      {
        type   = "metric"
        x      = 6
        y      = 4
        width  = 6
        height = 4
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,TargetGroup} MetricName=\"UnHealthyHostCount\"', 'Average', 60)", "label" : "🔴 UnHealthy: &&-SCHEMA-REPLACEMENT-&&", "id" : "uh1", "color" : "#d62728" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🎯 2-2. Ingress Auto-Generated Targets: UnHealthy Host Count"
          view   = "singleValue"
        }
      },

      # 2-3. ALB 요청수 - timeSeries (추이 확인)
      {
        type   = "metric"
        x      = 12
        y      = 4
        width  = 12
        height = 4
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"RequestCount\"', 'Sum', 60)", "label" : "Requests: &&-SCHEMA-REPLACEMENT-&&", "id" : "req1" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "📈 2-3. Ingress ALB Total Request Count (Traffic Rate)"
          view   = "timeSeries"
        }
      },

      # 2-4. 응답시간 - timeSeries (추이 확인)
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,TargetGroup} MetricName=\"TargetResponseTime\"', 'Average', 60)", "label" : "Latency: &&-SCHEMA-REPLACEMENT-&&", "id" : "latency1" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "⏱️ 2-4. Target Response Time per Auto-Generated Ingress Group (Average)"
          view   = "timeSeries"
        }
      },

      # 2-5. 노드 CPU - timeSeries
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{ContainerInsights,ClusterName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"node_cpu_utilization\"', 'Average', 60)", "label" : "Node CPU: &&-SCHEMA-REPLACEMENT-&&", "id" : "ncpu" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "☸️ 2-5. EKS Worker Nodes CPU Utilization (%)"
          view   = "timeSeries"
        }
      },

      # 2-6. 노드 Memory - timeSeries
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{ContainerInsights,ClusterName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"node_memory_utilization\"', 'Average', 60)", "label" : "Node Mem: &&-SCHEMA-REPLACEMENT-&&", "id" : "nmem" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "☸️ 2-6. EKS Worker Nodes Memory Utilization (%)"
          view   = "timeSeries"
        }
      },

      # 2-7. Pod 재시작 수 - timeSeries (전체 폭으로 한눈에)
      {
        type   = "metric"
        x      = 12
        y      = 14
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{ContainerInsights,ClusterName,Namespace} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"pod_number_of_container_restarts\"', 'Sum', 60)", "label" : "Restart Count: &&-SCHEMA-REPLACEMENT-&&", "id" : "podrest", "color" : "#1f77b4" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "☸️ 2-7. EKS Pod Container Restart Count (Detecting CrashLoopBackOff)"
          view   = "timeSeries"
        }
      },

      # ============================================================
      # [PAGE 3 - 애플리케이션 성능 및 DB 레이어 (y=20)]
      # ============================================================

      # 3-1. Pod CPU - timeSeries
      {
        type   = "metric"
        x      = 0
        y      = 20
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{ContainerInsights,ClusterName,Namespace,PodName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"pod_cpu_utilization\"', 'Average', 60)", "label" : "Pod CPU: &&-SCHEMA-REPLACEMENT-&&", "id" : "pcpu" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🚀 3-1. Application Pods CPU Utilization (By Microservices)"
          view   = "timeSeries"
        }
      },

      # 3-2. Pod Memory - timeSeries
      {
        type   = "metric"
        x      = 12
        y      = 20
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{ContainerInsights,ClusterName,Namespace,PodName} ClusterName=\"${module.workload.cluster_name}\" MetricName=\"pod_memory_utilization\"', 'Average', 60)", "label" : "Pod Mem: &&-SCHEMA-REPLACEMENT-&&", "id" : "pmem" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🚀 3-2. Application Pods Memory Utilization (By Microservices)"
          view   = "timeSeries"
        }
      },

      # 3-3. RDS CPU - timeSeries
      {
        type   = "metric"
        x      = 0
        y      = 26
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"CPUUtilization\"', 'Average', 60)", "label" : "DB CPU: &&-SCHEMA-REPLACEMENT-&&", "id" : "rdscpu" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🗄️ 3-3. Database (RDS) CPU Utilization (%)"
          view   = "timeSeries"
        }
      },

      # 3-4. DB 커넥션 수 - timeSeries
      {
        type   = "metric"
        x      = 12
        y      = 26
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"DatabaseConnections\"', 'Average', 60)", "label" : "Connections: &&-SCHEMA-REPLACEMENT-&&", "id" : "rdsconn", "color" : "#9467bd" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🗄️ 3-4. Database Connection Count (Connection Pool Monitor)"
          view   = "timeSeries"
        }
      },

      # ============================================================
      # [PAGE 4 - 용량 및 DR 레이어 (y=32)]
      # ============================================================

      # 4-1. TPS - timeSeries
      {
        type   = "metric"
        x      = 0
        y      = 32
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"RequestCount\"', 'Sum', 60) / 60", "label" : "TPS: &&-SCHEMA-REPLACEMENT-&&", "id" : "albtps" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🌐 4-1. ALB Transactions Per Second"
          view   = "timeSeries"
        }
      },

      # 4-2. ASG Desired vs Running - timeSeries
      {
        type   = "metric"
        x      = 8
        y      = 32
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupInServiceInstances\"', 'Average', 60)", "label" : "Running: &&-SCHEMA-REPLACEMENT-&&", "id" : "asgrun" }],
            [{ "expression" : "SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupDesiredCapacity\"', 'Average', 60)", "label" : "Desired: &&-SCHEMA-REPLACEMENT-&&", "id" : "asgdes", "color" : "#9467bd" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "☸️ 4-2. EKS Node Group (ASG) Desired vs Running Capacity"
          view   = "timeSeries"
        }
      },

      # 4-3. RDS 메모리/스토리지 여유 - timeSeries
      {
        type   = "metric"
        x      = 16
        y      = 32
        width  = 8
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"FreeableMemory\"', 'Average', 60)", "label" : "FreeMem: &&-SCHEMA-REPLACEMENT-&&", "id" : "rdsmem" }],
            [{ "expression" : "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"FreeStorageSpace\"', 'Average', 60)", "label" : "FreeDisk: &&-SCHEMA-REPLACEMENT-&&", "id" : "rdsdisk", "color" : "#8c564b" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🗄️ 4-3. RDS Memory & Storage Headroom"
          view   = "timeSeries"
        }
      },

      # 4-4. RDS Cross-Region Replication Lag (DR) - timeSeries
      {
        type   = "metric"
        x      = 0
        y      = 38
        width  = 24
        height = 6
        properties = {
          metrics = [
            [{ "expression" : "SEARCH('{AWS/RDS,DBInstanceIdentifier} DBInstanceIdentifier=petclinic MetricName=\"ReplicationLag\"', 'Maximum', 60)", "label" : "Lag Sec: &&-SCHEMA-REPLACEMENT-&&", "id" : "rdslag", "color" : "#e377c2" }]
          ]
          period = 60
          region = "ap-northeast-2"
          title  = "🗄️ 4-4. RDS Cross-Region Replication Lag (DR Metric)"
          view   = "timeSeries"
        }
      }
    ]
  })
}
