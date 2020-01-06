// Requiere que haya una variable de entorno con el fin de acceder a la contraseña que se desea establecer.
//$ export TF_VAR_db_password="(YOUR_DB_PASSWORD)"
// Si se deja un espacio al inicio del comando no queda en el history de la consola/terminal
variable "db_password" {
  description = "The password for the database"
  type        = string
}

variable "database_name" {
  description = "Nombre de la base de datos a crear"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type        = string
}
