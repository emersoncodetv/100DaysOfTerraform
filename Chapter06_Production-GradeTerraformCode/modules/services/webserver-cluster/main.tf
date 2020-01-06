provider "aws" {
  region = "us-east-2"

}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    # bucket = "terraform-up-and-running-state-serendipiaco"
    # key    = "stage/data-stores/mysql/terraform.tfstate"
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"
  }
}

# data "template_file" "user_data" {
#   // este funciona cuand no estoy usando modulos
#   # template = file("user-data.sh")
#   // probando file function con modulos
#   // este es la solucion, hay que averiguar que es path.modules de donde carga y que atributos tiene.
#   // https://github.com/hashicorp/terraform/issues/5213#issuecomment-186213954
#   template = file("${path.module}/user-data.sh")

#   vars = {
#     server_port = var.server_port
#     db_address  = data.terraform_remote_state.db.outputs.address
#     db_port     = data.terraform_remote_state.db.outputs.port
#   }
# }


data "template_file" "user_data" {
  count = var.enable_new_user_data ? 0 : 1

  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}

data "template_file" "user_data_new" {
  count = var.enable_new_user_data ? 1 : 0

  template = file("${path.module}/user-data-new.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
    server_text = var.server_text
  }
}


# terraform {
#   backend "s3" {
#     # Replace this with your bucket name!
#     bucket = "terraform-up-and-running-state-serendipiaco"
#     key    = "stage/services/webserver-cluster/terraform.tfstate"
#     region = "us-east-2"

#     # Replace this with your DynamoDB table name!
#     dynamodb_table = "terraform-up-and-running-locks"
#     encrypt        = true
#   }
# }

/*
Creación de una instancia en AWS.
User Data es usado para enviar un conjunto de comandos que serán ejecutados en el primer boot de la maquina. 
User Data Detalles: https://bloggingnectar.com/aws/automate-your-ec2-instance-setup-with-ec2-user-data-scripts/
*/
# resource "aws_instance" "example" {
#   ami                    = "ami-0c55b159cbfafe1f0"
#   vpc_security_group_ids = [aws_security_group.instance.id]
#   instance_type          = "t2.micro"

#   // El <<-EOF y EOF son Terraform heredoc syntax, permiten ingresar bloques de codigo sin necesidad de usar caracteres para romper e ir a la nueva linea.
#   # user_data = <<-EOF
#   #             #!/bin/bash
#   #             echo "Hello, World" > index.html
#   #             nohup busybox httpd -f -p ${var.server_port} &
#   #             EOF
#   # user_data = <<EOF
#   #       #!/bin/bash
#   #       echo "Hello, World" >> index.html
#   #       echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
#   #       echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
#   #       nohup busybox httpd -f -p ${var.server_port} &
#   #       EOF
#   user_data = data.template_file.user_data.rendered

#   tags = {
#     Name = "terraform-example"
#   }
# }

// Este recurso le dice a la VM Example que va a ser accedida por el puerto 8080 desde cualquier maquina en el mundo.
// El nuevo recurso es una lista de seguridad que va a ser creada.
resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  tags = {
    Name = "example instance security group"
  }
}


resource "aws_launch_configuration" "example" {
  # image_id        = "ami-0c55b159cbfafe1f0"
  image_id        = var.ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.id]

  # user_data = <<-EOF
  #             #!/bin/bash
  #             echo "Hello, World" > index.html
  #             nohup busybox httpd -f -p ${var.server_port} &
  #             EOF
  # user_data = <<EOF
  #       #!/bin/bash
  #       echo "Hello, World" >> index.html
  #       echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
  #       echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
  #       nohup busybox httpd -f -p ${var.server_port} &
  #       EOF
  # user_data = data.template_file.user_data.rendered
  user_data = (
    length(data.template_file.user_data[*]) > 0
    ? data.template_file.user_data[0].rendered
    : data.template_file.user_data_new[0].rendered
  )

  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  // Como no es posible eliminarlo primero dado que es usado en aws_autoscaling_group.example se debe invertir el comportamiento normal de Terraform, ahora lo crear, actualiza los recursos que dependen de este y luego elimina el recurso viejo.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  name = "${var.cluster_name}-${aws_launch_configuration.example.name}"

  launch_configuration = aws_launch_configuration.example.name
  #   vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  // Se usa de esta forma dado que la salida de las subnets son 6, las 3 adicionales son de andres cuando esta trabajando con functions de AWS. 
  vpc_zone_identifier = ["subnet-21d30b48",
    "subnet-6b050921",
  "subnet-804da3fb", ]
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  # When replacing this ASG, create the replacement first, and only delete the
  # original after
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg-example"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.custom_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_lb" "example" {
  name               = "${var.cluster_name}-asg-name"
  load_balancer_type = "application"
  // Se usa de esta forma dado que la salida de las subnets son 6, las 3 adicionales son de andres cuando esta trabajando con functions de AWS. 
  subnets = ["subnet-21d30b48",
    "subnet-6b050921",
  "subnet-804da3fb", ]
  # subnets            = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = "HTTP"
  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# resource "aws_security_group" "alb" {
#   name = "${var.cluster_name}-alb"

#   # Allow inbound HTTP requests
#   ingress {
#     from_port   = local.http_port
#     to_port     = local.http_port
#     protocol    = local.tcp_protocol
#     cidr_blocks = local.all_ips
#   }

#   # Allow all outbound requests
#   egress {
#     from_port   = local.any_port
#     to_port     = local.any_port
#     protocol    = local.any_protocol
#     cidr_blocks = local.all_ips
#   }
# }

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

# resource "aws"
resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

// Este es el recurso que me hizo doler la cabeza en cloud formation, aqui es mas sencillo de compprender y crear.
resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  /*   
    Warning: "condition.0.values": [DEPRECATED] use 'host_header' or 'path_pattern'
   condition {
    field  = "path-pattern"
    values = ["*"]
  } */

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-out-during-business-hours"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 10
  recurrence             = "0 9 * * *"
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-in-at-night"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name  = "${var.cluster_name}-high-cpu-utilization"
  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.example.name
  }

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Average"
  threshold           = 90
  unit                = "Percent"
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
  alarm_name  = "${var.cluster_name}-low-cpu-credit-balance"
  namespace   = "AWS/EC2"
  metric_name = "CPUCreditBalance"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.example.name
  }

  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Minimum"
  threshold           = 10
  unit                = "Count"
}
