resource "aws_security_group" "dms_sg" {
  name        = "dms-replication-sg"
  description = "Security group for DMS replication instance"
  vpc_id      = local.vpc_id

  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.db_sg.id]
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [local.azure_ip_cidr_block]
  }

  tags = {
    Name = "dms-replication-sg"
  }
}

resource "aws_dms_replication_subnet_group" "dms_subnet_group" {
  replication_subnet_group_id          = "dms-subnet-group"
  replication_subnet_group_description = "DMS subnet group for migration"
  subnet_ids                           = local.private_subnets_dms

  tags = {
    Name = "${local.namespace}-dms-sg"
  }
}

resource "aws_dms_replication_instance" "dms_instance" {
  replication_instance_id     = "dms-instance-mysql-to-mysql"
  replication_instance_class  = "dms.t3.medium"
  allocated_storage           = 50
  vpc_security_group_ids      = [aws_security_group.dms_sg.id]
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_subnet_group.id
  publicly_accessible         = false

  tags = {
    Name = "${local.namespace}-dms-ri"
  }
}

resource "aws_dms_endpoint" "source" {
  endpoint_id   = "source-rds-endpoint"
  endpoint_type = "source"
  engine_name   = "mysql"
  username      = aws_db_instance.petclinic_db.username
  password      = var.rds_mysql_password
  server_name   = split(":", aws_db_instance.petclinic_db.endpoint)[0]
  port          = 3306

  lifecycle {
    ignore_changes = [
      password
    ]
  }
}

resource "aws_dms_endpoint" "target" {
  endpoint_id   = "target-azure-endpoint"
  endpoint_type = "target"
  engine_name   = "mysql"
  username      = local.target_username
  password      = local.target_password
  server_name   = local.target_db_address
  port          = 3306

  lifecycle {
    ignore_changes = [
      password
    ]
  }
}

#AWS => Azure Migration Task
resource "aws_dms_replication_task" "migration_task" {
  replication_task_id      = "petclinic-migration-task"
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.dms_instance.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn

  table_mappings = jsonencode({
    rules = [
      {
        "rule-type" = "selection"
        "rule-id"   = "1"
        "rule-name" = "1"
        "object-locator" = {
          "schema-name" = "petclinic"
          "table-name"  = "%"
        }
        "rule-action" = "include"
      }
    ]
  })

  replication_task_settings = jsonencode({
    FullLoadSettings = {
      TargetTablePrepMode = "DO_NOTHING"
    }
    TargetMetadata = {
      TargetSchemaMode = "DoNothing"
      SupportLobs      = true
      FullLobMode      = true
      InlineLobMode    = true
      ConstraintSettings = {
        PrimaryKeyConstraints = false
        UniqueConstraints     = false
        Indexes               = false
      }
    }
    Logging = {
      EnableLogging = true
      LogComponents = [
        { Id = "SOURCE_UNLOAD", Severity = "LOGGER_SEVERITY_DEBUG" },
        { Id = "TARGET_LOAD", Severity = "LOGGER_SEVERITY_DEBUG" },
        { Id = "TRANSFORMATION", Severity = "LOGGER_SEVERITY_DEBUG" }
      ]
    }
  })

  tags = {
    Name = "petclinic-migration-task"
  }

  lifecycle {
    ignore_changes = [
      replication_task_settings,
      table_mappings
    ]
  }
}

resource "aws_dms_endpoint" "failback_source_azure" {
  endpoint_id   = "failback-source-azure-endpoint"
  endpoint_type = "source"
  engine_name   = "mysql"
  username      = local.target_username
  password      = local.target_password
  server_name   = local.target_db_address
  port          = 3306

  lifecycle {
    ignore_changes = [
      password,
      tags,
      tags_all
    ]
  }
}

resource "aws_dms_endpoint" "failback_target_rds" {
  endpoint_id   = "failback-target-azure-endpoint"
  endpoint_type = "target"
  engine_name   = "mysql"
  username      = aws_db_instance.petclinic_db.username
  password      = var.rds_mysql_password
  server_name   = split(":", aws_db_instance.petclinic_db.endpoint)[0]
  port          = 3306

  mysql_settings {
    parallel_load_threads = 1
  }

  lifecycle {
    ignore_changes = [
      password,
      tags,
      tags_all
    ]
  }
}

# Azure => AWS failback task
resource "aws_dms_replication_task" "failback_azure_aws_task" {
  replication_task_id      = "failback-azure-aws-task"
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.dms_instance.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.failback_source_azure.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.failback_target_rds.endpoint_arn

  table_mappings = jsonencode({
    rules = [
      {
        "rule-type" = "selection"
        "rule-id"   = "503559913"
        "rule-name" = "petclinic-users"
        "object-locator" = {
          "schema-name" = "petclinic"
          "table-name"  = "users"
        }
        "rule-action" = "include"
        filters       = []
      },
      {
        "rule-type" = "selection"
        "rule-id"   = "502440119"
        "rule-name" = "drtest-users"
        "object-locator" = {
          "schema-name" = "drtest"
          "table-name"  = "users"
        }
        "rule-action" = "include"
        filters       = []
      },
      {
        "rule-type" = "selection"
        "rule-id"   = "502408298"
        "rule-name" = "drtest-pets"
        "object-locator" = {
          "schema-name" = "drtest"
          "table-name"  = "pets"
        }
        "rule-action" = "include"
        filters       = []
      }
    ]
  })

  replication_task_settings = jsonencode({
    Logging = {
      EnableLogging    = true
      EnableLogContext = true
    }
    FullLoadSettings = {
      TargetTablePrepMode = "DO_NOTHING"
    }
  })

  lifecycle {
    ignore_changes = [
      replication_task_settings,
      start_replication_task,
      table_mappings,
      tags,
      tags_all
    ]
  }
}
