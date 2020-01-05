
variable "server_port" {
  description = "Puerto para la lista de seguridad y el purto por el cual va a estar escuchando el servidor web."
  type        = number
  default     = 8080
}

// Para encontrar el ID de la VPC que esta por default.
data "aws_vpc" "default" {
  default = true
}

// Una ves que encontramos el ID de la VPC podemos buscar los id de las subnet de dicha VPC.
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
