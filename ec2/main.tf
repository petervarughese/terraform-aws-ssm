resource "aws_instance" "example_server" {
  ami           = var.ami_id
  instance_type = var.web_instance_type
  tags = {
    Name        = "MyAmazonLinux2023Instance"
    PatchGroup  = aws_ssm_patch_group.al2_patch_group.patch_group
    Environment = "prod"
  }
}

  # IAM Role
  resource "aws_iam_role" "ssm_role" {
    name = "new-ssm-role-name"  # Changed to a unique role name
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
    # Example: Attach AmazonSSMManagedInstanceCore policy
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ]
  }
  
  # SSM Patch Baseline
  resource "aws_ssm_patch_baseline" "al2_patch_baseline" {
    name        = "AmazonLinux2PatchBaseline"
    description = "Patch baseline for Amazon Linux 2"
    operating_system = "AMAZON_LINUX_2"
  
    approval_rule {
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
    global_filter {
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
    schedule_offset   = 0
    schedule_timezone = ""
  }
    # Add a target for the maintenance window based on tags
    
# SSM Maintenance Window Target
resource "aws_ssm_maintenance_window_target" "patch_window_target" {
  window_id = aws_ssm_maintenance_window.patch_window.id
  name = "example-target"
  description = "Target instances based on tags"
  resource_type = "INSTANCE"
  targets {
    key = "tag:Environment"  # Key of the tag
    values = ["prod"]  # Value of the tag
  }
}

  