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
      values = ["Security", "Bugfix"]
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
      values = ["Critical", "Important"]
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
  patch_group = "AmazonLinux2PatchGroup"
}
