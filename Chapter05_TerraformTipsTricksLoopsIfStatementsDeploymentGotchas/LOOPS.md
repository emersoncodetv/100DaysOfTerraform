# Loop Count

Si quiero crear tres usuarios lo que deberia hacer sin loop es copiar y pegar el codigo como se muestra a continuación para hacer que se creen los tres usuarios

```terraform
provider "aws" {
  region = "us-east-2"
}

resource "aws_iam_user" "example" {
  name = "neo"
}
resource "aws_iam_user" "example" {
  name = "joe"
}
resource "aws_iam_user" "example" {
  name = "leo"
}
```

# This is just pseudo code. It won't actually work in Terraform.

pero si quisiera hacer un loop y crear los tres usuarios sin repetir codigo haria algo parecido a esto... recueda que este codigo no se ejecuta.

```terraform
for (i = 0; i < 3; i++) {
  resource "aws_iam_user" "example" {
    name = "neo"
  }
}
```

Así es como se crean tres usuarios, esto seria equivalente al codigo anterior, un problema con este codigo es que los tres usuarios ventrian a tener el mismo nombre. Lo que desencadenaria un errror.

```terraform
resource "aws_iam_user" "example" {
  count = 3
  name  = "neo"
}
```

# This is just pseudo code. It won't actually work in Terraform.

Uno vedria usando el indice para diferenciar cada usuario, pero entonces cada usuario quedaria con el nombre neo.0, neo.1 y neo.2 lo cual no deja que sea user friendly recuerda que el codigo a continuacion no es valido.

```terraform
for (i = 0; i < 3; i++) {
  resource "aws_iam_user" "example" {
    name = "neo.${i}"
  }
}
```

e.g.:
Este es el verdadero ejemplo si quieres tener tres usuario pero recuerda que el nombre no seria user friendly.

```terraform
resource "aws_iam_user" "example" {
  count = 3
  name  = "neo.${count.index}"
}
```

Para lo nombres sean diferentes debemos crear una variable de tipo lista de strings lo cual nos facilitaria el trabajo para declarar lo nombres y al mismo tiempo aislar los nombres en otro archivo de variables.

```terraform
variable "user_names" {
  description = "Create IAM users with these names"
  type        = list(string)
  default     = ["neo", "joe", "leo"]
}

resource "aws_iam_user" "example" {
  count = length(var.user_names)
  name  = var.user_names[count.index]
}
```

recordemos que lenght viene hacer una de las funciones de Terraform (built-in), las que uno puede probar desde `terraform console`.

length tambien funciona con string y maps

Para acceder a un valor del arrey especifico en la variable user_names es igual que en la mayoria de lenguajes de programación `var.user_names[count.index]`.

# Array lookup syntax

`ARRAY[<INDEX>]`

# Outputs

Ahora si yo quiero acceder a uno de los recursos creados con `aws_iam_user` debo especificarlo, asumamos que queremos acceder a neo, seria de la sigueinte manera.

syntax `<PROVIDER>\_<TYPE>.<NAME>[INDEX].ATTRIBUTE``

e.g.:

```terraform
output "neo_arn" {
  value       = aws_iam_user.example[0].arn
  description = "The ARN for user Neo"
}
```

Y si quiero acceder a todos e imprimirlos en la salida.

\* es un caracter comodin el cual le dice que debe entregar todo lo que hay en el array.

```terraform
output "all_arns" {
  value       = aws_iam_user.example[*].arn
  description = "The ARNs for all users"
}
```

# Issues

1. no se puede usar en inline blocks: Un "bloque en línea" es un argumento que se establece dentro de un recurso con el siguiente formato:

```terraform
resource "xxx" "yyy" {
  <NAME> {
    [CONFIG...]
  }
}
```

e.g.: Tags en el siguiente bloque de codigo

```terraform
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  target_group_arns    = [aws_lb_target_group.asg.arn]
  health_check_type    = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}
```

pero aqui biene el problema, si quieres hacer que tags sea dinamico y que solo le pases un array para generar los tags dinamicos no va a funcionar, count en inline blocks no esta soportado.

2. El segundo issue es mas comlejo dado que imaginemos que queremos remover uno de los valores del array que creamos en el ejemplo anterior.

e.g.:

```terraform
variable "user_names" {
  description = "Create IAM users with these names"
  type        = list(string)
  default     = ["neo", "leo"]
}
```

Al usar terraform plan te daras cuenta que joe sera renombrado, pero ¿por qué? bueno en este caso lo ve siempre como un array con sus posiciones, es decir que joe ahora va a cambiar de nombre a leo y leo va a ser eliminado.

Para terraform esto es la realidad

```
aws_iam_user.example[0]: neo
aws_iam_user.example[1]: joe
aws_iam_user.example[2]: leo
```

Y si reduces el numero de item de tu array lo que va a intentar hacer terraform es mover todo hacia la izquierda y lo que quede por fuera lo elimina y lo que se mueve lo renombre y NO ES LO QUE QUEREMOS!!!

```
aws_iam_user.example[0]: neo
aws_iam_user.example[1]: leo
```

# Loop for_each

permite iterar por lists, sets, y maps. Puede ser usado para iterar por recursos como lo vimos en `count` pero adicionalmente permite iterar en `inline blocks`lo cual soluciona una de las limitantes de `count`.

syntax

```terraform
resource "<PROVIDER>_<TYPE>" "<NAME>" {
  for_each = <COLLECTION>

  [CONFIG ...]
}
```

COLLECTION es un conjunto o mapa para recorrer (las listas no son compatibles cuando se usa for_each en un recurso) y CONFIG consta de uno o más argumentos que son específicos de ese recurso. Dentro de CONFIG, puede usar each.key y each.value para acceder a la clave y al valor del elemento actual en COLLECTION.

> IMPORTANTE!!
>
> > las listas no son compatibles cuando se usa for_each en un recurso

e.g.:
Si se dan cuenta como no es soportado la lista en un recurso debemos transformarla en set.

```terraform
resource "aws_iam_user" "example" {
  for_each = toset(var.user_names)
  name     = each.value
}
```

Tipicamente usted usa `each.key` en maps dado que son objetos de tipo key/value pairs.

COUNT tiene una estructura de array en su salida por eso difiere a la hora de crear outputs de for_each.

e.g.:
Terraform plan de COUNT

```shell
  aws_iam_user.example[0] will be created
 + resource "aws_iam_user" "example" {
     + arn           = (known after apply)
     + force_destroy = false
     + id            = (known after apply)
     + name          = "neo"
     + path          = "/"
     + unique_id     = (known after apply)
   }

  aws_iam_user.example[1] will be created
 + resource "aws_iam_user" "example" {
     + arn           = (known after apply)
     + force_destroy = false
     + id            = (known after apply)
     + name          = "joe"
     + path          = "/"
     + unique_id     = (known after apply)
   }

  aws_iam_user.example[2] will be created
 + resource "aws_iam_user" "example" {
     + arn           = (known after apply)
     + force_destroy = false
     + id            = (known after apply)
     + name          = "leo"
     + path          = "/"
     + unique_id     = (known after apply)
   }
```

Accediendo output para COUNT

```terraform
output "neo_arn" {
  value       = aws_iam_user.example[0].arn
  description = "The ARN for user Neo"
}

output "all_arns" {
  value       = aws_iam_user.example[*].arn
  description = "The ARNs for all users"
}
```

e.g.:
Terraform plan de FOR EACH

```shell
  # aws_iam_user.example["joe"] will be created
  + resource "aws_iam_user" "example" {
      + arn           = (known after apply)
      + force_destroy = false
      + id            = (known after apply)
      + name          = "joe"
      + path          = "/"
      + unique_id     = (known after apply)
    }

  # aws_iam_user.example["leo"] will be created
  + resource "aws_iam_user" "example" {
      + arn           = (known after apply)
      + force_destroy = false
      + id            = (known after apply)
      + name          = "leo"
      + path          = "/"
      + unique_id     = (known after apply)
    }

  # aws_iam_user.example["neo"] will be created
  + resource "aws_iam_user" "example" {
      + arn           = (known after apply)
      + force_destroy = false
      + id            = (known after apply)
      + name          = "neo"
      + path          = "/"
      + unique_id     = (known after apply)
    }
```

Accediendo outputs para FOR EACH

```terraform
output "all_users" {
  value = aws_iam_user.example
}

all_users = {
  "morpheus" = {
    "arn" = "arn:aws:iam::123456789012:user/morpheus"
    "force_destroy" = false
    "id" = "morpheus"
    "name" = "morpheus"
    "path" = "/"
    "tags" = {}
  }
  "neo" = {
    "arn" = "arn:aws:iam::123456789012:user/neo"
    "force_destroy" = false
    "id" = "neo"
    "name" = "neo"
    "path" = "/"
    "tags" = {}
  }
  "trinity" = {
    "arn" = "arn:aws:iam::123456789012:user/trinity"
    "force_destroy" = false
    "id" = "trinity"
    "name" = "trinity"
    "path" = "/"
    "tags" = {}
  }
}

output "all_arns" {
  value = values(aws_iam_user.example)[*].arn
}

all_arns = [
  "arn:aws:iam::123456789012:user/morpheus",
  "arn:aws:iam::123456789012:user/neo",
  "arn:aws:iam::123456789012:user/trinity",
]
```

El otro problema de COUNT era que si querias remover uno de los valores del array que esta en la mitan empezaba a tener un comportamiento no deseado de renombrar recursos y eliminar otros.

Ahora es mucho mas facil dado que como estan referenciados por el nombre como un map y no por indice como un array con count es mas facil remover el elemento deseado.

si removemos de la lista a joe ahora tenemos lo siguiente

```terraform
$ terraform plan

Terraform will perform the following actions:

  # aws_iam_user.example["trinity"] will be destroyed
  - resource "aws_iam_user" "example" {
      - arn           = "arn:aws:iam::123456789012:user/trinity" -> null
      - name          = "joe" -> null
    }

Plan: 0 to add, 0 to change, 1 to destroy.
```

Donde se puede evidenciar que solo ese recurso va a ser removido y los otros quedan intactos.

Las dos razones mencionadas con anterioridad son las razones de peso para preferir FOR EACH sobre COUNT cuando se están creando recursos del mismo tipo multiples veces.

Refiérase al ejemplo del ASG cuando recibe los diferentes tags a ser definidos allí, ahora va a poder encontrar un ejemplo muy sencillo en el cual se envían los diferentes tags que se quieren asociar al ASG y el FOR EACH podra asignarlos.

modules/services/webserver-cluster/variables.tf

```terraform
variable "custom_tags" {
  description = "Custom tags to set on the Instances in the ASG"
  type        = map(string)
  default     = {}
}
```

live/prod/services/webserver-cluster/main.tf

```terraform
module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-prod"
  db_remote_state_bucket = "(YOUR_BUCKET_NAME)"
  db_remote_state_key    = "prod/data-stores/mysql/terraform.tfstate"

  instance_type        = "m4.large"
  min_size             = 2
  max_size             = 10

  custom_tags = {
    Owner      = "team-foo"
    DeployedBy = "terraform"
  }

```

La sintaxis para cear FOR EACH en inline code es:

```terraform
dynamic "<VAR_NAME>" {
  for_each = <COLLECTION>

  content {
    [CONFIG...]
  }
}
```

e.g.:

```terraform
 dynamic "tag" {
    for_each = var.custom_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
```

# Loops with for Expressions

Que pasaria si yo quisiera convertir cada uno de los nombres de una lista en mayusculas... en este caso usaria un for Expression, este tipo de loop es completamente diferente a for each no confundir.

#### Python syntax list comprehension

e.g.:
el if es opcional `if len(name) < 5`

```python
names = ["neo", "joe", "leo"]

short_upper_case_names = [name.upper() for name in names if name == "neo"]
# upper_case_names = [name.upper() for name in names]

print short_upper_case_names

# Prints out: ['NEO']
```

#### Terraform syntax list comprehension

Terraform ofrece una forma similar de hacer lo mismo y la sintaxis es la siguiente:

`[for <ITEM> in <LIST> : <OUTPUT>`

```terraform
variable "names" {
  description = "A list of names"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}

output "upper_names" {
  value = [for name in var.names : upper(name)]
}
```

y al igual que en python le puedes definir un if para filtrar los valores

```terraform
variable "names" {
  description = "A list of names"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}

output "short_upper_names" {
  value = [for name in var.names : upper(name) if length(name) < 5]
}
```

Tambien te permite hacer loop for expression sombre un map con la siguiente sintaxis.

`[for <KEY>, <VALUE> in <MAP> : <OUTPUT>]`

e.g.:

```terraform
variable "hero_thousand_faces" {
  description = "map"
  type        = map(string)
  default     = {
    neo      = "hero"
    trinity  = "love interest"
    morpheus = "mentor"
  }
}

output "bios" {
  value = [for name, role in var.hero_thousand_faces : "${name} is the ${role}"]
}
```

También puede usar for expressions para generar un mapa en lugar de una lista con la siguiente sintaxis:

````shell
# Loop over a list and output a map
{for <ITEM> in <LIST> : <OUTPUT_KEY> => <OUTPUT_VALUE>}

# Loop over a map and output a map
{for <KEY>, <VALUE> in <MAP> : <OUTPUT_KEY> => <OUTPUT_VALUE>}
```
````

Las únicas diferencias son que (a) ajusta la expresión entre corchetes en lugar de llaves, y (b) en lugar de generar un solo valor en cada iteración, genera una clave y un valor, separados por una flecha. Por ejemplo, así es como puede transformar un mapa para poner todas las claves y valores en mayúsculas:

e.g.:

```terraform
variable "hero_thousand_faces" {
  description = "map"
  type        = map(string)
  default     = {
    neo      = "hero"
    trinity  = "love interest"
    morpheus = "mentor"
  }
}

output "upper_roles" {
  value = {for name, role in var.hero_thousand_faces : upper(name) => upper(role)}
}
```

output

```terraform
upper_roles = {
"MORPHEUS" = "MENTOR"
"NEO" = "HERO"
"TRINITY" = "LOVE INTEREST"
}
```

# Loops with the for String Directive

En el comienzo de este libro hablamos de strings y como hacer referencia de variables dentro de los strings.

```terraform
"Hello, ${var.name}"
```

**String directives** esto es lo que uno hacia en .net en MVC en los archivos de html, resivir una variable y con for o if statements crear dentro de string sentencias para mostrar algun valor en la pagina.

sintaxis

```terraform
%{ for <ITEM> in <COLLECTION> }<BODY>%{ endfor }
```

e.g.:
En el siguiente ejemplo se puede ver como en value se crear un bloque de codigo string con EOF y dentro de este podemos insertar un for o if statement.

```terraform
variable "names" {
  description = "Names to render"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}

output "for_directive" {
  value = <<EOF
%{ for name in var.names }
  ${name}
%{ endfor }
EOF
}
```

output
esta seria la salida, si se dan cuenta hay varios espacios en el resultado, podemos encargarnos de ello con ~

```shell
$ terraform apply

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

for_directive =
  neo

  trinity

  morpheus
```

e.g.: ~ remover espacios

```terraform
output "for_directive_strip_marker" {
  value = <<EOF
%{~ for name in var.names }
  ${name}
%{~ endfor }
EOF
}
```

output

```shell
for_directive_strip_marker =
  neo
  trinity
  morpheus
```
