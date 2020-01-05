provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "terraform-up-and-running-state-serendipiaco"
    key    = "workspaces-example/terraform.tfstate"
    region = "us-east-2"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

resource "aws_instance" "example" {
  ami = "ami-0c55b159cbfafe1f0"
  #instance_type = "t2.micro"
  # In fact, you can even change how that module behaves based on the workspace you’re in by reading the workspace name using the expression terraform.workspace. For example, here’s how to set the Instance type to t2.medium in the default workspace and t2.micro in all other workspaces (e.g., to save money when experimenting):
  // ternary syntax
  instance_type = terraform.workspace == "default" ? "t2.medium" : "t2.micro"
}
