# backend.hcl
# Replace this with your bucket name!
bucket = "terraform-up-and-running-state-serendipiaco"
region = "us-east-2"
# Replace this with your DynamoDB table name!
dynamodb_table = "terraform-up-and-running-locks"
encrypt        = true
