terraform {
  backend "gcs" {
    bucket = "redesaura-tfstate"
    prefix = "1-org"
  }
}
