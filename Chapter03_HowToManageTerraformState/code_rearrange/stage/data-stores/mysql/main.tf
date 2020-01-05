# provider "aws" {
#   region = "us-east-2"
# }

# resource "aws_db_instance" "example" {
#   identifier_prefix = "terraform-up-and-running"
#   engine            = "mysql"
#   allocated_storage = 10
#   instance_class    = "db.t2.micro"
#   name              = "example_database"
#   username          = "admin"

#   # How should we set the password?
#   password = "???"
# }

provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "terraform-up-and-running-state-serendipiaco"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  name              = "example_database"
  username          = "admin"

  password = var.db_password
}

# resource "aws_db_instance" "example" {
#   identifier_prefix = "terraform-up-and-running"
#   engine            = "mysql"
#   allocated_storage = 10
#   instance_class    = "db.t2.micro"
#   name              = "example_database"
#   username          = "admin"

#   password = data.aws_secretsmanager_secret_version.db_password.secret_string
# }

# resource "aws_secretsmanager_secret" "example" {
#   name = "example"
# }

# data "aws_secretsmanager_secret_version" "db_password" {
#   secret_id = "${aws_secretsmanager_secret.example.id}"
# }
