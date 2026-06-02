locals {
  org         = "tf-core-ej"
  project     = "test"
  environment = "dev"

  namespace = "${local.org}-${local.project}-${local.environment}"

}