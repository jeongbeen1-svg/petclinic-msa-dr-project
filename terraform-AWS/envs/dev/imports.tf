# import {
#   to = module.network.aws_route.azure["public-a"]
#   id = "rtb-065ebdf677486a582_10.0.0.0/16"
# }

import {
  to = module.platform.aws_dms_endpoint.failback_source_azure
  id = "failback-source-azure-endpoint"
}

import {
  to = module.platform.aws_dms_endpoint.failback_target_rds
  id = "failback-target-azure-endpoint"
}

import {
  to = module.platform.aws_dms_replication_task.failback_azure_aws_task
  id = "failback-azure-aws-task"
}
