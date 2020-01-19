# 6. Production-Grade Terraform Code

Why It Takes So Long to Build Production-Grade Infrastructure ✅
The Production-Grade Infrastructure Checklist ✅
Production-Grade Infrastructure Modules
Small Modules ✅
Composable Modules ✅
Testable Modules ✅
Releasable modules ✅
Beyond Terraform Modules ✅
Conclusion

## Why It Takes So Long to Build Production-Grade Infrastructure

DevOps is in the Stone Ages
yak shaving
long checklist of tasks

Accidental complexity refers to the problems imposed by the particular tools and processes you’ve chosen, as opposed to essential complexity, which refers to the problems inherent to whatever it is that you’re working on.3

## The Production-Grade Infrastructure Checklist

## Production-Grade Infrastructure Modules

### Small Modules

80 x 80
80 Caracteres por linea y
80 lineas de codigo por modulo.

- Los módulos grandes son lentos.
- Los módulos grandes son inseguros.
- Los módulos grandes son arriesgados.
- Los módulos grandes son difíciles de entender.
- Los módulos grandes son difíciles de revisar.
- Los módulos grandes son difíciles de probar.

La primera regla de las funciones es que deben ser pequeñas. La segunda regla de las funciones es que deberían ser más pequeñas que eso.

Robert C. Martin

### Composable Modules

e.g.:
function composition

```ruby
# Simple function to do addition
def add(x, y)
  return x + y
end

# Simple function to do subtraction
def sub(x, y)
  return x - y
end

# Simple function to do multiplication
def multiply(x, y)
  return x * y
end
```

```ruby
# Complex function that composes several simpler functions
def do_calculation(x, y)
  return multiply(add(x, y), sub(x, y))
end
```

This is function composition at work: you’re building up more complicated behavior (a “Hello, World” app) from simpler parts (ASG and ALB modules). A fairly common pattern you’ll see with Terraform is that you’ll have at least two types of modules:

##### Generic modules
Modules such as asg-rolling-deploy and alb are the basic building blocks of your code, reusable across a wide variety of use cases. You’ve already seen them used to deploy a “Hello, World” app, but you could also use the exact same modules to deploy, for example, an ASG to run a Kafka cluster or a completely standalone ALB that can distribute load across many different apps (running one ALB for all apps is cheaper than one ALB for each app).

##### Use-case-specific modules

Modules such as hello-world-app combine multiple generic modules to serve one specific use case such as deploying the “Hello, World” app.

### Testable Modules

##### A manual test harness

You can use this example code while working on the asg-rolling-deploy module to repeatedly deploy and undeploy it by manually running terraform apply and terraform destroy to check that it works as you expect.

##### An automated test harness

As you will see in Chapter 7, this example code is also how you create automated tests for your modules. I typically recommend that tests go into the test folder.

##### Executable documentation

If you commit this example (including README.md) into version control, other members of your team can find it, use it to understand how your module works, and take the module for a spin without writing a line of code. It’s both a way to teach the rest of your team and, if you add automated tests around it, a way to ensure that your teaching materials always work as expected.

### Releasable modules

Ya vimos en un capitulo como podemos hacer para versionar nuestros modulos. Pero solo para recordar el código aqui esta:

```shell
$ git tag -a "v0.0.5" -m "Create new hello-world-app module"
$ git push --follow-tags
```

For example, to deploy version v0.0.5 of your hello-world-app module in the staging environment, put the following code into live/stage/services/hello-world-app/main.tf:

```terraform
  provider "aws" {
    region = "us-east-2"

    # Allow any 2.x version of the AWS provider
    version = "~> 2.0"
  }

  module "hello_world_app" {
    # TODO: replace this with your own module URL and version!!
    source = "git@github.com:foo/modules.git//services/hello-world-app?ref=v0.0.5"

    server_text            = "New server text"
    environment            = "stage"
    db_remote_state_bucket = "(YOUR_BUCKET_NAME)"
    db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"

    instance_type      = "t2.micro"
    min_size           = 2
    max_size           = 2
    enable_autoscaling = false
  }
```

Next, pass through the ALB DNS name as an output in live/stage/services/hello-world-app/outputs.tf:

```terraform
output "alb_dns_name" {
  value       = module.hello_world_app.alb_dns_name
  description = "The domain name of the load balancer"
}
```

If that works well, you can then deploy the exact same version—and therefore, the exact same code—to other environments, including production. If you ever encounter an issue, versioning also gives you the option to roll back by deploying an older version.

### Beyond Terraform Modules

##### Provisioners

Terraform provisioners are used to execute scripts either on the local machine or a remote machine when you run Terraform, typically to do the work of bootstrapping, configuration management, or cleanup. There are several different kinds of provisioners, including local-exec (execute a script on the local machine), remote-exec (execute a script on a remote resource), chef (run Chef Client on a remote resource), and file (copy files to a remote resource).

e.g.:

```terraform
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo \"Hello, World from $(uname -smp)\""
  }
}
```

OJO!!! Esto se ejecuta en la maquina local en el Mac... revisar la salida
When you run terraform apply on this code, it prints “Hello, World from” and then the local operating system details using the uname command:

salida:

```shell
$ terraform apply

(...)

aws_instance.example (local-exec): Hello, World from Darwin x86_64 i386

(...)
```

Aqui si hay que tener mucha paciencia dado que se esta ejecutando un codigo en un lugar con pribililegion entonces se debe tener en cuenta la seguridad.

Trying out a remote-exec provisioner is a little more complicated. To execute code on a remote resource, such as an EC2 Instance, your Terraform client must be able to do the following:

- Communicate with the EC2 Instance over the network
  You already know how to allow this with a security group.

- Authenticate to the EC2 Instance
  The remote-exec provisioner supports SSH and WinRM connections. Since you’ll be launching a Linux EC2 Instance (Ubuntu), you’ll want to use SSH authentication. And that means you’ll need to configure SSH keys.

Let’s begin by creating a security group that allows inbound connections to port 22, the default port for SSH:

```terraform
resource "aws_security_group" "instance" {
ingress {
from_port = 22
to_port = 22
protocol = "tcp"

    # To make this example easy to try out, we allow all SSH connections.
    # In real world usage, you should lock this down to solely trusted IPs.
    cidr_blocks = ["0.0.0.0/0"]

}
}


```

Y esto es solo para abrir el puerto... ver el ejemplo completo en Oreally

Next, let’s add the remote-exec provisioner to this EC2 Instance:

```terraform
resource "aws_instance" "example" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = aws_key_pair.generated_key.key_name

  provisioner "remote-exec" {
    inline = ["echo \"Hello, World from $(uname -smp)\""]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = tls_private_key.example.private_key_pem
  }
}
```

PROVISIONERS VERSUS USER DATA

##### Provisioners with null_resource

Provisioners can be defined only within a resource, but sometimes, you want to execute a provisioner without tying it to a specific resource. You can do this using something called the null_resource, which acts just like a normal Terraform resource, except that it doesn’t create anything. By defining provisioners on the null_resource, you can run your scripts as part of the Terraform life cycle, but without being attached to any “real” resource:

```terraform
resource "null_resource" "example" {
  provisioner "local-exec" {
    command = "echo \"Hello, World from $(uname -smp)\""
  }
}
```

```terraform
resource "null_resource" "example" {
  # Use UUID to force this null_resource to be recreated on every
  # call to 'terraform apply'
  triggers = {
    uuid = uuid()
  }

  provisioner "local-exec" {
    command = "echo \"Hello, World from $(uname -smp)\""
  }
}
```

##### External data source

Provisioners will typically be your go-to for executing scripts from Terraform, but they aren’t always the correct fit.Sometimes, what you’re really looking to do is execute a script to fetch some data and make that data available withinthe Terraform code itself. To do this, you can use the external data source, which allows an external command thatimplements a specific protocol to act as a data source.

```terraform
data "external" "echo" {
  program = ["bash", "-c", "cat /dev/stdin"]

  query = {
    foo = "bar"
  }
}

output "echo" {
  value = data.external.echo.result
}

output "echo_foo" {
  value = data.external.echo.result.foo
}
```

Conclusion
Now that you’ve seen all of the ingredients of creating production-grade Terraform code, it’s time to put them together. The next time you begin to work on a new module, use the following process:

Go through the production-grade infrastructure checklist in Table 6-2 and explicitly identify the items you’ll be implementing and the items you’ll be skipping. Use the results of this checklist, plus Table 6-1, to come up with a time estimate for your boss.

Create an examples folder and write the example code first, using it to define the best user experience and cleanest API you can think of for your modules. Create an example for each important permutation of your module and include enough documentation and reasonable defaults to make the example as easy to deploy as possible.

Create a modules folder and implement the API you came up with as a collection of small, reusable, composable modules. Use a combination of Terraform and other tools like Docker, Packer, and Bash to implement these modules. Make sure to pin your Terraform and provider versions.

Create a test folder and write automated tests for each example.
