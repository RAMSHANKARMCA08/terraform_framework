terraform {
  backend "s3" {
    key = "prod/platform.tfstate"
  }
}
