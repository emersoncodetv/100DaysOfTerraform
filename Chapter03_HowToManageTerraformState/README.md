# 3. How to Manage Terraform State

What Is Terraform State?
Shared Storage for State Files
Limitations with Terraform’s Backends
Isolating State Files
Isolation via Workspaces
Isolation via File Layout
The terraform_remote_state Data Source
Conclusion

# This code sets four arguments:

## bucket

This is the name of the S3 bucket. Note that S3 bucket names must be globally unique among all AWS customers. Therefore, you will need to change the bucket parameter from "terraform-up-and-running-state" (which I already created) to your own name.3 Make sure to remember this name and take note of what AWS region you’re using because you’ll need both pieces of information again a little later on.

## prevent_destroy

prevent_destroy is the second lifecycle setting you’ve seen (the first was create_before_destroy in Chapter 2). When you set prevent_destroy to true on a resource, any attempt to delete that resource (e.g., by running terraform destroy) will cause Terraform to exit with an error. This is a good way to prevent accidental deletion of an important resource, such as this S3 bucket, which will store all of your Terraform state. Of course, if you really mean to delete it, you can just comment that setting out.

## versioning

This block enables versioning on the S3 bucket so that every update to a file in the bucket actually creates a new version of that file. This allows you to see older versions of the file and revert to those older versions at any time.

## server_side_encryption_configuration

This block turns server-side encryption on by default for all data written to this S3 bucket. This ensures that your state files, and any secrets they might contain, are always encrypted on disk when stored in S3.

```terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-up-and-running-state"

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
```
