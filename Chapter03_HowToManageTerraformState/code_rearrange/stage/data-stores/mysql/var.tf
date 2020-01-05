// Requiere que haya una variable de entorno con el fin de acceder a la contraseña que se desea establecer.
//$ export TF_VAR_db_password="(YOUR_DB_PASSWORD)"
// Si se deja un espacio al inicio del comando no queda en el history de la consola/terminal
variable "db_password" {
  description = "The password for the database"
  type        = string
}
