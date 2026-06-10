
# Azure SQL Server 생성
resource "azurerm_mssql_server" "petclinic_sql_server" {
  name                         = "${local.namespace}-sql-server"
  resource_group_name          = local.resource_group_name
  location                     = local.location
  version                      = "12.0"
  administrator_login          = "pet_admin"
  administrator_login_password = "data1234!" # sensitive 변수 사용 권장

  tags = { Name = "${local.namespace}-petclinic-sql-server" }
}

# SQL Database 생성 (사양 동일 수준: Basic 계층 또는 S0)
resource "azurerm_mssql_database" "petclinic_db" {
  name           = "petclinic"
  server_id      = azurerm_mssql_server.petclinic_sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = "Basic" # AWS db.t3.micro와 유사한 학습/소규모 사양
  max_size_gb    = 2
}

# Azure SQL 방화벽 규칙 (DMS 및 노드 접근용)
# DMS 복제 인스턴스의 공인 IP를 이 방화벽에 추가해야 DMS가 접근 가능
resource "azurerm_mssql_firewall_rule" "allow_dms_and_nodes" {
  name             = "AllowDMSAndNodes"
  server_id        = azurerm_mssql_server.petclinic_sql_server.id
  start_ip_address = local.dms_ip # DMS 공인 IP나 EKS NAT Gateway IP로 제한
  end_ip_address   = local.dms_ip # start와 end를 동일하게 설정하여 특정 IP만 허용
}

# Azure SQL 방화벽 규칙 (쿼리 편집기 접근용)
resource "azurerm_mssql_firewall_rule" "allow_query_editor" {
  name             = "AllowQueryEditor"
  server_id        = azurerm_mssql_server.petclinic_sql_server.id
  start_ip_address = local.my_ip # 본인 로컬의 IP로 제한
  end_ip_address   = local.my_ip # start와 end를 동일하게 설정하여 특정 IP만 허용
}