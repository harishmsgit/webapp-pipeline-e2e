terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_YOUR_TFSTATE_BUCKET"
    key            = "terraform/terraform.tfstate"
    region         = "REPLACE_WITH_YOUR_AWS_REGION"
    dynamodb_table = "REPLACE_WITH_YOUR_LOCK_TABLE"
    use_lockfile   = true
    encrypt        = true
  }
}
