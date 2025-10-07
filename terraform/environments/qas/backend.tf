# Backend configuration para state remoto QAS

terraform {
  backend "s3" {
    bucket         = "turnaki-nexioq-terraform-state"
    key            = "qas/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "turnaki-nexioq-terraform-locks"
  }
}
