locals {
  org         = "tf-core-jaebok1205"
  project     = "test"
  environment = "dev"
  location    = "koreacentral"

  namespace = "${local.org}-${local.project}-${local.environment}"
}
