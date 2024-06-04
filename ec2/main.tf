resource "aws_instance" "example_server" {
  ami           = var.ami_id
  instance_type = var.web_instance_type
  tags = {
    Name        = "MyAmazonLinux2023Instance"
    PatchGroup  = aws_ssm_patch_group.al2023_patch_group.patch_group
  }
}

resource "aws_ssm_patch_baseline" "al2023_patch_baseline" {
  name        = "AmazonLinux2023PatchBaseline"
  description = "Patch baseline for Amazon Linux 2023"
  operating_system = "AMAZON_LINUX_2"

  approval_rule {
    patch_filter {
      key = "PRODUCT"
      values = ["AmazonLinux2023"]
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
      values = ["AmazonLinux2023"]
    }

    patch_filter {
      key = "SEVERITY"
      values = ["Critical", "Important"]
    }

    compliance_level = "CRITICAL"
    approve_after_days = 0
    enable_non_security = false
  }

  tags = {
    Name = "AmazonLinux2023PatchBaseline"
  }
}

resource "aws_ssm_patch_group" "al2023_patch_group" {
  baseline_id = aws_ssm_patch_baseline.al2023_patch_baseline.id
  patch_group = "AmazonLinux2023PatchGroup"
}

output "patch_baseline_id" {
  value = aws_ssm_patch_baseline.al2023_patch_baseline.id
}

output "patch_group" {
  value = aws_ssm_patch_group.al2023_patch_group.patch_group
}

output "instance_id" {
  value = aws_instance.my_instance.id
}