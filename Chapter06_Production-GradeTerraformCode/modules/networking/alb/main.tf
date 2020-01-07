resource "aws_lb" "example" {
  # name               = "${var.cluster_name}-asg-name"
  name               = var.alb_name
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

resource "aws_security_group" "alb" {
  # name = "${var.cluster_name}-alb"
  name = var.alb_name
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
