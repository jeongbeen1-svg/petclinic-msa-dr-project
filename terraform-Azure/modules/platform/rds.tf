
# Azure SQL Server 생성
resource "azurerm_mssql_server" "petclinic_sql_server" {
  name                         = "${local.namespace}-sql-server"
  resource_group_name          = local.resource_group_name
  location                     = local.location
  version                      = "12.0"
  administrator_login          = "pet_admin"
  administrator_login_password = "data1234!" # sensitive 변수 사용 권장

  # 퍼블릭 접속 차단
  public_network_access_enabled = false

  tags = { Name = "${local.namespace}-petclinic-sql-server" }
}

# 가상 네트워크 내 프라이빗 엔드포인트 연결
resource "azurerm_private_endpoint" "sql_endpoint" {
  name                = "${local.namespace}-sql-endpoint"
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = local.private_subnet_ids[0] # 데이터베이스용 프라이빗 서브넷

  private_service_connection {
    name                           = "sql-service-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mssql_server.petclinic_sql_server.id
    subresource_names              = ["sqlServer"]
  }
}

# SQL Database 생성 (사양 동일 수준: Basic 계층 또는 S0)
resource "azurerm_mssql_database" "petclinic_db" {
  name           = "petclinic"
  server_id      = azurerm_mssql_server.petclinic_sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = "Basic" # AWS db.t3.micro와 유사한 학습/소규모 사양
  max_size_gb    = 2
}