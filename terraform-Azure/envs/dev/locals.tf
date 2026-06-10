locals {
  org         = "tf-core-ejn"
  project     = "test"
  environment = "dev"
  location    = "koreacentral"

  namespace = "${local.org}-${local.project}-${local.environment}"

  # 일단은 데베 테스트만 진행하실 떄는 0.0.0.0으로 설정하고 진행해주세요
  dms_ip = "본인의 DMS 복제 인스턴스 퍼블릭 주소를 입력"
  my_ip  = "본인의 IP 주소를 입력"
}
