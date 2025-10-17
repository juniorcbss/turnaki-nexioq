plugin "aws" {
  enabled = true
  version = "~> 0.30.0"
}

rule "terraform_required_providers" {
  enabled = false
}

config {
  module = true
  force = false
}


