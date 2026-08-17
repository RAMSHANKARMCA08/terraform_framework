terraform {
  backend "s3" {
    key = "stage/platform.tfstate"
  }
}
