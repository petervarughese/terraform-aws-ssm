resource "aws_instance" "example_server" {
  ami           = var.ami_id
  instance_type = var.web_instance_type
  tags = {
    Name        = "MyAmazonLinux2023Instance"
    PatchGroup  = aws_ssm_patch_group.al2023_patch_group.patch_group
  }
}
module "aws_ssm_patch_group" {
    source = "./ssm-patch-linux2023"
}