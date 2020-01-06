# 4. How to Create Reusable Infrastructure with Terraform Modules

### Module Basics

A Terraform module is very simple: any set of Terraform configuration files in a folder is a module. All of the configurations you’ve written so far have technically been modules, although not particularly interesting ones, since you deployed them directly (the module in the current working directory is called the root module). To see what modules are really capable of, you need to use one module from another module.

Module Inputs
Module Locals
Module Outputs
Module Gotchas
File Paths
Inline Blocks
Module Versioning
Conclusion

## Module

Una carpeta con varios archivos tf realmente son un modulo, anteriormente no lo estabamos usando como -modulos- propiamente dado que ejecutavamos todo al ejecutar el comando terraform apply.

A continuación la sintaxis del uso de modulos en un tf.

```terraform
module "<NAME>" {
  source = "<SOURCE>"

  [CONFIG ...]
}
```

e.g.:

```terraform
module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-stage"
  db_remote_state_bucket = "(YOUR_BUCKET_NAME)"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"
}
```

where NAME is an identifier you can use throughout the Terraform code to refer to this module (e.g., web-service), SOURCE is the path where the module code can be found (e.g., modules/services/webserver-cluster), and CONFIG consists of one or more arguments that are specific to that module. For example, you can create a new file in stage/services/webserver-cluster/main.tf and use the webserver-cluster module in it as follows:

## Module Inputs

Como en una función en el lenguaje de programación node.js, puede recibir parametros:

```javascript
const func = function(firtsName, lastName) {
  console.log(`Hola ${firtsName} ${lastName}`);
};

// Llamada de dicha función en cualquier parte del código

func("Emerson", "Volkov");
```

Nosotros ya vimos un mecanismo para las variables, te acuerdas del archivo var.tf `modules/services/webserver-cluster/var.tf` a diferencia de las primeras 3 variables estas estan sin ningun valor inicial o es establecida en el proceso.

## Module Locals

Muchas veces queremos definir una serie de variables para hacer refactoring del modulo, asi no tenemos que estan repitiendo el puerto o el protocolo por todos los documentos de dicho modulo.

Las variables locales entrar a solucionar este problema haciendo el código mas legible. Lo mejor es que no son accedidas desde afuerda y no se comparten entre modulos, quedan dedicadas para el modulo donde la defines.

e.g.:

```terraform
# var.tf file
locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

```

El modo de emplearlas es `local.<NAME>` `local.http_port`

Local ayudan a que tú código sea mucho mas legible.

## Module Outputs

Vamos a ver en el proceso de creación diferentes mecanismos para escribir nuestro codigo IaC. Uno de estos mecanismos es la posibilidad de tener codigo dedicado por ambiente, esto quiere decir que el modulo sirve como base y lo que es peculir del ambiente lo dejo directamente alojado alli.

Pero, ¿Qué pasaria si necesito una salida del modulo como entrada de mi código peculiar?

Ya hemos visto como esto funciona con outputs, asi que podemos definir outputs a nuestro modulo en su archivo outputs.tf y luego ese valor ser usado en nuestro código peculiar.

e.g.:
Este código se encuentra en los outputs.tf que se encuentra en /modules/services/webserver-cluster/outputs.tf

```terraform
output "asg_name" {
  value       = aws_autoscaling_group.example.name
  description = "The name of the Auto Scaling Group"
}
```

Puedes usar la siguiente syntaxis para acceder a las variables de salida del modulo `module.<MODULE_NAME>.<OUTPUT_NAME>` e.g.: `module.frontend.asg_name`

Tambien puedes ser usado como **pass through** lo cual te permite tener una salida del modulo como si fuera una salida de tu ambiente.

e.g.:
Este código lo pueden encontrar en outputs.tf que se encuentra en /prod/services/webserver-cluster/var.tf

```terraform
output "alb_dns_name" {
  value       = module.webserver_cluster.alb_dns_name
  description = "The domain name of the load balancer"
}
```

Su clúster de servidores web está casi listo para implementarse. Lo único que queda es tener en cuenta algunas trampas.

## Module Gotchas

### File paths

Terraform ejecuta el código y toma algunas variables por default en el camino, una de ella es el path. Recuerden que estamos usando file en el despliegue de nuestro webserver-cluster, pero ahora dado que estamos ejecutandolo a tráves de un modulo el path es relativo y lo toma desde donde se ejecuta el comando de terraform, lo cual devuelve un error en el momento de quere ejecutar nuestro IaC project.

Para esto Terraform ofrece `path.<TYPE>` el cual tiene los siguiente tipos de path reference.

##### path.module

Devuelve la ruta del sistema de archivos del módulo donde se define la expresión.

##### path.root

Devuelve la ruta del sistema de archivos del módulo raíz.

##### path.cwd

Devuelve la ruta del sistema de archivos del directorio de trabajo actual. En el uso normal de Terraform, esto es lo mismo que path.root, pero algunos usos avanzados de Terraform lo ejecutan desde un directorio distinto del directorio del módulo raíz, lo que hace que estas rutas sean diferentes.

e.g.:

```terraform
file("${path.module}/user-data.sh")
```

### Inline blocks

Dentro de los diferentes recursos que se pueden usar en Terraform con los diferentes providers hay diferentes opciones de definirlos, una de esas opciones en inline blocks lo cual deja un solo recurso haciendo varias cosas al tiempo. Recordemos clean code, siempre una función debe hacer una unica cosa y nada más.

e.g.:
Aqui un ejemplo que tenemos hecho en nuestro proyecto y más especificamente en nuestro modulo webserver-cluster.

```terraform
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"

  ingress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  egress {
    from_port   = local.any_port
    to_port     = local.any_port
    protocol    = local.any_protocol
    cidr_blocks = local.all_ips
  }
}
```

Aqui debemos refactorizar el codigo y dejar todo separado permitiendo una mejor lectura del codigo.

e.g.:

```terraform
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}
```

Ambos recursos son completamente validos, el problema es que el inline block es menos felxible, en el momento que necesites hacer una configuración, el recurso entero debe ser actualizado, en cambio separandolo es mas facil de hacer cambios atomicos a el despliegue de tu infraestructura.

No usar las dos formas esto puede generar inconsistencias y reescritura de las reglas que pueden al final generar errores ya sean de syntaxis o errores logicos los cuales son más dificiles de indentificar.

Al desplegar todo en recursos separados puedes exponer los ID de dichos recursos y hacer tus propias configraciones al modulo sin necesidad de escribirlos directamente allí.

e.g.:
/modules/services/webserver-cluster/outputs.tf

```terraform
output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the Security Group attached to the load balancer"
}
```

Ahora imagine que en un ambiente de staging quiere exponer otro puerto por temas de gestion o configuración.

e.g.:
/stage/service/webserver-cluster/main.tf

```terraform
resource "aws_security_group_rule" "allow_testing_inbound" {
  type              = "ingress"
  security_group_id = module.webserver_cluster.alb_security_group_id

  from_port   = 12345
  to_port     = 12345
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

Este tipo de situaciones se pueden presentar en otros recursos como:

-- aws_security_group and aws_security_group_rule
-- aws_route_table and aws_route
-- aws_network_acl and aws_network_acl_rule

## Module Versioning

En el ejemplo de este capitulo nos podemos dar cuenta que tanto el ambiente de prod y de staging apuntan al mismo modulo. En el momento que yo quiera hacer cambios al modulo para hacer pruebas en staging va a afectar a prod por que comparten el mismo código base. La idea es trabajar con versiones de los modulos por esta razón deben quedar en diferentes proyectos en git para que se puedan importar en en el proyecto a traves de versiones tags del release.

Terraform soporta otros module sources fuera de local paths como: Git URLs, Mercurial URLs, y arbitrarias HTTP URLs.

Que tu código quede esparcido en diferentes proyectos Git pero esto tiene una gran ventaja, los equipos tienen roles y tareas diferentes por proyecto y de esa forma se evitan problemas en las dependencias en los ambientes.

Modules

Este repositorio define módulos reutilizables. Piense en cada módulo como un "plano" que define una parte específica de su infraestructura.

live

Este repositorio define la infraestructura en vivo que está ejecutando en cada entorno (stage, prod, mgmt, etc.). Piense en esto como las "casas" que construyó a partir de los "planos" en el repositorio de módulos.

El proceso es sencillo, debemos crear un proyecto en git dentro de modules.

e.g.:

```shell
$ cd modules
$ git init
$ git add .
$ git commit -m "Initial commit of modules repo"
$ git remote add origin "(URL OF REMOTE GIT REPOSITORY)"
$ git push origin master
```

También puede agregar una etiqueta al repositorio de módulos para usarla como número de versión. Si usa GitHub, puede usar la interfaz de usuario de GitHub para crear una versión, que creará una etiqueta debajo del capó. Si no está usando GitHub, puede usar la CLI de Git:

e.g.:

```shell
$ git tag -a "v0.0.1" -m "First release of webserver-cluster module"
$ git push --follow-tags
```

https://www.terraform.io/docs/modules/sources.html#github

Los nombres de las ramas no son estables, ya que siempre obtienes el último commit en una rama, que puede cambiar cada vez que ejecutas el comando init, y los hash sha1 no son muy amigables para los humanos. Las etiquetas Git son tan estables como una confirmación (de hecho, una etiqueta es solo un puntero a una confirmación), pero le permiten usar un nombre amigable y legible.

A particularly useful naming scheme for tags is semantic versioning. This is a versioning scheme of the format MAJOR.MINOR.PATCH (e.g., 1.0.4) with specific rules on when you should increment each part of the version number. In particular, you should increment the

MAJOR version when you make incompatible API changes,

MINOR version when you add functionality in a backward-compatible manner, and

PATCH version when you make backward-compatible bug fixes.
