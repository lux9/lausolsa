# Documentación RubyCRM

## Estructura de carpetas

### ./config

Guarda archivos de configuración para los distintos entornos (development, local y production). En los mismos se mantienen los usuarios y contraseñas para acceder a las bases de datos.

### ./controllers

La carpeta controllers, guarda las rutas y respuestas que acepta la aplicación. Está organizado en objetos semánticos que heredan todos del ApplicationController y están separados según su URL de acceso.
  
> Por ejemplo la URL `/employee/*` cargará `./controllers/employee_controller.rb` y `./controllers/application_controller.rb`

Para más detalles revisa el archivo [CONTROLLERS.md](CONTROLLERS.md)

### ./documentation

Esta carpeta, contiene la documentación del programa, la primera página es [README.md](README.md) desde donde se desprenden sub-secciones

### ./helpers

La carpeta helpers, guarda distintos archivos con funciones comúnes que pueden llamarse desde los controllers. Los mismos se incluyen todos desde el `ApplicationController`, por lo tanto también en cada controlador hijo de éste. Usualmente las funciones se llaman del controlador o vistas con su mismo nombre, pero puede no ser siempre así.
  
> Por ejemplo la función `action_log_for_employee_absence` del archivo `./helpers/action_log_helper.rb` se llama cada vez que se crea, borra o modifica algún atributo de un empleado. Mayormente se encuentra usada en el archivo `./controllers/employee_controller.rb` pero también cuando se carga una ausencia desde `./controllers/absence_controller.rb`, o se asigna un turno desde `./controllers/shift_controller.rb`

Para más detalles revisa el archivo [HELPERS.md](HELPERS.md)

### ./migrations

Esta carpeta contiene operaciones ordenadas que deben hacerse en la base de datos para que el código funcione. Las mismas son manejadas por el comando rake.

> Un ejemplo de actualización sería el siguiente: `RACK_ENV=XXX rake "db:migrate"`, el environment (xxx) se reemplaza usualmente por "local", dado que los otros se corren automáticamente al iniciar.

### ./models

Esta carpeta contiene las definiciones de clases, que heredan de `Sequel::Model`. Las mismas tienen un match exacto en la base de datos, pero con una convención de nombres diferente. En cada clase se indican también las relacciones entre esa tabla y otras. 

> Por ejemplo la clase `EmployeeFile` (en `employee_file.rb`) está enlazada a la tabla `employee_files` de la base de datos.   
> A su vez un empleado (`Employee`) puede tener _uno-o-más_ archivos (`EmployeeFile`), pero los archivos sólo se asocian a un único empleado.

### ./public

Esta carpeta contiene imágenes y otros archivos estáticos que se pueden descargar o cargar desde la página web. Ejemplos de archivos que se cargan y descargan serían los avatares de empleados (`./public/avatars*`), o logos de clientes (`./public/logos/*`). Otros de sólo lectura serían los templates por defecto para importar clientes, empleados o estaciones de trabajo.

### ./spec

Esta carpeta contiene la configuración necesaria para generar tests unitarios o de integración. Al momento se encuentra vacía.

### ./views

Esta carpeta contiene los archivos de vistas (HTML / JavaScript) que se utilizan para generar la página de inicio, distintos formularios de tipo modal o "pop-in", y las páginas de cada sección. 

> Por ejemplo la página `/employee/new` (para crear un nuevo empleado), importa el diseño general (`./views/layout.rb`), la vista particular `./views/employee_new.erb` y las quick actions (`./views/forms/quick_actions.erb`), que están disponibles en todos los enlaces.

### ./

Existen varios archivos en la carpeta principal que tiene un uso particular. Entre ellos están...

- `.dockerignore`: configura exclusiones para el servicio Docker
- `.gitignore`: configura exclusiones para el servicio git
- `.gitlab-ci.yml`: configura el servicio de CI/CD de gitlab.com para generar una imágen de docker y deployarla al sitio automáticamente
- `.rspec`: configura el entorno de tests para que funcione correctamente
- `ci-utils.sh`: archivo con funciones utilitarias usadas en el proceso de CI/CD
- `config.ru`: archivo que es leido para iniciar el sitio web mediante el comando `rackup`
- `docker-compose.yml`: archivo que contiene la configuración necesaria para levantar una flota de dockers, necesaria por la solución
- `docker-compose-local.yml`: una variante del archivo de composición para correr la suite localmente con menos controles de seguridad
- `Dockerfile`: archivo de configuración de Docker que indica cómo se buildean los contenedores de docker de la aplicación
- `Gemfile`: archivo que lista las dependencias de la aplicación
- `Gemfile.lock`: archivo con versiones específicas que se usaron para empaquetar la aplicación (generado y leído por `bundler`)
- `Rakefile.rb`: archivo que configura los archivos necesarios para que `rake` pueda hacer migraciones contra la base de datos
- `README.md`: este archivo
- `traefik.toml`: configuración necesaria para el proxy traefik que decide a qué contenedor enviar las visitas según la URL
