provider "aws" {
  region = "us-east-2"
}

module "webserver_cluster" {
  source = "../../../modules/webserver-cluster"

  cluster_name           = "webservers-prod"
  db_remote_state_bucket = "terraform-up-and-running-state-serendipiaco"
  db_remote_state_key    = "prod/data-stores/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2

  // En producción si debo usar unas maquinas mas grandes con el fin de garantizar la disponibilidad de mi servicio por recursos $$ lo dejo con lo minimo pero dejo comentariado como deberia ir.
  # instance_type = "m4.large"
  # min_size      = 2
  # max_size      = 10
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name  = "scale-out-during-business-hours"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 10
  recurrence             = "0 9 * * *"
  autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name  = "scale-in-at-night"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
  autoscaling_group_name = module.webserver_cluster.asg_name
}
