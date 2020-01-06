provider "aws" {
  region = "us-east-2"
}

module "mysql_batabase" {
  source = "../../../modules/data-stores/mysql"

  database_name = "prod-database"
  db_password   = "prod-Password-123"
}
