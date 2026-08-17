terraform {
  backend "s3" {
    key = "dev/platform.tfstate"
  }
}
