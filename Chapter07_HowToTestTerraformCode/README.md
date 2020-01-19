# 7. How to Test Terraform Code

Manual Tests ✅
Manual Testing Basics ✅
Cleaning Up After Tests ✅
Automated Tests ✅
Unit Tests >> Código en Go
Integration Tests
End-to-End Tests
Other Testing Approaches
Conclusion

## Manual Tests

Hacer siempre la analogía con el desarrollo de código tradicional con algún lenguaje de programación como javascript, y pensar como se podría hacer el mismo proceso y como este se "traduce" a terraform y herramientas IaC.

## Manual Testing Basics

key testing takeaway
#1: when testing Terraform code, there is no localhost.

En el momento de validar la infraestructura se realiza el proceso como se haría en el desarrollo de un servidor web con javascript, se abre el navegador y se prueba que realmente este funcionando y entregando los datos esperados.

También ese mismo proceso se puede realizar con curl y un llamado http. Esto también aplica para otras herramientas como por ejemplo si despliego una base de datos mysql debo probar la conexión con un cliente de mysql y lanzar un comando de validación, o por ejemplo desplegar una VPN, debo usar un cliente de VPN y conectarme para realmente saber si esta funcionando bien etc etc. Ya agarraste la idea en este punto.

## Cleaning Up After Tests

key testing takeaway
#2 is: regularly clean up your sandbox environments.

Debe crearse una cultura donde se acostumbre a ejecutar terraform destroy para realmente validar que todo quede de nuevo en un estado Zero con el fin de asegurar que las siguientes pruebas puedan ser ejecutadas sin contratiempos. Adicionalmente se puede crear un proceso automatizado (cron) con el cual también se garantice que los recursos hayan sido eliminados.

- cloud-nuke
  Proyecto open source con el cual puedes asociar una cuenta y garantizar que todo haya sido eliminado. También puedes ejecutar la limpieza con ciertos parametros como por ejemplo eliminar todo que tenga mas de 2 días de desplegado.

`$ cloud-nuke aws --older-than 48h`

- Janitor Monkey

Homologo de cloud-nuke

- aws-nuke

Homologo de cloud-nuke

## Automated Tests

En términos generales, hay tres tipos de pruebas automatizadas:

- Unit tests

Se refiere a pruebas pequeñas de una pequeña unidad de código. Para probar que su código funciona en una variedad de escenarios. En lenguajes de programación de uso general se refiere a probar una clase o una función. Aquí se puede emular una base de datos y "hardcodear" los escenarios.

    * Se ejecutan rápido.
    * Obtiene feedback inmediato.

Esta limitado a que por si solo puede ejecutarse de manera correcta pero con otros componentes puede llegar a fallar.

- Integration tests

Verifica que multiples unidades de código funcionan correctamente conjuntamente. En lenguajes de programación de uso general se refiere a probar varias clases o funciónes de forma conjunta. Aquí si se debe validar directamente contra otro sistema, no se vale emularlo.

    * Se ejecutan en un periodo de tiempo más prolongado.
    * Se garantiza que los componentes se hablan entre si.

- End-to-end tests

Involucra ejecutar toda la infraestructura con sus aplicaciones. Usualmente estas pruebas son ejecutadas desde la perspectiva del usuario final. Aquí que se usan herramientas como Selenium para automatizar el comportamiento de un usuario final por ejemplo en una pagina web.

    * Recogen las dos anteriores pruebas y se prueba desde una perspectiva de usuario.
    * Se espera que se comporte de una forma esperada y que el usuario acepte dicho comportamiento.

## Unit Test

Para comprender como funcionan las pruebas unitarias, vamos a escribir un poco de código en un lenguaje de proposito general como lo es javascript.

> > > > > Revisar en el libro pero el momento dejo el espacio en blanco

#### Unit testing basics

key testing takeaway
#3: you cannot do pure unit testing for Terraform code.

Notece la palabra **pure**, aún es posible probar secciones de código de terraform en un ambiente real en una cuenta real. Aunque técnicamente son pruebas de integración pero es preferible llamar los despliegues de recursos pequeños unit test, para tener feedback inmediato de cada chunck.

- Estrategia básica:

1. Crear una genérica standalone module.
2. Crear un easy-to-deploy ejemplo para el modulo.
3. Ejecutar `terraform apply` para desplegar el ejemplo dentro de un ambiente real.
4. Verificar que el despliegue realmente funciona, esto varia dependiendo del servicio y la tecnología que se este probando http, vpn, ssh etc etc.
5. Ejecutar `terraform destroy` para limpiar el ambiente.

## ¿Cómo habría probado esto manualmente para estar seguro de que funciona? e implemente este esa prueba en código.

Puedes usar cualquier lenguaje de programación para escribir las pruebas. Se recomienda usar go dado que Gruntwork tiene una librería llamada terratest que admite probar una amplia variedad de infraestructura como herramientas de código (e.g., Terraform, Packer, Docker, Helm) en una amplia variedad de entornos (e.g., AWS, Google Cloud, Kubernetes).

Buscar en el capito
"To use Terratest, you need to do the following"

##############################################################################
key testing takeaway
#4: you must namespace all of your resources.
##############################################################################

##### Test stages

Cuando se esta probando el código solo una parte del proyecto, pero estamos haciendo pruebas de integración necesitamos todo que este desplegado, esto hace que si cambiamos algo de uno de los módulos el proyecto de pruebas va a validar todo el despliegue y va a correr todos los `terraform apply` indiferentemente si el código haya o no tenido cambios.

Imaginemos que solo hacemos un cambio en hello-world-app modulo

1. Run `terraform apply` on the mysql module.
2. Run `terraform apply` on the hello-world-app module.
3. Run validations to make sure everything is working.
4. Run `terraform destroy` on the hello-world-app module.
5. Run `terraform destroy` on the mysql module.

El anterior set de pruebas va a hacer que se vuelva a correr mysql, y este nunca tubo cambios, esto va a incluir al menos 5 minutos mas a las pruebas que son innecesarias.

Un ser te pruebas que mitigue esto se vería de la siguiente forma:

1. Run `terraform apply` on the mysql module.
2. Run `terraform apply` on the hello-world-app module.
3. Now, you start doing iterative development:
   - Make a change to the hello-world-app module.
   - Rerun `terraform apply` on the hello-world-app module to deploy your updates.
   - Run validations to make sure everything is working.
   - If everything works, move on to the next step. If not, go back to step (3a).
4. Run `terraform destroy` on the hello-world-app module.
5. Run `terraform destroy` on the mysql module.

El truco esta en el paso 3, aqui es importante saber si realmente es necesario correr mysql, esto lo hace **terratest**

##### Retries

En ocaciones las pruebas pueden fallar, y dichos fallos son agenos al código implementado/desarrollado. Oracle Cloud como cualquier otra nube puede en algun momento entregar un error ya sea por que no pude arrancar una maquina o algún servicio por alguna razón no pudo ser ejecutado.

Por esta razón en el código se puede controlar los errores mas comunides y así evitar estar tan pendiente de esos problemas y delegar esa tareas a las pruebas.

##### End-to-End Tests

La misma estrategia que se usa para hacer las pruebas de integración se deben usar para las pruebas de end-to-end.

Piramide de costos de ejecutar pruebas en las tres capas.

key testing takeaway
#5: smaller modules are easier and faster to test.

You saw in the previous sections that it required a fair amount of work with namespacing, dependency injection, retries, error handling, and test stages to test even a relatively simple hello-world-app module. With larger and more complicated infrastructure, this only becomes more difficult. Therefore, you want to do as much of your testing as low in the pyramid as you can because the bottom of the pyramid offers the fastest, most reliable feedback loop.

When testing Terraform code, there is no localhost

    Therefore, you need to do all of your manual testing by deploying real resources into one or more isolated sandbox environments.

Regularly clean up your sandbox environments

    Otherwise, the environments will become unmanageable, and costs will spiral out of control.

You cannot do pure unit testing for Terraform code

    Therefore, you have to do all of your automated testing by writing code that deploys real resources into one or more isolated sandbox environments.

You must namespace all of your resources

    This ensures that multiple tests running in parallel do not conflict with one another.

Smaller modules are easier and faster to test

    This was one of the key takeaways in Chapter 6, and it’s worth repeating in this chapter, too: smaller modules are easier to create, maintain, use, and test.
