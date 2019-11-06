## Detalle de controladores (controllers)

#### ./controllers/absence\_controller.rb (prefijo: /absence)

Este controlador maneja licencias de empleados, ausencias a turnos y períodos de no-disponibilidad

| MÉTODO   | URI                          | PRIVILEGIOS          | PROVEE     | DETALLES                                                                    |
|----------|------------------------------|----------------------|------------|-----------------------------------------------------------------------------|
| GET      | /list                        | :user                | html       | Devuelve una lista de ausencias recientes, actualmente en desuso            |
| GET      | /cancel/:employee\_absence\_id | :absence\_cancel      | html       | Cancela un período de ausencia ya cargado                                   |
| GET+POST | /assign                      | :absence\_assign      | html       | Carga la página de "versus" para asignar suplentes y/o procesa su resultado |
| GET      | /unassign/:absence\_id        | :absence\_unassign    | html       | Remueve un suplente de una ausencia                                         |
| POST     | /license/new                 | :absence\_license\_new | html       | Carga y asocia un parte médico a una ausencia                               |
| GET      | /new/:employee\_id            | :absence\_new         | html       | Muestra el formulario para cargar ausencias a empleados                     |
| POST     | /new/:employee\_id            | :absence\_new         | html, json | Genera el período de ausencia según formulario (GET)                        |
| POST     | /edit/:employee\_absence\_id   | :absence\_new         | html, json | Modifica un período de ausencia                                             |

#### ./controllers/action\_log\_controller.rb (prefijo: /action\_log)

Este controlador maneja el registro de cambios

| MÉTODO | URI                                     | PRIVILEGIOS | PROVEE | DETALLES                                                                      |
|--------|-----------------------------------------|-------------|--------|-------------------------------------------------------------------------------|
| GET    | /recent(/:current\_page?)                | :user       | html   | Devuelve una tabla con los últimos datos cargados al registro (action\_log)    |
| GET    | /client/:client\_id(/:current\_page?)     | :user       | html   | Devuelve la tabla de cambios que afectan a un cliente                         |
| GET    | /employee/:employee\_id(/:current\_page?) | :user       | html   | Devuelve la tabla de cambios que afectan a un empleado                        |
| GET    | /location/:location\_id(/:current\_page?) | :user       | html   | Devuelve la tabla de cambios que afectan a una estación de trabajo (location) |

#### ./controllers/alert\_controller.rb (prefijo: /alert)

Este controlador maneja las alertas

| MÉTODO | URI           | PRIVILEGIOS | PROVEE | DETALLES                                                   |
|--------|---------------|-------------|--------|------------------------------------------------------------|
| GET    | /list         | :user       | html   | Devuelve una tabla con las alertas activas actualmente     |
| GET    | /cleanup      | :user       | html   | Remueve de la tabla de alertas ausencias que ya ocurrieron |
| GET    | /client/:id   | :user       | html   | Devuelve la tabla de alertas que afectan a un cliente      |
| GET    | /employee/:id | :user       | html   | Devuelve la tabla de alertas que afectan a un empleado     |

#### ./controllers/application\_controller.rb (sin prefijo)

Este controlador es general, todos lo incluyen, además de rutas posee algunas funciones especiales, por ejemplo `auth()` obtiene la autenticación de un usuario antes de decidir si puede o no ver una ruta en particular, o `json\_to\_params` procesa datos enviados por JSON en vez de usando form\_data.

| MÉTODO | URI         | PRIVILEGIOS | PROVEE | DETALLES                                                                     |
|--------|-------------|-------------|--------|------------------------------------------------------------------------------|
| GET    | /           | :user       | html   | Muestra los íconos del home page                                             |
| GET    | /initialize |             | html   | Inicializa la base de datos por primera vez (debería pasarse a un migration) |
| GET    | /403        |             | html   | Se muestra esta página cuando un usuario intenta algo sin privilegios        |
| GET    | /404        |             | html   | Se muestra esta página cuando se ingresa a una URL inválida                  |
| GET    | /\*         |             | html   | Atrapa rutas que no hayan sido definidas y las envía a /404                  |

#### ./controllers/auth\_controller.rb (prefijo: /auth)

Este controlador maneja el proceso de autenticación (login)

| MÉTODO | URI     | PRIVILEGIOS | PROVEE | DETALLES                                                           |
|--------|---------|-------------|--------|--------------------------------------------------------------------|
| GET    | /       |             | html   | Envía al usuario a /auth/login                                     |
| GET    | /login  |             | html   | Muestra el formulario para iniciar sesión                          |
| POST   | /login  |             | html   | Procesa el formulario e inicia una sesión si los datos son válidos |
| GET    | /logout |             | html   | Anula la sesión activa                                             |

#### ./controllers/client\_controller.rb (prefijo: /client)

Este controlador maneja a los clientes

| MÉTODO | URI                    | PRIVILEGIOS       | PROVEE     | DETALLES                                                                  |
|--------|------------------------|-------------------|------------|---------------------------------------------------------------------------|
| GET    | /list(/:current\_page?) | :user             | html, json | Devuelve un listado de empleados                                          |
| GET    | /edit/:id              | :client\_new       | html       | Muestra el formulario para editar empleados                               |
| POST   | /edit/:id              | :client\_new       | html       | Procesa el formulario y modifica datos del empleado                       |
| GET    | /new                   | :client\_new       | html       | Muestra el formulario para crear clientes                                 |
| POST   | /new                   | :client\_new       | html       | Genera un nuevo cliente                                                   |
| POST   | /logo/:id              | :client\_logo      | html       | Modifica el logo de un cliente                                            |
| GET    | /archive/:id           | :client\_archive   | html       | Archiva (da de baja) a un cliente                                         |
| GET    | /unarchive/:id         | :client\_unarchive | html       | Desarchiva (da de alta) un cliente archivado                              |
| GET    | /delete/:id            | :client\_archive   | html       | Archiva un cliente (si tiene datos cargados) o lo elimina (si está vacío) |
| GET    | /:id(/:current\_page?)  | :user             | html, json | Devuelve los detalles y estaciones de trabajo de un cliente               |

#### ./controllers/control\_panel\_controller.rb (prefijo: /control\_panel

Este controlador muestra el panel de control y procesa cambios en el mismo

| MÉTODO   | URI                                 | PRIVILEGIOS        | PROVEE | DETALLES                                                    |
|----------|-------------------------------------|--------------------|--------|-------------------------------------------------------------|
| GET      | /list                               | :user              | html   | Muestra el panel de control                                 |
| GET      | /roles/new                          | :roles\_new         | html   | Muestra el formulario para crear roles (listas de permisos) |
| POST     | /roles/new                          | :roles\_new         | html   | Procesa el formulario y genera un nuevo rol                 |
| GET      | /roles/edit/:id                     | :roles\_new         | html   | Muestra el formulario para modificar un rol                 |
| POST     | /roles/edit/:id                     | :roles\_new         | html   | Modifica el rol según datos del formulario                  |
| GET      | /delete\_file\_type/:id               | :file\_types\_delete | html   | Elimina un tipo de archivo                                  |
| GET      | /delete\_job\_type/:id                | :job\_types\_delete  | html   | Elimina un tipo de trabajo                                  |
| GET      | /delete\_user/:id                    | :users\_delete      | html   | Elimina un usuario                                          |
| POST     | /new\_user                           | :users\_new         | html   | Genera un nuevo usuario                                     |
| POST     | /update\_user\_password               | :users\_password    | html   | Modifica la contraseña de un usuario                        |
| GET+POST | /update\_user\_role/:user\_id/:role\_id | :users\_role        | html   | Cambia el rol asignado a un usuario                         |
| POST     | /new\_file\_type                      | :file\_types\_new    | html   | Genera un nuevo tipo de archivo                             |
| POST     | /new\_job\_type                       | :job\_types\_new     | html   | Genera un nuevo tipo de trabajo                             |

#### ./controllers/document\_controller.rb (prefijo: /document)

Este controlador maneja el generador de documentos y la impresión de los mismos

| MÉTODO | URI                                       | PRIVILEGIOS        | PROVEE | DETALLES                                                                         |
|--------|-------------------------------------------|--------------------|--------|----------------------------------------------------------------------------------|
| GET    | /list(/:current\_page?)                    | :user              | html   | Muestra la lista de documentos cargados                                          |
| GET    | /new                                      | :document\_new      | html   | Muestra el formulario para crear una plantilla de documento                      |
| POST   | /new                                      | :document\_new      | html   | Procesa el formulario y genera una nueva plantilla de documento                  |
| GET    | /edit/:id                                 | :document\_new      | html   | Permite editar el texto plantilla del documento                                  |
| POST   | /edit/:id                                 | :document\_new      | html   | Modifica el documento según datos del formulario                                 |
| GET    | /delete/:id                               | :document\_delete   | html   | Elimina un documento cargado                                                     |
| GET    | /:id                                      | :user              | html   | Muestra el contenido de un documento y permite asignar campos de auto completado |
| GET    | /delete\_user/:id                          | :document\_delete   | html   | Elimina un usuario                                                               |
| GET    | /print/:document\_id/employee/:employee\_id | :document\_employee | html   | Arma un documento con datos de un empleado en particular y permite imprimirlo    |

#### ./controllers/employee\_controller.rb (prefijo: /employee)

Este controlador maneja los empleados, tiene embebidas las rutas de llegadas tarde, fichero y horas extras que se podrían separar

| MÉTODO | URI                            | PRIVILEGIOS            | PROVEE     | DETALLES                                                                        |
|--------|--------------------------------|------------------------|------------|---------------------------------------------------------------------------------|
| GET    | /list(/:current\_page?)         | :user                  | html       | Muestra la lista de empleados                                                   |
| GET    | /edit/:id                      | :employee\_new          | html       | Edita los datos de un empleado                                                  |
| POST   | /edit/:id                      | :employee\_new          | html       | Procesa el formulario y modifica los datos del empleado                         |
| GET    | /new                           | :employee\_new          | html       | Muestra el formulario para crear empleados                                      |
| POST   | /new                           | :employee\_new          | html       | Procesa el formulario y genera un empleado nuevo                                |
| POST   | /avatar/:id                    | :employee\_avatar       | html       | Modifica el avatar de un empleado                                               |
| GET    | /late\_arrival/new/:employee\_id | :late\_arrival\_new      | html       | Muestra el formulario para cargar llegadas tarde a un empleado                  |
| POST   | /late\_arrival/new/:employee\_id | :late\_arrival\_new      | html, json | Carga una llegada tarde, o varias según el formulario                           |
| GET    | /late\_arrival/delete/:id       | :late\_arrival\_delete   | html       | Elimina/cancela una llegada tarde                                               |
| GET    | /overtime/:id                  | :overtime\_new          | html       | Muestra formulario para cargar horas adicionales / extra a un empleado          |
| POST   | /overtime/:id                  | :overtime\_new          | html       | Carga horas adicionales / extra para un empleado                                |
| GET    | /overtime/delete/:id           | :overtime\_delete       | html       | Remueve horas adicionales / extra cargadas a un empleado                        |
| GET    | /file/:id                      | :user                  | html       | Descarga un archivo cargado al fichero de empleado                              |
| POST   | /file/:id                      | :employee\_file\_new     | html       | Carga un archivo al fichero del empleado                                        |
| GET    | /file/delete/:id               | :employee\_file\_delete  | html       | Elimina un archivo del fichero de empleado                                      |
| POST   | /edit\_availability/:id         | :employee\_availability | html       | Modifica las horas de disponibilidad de un empleado                             |
| GET    | /archive/:id                   | :employee\_archive      | html       | Archiva / da de baja un empleado, desasociándolo de turnos y suplencias futuras |
| GET    | /unarchive/:id                 | :employee\_unarchive    | html       | Reactiva / da de alta un empleado (no modifica turnos o suplencias)             |
| GET    | /delete/:id                    | :employee\_archive      | html       | Archiva un empleado (si tiene datos) o lo elimina si está vacío                 |
| GET    | /:id                           | :user                  | html       | Devuelve la ficha de un empleado                                                |

#### ./controllers/export\_controller.rb (prefijo: /export)

Este controlador se encarga da exportar datos en formato CSV

| MÉTODO | URI               | PRIVILEGIOS | PROVEE | DETALLES                                                      |
|--------|-------------------|-------------|--------|---------------------------------------------------------------|
| GET    | /custom           | :user       | html   | Muestra formulario para exportado a medida                    |
| POST   | /custom/client    | :user       | html   | Realiza exportado a medida de clientes según formulario       |
| POST   | /custom/employee  | :user       | html   | Realiza exportado a medida de empleados según formulario      |
| GET    | /clients          | :user       | html   | Exporta todos los clientes                                    |
| GET    | /employees        | :user       | html   | Exporta todos los empleados                                   |
| POST   | /employee\_updates | :user       | html   | Exporta las novedades para empleados en un tiempo determinado |
| GET    | /locations        | :user       | html   | Exporta todas las estaciones de trabajo                       |
| GET    | /shifts           | :user       | html   | Exporta todos los turnos de trabajo                           |

#### ./controllers/holiday\_controller.rb (prefijo: /holiday)

Este controlador se encarga de cargar o anular feriados

| MÉTODO | URI            | PRIVILEGIOS     | PROVEE | DETALLES                                    |
|--------|----------------|-----------------|--------|---------------------------------------------|
| GET    | /list(/:year?) | :user           | html   | Muestra el calendario con feriados marcados |
| POST   | /new           | :holiday\_new    | html   | Carga un nuevo feriado                      |
| POST   | /delete        | :holiday\_delete | html   | Remueve un feriado cargado                  |

#### ./controllers/import\_controller.rb (prefijo: /import)

Este controlador maneja la importación de datos desde un archivo Excel o CSV para inicializar la base de datos

| MÉTODO | URI        | PRIVILEGIOS | PROVEE | DETALLES                                                   |
|--------|------------|-------------|--------|------------------------------------------------------------|
| GET    | /          | :user       | html   | Muestra los uploaders de archivos y descarga de plantillas |
| POST   | /clients   | :user       | html   | Importa una plantilla de clientes                          |
| POST   | /employees | :user       | html   | Importa una plantilla de empleados                         |
| POST   | /locations | :user       | html   | Importa una plantilla de estaciones de trabajo             |

#### ./controllers/location\_controller.rb (prefijo: /location)

Este controlador maneja las estaciones de trabajo

| MÉTODO | URI                           | PRIVILEGIOS             | PROVEE | DETALLES                                                                       |
|--------|-------------------------------|-------------------------|--------|--------------------------------------------------------------------------------|
| GET    | /new/:client\_id(/:parent\_id?) | :location\_new           | html   | Muestra el formulario para crear una estación o sub-estación de trabajo        |
| POST   | /new/:client\_id(/:parent\_id?) | :location\_new           | html   | Genera una estación o sub-estación de trabajo según formulario                 |
| GET    | /edit/:location\_id            | :location\_new           | html   | Muestra el formulario para editar una estación de trabajo                      |
| POST   | /edit/:location\_id            | :location\_new           | html   | Modifica una estación de trabajo según el formulario                           |
| GET    | /contract/:location\_id        | :location\_contract\_edit | html   | Muestra el editor de contrato de una estación de trabajo                       |
| POST   | /contract/:location\_id        | :location\_contract\_edit | html   | Modifica un contrato de estación de trabajo según el formulario                |
| GET    | /archive/:id                  | :location\_archive       | html   | Archiva una estación de trabajo, junto a sus hijos, archiva también sus turnos |
| GET    | /unarchive/:id                | :location\_unarchive     | html   | Reactiva una estación de trabajo y sus hijos (no modifica turnos)              |
| GET    | /delete/:id                   | :location\_archive       | html   | Elimina una estación de trabajo si está vacía, sino la archiva                 |
| GET    | /:id                          | :user                   | html   | Muestra el detalle de una estación de trabajo y sus turnos                     |

#### ./controllers/shift\_backup\_controller.rb (prefijo: /shift\_backup)

Este controlador maneja los pedidos de refuerzo

| MÉTODO | URI                        | PRIVILEGIOS            | PROVEE     | DETALLES                                                  |
|--------|----------------------------|------------------------|------------|-----------------------------------------------------------|
| POST   | /assign                    | :shift\_backup\_assign   | html       | Asigna un empleado a cubrir un pedido de refuerzo         |
| GET    | /unassign/:shift\_backup\_id | :shift\_backup\_unassign | html       | Remueve a un empleado de un pedido de refuerzo            |
| GET    | /new/:location\_id          | :shift\_backup\_new      | html       | Muestra formulario para crear pedidos de refuerzo         |
| POST   | /new/:location\_id          | :shift\_backup\_new      | html, json | Genera un pedido de refuerzo para una estación de trabajo |
| GET    | /delete/:shift\_backup\_id   | :shift\_backup\_delete   | html       | Elimina un pedido de refuerzo cargado                     |
| GET    | /:shift\_backup\_id          | :user                  | html       | Muestra el formulario para asignar un pedido de refuerzo  |

#### ./controllers/shift\_controller.rb (prefijo: /shift)

Este controlador maneja los turnos de trabajo

| MÉTODO | URI                 | PRIVILEGIOS     | PROVEE | DETALLES                                                                   |
|--------|---------------------|-----------------|--------|----------------------------------------------------------------------------|
| POST   | /assign             | :shift\_assign   | html   | Asigna un empleado a cubrir un turno de trabajo                            |
| GET    | /unassign/:shift\_id | :shift\_unassign | html   | Remueve a un empleado de un turno de trabajo                               |
| GET    | /new/:location\_id   | :shift\_new      | html   | Muestra formulario para crear turnos de trabajo                            |
| POST   | /new/:location\_id   | :shift\_new      | html   | Genera un turno de trabajo en una estación de trabajo                      |
| GET    | /edit/:shift\_id     | :shift\_new      | html   | Muestra formulario para editar un turno de trabajo                         |
| POST   | /edit/:shift\_id     | :shift\_new      | html   | Modifica los detalles de un turno de trabajo                               |
| GET    | /copy/:shift\_id     | :shift\_new      | html   | Genera un nuevo turno copiando los datos de otro                           |
| GET    | /delete/:shift\_id   | :shift\_delete   | html   | Archiva un turno de trabajo si tiene a alguien asignado, sino, lo borra    |
| GET    | /:shift\_id          | :user           | html   | Muestra formulario para asignar a un empleado a cubrir un turno de trabajo |

