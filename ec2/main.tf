resource "aws_instance" "example_server" {
  ami           = var.ami_id
  instance_type = var.web_instance_type
  tags = {
    Name        = "MyAmazonLinux2023Instance"
    PatchGroup  = aws_ssm_patch_group.al2_patch_group.patch_group
  }
}

resource "aws_ssm_patch_baseline" "al2_patch_baseline" {
  name             = "AmazonLinux2PatchBaseline"
  description      = "Patch baseline for Amazon Linux 2"
  operating_system = "AMAZON_LINUX_2"

  approval_rule {
    patch_filter {
      key    = "PRODUCT"
      values = ["AmazonLinux2"]
    }

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security", "Bugfix", "Feature", "Enhancement", "Other"]
    }

    compliance_level    = "CRITICAL"
    approve_after_days  = 7
    enable_non_security = true
  }

  approval_rule {
    patch_filter {
      key    = "PRODUCT"
      values = ["AmazonLinux2"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important", "Medium", "Low", "Informational", "Unspecified"]
    }

    compliance_level    = "CRITICAL"
    approve_after_days  = 0
    enable_non_security = false
  }

  tags = {
    Name = "AmazonLinux2PatchBaseline"
  }
}

resource "aws_ssm_patch_group" "al2_patch_group" {
  baseline_id = aws_ssm_patch_baseline.al2_patch_baseline.id
  patch_group = "AmazonLinux2PatchGroup-unique"
}

resource "aws_ssm_maintenance_window" "patch_window" {
  name               = "PatchWindow"
  schedule           = "cron(0 3 ? * SUN *)"  # Runs every Sunday at 3 AM UTC
  duration           = 4
  cutoff             = 1
  allow_unassociated_targets = true
  enabled            = true
}

resource "aws_ssm_maintenance_window_target" "patch_window_target" {
  window_id = aws_ssm_maintenance_window.patch_window.id
  name      = "PatchWindowTarget"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:PatchGroup"
    values = [aws_ssm_patch_group.al2_patch_group.patch_group]
  }
}

resource "aws_ssm_maintenance_window_task" "patch_window_task" {
  window_id = aws_ssm_maintenance_window.patch_window.id
  max_concurrency = "1"
  max_errors      = "1"
  task_arn        = "AWS-RunPatchBaseline"
  task_type       = "RUN_COMMAND"
  priority        = 1

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.patch_window_target.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      comment = "Patch instance"

      parameter {
        name   = "Operation"
        values = ["Install"]
      }

      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ssm.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_role_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_ssm_association" "patch_association" {
  name       = "PatchAssociation"
  instance_id = aws_instance.example_server.id
  schedule_expression = "rate(30 days)" # Run every 30 days
  association_name = "MyPatchAssociation"

  targets {
    key    = "tag:PatchGroup"
    values = [aws_ssm_patch_group.al2_patch_group.patch_group]
  }
}