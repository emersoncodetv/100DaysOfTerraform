# Condicionales

# Conditionals with the count Parameter

- count parameter

  - Utilizado para recursos condicionales

- for_each and for expressions

  - Se usa para recursos condicionales y bloques en línea dentro de un recurso

- if string directive
  - Usado para condicionales dentro de una cadena

### IF-STATEMENTS WITH THE COUNT PARAMETER

inline if con count / ternary syntax

`<CONDITION> ? <TRUE_VAL> : <FALSE_VAL>.``

e.g.:

`count = var.variable ? 1 : 0`

Veamos un ejempplo mas complejo imginen que necesitamos cear un par de alarmas para poder reportar cambios en la incraestructura. Y para este ejemplo vamos a usar cloud_watch

```terraform
resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
  alarm_name = "${var.cluster_name}-low-cpu-credit-balance"
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
```

El problema es que los créditos de CPU se aplican solo a las instancias tXXX (por ejemplo, t2.micro, t2.medium, etc.). Los tipos de instancia más grandes (p. Ej., M4.large) no usan créditos de CPU y no informan una métrica de CPUCreditBalance, por lo que si crea una alarma de ese tipo para esas instancias, la alarma siempre estará bloqueada en el estado INSUFFICIENT_DATA. ¿Hay alguna forma de crear una alarma solo si var.instance_type comienza con la letra "t"?

```terraform
  resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
  count = format("%.1s", var.instance_type) == "t" ? 1 : 0

  alarm_name = "${var.cluster_name}-low-cpu-credit-balance"
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
```

esta es la linea que hace la magia, la siguiente linea valida que solo las intancias de tipo tXXXX es decir todas las que comiencen con t se les va a aplicar este cloudwatch las otras no.

`count = format("%.1s", var.instance_type) == "t" ? 1 : 0`

Revisar en la documentacion de terraform format, pero para el caso que acabamos de ver lo que hace es validar que el string comience con t de lo contrario devuelve 0.

### IF-ELSE-STATEMENTS WITH THE COUNT PARAMETER

En el ejemplo anterior tambien se usa if-else statement pero en el caso anterior es ejecutarlo o dejarlo de ejecutar, que pasaria si necesitamos ejecutar un codigo completamente distinto para la parte verdadera y otra para la parte falsa.

Vamos a imaginar que necesitamos asignar unas politicas de seguridad a un usuario dependiendo del valor que llege.

e.g.:
politica de seguridad que solo deja leer o tener acceso a cloud watch.

```terraform
resource "aws_iam_policy" "cloudwatch_read_only" {
  name   = "cloudwatch-read-only"
  policy = data.aws_iam_policy_document.cloudwatch_read_only.json
}

data "aws_iam_policy_document" "cloudwatch_read_only" {
  statement {
    effect    = "Allow"
    actions   = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*"
    ]
    resources = ["*"]
  }
}
```

plitica de seguridad que da full control lectura y escritura

```terraform
resource "aws_iam_policy" "cloudwatch_full_access" {
  name   = "cloudwatch-full-access"
  policy = data.aws_iam_policy_document.cloudwatch_full_access.json
}

data "aws_iam_policy_document" "cloudwatch_full_access" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:*"]
    resources = ["*"]
  }
}
```

EL OBJETIVO es elegir uno de los dos recursos anteriores basados en un
parametro.

e.g.:
Ejemplo de parametro

```terraform
variable "give_neo_cloudwatch_full_access" {
  description = "If true, neo gets full access to CloudWatch"
  type        = bool
}
```

Puedes usar `COUNT` para cada uno de los recursos:

e.g.:

```terraform
resource "aws_iam_user_policy_attachment" "neo_cloudwatch_full_access" {
  count = var.give_neo_cloudwatch_full_access ? 1 : 0

  user       = aws_iam_user.example[0].name
  policy_arn = aws_iam_policy.cloudwatch_full_access.arn
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_read_only" {
  count = var.give_neo_cloudwatch_full_access ? 0 : 1

  user       = aws_iam_user.example[0].name
  policy_arn = aws_iam_policy.cloudwatch_read_only.arn
}
```

Si se dan cuenta aqui es la misma condicion pero la diferenia es el valor en true y else.

```
 if-clause
count = var.give_neo_cloudwatch_full_access ? 1 : 0
 else-clause
count = var.give_neo_cloudwatch_full_access ? 0 : 1
```

Imaginemos que necesitamos tener la opcion en nuestro proyecto websever-cluster de poder usar una configuracion inicial diferente sh file para nuestro servidor

Primer debemos tener dos sh file, pero necesitamos crear una condición con el fin de tener acceso a uno u otro.

e.g.:

```terraform
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
  }
}
```

Ahora dependiendo del output de las otras dos sentencias necesitamos asociar dicho template a el servidor en el momento que se lanza la maquina.

e.g.:

```terraform
resource "aws_launch_configuration" "example" {
  image_id        = "ami-0c55b159cbfafe1f0"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.id]

  user_data = (
    length(data.template_file.user_data[*]) > 0
      ? data.template_file.user_data[0].rendered
      : data.template_file.user_data_new[0].rendered
  )

  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}
```

El truco lo hace la siguiente linea de codigo

```
  user_data = (
    length(data.template_file.user_data[*]) > 0
      ? data.template_file.user_data[0].rendered
      : data.template_file.user_data_new[0].rendered
  )
```

esta linea `length(data.template_file.user_data[*]) > 0` verifica si en el primer template se ejecuto algo, de lo contrario el sistema sabe que se ejecuto el segundo el cual se encuentra en el false

# Conditionals with for_each and for Expressions

Este es un ejemplo bobo, pero ayuda a ver el funcinamiento:

Imaginemos en el el map se envia Name para los tags el tema es que el tag name ya es asignado y necesitamos saltarnoslo por si algun equipo le da por agregar el tag en el variable map con tags.

```terraform

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = ["subnet-21d30b48",
    "subnet-6b050921",
  "subnet-804da3fb", ]
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  # No queremos que este sea sobre escrito
  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg-example"
    propagate_at_launch = true
  }

  # Con lo que se encuentra aquí
  dynamic "tag" {
    for_each = var.custom_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
```

Para hacer esto podemos usar `for Expressions` como lo vemos a continuacion

```terraform
  dynamic "tag" {
    for_each = {
      for key, value in var.custom_tags:
      key => upper(value)
      if key != "Name"
    }

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
```

En ese mismo ejemplo nos damos cuenta que todos los tags fuera de name van a ser en minuscula, esto tambien ayuda a definir reglas y que se cumplan a la hora de describir la infraestructura.

# Conditionals with the if String Directive

e.g.: \_PLAYGROUND/2_CONDITIONALS/ConditionalsWithTheIfStringDirective/if_else.tf

Este tipo de string tiene su variacion en if y if-else

`%{ if <CONDITION> }<TRUEVAL>%{ endif }``

`%{ if <CONDITION> }<TRUEVAL>%{ else }<FALSEVAL>%{ endif }``

Donde puede ser usado en una sola linea para evaluar

e.g.:

```terraform
variable "name" {
  description = "A name to render"
  type        = string
}

output "if_else_directive" {
  value = "Hello,
  %{ if var.name != "" }
    ${var.name}
  %{ else }
    (unnamed)
  %{ endif }"
}
```

```terraform
output "if_else_directive" {
  value = "Hello, %{ if var.name != "" }${var.name}%{ else }(unnamed)%{ endif }"
}
```

```shell
$ terraform apply -var name="World"

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

if_else_directive = Hello, World
```

```shell
$ terraform apply -var name=""

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

if_else_directive = Hello, (unnamed)
```
