resource "aws_instance" "example_server" {
  ami           = var.ami_id
  instance_type = var.web_instance_type
  tags = {
    Name        = "MyAmazonLinux2023Instance"
    Environment = "prod"
  }
}

resource "aws_ssm_patch_baseline" "al2023_patch_baseline" {
  name        = "AmazonLinux2PatchBaseline"
  description = "Patch baseline for Amazon Linux 2"
  operating_system = "AMAZON_LINUX_2"

  approval_rule {
    patch_filter {
      key = "PRODUCT"
      values = ["AmazonLinux2"]
    }

    patch_filter {
      key = "CLASSIFICATION"
      values = ["Security", "Bugfix"]
    }

    compliance_level = "CRITICAL"
    approve_after_days = 7
    enable_non_security = true
  }

  approval_rule {
    patch_filter {
      key = "PRODUCT"
      values = ["AmazonLinux2"]
    }

    patch_filter {
      key = "SEVERITY"
      values = ["Critical", "Important"]
    }

    compliance_level = "CRITICAL"
    approve_after_days = 0
    enable_non_security = true
  }

  approval_rule {
    patch_filter {
      key = "PRODUCT"
      values = ["AmazonLinux2"]
    }

    patch_filter {
      key = "SEVERITY"
      values = ["Medium"]
    }

    compliance_level = "HIGH"
    approve_after_days = 14
    enable_non_security = true
  }

  approval_rule {
    patch_filter {
      key = "PRODUCT"
      values = ["AmazonLinux2"]
    }

    patch_filter {
      key = "SEVERITY"
      values = ["Low"]
    }

    compliance_level = "MEDIUM"
    approve_after_days = 30
    enable_non_security = true
  }

  tags = {
    Name = "AmazonLinux2PatchBaseline"
  }
}

resource "aws_ssm_patch_group" "al2023_patch_group" {
  baseline_id = aws_ssm_patch_baseline.al2023_patch_baseline.id
  patch_group = "AmazonLinux2PatchGroup"
}

resource "aws_ssm_maintenance_window" "example" {
  name               = "ExampleMaintenanceWindow"
  schedule           = "cron(5 8 * * ? *)" # This is the cron expression for 8:05 AM CST
  schedule_timezone  = "CST6CDT" # Central Standard Time (CST)
  duration           = 1
  cutoff             = 0
  allow_unassociated_targets = true
  enabled            = true
}

resource "aws_ssm_maintenance_window_target" "example" {
  window_id = aws_ssm_maintenance_window.example.id
  name      = "ProdInstances"
  description = "Target instances with the tag Environment=prod"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Environment"
    values = ["prod"]
  }
}

resource "aws_ssm_maintenance_window_task" "example" {
  window_id          = aws_ssm_maintenance_window.example.id
  max_concurrency    = "1"
  max_errors         = "1"
  task_arn           = "AWS-PatchInstanceWithRollback"
  service_role_arn   = aws_iam_role.ssm_service_role.arn
  task_type          = "RUN_COMMAND"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.example.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      comment                  = "Patch Instances"
      document_hash            = "PatchDocument"
      timeout_seconds          = 3600
    }
  }
}

resource "aws_iam_role" "ssm_service_role" {
  name = "SSMServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ssm.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "ssm_service_role_policy" {
  role       = aws_iam_role.ssm_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}
