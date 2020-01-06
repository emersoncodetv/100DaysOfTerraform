# Zero-Downtime Deployment

Ahora que su módulo tiene una API limpia y simple para implementar un clúster de servidores web, una pregunta importante es cómo actualizar ese clúster. Es decir, cuando realiza cambios en su código, ¿cómo implementa una nueva imagen de máquina de Amazon (AMI) en el clúster? ¿Y cómo lo hace sin causar tiempo de inactividad para sus usuarios?

```terraform
# /modules/services/webserver-cluster/var.tf
variable "ami" {
  description = "The AMI to run in the cluster"
  default     = "ami-0c55b159cbfafe1f0"
  type        = string
}

variable "server_text" {
  description = "The text the web server should return"
  default     = "Hello, World"
  type        = string
}
```

```terraform
# /modules/services/webserver-cluster/main.tf
...
data "template_file" "user_data" {
  .
  .
  .

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
    server_text = var.server_text
  }
}
...
```

```shell
# /modules/services/webserver-cluster/user-data-new.sh
#!/bin/bash

cat > index.html <<EOF
<h1>${server_text}</h1>
<p>DB address: ${db_address}</p>
<p>DB port: ${db_port}</p>
EOF

nohup busybox httpd -f -p ${server_port} &
```

```terraform
# /modules/services/webserver-cluster/main.tf
...
resource "aws_launch_configuration" "example" {
  image_id        = var.ami
  .
  .
  .
}
...
```

```terraform
# /live/stage/service/webserver-cluster/main.tf
...
module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  ami         = "ami-0c55b159cbfafe1f0"
  server_text = "New server text"

  .
  .
  .
}
...
```

Una ves de hacer estos cambios nos damos cuenta que aunque se apliquen los cambios como se ven a continuacion con terraform plan:

```shell
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  ~ update in-place
+/- create replacement and then destroy

Terraform will perform the following actions:

  # module.webserver_cluster.aws_autoscaling_group.example will be updated in-place
  ~ resource "aws_autoscaling_group" "example" {
        arn                       = "arn:aws:autoscaling:us-east-2:314418232935:autoScalingGroup:7b210b6e-8a21-4712-994c-bf872ece6a7c:autoScalingGroupName/tf-asg-20200106160048641100000002"
        availability_zones        = [
            "us-east-2a",
            "us-east-2b",
            "us-east-2c",
        ]
        default_cooldown          = 300
        desired_capacity          = 2
        enabled_metrics           = []
        force_delete              = false
        health_check_grace_period = 300
        health_check_type         = "ELB"
        id                        = "tf-asg-20200106160048641100000002"
      ~ launch_configuration      = "terraform-20200106160027559100000001" -> (known after apply)
        load_balancers            = []
        max_instance_lifetime     = 0
        max_size                  = 2
        metrics_granularity       = "1Minute"
        min_size                  = 2
        name                      = "tf-asg-20200106160048641100000002"
        protect_from_scale_in     = false
        service_linked_role_arn   = "arn:aws:iam::314418232935:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        suspended_processes       = []
        target_group_arns         = [
            "arn:aws:elasticloadbalancing:us-east-2:314418232935:targetgroup/terraform-asg-example/2532c22e3730cebb",
        ]
        termination_policies      = []
        vpc_zone_identifier       = [
            "subnet-21d30b48",
            "subnet-6b050921",
            "subnet-804da3fb",
        ]
        wait_for_capacity_timeout = "10m"

        tag {
            key                 = "DeployedBy"
            propagate_at_launch = true
            value               = "terraform"
        }
        tag {
            key                 = "Name"
            propagate_at_launch = true
            value               = "webservers-stage-asg-example"
        }
        tag {
            key                 = "Owner"
            propagate_at_launch = true
            value               = "team-bar"
        }
    }

  # module.webserver_cluster.aws_launch_configuration.example must be replaced
+/- resource "aws_launch_configuration" "example" {
        associate_public_ip_address      = false
      ~ ebs_optimized                    = false -> (known after apply)
        enable_monitoring                = true
      ~ id                               = "terraform-20200106160027559100000001" -> (known after apply)
        image_id                         = "ami-0c55b159cbfafe1f0"
        instance_type                    = "t2.micro"
      + key_name                         = (known after apply)
      ~ name                             = "terraform-20200106160027559100000001" -> (known after apply)
        security_groups                  = [
            "sg-0b58cd5403c8ac78a",
        ]
      ~ user_data                        = "043288b57ace7edbb9ac6857ec52d7702c61153d" -> "c8021c57c9072ba23c8f5c8c283f965eba1c2959" # forces replacement
      - vpc_classic_link_security_groups = [] -> null

      + ebs_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + no_device             = (known after apply)
          + snapshot_id           = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }

      + root_block_device {
          + delete_on_termination = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }
    }

Plan: 1 to add, 1 to change, 1 to destroy.
```

Como puede ver, Terraform quiere hacer dos cambios: primero, reemplace la configuración de inicio anterior por una nueva que tenga los datos de usuario actualizados; y segundo, modifique el Grupo de Auto Scaling en su lugar para hacer referencia a la nueva configuración de inicio. El problema es que simplemente hacer referencia a la nueva configuración de inicio no tendrá efecto hasta que el ASG lance nuevas instancias de EC2. Entonces, ¿cómo se instruye al ASG para implementar nuevas instancias?

A continuación, le mostramos cómo puede aprovechar esta configuración del ciclo de vida para obtener una implementación de tiempo de inactividad cero:

- Configure el parámetro de nombre de ASG para que dependa directamente del nombre de la configuración de inicio. Cada vez que cambia la configuración de inicio (lo que ocurrirá cuando actualice el AMI o los Datos del usuario), cambia su nombre y, por lo tanto, cambiará el nombre del ASG, lo que obliga a Terraform a reemplazar el ASG.

e.g.:
Asi es que se ve esa dependencia
/modules/services/webserver-cluster/main.tf

```terraform
...
resource "aws_autoscaling_group" "example" {
  # Explicitly depend on the launch configuration's name so each time it's
  # replaced, this ASG is also replaced
  name = "${var.cluster_name}-${aws_launch_configuration.example.name}"

 # When replacing this ASG, create the replacement first, and only delete the
  # original after
  lifecycle {
    create_before_destroy = true
  }

}
...
```

Definititivamente hay que verlo mas en detalle para cada nube, en este caso esto me hace ver que siempre va a forcar que el auto-scaling group se rehaga y esto hace que haya zero down time pero me imagino que puede cambiar segun el servicio en la nube que se este desplegando.
