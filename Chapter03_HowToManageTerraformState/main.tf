provider "aws" {
  region = "us-east-2"
}

variable "bucket_terraform_remote_backend" {
  description = "Bucket where the state of terraform is going to be stored and shared between the developer team."
  default     = "terraform-up-and-running-state-serendipiaco"
}



resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-up-and-running-state-serendipiaco"

  // Pevenir que accidentalmente se elimine el bucket
  lifecycle {
    prevent_destroy = true
  }

  // Habilitar versionamiento para poder ver completamente el historial de versiones de lo archivos de estado de terraform
  versioning {
    enabled = true
  }

  // habilitando server-side encripcion de forma predeterminada
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Only the key parameter remains in the Terraform code, since you still need to set a different key value for each module:
# El resto de parametros van en el partial configuration file el cual tiene extencion .hcl
# Partial configuration. The other settings (e.g., bucket, region) will be
# passed in from a file via -backend-config arguments to 'terraform init'
# para ejecutar ahora el archivo de terraform debes usar la siguiente variacion en el comando de terraform 
# terraform init -backend-config=backend.hcl
# Vert Terragrunt
terraform {
  backend "s3" {
    key = "global/s3/terraform.tfstate"
  }
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table"
}
