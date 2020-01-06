provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "terraform-up-and-running-state-serendipiaco"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    # bucket = var.db_remote_state_bucket
    # key    = var.db_remote_state_key
    region = "us-east-2"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

module "mysql_database" {
  # source = "../../../../modules/data-stores/mysql"
  source = "git::https://github.com/emersonvolkov/modulesTerraform.git//data-stores/mysql?ref=v0.0.1"

  database_name          = "stage-database"
  db_password            = "stage_Password_123"
  db_remote_state_bucket = "terraform-up-and-running-state-serendipiaco"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"
}
