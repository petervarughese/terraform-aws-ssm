# IAM Role
resource "aws_iam_role" "ssm_role" {
  name = "new-ssm-role-patch"  # Changed to a unique role name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      },
    ]
  })
  
  # Attach policies to the role as needed
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

# SSM Patch Baseline
resource "aws_ssm_patch_baseline" "al2_patch_baseline" {
  name        = "AmazonLinux2PatchBaseline"
  description = "Patch baseline for Amazon Linux 2"
  operating_system = "AMAZON_LINUX_2"

  approval_rules {
    approve_after_days = 7

    patch_filter {
      key = "CLASSIFICATION"
      values = ["Security", "Bugfix", "Enhancement", "Recommended", "Newpackage"]  # Valid values
    }

    patch_filter {
      key = "SEVERITY"
      values = ["Critical", "Important", "Medium", "Low"]  # Valid values
    }
  }

  # Optional: Add global filters if needed
  global_filters {
    key    = "PRODUCT"
    values = ["AmazonLinux2"]
  }
}

# SSM Maintenance Window
resource "aws_ssm_maintenance_window" "patch_window" {
  name               = "patch-window"
  schedule           = "cron(0 0 1 * ? *)"
  duration           = 4
  cutoff             = 1
  allow_unassociated_targets = true

  # Ensure that all required fields are provided correctly
  description       = ""
  start_date        = ""
  end_date          = ""
  schedule_offset   = 1  # Set to a valid value (1-6)
  schedule_timezone = ""
}

# SSM Maintenance Window Target
resource "aws_ssm_maintenance_window_target" "patch_window_target" {
  window_id = aws_ssm_maintenance_window.patch_window.id
  name = "example-target"
  description = "Target instances based on tags"
  resource_type = "INSTANCE"
  targets {
    key = "tag:Environment"  # Key of the tag
    values = ["production"]  # Value of the tag
  }
}

# Declare the SSM Patch Group if needed
resource "aws_ssm_patch_group" "al2_patch_group" {
  baseline_id = aws_ssm_patch_baseline.al2_patch_baseline.id
  patch_group = "my-patch-group"  # Specify your patch group name
}

# Example Instance with Patch Group Tag
resource "aws_instance" "example_server" {
  ami           = "ami-0abcdef1234567890"  # Specify your AMI ID
  instance_type = "t2.micro"

  tags = {
    Name        = "ExampleServer"
    Environment = "prod"  # Match the tag value used in the target
    PatchGroup  = aws_ssm_patch_group.al2_patch_group.patch_group  # Reference the declared patch group
  }
}

# Example Module Usage
module "PeterExample" {
  source = "./modules/PeterExample"
  
  # Other module variables...
  ssm_role_arn = aws_iam_role.ssm_role.arn
  patch_baseline_id = aws_ssm_patch_baseline.al2_patch_baseline.id
  maintenance_window_id = aws_ssm_maintenance_window.patch_window.id
}
