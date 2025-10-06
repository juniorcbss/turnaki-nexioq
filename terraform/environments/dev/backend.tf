# Backend configuration para state remoto
# Comentado por defecto - descomentar después de crear bucket S3

terraform {
  backend "s3" {
    bucket         = "turnaki-nexioq-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "turnaki-nexioq-terraform-locks"
  }
}
