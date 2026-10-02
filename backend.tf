# backend.tf
# Remote backend
terraform {
  backend "s3" {
    bucket       = "backend-files-tf"
    key          = "new-dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}