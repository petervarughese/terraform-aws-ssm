terraform {
  backend "s3" {
    bucket = "${peter-github-oidc-terraform-aws-tfstates-ssm}"
    key    = "${infra.tfstate}"
    region = "${us-east-1}"
  }
}
