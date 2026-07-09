# 4 - Administracion de trabajos

> Fuente: MANUAL SGMWIN3.docx - L&M Ingenieria S.R.L.
> Extraido automaticamente. Las referencias a figuras (Figura X) corresponden al manual original impreso.

ÓRDENES DE TRABAJO
Las órdenes de trabajo (O.T.), son aquellos mandatos o procedimientos escritos de mantenimiento que se deberán ejecutar sobre determinados equipos y que contienen definidos los requisitos necesarios para su correcta ejecución.
Los procedimientos a ejecutar pueden ser periódicos, los cuales poden llevarse a cabo mediante la emisión de
O.T. Periódicas; o no periódicos, que los podemos realizar a través de las O.T. No periódicas.
Una vez que es emitida, la orden de trabajo va adquiriendo distintos estados a medida que se le va incorporando información y actualizando los datos que requiere. Estos estados son: O.T. Necesaria de Emitir,
O.T. Pendiente, O.T. en Ejecución, y O.T. Realizadas.

## Emitir O.T. periódicas

## La emisión de órdenes de trabajo periódicas se puede realizar de 2 formas:
Emitir al asociar un procedimiento a los equipos: Esta operación se realiza desde la gestión de procedimientos, al momento de asociar un procedimiento a uno o varios equipos, si lo desea, una vez habilitada la asociación, podrá emitir por primera vez la O.T.
Emitir de O.T. necesarias: Son aquellas O.T. que deben emitirse nuevamente, por haberse cumplido la periodicidad (en tiempo y/o eventos) establecida en el procedimiento respectivo desde la última ejecución.

### Emitir al asoci ar un procedimiento a los equipos

## Los pasos generales para realizar esta operación son los siguientes:
En la ventana de gestión de procedimientos, localice el procedimiento, ya sea en forma manual o utilizando los métodos descriptos en “Buscar un procedimiento”, del capítulo “3.ARCHIVOS MAESTROS”.

## Una vez localizado, sigua los pasos descriptos en “Asociar un procedimiento”, del capítulo

### “3.ARCHIVOS MAESTROS”.
Recuerde que para realizar la emisión de la orden, el procedimiento debe estar habilitado.

### Emitir O.T. Neces arias
Para acceder a la emisión de órdenes de trabajo necesarias, elija la opción Programación | Estado de O.T. |
O.T. necesarias, del menú principal o haga un clic sobre la opción O.T. necesarias -  , de la barra de herramientas, de esta manera aparecerá la ventana de consulta (figura OT2)

## Los pasos generales para realizar esta operación son los siguientes:
Seleccione en Equipos, el equipo del cual desea ver las OT necesarias de emitir nuevamente. Al seleccionar uno Ud. verá las O.T. del equipo y de todos sus componentes si los tuviera. Si no selecciona ninguno, el sistema interpretará que las O.T. a listar serán las que corresponden al todo el equipamiento.
Ingrese en Necesarias al, la fecha a la cual desea conocer las O.T. necesarias de emitir. Esta fecha puede manejarse de acuerdo a las circunstancias, normalmente fijándose al final del período para el cual se programan los trabajos, por ejemplo: fin de la quincena o del mes. En casos particulares, por ejemplo cuando el equipo va a estar parado durante varios días, se puede fijar esa fecha a más largo plazo para saber si a mediano plazo es necesario realizar un trabajo por ejemplo anual, y decidir adelantarlo o no.

> **Figura OT1**

> **Figura OT2**
Ingrese en Contadores, la fecha de actualización de los contadores. Esta fecha sirve para chequear si los contadores de eventos están actualizados. Si el sistema detecta que la última actualización de un contador es anterior a ésta, incluirá una leyenda de aviso en el listado.
Esta fecha solo será tenida en cuenta si el o los equipos a chequear tienen un uso promedio igual a "0". En caso contrario, el estado del contador se extrapolará tomando en cuenta la última lectura y el promedio de uso por día, a fin de determinar si una OT es necesaria de emitir nuevamente.
Seleccione el Sector Responsable del procedimiento de las O.T., para ello haga un clic sobre la flecha del control y podrá seleccionar del listado quién o qué sector será responsable de la tarea a realizar. Si deja vacío el control, se listarán las O.T. de todos los responsables.
Seleccione el Tipo de Procedimiento, para ello haga un clic sobre la flecha del control y podrá seleccionar del listado los distintos tipos de procedimiento, de acuerdo a las características del mantenimiento realizado. Si deja vacío el control, se listarán las O.T. de todos los tipos de procedimiento.
Seleccione el Tipo de Equipo, para ello haga un clic sobre la flecha del control y podrá seleccionar del listado los distintos tipos de equipos. Si deja vacío el control, se listarán las O.T. sin tener en cuenta el tipo de equipo.
Una vez que ha determinado el filtrado que desea, en la sección Opción, señale la opción Emitir, luego haga un clic sobre el botón Buscar, de esta manera aparecerá la ventana de trabajos necesarios de emitir (figura OT2).
Para acotar al máximo las órdenes necesarias de emitir, puede combinar el Sector Responsable, Tipo de Procedimiento y el Tipo de equipo. Esto resulta de suma importancia cuando el número de órdenes necesarias de emitir es demasiado extenso. Si desea listar la totalidad deje en blanco los casilleros.
En el listado de trabajos necesarios de emitir, seleccione el trabajo, haga un doble clic sobre la celda correspondiente a la columna O.T. Emisión, indicando de esta forma la emisión de una O.T. para dicho trabajo.
Tenga en cuenta que puede indicar más de uno o todos los trabajos necesarios de emitir, para la emisión de, de la barra de herramientas.un clic sobre la opción desmarcar todo -, de la barra de herramientas, caso contrario, hagala O.T., haga un clic sobre la opción marcar todo -
Tenga en cuenta que puede indicar más de uno o todos los trabajos necesarios de emitir, para la emisión de
, de la barra de herramientas.
un clic sobre la opción desmarcar todo -
, de la barra de herramientas, caso contrario, haga
la O.T., haga un clic sobre la opción marcar todo -
Tenga en cuenta que puede indicar más de uno o todos los trabajos necesarios de emitir, para la emisión de
, de la barra de herramientas.
un clic sobre la opción desmarcar todo -
, de la barra de herramientas, caso contrario, haga
la O.T., haga un clic sobre la opción marcar todo -
En la celda correspondiente a la columna Fecha Programación, una vez indicada la emisión de la O.T. aparecerá por defecto la fecha actual, la cual puede modificar a su conveniencia, para ello haga un doble clic sobre la celda y aparecerá un calendario donde podrá seleccionar la fecha.
En el caso de que el trabajo necesario de emitir tenga materiales reservados para realizar el trabajo, aparecerá indicado con una tilde en la columna Vale Materiales, donde podrá habilitar o no la impresión. Lo mismo ocurre en el caso de que posea una planilla de lecturas adicionales asignada, que aparecerá indicado con una tilde en la columna Lectura, donde podrá habilitar o no la impresión.
En el caso de que necesitara revisar la última O.T. realizada, haga un clic sobre la opción abrir O.T. anteriorProcedimiento, en adelante., o haga un doble clic sobre cualquiera de las columnas desde la columna Descripción del-
En el caso de que necesitara revisar la última O.T. realizada, haga un clic sobre la opción abrir O.T. anterior
Procedimiento, en adelante.
, o haga un doble clic sobre cualquiera de las columnas desde la columna Descripción del
-
En el caso de que necesitara revisar la última O.T. realizada, haga un clic sobre la opción abrir O.T. anterior
Procedimiento, en adelante.
, o haga un doble clic sobre cualquiera de las columnas desde la columna Descripción del
-
Luego indique la cantidad de copias que necesitará de cada O.T., para ello haga un clic en cualquiera de las tres opciones de la barra de herramientas -  ,  ,  .
Si elige “0” copias -, de cualquier modo la O.T. se encuentra efectivamente emitida y el sistema lamostrará como O.T. pendiente hasta que se haya ingresado como realizada.

## Si elige “0” copias -
, de cualquier modo la O.T. se encuentra efectivamente emitida y el sistema la
mostrará como O.T. pendiente hasta que se haya ingresado como realizada.
, de cualquier modo la O.T. se encuentra efectivamente emitida y el sistema la
mostrará como O.T. pendiente hasta que se haya ingresado como realizada.
Completada toda la operación haga clic sobre la opción emitir O.T. -, de la barra de herramientas, o cierre la ventana para cancelar la operación y volver a la ventana de consulta.

### Program ación de O.T. Necesarias en form a gráfica
También es posible la programación de O.T. necesarias en forma gráfica, reacomodándolas en un diagrama de Gantt (Figura OT3).
Esto permite una rápida visualización de superposiciones entre trabajos y de las duraciones de los mismos, permitiendo así llevar a cabo con facilidad una programación más eficiente.

## Para efectuar la programación en forma gráfica, siga los siguientes pasos:

## Efectúe la búsqueda de O.T. Necesarias de emitir (pasos 1 a 7 de la sección anterior)
Una vez en la ventana de trabajos necesarios de emitir (figura OT2), haga un clic sobre el ícono -  - de la barra de herramientas. De esta manera aparecerá la ventana de la figura OT 3.
Tenga en cuenta que una vez obtenida la gráfica, podrá contar con una serie de opciones y herramientas. Para mayor información sobre el manejo de la gráfica, vea el capítulo “10.ANEXO 3”
Realice la programación de trabajos arrastrando los mismos con el mouse hacia la fecha de programación que desee.
Haga un clic sobre el botón -  - para guardar los cambios, o bien, haga un clic sobre el botón -  - para deshacer los mismos.

> **Figura OT3**

## Emitir  O.T. no periódicas

## La emisión de órdenes de trabajo no periódicas se puede realizar de 3 formas:
Emitir convencionalmente O.T. no periódicas: Este tipo de O.T. no está basada en un procedimiento predefinido, sino que se precisan todos los datos en esa pantalla.
Tenga en cuenta que el sistema generará a partir de esta O.T. un procedimiento correctivo, que puede reutilizarse.
Emitir en base a una solicitud de trabajo, O.T. no periódicas: Es igual a la emisión convencional de
O.T. no periódicas, salvo que algunos de los datos cargados en la solicitud son volcados y pasan a formar parte de la O.T.

### Emitir convencionalm ente O.T. no periódic as
Para acceder a la emisión convencional de órdenes de trabajo no periódicas, elija la opción Programación | Emisión de O.T. | Emisión de O.T. no periódicas, del menú principal o haga un clic sobre la opción emisión de O.T. no periódicas -  , de la barra de herramientas, de esta manera aparecerá la ventana de emisión (figura OT4).

> **Figura OT4**

## Los pasos generales para realizar esta operación son los siguientes:
Localice en Equipo, el equipo al que desea emitir una O.T.
Seleccione el Sector Responsable de la ejecución de los trabajos. Para ello haga un clic sobre la flecha del control y podrá seleccionar del listado quién o qué sector será responsable de la tarea a realizar.
En el caso de que el Sector Responsable no se encontrara en la lista, podrá agregar rápidamente uno nuevo, haciendo un clic sobre el botón que se encuentra al lado del control de lista.
Seleccione el Tipo de Procedimiento a realizar. Para ello haga un clic sobre la flecha del control y podrá seleccionar del listado los distintos tipos de procedimiento, de acuerdo a las características del mantenimiento a aplicar.
En el caso de que el Tipo de Procedimiento no se encontrara en la lista, podrá agregar rápidamente uno nuevo, haciendo un clic sobre el botón que se encuentra al lado del control de lista.
Seleccione el operario que Recibe la O.T. Para ello haga un clic sobre la flecha del control y podrá seleccionar del listado quién o qué operario será el receptor de la O.T.
En el caso de que el operario no se encontrara en la lista, podrá agregar rápidamente uno nuevo, haciendo un clic sobre el botón que se encuentra al lado del control de lista.
Ingrese en Programado, la fecha en que se ha previsto realizar el trabajo.
Ingrese los Valores Estimados. En esta sección se incorporan los valores estimados que se utilizarán en el cálculo automático de Horas Necesarias para ponerse al día. Indique los valores necesarios de Horas Hombre, el número de personal afectado y tiempo que demandará la operación..
H. Hombre: Ingrese la cantidad de horas hombre reales empleadas en la ejecución del trabajo. Pueden introducir directamente, o bien lo hace el sistema automáticamente al detallar la mano de obra empleada en la sección de Costos.
Cant. de Operarios: Ingrese la cantidad real de operarios que intervinieron en la realización del trabajo, o bien lo hace el sistema automáticamente al detallar la mano de obra empleada en la sección de Costos.
Duración: Ingrese la duración real del trabajo.
Ingrese en Inicio, la fecha y la hora cuando se inicia el trabajo. Generalmente en el caso de las correctivas será igual a la de programación de la O.T. Si al momento de emitirse la O.T. no se ha comenzado, debe dejarse vacía.
Tenga en cuenta que la carga de la hora de inicio no es obligatoria al crear una O.T. no periódica.
Ingrese en Finalización la fecha en la cual se terminó el trabajo, a partir de la cual la O.T. se considera realizada. Si se emite la O.T. antes de la ejecución, esta fecha debe dejarse vacía, para que el sistema registre la O.T. como pendiente, y completarse una vez realizada y reingresada al sistema con toda la información correspondiente. Al ingresar la hora en la cual sé terminó el trabajo. Al ingresar la misma el sistema le indicará la duración calculada de los trabajos y la indisponibilidad que provocaron.
Al ingresar la hora de finalización, el sistema le sugerirá la duración del trabajo y la indisponibilidad provocada; confírmela si es pertinente, o elimínela en caso contrario.
Ingrese los Valores reales. En esta sección se incorporan los valores obtenidos después de la realización del trabajo, entre los cuales se encuentra la mano de obra a utilizar, tiempo que demandará la operación, periodo en el que las instalaciones estarán fuera de servicios y el estado del contador.
H. Hombre: Ingrese la cantidad de horas hombre reales empleadas en la ejecución del trabajo. Pueden introducir directamente, o bien lo hace el sistema automáticamente al detallar la mano de obra empleada en la sección de Costos.
Cant. de Operarios: Ingrese la cantidad real de operarios que intervinieron en la realización del trabajo, o bien lo hace el sistema automáticamente al detallar la mano de obra empleada en la sección de Costos.
Duración: Ingrese la duración real del trabajo.
Tenga en cuenta que el sistema le sugerirá la duración del trabajo, siempre que la fecha y hora de finalización sean cargadas.
Indisponibilidad: Ingrese la indisponibilidad real, provocada por el tiempo en que las instalaciones estuvieron fuera de servicio, motivado por la ejecución de la O.T.
Tenga en cuenta que el sistema le sugerirá la indisponibilidad provocada, siempre que la fecha y hora de finalización sean cargadas.
Eq. Afectados: Puede seleccionar si la indisponibilidad afectó además a otros equipos. Para ello, haga click en el botón y escoja de a uno, los equipos del árbol de equipos. Luego haga clic derecho y seleccione Afectado en el menú contextual. Si el equipo seleccionado tiene sub equipos asociados, éstos también se incluirán.
Recuerde que las indisponibilidades se asocian automáticamente en el árbol de equipos. El uso de esta opción queda reservado para casos excepcionales en los cuales el equipo afecte la operación normal de otros.
Contador: Ingrese el estado del contador del equipo a la hora de realizar la O.T. para ello haga un clic
sobre el botón Lecturas del contador -, de esta manera aparecerá la ventana donde podrá cargar la lectura del contador (figura OT6)

> **Figura OT6**
El ingreso de esta información es importante ya que el equipo al cual le está realizando el trabajo puede tener emitida O.T., cuyo procedimiento esté influenciado por el contador.

## Los pasos para agregar una lectura del contador son:
Ingrese en Fecha y Hora, la fecha y hora en la que se toma la lectura.
Luego ingrese en Contador, la lectura tomada del contador; o bien, ingrese el Incremento sufrido por el contador desde la última lectura ingresada.
Completada toda la operación haga clic sobre el botón Confirmar para volver a la ventana de emisión, o haga un clic sobre el botón Cancelar para desechar lo realizado y volver a la ventana de emisión.
Ingrese los Costos, en esta sección se incorporan los costos generados por la realización del trabajo, entre los cuales se encuentra los materiales, mano de obra y recursos adicionales.
Materiales: Ingrese el costo de los materiales utilizados en la ejecución de la O.T., o bien el sistema lo hace automáticamente al detallar los materiales empleados, para ello haga un clic sobre el botón
detalle de materiales -  , de esta manera aparecerá la ventana de carga de materiales (figura OT7)

> **Figura OT7**

## Los pasos para detallar los materiales son:
Seleccione el material, el cual Ud. podrá localizar haciendo un clic sobre la flecha del control Buscar por, de esta forma indicara cual será el filtrado de la búsqueda.
Luego en Buscar, escriba la descripción, que puede ser texto, código o alguna palabra clave que contenga el o los ítem que desea ubicar, o en el caso de que sea una búsqueda que realizó anteriormente, haciendo un clic sobre la flecha del control, podrá seleccionar del listado, cualquiera de ellas.
El sistema guarda siempre las últimas 10 búsquedas realizadas, las cuales están a su disposición para utilizarlas.
Luego haga un clic sobre el botón buscar -  , para llenar la lista con aquellos materiales que coincidan con el criterio de búsqueda. Luego seleccione de la lista el material a cargar.

## Ingrese la Cantidad de material a utilizar.
Ingrese en Fecha la fecha en la que se reservó el material. El costo del material que se imputará a la O.T. será el precio vigente del material en la fecha seleccionada.
Si lo desea, puede seleccionar la Marca del material a imputar a la O.T.

## Una vez ingresados los datos, haciendo un clic sobre el botón agregar -
, actualizará la lista de Materiales a utilizar. En el caso de que necesite corregir o se haya equivocado, seleccione el material y luego haga un clic sobre el botón borrar -  .
Después de seleccionar los materiales, haga un clic sobre el botón Confirmar para aprobar la lista de materiales o en el caso contrario haga un clic en el botón Salir para anular la operación.
Mano de Obra: Ingrese el costo de la mano de obra utilizada en la ejecución de la O.T., o bien el sistema lo hace automáticamente al detallar la mano de obra empleada, para ello haga un clic sobre el botón detalle de mano de obra -  , de esta manera aparecerá la ventana de carga de mano de obra (figura OT8)

## Los pasos para detallar la mano de obra son:
Ingrese en Fecha la fecha en la que se empleó la mano de obra.
Seleccione en Descripción, la mano de obra, para ello haga un clic sobre la flecha del control y podrá seleccionar del listado quién ejecutará la tarea a realizar.
En el caso de que la mano de obra no se encontrara en la lista, podrá agregar rápidamente una nueva, haciendo un clic sobre el botón que se encuentra al lado del control de lista.

> **Figura OT8**

## Ingrese la cantidad de horas que estará abocado al trabajo, las cuales se dividen en:
Cant. Hr. Normales: Ingrese la cantidad de horas normales que se trabajaron.
Cant. Hrs. Extras 50%: Ingrese la cantidad de horas extras que se trabajaron.
Cant. Hrs. Extras 100%: Ingrese la cantidad de horas extras al 100% que se trabajaron.
Cant. Hrs. Extras 200%: Ingrese la cantidad de horas extras al 200% que se trabajaron.
Una vez ingresados los datos, haciendo un clic sobre el botón agregar -, actualizará la lista de Mano de obra empleada. En el caso de que necesite corregir o se haya equivocado, seleccione la mano de obra y luego haga un clic sobre el botón borrar -  .
Después de seleccionar la mano de obra, haga un clic sobre el botón Confirmar para aprobar la lista de mano de obra o en el caso contrario haga un clic en el botón Salir para anular la operación.
Recursos: Ingrese el costo del los recursos extras utilizados en la ejecución de la O.T., o bien el sistema lo hace automáticamente al detallar los recursos utilizados. Para ello haga un clic sobre el botón detalle de recursos -  , de esta manera aparecerá la ventana de carga de recursos (figura OT9)

> **Figura OT9**

## Los pasos para detallar recursos extras son:
Ingrese en Fecha, la fecha en la que se empleó el recurso.
Seleccione en Descripción, el recurso, para ello haga un clic sobre la flecha del control y podrá seleccionarlo del listado.
En el caso de que el recurso no se encontrara en la lista, podrá agregar rápidamente uno nuevo, haciendo un clic sobre el botón que se encuentra al lado del control de lista.

## Ingrese la cantidad de horas que estará abocado al trabajo, las cuales se dividen en:
Cant. Hr. Normales: Ingrese la cantidad de horas normales que se utilizó el recurso.
Cant. Hrs. Extras: Ingrese la cantidad de horas extras que se utilizó el recurso.
Una vez ingresados los datos, haciendo un clic sobre el botón agregar -, actualizará la lista de Recursos empleados. En el caso de que necesite corregir o se haya equivocado, seleccione el recurso y luego haga un clic sobre el botón borrar -  .
Después de seleccionar el recurso, haga un clic sobre el botón Confirmar para aprobar la lista de recursos o en el caso contrario haga un clic en el botón Salir para anular la operación.
Costo Total: Se muestra el total de la suma de materiales, mano de obra y recursos.
Ingrese, en el caso de que lo necesite, información respecto del tipo de falla. Para ello haga un clic sobre el botón Fallas, de esta manera aparecerá la ventana de tipificación de fallas (figura OT10)

## Los pasos para detallar recursos extras son:
Seleccione en Causa la causa de la falla, para ello haga un clic sobre la flecha del control y podrá seleccionarla de la lista.
Seleccione en Objeto el objeto o parte del equipo afectado, para ello haga un clic sobre la flecha del control y podrá seleccionarlo de la lista.

> **Figura OT10**
Seleccione en Síntoma el síntoma que presentaba el equipo afectado, para ello haga un clic sobre la flecha del control y podrá seleccionarlo de la lista.
Seleccione en Acción la acción correctiva adoptada, para ello haga un clic sobre la flecha del control y podrá seleccionarlo de la lista.
En el caso de que tanto la causa, el objeto, el síntoma o la acción no se encontrara en las correspondientes listas, podrá agregar rápidamente cualquiera de ellas, haciendo un clic sobre el botón que se encuentra al lado del control de lista.
Completada toda la operación haga clic sobre el botón Confirmar para volver a la ventana de emisión, o haga un clic sobre el botón Cancelar para desechar lo realizado y volver a la ventana de emisión.
En el caso de que al realizar el trabajo se tomaran mediciones al equipo podrá cargar las mismas, para ello haga un clic sobre el botón Lecturas, de esta manera aparecerá la ventana donde podrá realizar esta operación.
Tenga en cuenta que para poder cargar las lecturas el equipo tiene que estar asociado a un tipo de equipo, y éste tener definida la tabla de lecturas.
Si desea, puede cuantificar mediante un número entre los valores de Gravedad, Urgencia y Tendencia. Para cuantificar estos valores deberá hacer clic en el botón Prioridad. Estos valores serán utilizados para calcular la prioridad de la siguiente manera: (Gravedad + Urgencia) * Tendencia.
Puede adjuntar uno o más Documentos a la O.T. Para ello, haga clic sobre el botón Documentos. Aparecerá la ventana de documentos asociados, donde se podrán visualizar los documentos asociados a la O.T. si los hubiera. Para agregar un nuevo archivo adjunto, haga clic sobre el botón Agregar y seleccione el documento a asociar. Para eliminar un documento asociado, selecciónelo de la lista y haga clic en el botón Borrar.
En el caso de que necesitara realizar algún comentario adicional, haga un clic sobre el botón de Observación (figura OT11). Los botones Confirmar o Salir, están disponibles para guardar o cancelar las observaciones realizadas.

> **Figura OT11**
En la sección Copias, indique la cantidad de impresiones que necesitará de la O.T.
Si elige No imprimir, de cualquier modo la O.T. se encuentra efectivamente emitida.
En la sección Email indique si desea enviar un correo electrónico a uno o más usuarios con la información de emisión de la O.T. Al confirmar la emisión de la O.T. aparecerá una ventana en la que deberá de seleccionar los usuarios a los que desee enviar el correo electrónico mediante su cliente de correo predeterminado.
Completada toda la operación haga clic sobre el botón Confirmar, de esta forma guardará la información, y también la información asociada, aunque ésta haya sido cargada a través de materiales, mano de obra, recursos, contador, fallas, lecturas u observación o en el caso de que desee cancelar la operación, haga un clic sobre el botón Cancelar quedando de esta forma también eliminada la información asociada.
El sistema permite especificar archivos adjuntos a una O.T., los cuales se imprimen en conjunto con esta. Para mayor información sobre cómo configurar esta característica, vea los métodos descriptos en la sección “Archivos Adjuntos a las Órdenes de Trabajo” del capítulo “8.CONFIGURACIÓN”.

### Emitir en b ase a una solicitud de trab ajo, O.T. no periódicas
Para acceder a la emisión en base a una solicitud de trabajo, de órdenes de trabajo no periódicas, elija la opción Programación | Emisión de O.T. | Emisión de O.T. no periódicas, del menú principal o haga un clic sobre la opción emisión de O.T. no periódicas -  , de la barra de herramientas, de esta manera aparecerá la ventana de emisión (figura OT4).

## Los pasos generales para realizar esta operación son los siguientes:

## Una vez en la ventana de emisión:

## Seleccione un equipo al que quiere emitir la Orden.
Seleccione el Sector Responsable de la ejecución de los trabajos, para ello haga un clic sobre la flecha del control y podrá seleccionar del listado quién o qué sector será responsable de la tarea a realizar.
En el caso de que el Sector Responsable no se encontrara en la lista, podrá agregar rápidamente uno nuevo, haciendo un clic sobre el botón que se encuentra al lado del control de lista.
Seleccione el Tipo de Procedimiento a realizar, para ello haga un clic sobre la flecha del control y podrá seleccionar del listado los distintos tipos de procedimiento, de acuerdo a las características del mantenimiento a aplicar.
En el caso de que el Tipo de Procedimiento no se encontrara en la lista, podrá agregar rápidamente uno nuevo, haciendo un clic sobre el botón que se encuentra al lado del control de lista.
Ingrese en Programado, la fecha en que se ha previsto realizar el trabajo.
Ingrese en Inicio, la fecha y la hora cuando se inicia el trabajo. Generalmente en el caso de las correctivas será igual a la de programación de la O.T.
Como puede ver todavía no se ha indicado el trabajo a realizar, esto es porque en la solicitud se encuentra toda esa información. Para acceder a las solicitudes haga un clic sobre el botón Solicitudes, de esta manera aparecerá la ventana de solicitudes de trabajo aprobadas (figura OT12).

> **Figura OT12**
Una vez en la ventana, en la lista de Solicitudes de trabajos, seleccione la solicitud en la que quiere basar la O.T. Puede asociar a la O.T. más de una solicitud en el caso de que existan múltiples referencias que puedan realizarse de una sola vez, es decir, que existan muchas solicitudes que puedan cumplirse con una misma orden. Para vincular más de una solicitud debe mantener la tecla CTRL mientras las selecciona. Una vez finalizada la selección, haga un clic sobre la opción emitir O.T. -  , de la barra de herramientas. De esta manera, una vez realizado esto, verá que los distintos datos cargados en la solicitud toman su ubicación en la O.T.
Descripción del Trabajo EquipoTrabajo (descripción del trabajo) EquipoO . T .S O L I C I T U DDescripción del Trabajo EquipoTrabajo (descripción del trabajo) EquipoO . T .S O L I C I T U DPuede darse el caso que un equipo tenga demasiadas solicitudes. Se le indicará que realice la operación desde la ventana Gestión de Solicitudes. Pág. 4 - 30

## Descripción del Trabajo Equipo

## Trabajo (descripción del trabajo) Equipo

## O . T .

## Descripción del Trabajo Equipo

## Trabajo (descripción del trabajo) Equipo

## O . T .
Puede darse el caso que un equipo tenga demasiadas solicitudes. Se le indicará que realice la operación desde la ventana Gestión de Solicitudes. Pág. 4 - 30
Una vez cargada la solicitud, sigua los pasos descriptos en “Emisión convencional de O.T. no periódicas”, de este mismo capítulo.
Tenga en cuenta que si modificó la descripción del trabajo y/o el equipo al que le desea realizar el trabajo, de cualquier manera quedará indicada en la solicitud la O.T. que se emitió en base a la misma.
Búsqueda, visualización y actualización de O.T.
Una vez emitida la O.T., la misma deberá ir siendo actualizada con información relativa al trabajo, tales como las fechas en que se inicia y termina el trabajo, el motivo por el cual una determinada O.T. está pendiente, y los costos asociados al trabajo entre otros.
La carga de información de los trabajos realizados en la O.T. implicará cambios de estado en las mismas. Dichos estados son detallados a continuación:
O.T. pendientes: Son aquellas órdenes de trabajo, que superada la fecha de programación no poseen fecha de inicio y tampoco de finalización, por lo que el sistema no las registra como en ejecución y tampoco como realizadas.
O.T. en ejecución: Son aquellas órdenes de trabajo, que se les ha fijado una fecha de inicio cuando se empezaron a realizar los trabajos descriptos en la O.T., y aún no se han terminado, por lo que el sistema no las registra como realizadas perdurando en este estado hasta que no se indique la fecha de finalización. Tenga en cuenta, esta opción es útil cuando se realicen órdenes de larga duración.
O.T. realizadas: Son aquellas órdenes de trabajo, que se encuentran realizadas e incorporadas al sistema como tales.

### Buscar O. T.
Para acceder a la búsqueda de órdenes de trabajo, elija la opción Programación | Búsqueda y actualización de O.T., del menú principal o haga un clic sobre la opción Búsqueda y actualización -  , de la barra de herramientas, de esta manera aparecerá la ventana de consulta, mostrada en detalle en la figura BAOT1.

## Los pasos generales para realizar esta operación son los siguientes:
Seleccione o busque en Equipos, el equipo al que desea realizar la consulta. Podrá filtrar la búsqueda por descripción, código, o código del fabricante. Al seleccionar uno, verá las órdenes emitidas al equipo y de todos sus componentes si los tuviera.
Indique si desea considerar movimientos de equipos en la búsqueda. Si la casilla está marcada, el sistema tendrá en cuenta la ubicación temporal de equipos movidos dentro del rango de fechas indicadas. Si la casilla no está marcada, el sistema mostrará los resultados de los equipos en la posición en que se encuentran actualmente.

## Barra de Herramientas:

## Actualizar resultadosExportar a ExcelVisualizar O.T. derivadas
Leer Código de barrasAbrir O.T. seleccionadaAyuda Imprimir resultadosMotivo de O.T. pendiente

## Ver gráfica de GanttEmitir O.T. derivada

> **Figura BAOT1**
Ingrese en los controles Desde y Hasta, el intervalo de fecha en el que desea conocer las O.T., para ello indique la fecha desde la cual desea listar las órdenes, y luego ingrese la fecha hasta donde desea listar las órdenes.
Si lo desea puede tener en cuenta o no la fecha para realizar la consulta, ya que haciendo un clic sobre las tildes que se encuentran en cualquiera de los dos controles podrá habilitar o no el uso de este parámetro.
Indique los estados de O.T. que desea que aparezcan en los resultados de búsqueda. Tenga en cuenta lo siguiente:
O.T. En ejecución: Se mostrarán aquellas cuya fecha de inicio se encuentre dentro del rango de fechas indicado.
O.T. Pendientes: Se mostrarán aquellas cuya fecha de programación se encuentre dentro del rango de fechas indicado.
O.T. Realizadas: Se mostrarán aquellas cuya fecha de finalización se encuentre dentro del rango de fechas indicado.
O.T. Anuladas: Se mostrarán aquellas anuladas que coincidan con alguno de los criterios anteriores marcados. Si desea ver todas las O.T. anuladas, independientemente del estado que tenían antes de ser anuladas, marque solamente esta casilla.
Ingrese en Código O.T., el número de la O.T. a localizar.
Si deja en “0”, el código a buscar, la misma se realizará dentro del rango de fecha estipulado, pero si tampoco específico un rango de fecha se devolverá todas las órdenes de trabajo para el equipo especificado.
Si desea filtrar por el Sector Responsable, haga un clic sobre la flecha del control y se desplegará la lista general de responsables. Usted podrá seleccionar alguno de ellos y al listar se mostrarán solo las órdenes emitidas que estén bajo la supervisión del responsable seleccionado.
Si desea filtrar por el Tipo de Equipo, en forma similar, haga un clic sobre la flecha del control y se desplegará la lista de todos los tipos de equipo disponibles. Seleccionando uno de ellos, al listar se mostrarán solo las órdenes emitidas a aquellos equipos que se encuentren asociados a ese tipo de equipo.
Si desea filtrar por el Tipo de Procedimiento, en forma similar, haga un clic sobre la flecha del control y se desplegará una lista de todos los tipos de mantenimientos disponibles. Seleccionado uno de ellos, al listar se mostrarán solo las órdenes emitidas bajo los procedimientos de ese tipo.
Si desea filtrar por la persona que Recibe la O.T., haga un clic sobre la flecha del control y se desplegará la lista de personas. Seleccionando uno de ellos al listar se mostrarán solo las órdenes recibidas por la persona seleccionada.
Si desea filtrar por el Motivo de O.T. Pendiente, haga un clic sobre la flecha del control y se desplegará una lista de todos los motivos disponibles. Seleccionado uno de ellos, al listar se mostrarán solo las órdenes que se encuentran pendientes por el motivo seleccionado.
Una vez que ha determinado el filtrado que desea, haga clic sobre el botón Buscar y la ventana se actualizará para mostrar los resultados de búsqueda. Además, en la parte inferior de la ventana se muestra la cantidad de O.T. encontradas, discriminadas por estado, así como también los costos de mantenimiento relativos a los resultados de búsqueda, separados en costos de materiales, de mano de obra y de recursos utilizados.

### Visu aliz ar  resultados  en  gráfico  de  Gantt
Es posible visualizar los resultados de una operación de búsqueda en un gráfico de Gantt. Esto permite una rápida visualización de superposiciones entre trabajos y de las duraciones y estado actual de los mismos.
Los pasos a seguir para visualizar los resultados en un gráfico de Gantt son los siguientes:
En la ventana de búsqueda (BAOT1), efectúe la búsqueda de las órdenes a mostrar en el gráfico, utilizando los filtrados que desee, tal como se indica en la sección “Búsqueda de O.T.”.
Haga un clic sobre el ícono -  - de la barra de herramientas. De esta manera, aparecerá la ventana de gráficos de Gantt (BAOT2).
Tenga en cuenta que una vez obtenida la gráfica, podrá contar con una serie de opciones y herramientas. Para mayor información sobre el manejo de la gráfica, vea el capítulo “10.ANEXO 3”

### Imprimir  resultad os  de  búsqueda

## Para imprimir un reporte con los resultados de búsqueda siga los siguientes pasos:
Haga clic sobre el ícono -  - de la barra de herramientas de la ventana de búsqueda (figura BAOT1).
Seleccione la forma de impresión. Aquí se seleccionará el destino de salida del listado.
Vista preliminar: Se visualizará en pantalla, pudiendo luego desde ahí ordenarse la impresión.
Impresora: Salida por la impresora predeterminada.
Tenga en cuenta que por defecto los listados saldrán por pantalla, y para ello, se abrirá un programa llamado REPORT PRO, que maneja exclusivamente reportes. Para mayor información sobre el manejo de REPORT PRO vea " Visualización de listados con REPORT PRO", del capítulo “9.ANEXO 1”.
Figura BAOT2

### Export ar resultados de búsqued a a Excel
Para exportar los resultados de búsqueda a Microsoft Excel, simplemente haga clic sobre el ícono -  - de la barra de herramientas de la ventana de búsqueda (figura BAOT1). De esta manera, aparecerá la ventana de guardado de archivo, donde podrá elegir el nombre de archivo y la ubicación donde guardar el mismo.

### Actualizar O. T.
Para acceder a la actualización de una orden de trabajo, siga los métodos descriptos en “Búsqueda de O.T.”, de este capítulo. Una vez realizados, los pasos generales para realizar esta operación son los siguientes:
Una vez localizada la orden, haga doble clic sobre fila correspondiente a la orden o haga un clic sobre la opción Abrir O.T. -  , de la barra de herramientas, de esta manera aparecerá la ventana de actualización (figura BAOT3).
Una vez en la ventana de actualización, dependiendo del estado de la O.T., se le indicará que datos ingresar inicialmente.
O.T. pendiente: Ingrese en Inicio, la fecha y la hora cuando se inicia el trabajo y luego si es necesario, ingrese en Finalización, la fecha y hora en la cual se terminó el trabajo. Al ingresar la misma el sistema le indicará la duración calculada de los trabajos y la indisponibilidad que provocaron.
O.T. en ejecución: Ingrese en Finalización, la fecha y hora en la cual se terminó el trabajo. Al ingresar la misma el sistema le indicará la duración calculada de los trabajos y la indisponibilidad que provocaron.

> **Figura BAOT3**
Al ingresar la hora de finalización, el sistema le sugerirá la duración del trabajo y la indisponibilidad provocada; confírmela si es pertinente, o elimínela en caso contrario.
Tanto el Equipo, como Responsable, Tipo de Procedimiento, Descripción del Trabajo y Programado, no se pueden modificar ya que son datos que fueron definidos en el procedimiento o en la emisión de la misma.
La configuración de la ventana no solo está atada al estado de la O.T., sino que también la afecta el perfil del usuario que está utilizando el sistema.
Ingrese los Valores reales, en esta sección se incorporan los valores obtenidos después de la realización del trabajo, entre los cuales se encuentra la mano de obra a utilizar, tiempo que demandará la operación, periodo en el que las instalaciones estarán fuera de servicios y el estado del contador.
H. Hombre: Ingrese la cantidad de horas hombre reales empleadas en la ejecución del trabajo. Pueden introducir directamente, o bien lo hace el sistema automáticamente al detallar la mano de obra empleada en la sección de Costos.
Cant. de Opera.: Ingrese la cantidad real de operarios que intervinieron en la realización del trabajo, o bien lo hace el sistema automáticamente al detallar la mano de obra empleada en la sección de Costos.
Duración: Ingrese la duración real del trabajo.
Tenga en cuenta que el sistema le sugerirá la duración del trabajo, siempre que la fecha y hora de finalización sean cargadas.
Indisponibilidad: Ingrese la indisponibilidad real, provocada por el tiempo en que las instalaciones estuvieron fuera de servicio, motivado por la ejecución de la O.T.
Tenga en cuenta que el sistema le sugerirá la indisponibilidad provocada, siempre que la fecha y hora de finalización sean cargadas.
Contador: Ingrese el estado del contador del equipo a la hora de realizar la O.T. para ello haga un clic
sobre el botón detalle de Lecturas del contador -, de esta manera aparecerá la ventana donde podrá cargar la lectura del contador (figura BAOT4)

> **Figura BAOT4**
Ingrese los Costos. En esta sección se incorporan los costos generados por la realización del trabajo, entre los cuales se encuentra los materiales, mano de obra y recursos adicionales. Los pasos a seguir para efectuar esta tarea son similares a los especificados en la sección “Emitir Convencionalmente O.T. No Periódicas”
Ingrese, en el caso de que lo necesite, información respecto del tipo de falla, tal como se especificó en la sección “Emitir Convencionalmente O.T. No Periódicas”
En el caso de que al realizar el trabajo se tomaran mediciones al equipo podrá cargar las mismas, para ello haga un clic sobre el botón Lecturas, de esta manera aparecerá la ventana donde podrá realizar esta operación.
Tenga en cuenta que para poder cargar las lecturas el equipo tiene que estar asociado a un tipo de equipo, y éste tener definida la tabla de lecturas.
En el caso de que necesitara realizar algún comentario adicional, haga un clic sobre el botón de Observación.
En la sección Copias, indique la cantidad de impresiones que necesitará de la O.T.
Si elige No imprimir, de cualquier modo la O.T. se encuentra efectivamente actualizada.
Completada toda la operación haga clic sobre el botón Confirmar, de esta forma guardara la información, y también la información asociada, aunque ésta haya sido cargada a través de materiales, mano de obra,
recursos, contador, fallas, lecturas u observación o en el caso de que desee cancelar la operación, haga un clic sobre el botón Cancelar quedando de esta forma también eliminada la información asociada.
Tenga en cuenta que cada vez que ingrese a actualizar la O.T., esto quedará registrado junto con el usuario que la realizó, en el histórico de la orden.

### Reabrir O.T.
Para reabrir una orden de trabajo, siga los métodos descriptos en “Búsqueda de O.T.”, de este capítulo. Una vez realizados, los pasos generales para realizar esta operación son los siguientes:
Tenga en cuenta que esta operación solo la puede realizar el usuario “SGM”, ya que es el único que posee perfil de administrador.
Tenga en cuenta que la orden que va a reabrir debe estar realizada, o sea que en la ventana de resultado de búsqueda, podrá identificar esta orden por su indicador de estado está en blanco, este indicador es parte de la columna Código de la O.T. ya que es el color de fondo de cada celda.
Una vez localizada la orden, haga doble clic sobre fila correspondiente a la orden o haga un clic sobre la opción Abrir O.T. -  , de la barra de herramientas, de esta manera aparecerá la ventana de actualización (figura BAOT3).
Tenga en cuenta que las órdenes que se encuentren anuladas no se pueden reabrir.
Una vez en la ventana de actualización, haga un clic sobre el botón Reabrir, verá que en la ventana el nivel de habilitación es tal que se comprara con la de una orden pendiente.
Para completar la operación puede seguir los métodos descriptos en “Actualización de O.T.”, de este capítulo.
Tenga en cuenta que esta operación quedará registrada y el usuario que la realizo, en el histórico de la orden.

### Anular O.T.
Para anular una orden de trabajo, siga los métodos descriptos en “Búsqueda de O.T.”, de este capítulo. Una vez realizados, los pasos generales para realizar esta operación son los siguientes:
Una vez localizada la orden, haga doble clic sobre la fila correspondiente a la orden o haga un clic sobre la opción Abrir O.T. -  , de la barra de herramientas, de esta manera aparecerá la ventana de actualización (figura BAOT3).
Una vez en la ventana de actualización, haga un clic sobre el botón Anular.
Tenga en cuenta que esta operación quedará registrada y el usuario que la realizó, en el histórico de la orden.

### Reimprimir O.T.
Para reimprimir una orden de trabajo, siga los métodos descriptos en “Búsqueda de O.T.”, de este capítulo. Una vez realizados, los pasos generales para realizar esta operación son los siguientes:
Tenga en cuenta que la orden que va a reimprimir debe estar pendiente, o sea que en la ventana de resultado de búsqueda, podrá identificar esta orden por su indicador de estado en rojo. Este indicador es parte de la columna Código de la O.T. ya que es el color de fondo de cada celda.
Una vez localizada la orden, haga doble clic sobre la fila correspondiente a la orden o haga un clic sobre la opción Abrir O.T. -  , de la barra de herramientas, de esta manera aparecerá la ventana de actualización (figura BAOT3).
Una vez en la ventana de actualización, en la sección Copias, indique la cantidad de impresiones que necesitara de la O.T.
Luego haga un clic sobre el botón Reimprimir.

### Indicar  que  un a  O. T reemplaz a  a  otra  O. T.
Es posible que el trabajo de una O.T. no periódica incluya el trabajo de un procedimiento preventivo asociado al equipo. Para evitar que el procedimiento aparezca como necesario de ser realizado siendo que ya ha sido incluido en una O.T. no periódica, es preciso indicar en ésta el procedimiento que reemplaza o posterga.
Al momento de determinar la nueva ejecución del procedimiento en cuestión, se utilizará la fecha de cierre la
O.T. no periódica que lo reemplazó o postergó.
Para indicar que una O.T. no periódica reemplaza a una periódica siga los siguientes pasos:
Siga los pasos descritos en “Actualizar O.T” de este capítulo hasta llegar a la ventana de la Figura

### BAOT3.
Haga clic sobre el botón Reemplazo. Aparecerá una ventana con los procedimientos asociados al equipo seleccionado (figura ROT1).

> **Figura ROT1**

## Seleccione el procedimiento a postergar o reemplazar y haga clic en Posterga.

## Visualización de reportes de estado de las órdenes de trabajo

## O.T. PENDIENTES
Para acceder a la consulta de órdenes de trabajo pendientes, elija la opción Programación | Estado de O.T. |
O.T. pendientes, del menú principal o haga un clic sobre la opción O.T. pendientes -  , de la barra de herramientas, de esta manera aparecerá la ventana de consulta (figura EOT1).

> **Figura EOT1**

## Los pasos generales para realizar esta operación son los siguientes:
Seleccione en Equipos, el equipo al que desea realizar la consulta. Al seleccionar uno verá las órdenes emitidas al equipo y de todos sus componentes si los tuviera. Si no selecciona ninguno, el sistema interpretará que las órdenes de trabajo a listar serán las que corresponden al todo el equipamiento.
Ingrese en Pendientes al, la fecha a la cual desea conocer las órdenes pendientes.
Por lo general se utiliza la fecha actual, pero si las órdenes pendientes son muchas, se puede acotar, colocando una fecha anterior para conocer cuales ya estaban pendientes en esa fecha.
Si desea filtrar por el Sector Responsable, haga un clic sobre la flecha del control y se desplegará la lista general de responsables. Ud. podrá seleccionar alguno de ellos y al listar se mostrarán solo las órdenes emitidas que estén bajo la supervisión del responsable seleccionado.
Si desea filtrar por el Tipo de Procedimiento, en forma similar, haga un clic sobre la flecha del control y se desplegará una lista de todos los tipos de mantenimientos disponibles. Seleccionado uno de ellos al listar se mostrarán sólo las órdenes emitidas bajo los procedimientos de ese tipo.
Si desea filtrar por el Tipo de Equipo, en forma similar, haga un clic sobre la flecha del control y se desplegará la lista de todos los tipos de equipo disponibles. Seleccionando uno de ellos al listar se mostrarán solo las órdenes emitidas a aquellos equipos que se encuentren asociados a ese tipo de equipo.
Una vez que ha determinado el filtrado que desea, haga clic sobre el botón Listar, de esta manera aparecerá la ventana de listar.
Si en vez de visualizar el listado, desea exportar los datos a Microsoft Excel, haga clic sobre el botónExportar XLS.
Si en vez de visualizar el listado, desea exportar los datos a Microsoft Excel, haga clic sobre el botón

## Exportar XLS.
Si en vez de visualizar el listado, desea exportar los datos a Microsoft Excel, haga clic sobre el botón
Seleccione la Forma de Impresión. Aquí se seleccionará el destino de salida del listado.
Vista preliminar: Se visualizará en pantalla, pudiendo luego desde ahí ordenarse la impresión.
Impresora: Salida por la impresora predeterminada.
Tenga en cuenta que por defecto los listados saldrán por pantalla, y para ello, se abrirá un programa llamado REPORT PRO, que maneja exclusivamente reportes. Para mayor información sobre el manejo de REPORT PRO vea " Visualización de listados con REPORT PRO", del capítulo “9.ANEXO 1”.
Completada toda la operación haga clic sobre el botón Confirmar, o haga un clic sobre el botón Cancelar

## para volver a la ventana de consulta.
Para acotar al máximo las órdenes pendientes a listar, puede combinar el Sector Responsable, Tipo de Procedimiento y el Tipo de equipo. Esto resulta de suma importancia cuando el número de órdenes pendientes es demasiado extenso. Si desea listar la totalidad deje en blanco los casilleros.
O.T. EN EJECUCIÓN
Para acceder a la consulta de órdenes de trabajo en ejecución, elija la opción Programación | Estado de O.T.
| O.T. en ejecución, del menú principal o haga un clic sobre la opción O.T. en ejecución -  , de la barra de herramientas, de esta manera aparecerá la ventana de consulta (figura EOT2).

> **Figura EOT2**

## Los pasos generales para realizar esta operación son los siguientes:
Seleccione en Equipos, el equipo al que desea realizar la consulta. Al seleccionar uno verá las órdenes emitidas al equipo y de todos sus componentes si los tuviera. Si no selecciona ninguno, el sistema interpretará que las órdenes de trabajo a listar serán las que corresponden al todo el equipamiento.
Ingrese en, En Ejecución al, la fecha a la cual desea conocer las órdenes en ejecución.
Por lo general se utiliza la fecha actual, pero si las órdenes en ejecución son muchas, se puede acotar colocando una fecha anterior para conocer las órdenes que iniciaron primero.
Si desea filtrar por el Sector Responsable, haga un clic sobre la flecha del control y se desplegará la lista general de responsables. Ud. podrá seleccionar alguno de ellos y al listar se mostrarán solo las órdenes emitidas que estén bajo la supervisión del responsable seleccionado.
Si desea filtrar por el Tipo de Procedimiento, en forma similar, haga un clic sobre la flecha del control y se desplegará una lista de todos los tipos de mantenimientos disponibles, seleccionado uno de ellos al listar se mostrarán solo las órdenes emitidas bajo los procedimientos de ese tipo.
Si desea filtrar por el Tipo de Equipo, en forma similar, haga un clic sobre la flecha del control y se desplegará la lista de todos los tipos de equipo disponibles, seleccionando uno de ellos al listar se mostrarán solo las órdenes emitidas a aquellos equipos que se encuentren asociados a ese tipo de equipo.
Una vez que ha determinado el filtrado que desea, haga clic sobre el botón Listar, de esta manera aparecerá la ventana de listar.
Seleccione la Forma de Impresión. Aquí se seleccionará el destino de salida del listado.
Vista preliminar: Se visualizará en pantalla, pudiendo luego desde ahí ordenarse la impresión.
Impresora: Salida por la impresora predeterminada.
Tenga en cuenta que por defecto los listados saldrán por pantalla, y para ello, se abrirá un programa llamado REPORT PRO, que maneja exclusivamente reportes. Para mayor información sobre el manejo de REPORT PRO vea " Visualización de listados con REPORT PRO", del capítulo “9.ANEXO 1”.
Completada toda la operación haga clic sobre el botón Confirmar, para listar, o haga un clic sobre el botón
Cancelar para anular la operación.
Para acotar al máximo las órdenes en ejecución a listar, puede combinar el Sector Responsable, Tipo de Procedimiento y el Tipo de equipo. Esto resulta de suma importancia cuando el número de órdenes en ejecución es demasiado extenso. Si desea listar la totalidad deje en blanco los casilleros.

## O.T. NECESARIAS
Para acceder a la consulta de órdenes de trabajo necesarias, elija la opción Programación | Estado de O.T. |
O.T. necesarias, del menú principal o haga un clic sobre la opción O.T. necesarias -  , de la barra de herramientas, de esta manera aparecerá la ventana de consulta (figura OT2).

## Los pasos generales para realizar esta operación son los siguientes:
Seleccione en Equipos, el equipo al que desea realizar la consulta. Al seleccionar uno verá las órdenes emitidas al equipo y de todos sus componentes si los tuviera. Si no selecciona ninguno, el sistema interpretará que las órdenes de trabajo a listar serán las que corresponden al todo el equipamiento.
Ingrese en Necesarias al, la fecha a la cual desea conocer las O.T. necesarias de emitir. Esta fecha puede manejarse de acuerdo a las circunstancias, normalmente fijándose al final del período para el cual se programan los trabajos, por ejemplo: fin de la quincena o del mes. En casos particulares, por ejemplo cuando el equipo va a estar parado durante varios días, se puede fijar esa fecha a más largo plazo para saber si a mediano plazo es necesario realizar un trabajo por ejemplo anual, y decidir adelantarlo o no.
Ingrese en Contadores, la fecha de actualización de los contadores. Esta fecha sirve para chequear si los contadores de eventos están actualizados. Si el sistema detecta que la última actualización de un contador es anterior a ésta, incluirá una leyenda de aviso en el listado. Esto no implica que la Orden de Trabajo sea necesaria de emitir, sino que es necesario actualizar el contador.
Esta fecha solo será tenida en cuenta si el o los equipos a chequear tienen un uso promedio igual a "0". En caso contrario, el estado del contador se extrapolará tomando en cuenta la última lectura y el promedio de uso por día, a fin de determinar si una OT es necesaria de emitir nuevamente.
Si desea filtrar por el Sector Responsable, haga un clic sobre la flecha del control y se desplegará la lista general de responsables. Ud. podrá seleccionar alguno de ellos y al listar se mostrarán solo las órdenes necesarias que estén bajo la supervisión del responsable seleccionado.
Si desea filtrar por el Tipo de Procedimiento, en forma similar, haga un clic sobre la flecha del control y se desplegará una lista de todos los tipos de mantenimientos disponibles, seleccionado uno de ellos al listar se mostrarán solo las órdenes necesarias bajo los procedimientos de ese tipo.
Si desea filtrar por el Tipo de Equipo, en forma similar, haga un clic sobre la flecha del control y se desplegará la lista de todos los tipos de equipo disponibles, seleccionando uno de ellos al listar se mostrarán solo las órdenes necesarias a aquellos equipos que se encuentren asociados a ese tipo de equipo
Una vez que ha determinado el filtrado que desea, en la sección Opción, señale la opción Listar, luego haga un clic sobre el botón Buscar, de esta manera aparecerá la ventana de listar.
Seleccione la Forma de Impresión. Aquí se seleccionará el destino de salida del listado.
Vista preliminar: Se visualizará en pantalla, pudiendo luego desde ahí ordenarse la impresión.
Impresora: Salida por la impresora predeterminada.
Tenga en cuenta que por defecto los listados saldrán por pantalla, y para ello, se abrirá un programa llamado REPORT PRO, que maneja exclusivamente reportes. Para mayor información sobre el manejo de REPORT PRO vea " Visualización de listados con REPORT PRO", del capítulo “9.ANEXO 1”.
Completada toda la operación haga clic sobre el botón Confirmar, o haga un clic sobre el botón Cancelar

## si desea volver a la ventana de consulta.
Para acotar al máximo las órdenes necesarias a listar, puede combinar el Sector Responsable, Tipo de Procedimiento y el Tipo de equipo. Esto resulta de suma importancia cuando el número de órdenes necesarias es demasiado extenso. Si desea listar la totalidad deje en blanco los casilleros.

## O.T. REALIZ AD AS
Para acceder a la consulta de órdenes de trabajo necesarias, elija la opción Programación | Estado de O.T. |
O.T. realizadas, del menú principal o haga un clic sobre la opción O.T. realizadas -  , de la barra de herramientas, de esta manera aparecerá la ventana de consulta (figura EOT4).

> **Figura EOT4**

## Los pasos generales para realizar esta operación son los siguientes:
Seleccione en Equipos, el equipo al que desea realizar la consulta. Al seleccionar uno verá las órdenes emitidas al equipo y de todos sus componentes si los tuviera. Si no selecciona ninguno, el sistema interpretará que las órdenes de trabajo a listar serán las que corresponden a todo el equipamiento.
Ingrese el intervalo de fechas en el que desea conocer las O.T. realizadas, para ello indique la fecha Desde la cual desea listar las órdenes realizadas, y luego ingrese la fecha Hasta donde desea listar las órdenes.
Si desea filtrar por el Sector Responsable, haga un clic sobre la flecha del control y se desplegará la lista general de responsables. Ud. podrá seleccionar alguno de ellos y al listar se mostrarán solo las órdenes realizadas que estén bajo la supervisión del responsable seleccionado.
Si desea filtrar por el Tipo de Procedimiento, en forma similar, haga un clic sobre la flecha del control y se desplegará una lista de todos los tipos de mantenimientos disponibles, seleccionado uno de ellos al listar se mostrarán solo las órdenes realizadas bajo los procedimientos de ese tipo.
Si desea filtrar por el Tipo de Equipo, en forma similar, haga un clic sobre la flecha del control y se desplegará la lista de todos los tipos de equipo disponibles, seleccionando uno de ellos al listar se mostrarán solo las órdenes realizadas a aquellos equipos que se encuentren asociados a ese tipo de equipo.
En la sección Detallar, señale el tipo de listado a obtener.
Si: Con esta opción obtendrá el listado en forma detallada por O.T., los trabajos realizados, H.H., Costos, etc., para cada equipo.
No: Con esta opción obtendrá solo los totales para cada equipo tal como H.H., Costos, etc.
Una vez que ha determinado el filtrado que desea, haga clic sobre el botón Listar, de esta manera aparecerá la ventana de listar.
Si en vez de visualizar el listado, desea exportar los datos a Microsoft Excel, haga clic sobre el botónExportar XLS.
Si en vez de visualizar el listado, desea exportar los datos a Microsoft Excel, haga clic sobre el botón

## Exportar XLS.
Si en vez de visualizar el listado, desea exportar los datos a Microsoft Excel, haga clic sobre el botón
Seleccione la Forma de Impresión. Aquí se seleccionará el destino de salida del listado.
Vista preliminar: Se visualizará en pantalla, pudiendo luego desde ahí ordenarse la impresión.
Impresora: Salida por la impresora predeterminada.
Tenga en cuenta que por defecto los listados saldrán por pantalla, y para ello, se abrirá un programa llamado REPORT PRO, que maneja exclusivamente reportes. Para mayor información sobre el manejo de REPORT PRO vea " Visualización de listados con REPORT PRO", del capítulo “9.ANEXO 1”...
Completada toda la operación haga clic sobre el botón Confirmar, o haga un clic sobre el botón Cancelar

## para volver a la ventana de consulta.
Para acotar al máximo las órdenes realizadas a listar, puede combinar el Sector Responsable, Tipo de Procedimiento y el Tipo de equipo. Esto resulta de suma importancia cuando el número de órdenes realizadas es demasiado extenso. Si desea listar la totalidad deje en blanco los casilleros.
Histórico de O.T.
Podrá visualizar el registro de todos los movimientos que se le han realizado a la O.T.
Para acceder al histórico de una O.T., siga los métodos descriptos en “Búsqueda de O.T.”, de este capítulo. Una vez realizados, los pasos generales para realizar esta operación son los siguientes:
Una vez localizada la orden, haga doble clic sobre columna Historial, de esta manera aparecerá la ventana de histórico.
Una vez en la ventana de histórico podrá ver el desarrollo de las modificaciones realizadas a la O.T., ordenadas por fecha e indicando el usuario que realizó esa modificación.

## Agregar un motivo a una O.T. pendiente
Podrá agregar un motivo a una O.T. pendiente, con el fin de informar por qué las tareas correspondientes a la misma aún no han sido ejecutadas.
Para agregar un motivo a una O.T. pendiente, siga los métodos descriptos en “Búsqueda de O.T.”, de este capítulo. Una vez realizados, los pasos generales para realizar la operación son los siguientes:
Una vez localizada la orden, haga clic sobre la misma, y luego sobre el botón -  -, de la barra de herramientas, de esta manera aparecerá la ventana de motivos de O.T. pendiente (figura MOT1).
Seleccione de la lista desplegable el motivo por el que la O.T. queda pendiente o agregue un motivo nuevo.

> **Figura MOT1**
Completada toda la operación haga clic sobre el botón Confirmar para guardar los datos, o haga un clic sobre el botón Cancelar para desechar lo realizado y volver a la ventana de resultados de búsqueda de O.T.

## Emitir una O.T. derivada
En el caso de que existan trabajos complementarios o relacionados con otros trabajos especificados en una orden previamente emitida, podrá emitir una O.T. derivada indicando que las tareas a llevar a cabo derivan o se relacionan con los de la otra orden.
Para emitir una O.T. derivada, siga los métodos descriptos en “Búsqueda de O.T.”, de este capítulo. Una vez realizados, los pasos generales para realizar la operación son los siguientes:
Una vez localizada la orden de la que derivará la orden a emitir, haga clic sobre la misma, y luego sobre el botón -  -, de la barra de herramientas, de esta manera aparecerá la ventana de emisión (figura OT5).
Tenga en cuenta que para poder emitir una O.T. derivada, la orden de la que deriva deberá encontrarse en estado de realizada o en estado de ejecución.
Siga los pasos detallados en la sección “Emitir convencionalmente O.T. No Periódicas” de este mismo capítulo.
Completada toda la operación haga clic sobre el botón Confirmar para emitir la orden de trabajo derivada, o haga un clic sobre el botón Cancelar para desechar lo realizado y volver a la ventana de resultados de búsqueda de O.T.
Una vez emitida la orden derivada, la O.T. de la que deriva se marcará de color naranja en la ventana de resultados de búsqueda para indicar que la misma posee O.T. derivadas. Para visualizar las O.T. derivadas de una orden, haga clic sobre ella, y luego sobre el botón -  -, de la barra de herramientas.

## SOLICITUDES DE O.T.
La solicitud es una facilidad del sistema, destinada a que se informe al encargado o programador de las operaciones de mantenimiento, de las tareas que son necesarias de realizar, las cuales después de su estudio, son aprobadas o no por él, para la emisión de una O.T.
Para acceder a la gestión de solicitudes de órdenes de trabajo, elija la opción Programación | Solicitudes de O.T., del menú principal o haga un clic sobre la opción Solicitudes de O.T. -  , de la barra de herramientas, de esta manera aparecerá la ventana de gestión (figura SOT1).

> **Figura SOT1**

## Barra de Herramientas
Búsqueda de Solicitud

## Modificar SolicitudObservaciones

> **FiguraSOT2**

## Listado de Solicitudes

## EstadoEmitir O.T.

## Agregar SolicitudDar ConformidadAbrir O.T.

## Agregar una solicitud
Para agregar una solicitud, en la ventana de gestión (figura SOT1), haga un clic sobre el botón Nueva solicitud.

## Los pasos generales para agregar una solicitud son los siguientes:
Ingrese la Descripción o nombre de la solicitud de trabajo.
Ingrese en Trabajo (descripción del trabajo), la descripción del trabajo necesario de realizar, la misma será utilizada en la descripción de la O.T.

## Seleccione el valor de Prioridad de la solicitud.
En caso de tener más de una Sucursal y de poseer autorización, deberá seleccionar la sucursal a la que corresponde la solicitud.

## Seleccione el sector Responsable de la solicitud.

## Seleccione el Tipo de procedimiento del trabajo a solicitar.
Localice en Equipo, el equipo al cual le realizará el trabajo, esto mismo será utilizado en la O.T. para indicar el equipo.
Tenga en cuenta que la carga del equipo no es una condición necesaria y puede omitirse, ya que es un simple indicar de a qué equipo se le necesita realizar el trabajo.
En el caso de que necesitara realizar algún comentario adicional, haga un clic sobre el botón de Agregar Observación. Aparecerá una ventana de donde se puede detallar las particularidades del trabajo a realizar, materiales, recursos adicionales, etc. solicitud. Los botones Confirmar o Salir, están disponibles para guardar o cancelar las observaciones realizadas. Al confirmar, la observación agregada se añadirá al final de las observaciones previas (si las hubiese), indicando además la fecha y hora en que se realizó la observación. Las observaciones de una solicitud no pueden ser eliminadas o modificadas.
Dispone de la posibilidad de agregar Documentos relevantes a la solicitud. Haga clic sobre el botón, se abrirá una venta donde puede seleccionar imágenes, tablas de Excel, archivos PDF o cualquier otro tipo de archivo que considere importante.

> **Figura SOT3**
Agregar permite añadir nuevos documentos asociados a la S.O.T.. Al añadir necesita seleccionar el archivo y agregar una descripción que lo ayude a recordar el archivo adjunto.

## Modificar permite que pueda cambiar el archivo adjunto a la S.O.T.
Para Borrar documentos adjuntos, simplemente haga clic en el botón correspondiente.
Para Abrir un documento adjunto con el programa por defecto para la extensión correspondiente, haga clic en el botón.
Una vez que esté conforme con los archivos adjuntos con la S.O.T. haga clic en Confirmar. En caso que quiera Cancelar los cambios, haga clic en el botón.
Si desea, puede cuantificar mediante un número entero (1 al 5) los valores de Gravedad, Urgencia y Tendencia. Para cuantificar estos valores deberá hacer clic en el botón Prioridad. Estos valores serán utilizados para calcular la prioridad de la siguiente manera: (Gravedad + Urgencia) * Tendencia.
Completada toda la operación haga clic sobre el botón Confirmar para volver a la ventana de gestión, o haga un clic sobre el botón Cancelar para desechar lo realizado y volver a la ventana de gestión
Tenga en cuenta que si es el usuario Administrador podrá elegir además la sucursal en la que desea realizar la operación.

## Enviar E-Mail con aviso de solicitud urgente
El sistema brinda la posibilidad de avisar al usuario sobre una solicitud de alta prioridad (aquellas cuya prioridad fue definida en 0) en forma automática a través del envío de un correo electrónico a una dirección preestablecida, una vez transcurrido un tiempo definido con anterioridad sin que sea considerada.
Para más información sobre como configurar esta opción, véase la sección “Solicitud” del capítulo“8.CONFIGURACIÓN”
Para más información sobre como configurar esta opción, véase la sección “Solicitud” del capítulo
“8.CONFIGURACIÓN”
Para más información sobre como configurar esta opción, véase la sección “Solicitud” del capítulo
“8.CONFIGURACIÓN”

## Buscar una solicitud

## Los pasos generales para buscar una solicitud son los siguientes:
En la ventana de gestión (figura SOT1), seleccione el conjunto de criterios que desee para efectuar la búsqueda. Si desea refinar aun más el criterio de búsqueda, haga clic sobre el botón Avanzada para mostrar todos los criterios de búsqueda.
Una vez que ha determinado el filtrado que desea, haga clic sobre el botón Buscar y la ventana se actualizará para mostrar los resultados de búsqueda. En la parte inferior de la ventana se muestra la cantidad de solicitudes encontradas, discriminadas por estado
Tenga en cuenta que cuando realice una búsqueda de las solicitudes emitidas, solo se verán aquellas que se emitieron por el mismo usuario que está realizando la consulta.

## Modificar una solicitud

## Los pasos generales para modificar una solicitud son los siguientes:
Localice la solicitud que desea modificar, ya sea en forma manual o utilizando los métodos descriptos en

### “Buscar una solicitud”.
Una vez localizado, haga un clic sobre el botón Modificar -  -, de esta manera aparecerá la ventana de edición donde podrá realizar todas las modificaciones que estime conveniente siguiendo los pasos descriptos en “Agregar una solicitud”.
Tenga en cuenta que solo podrá modificar aquellas solicitudes emitidas por el mismo usuario que está tratando de realizar la modificación.

## Listar solicitudes

## Los pasos generales para listar solicitudes son los siguientes:
Siga los pasos descriptos en "Buscar una solicitud" para establecer el criterio de filtrado del reporte y haga clic sobre el botón Imprimir Resultados -  -
Luego Seleccione la Forma de Impresión. Aquí se seleccionará el destino de salida del listado.
Vista preliminar: Se visualizará en pantalla, pudiendo luego desde ahí ordenarse la impresión.
Impresora: Salida por la impresora predeterminada.
Tenga en cuenta que por defecto los listados saldrán por pantalla, y para ello, se abrirá un programa llamado REPORT PRO, que maneja exclusivamente reportes. Para mayor información sobre el manejo de REPORT PRO vea " Visualización de listados con REPORT PRO", del capítulo “9.ANEXO 1”.
Completada toda la operación haga clic sobre el botón Confirmar, o haga un clic sobre el botón Cancelar
para volver a la ventana de gestión.
Para acotar al máximo el número de solicitudes a listar, puede combinar el rango de fecha (Desde, Hasta), con el Estado de las solicitudes. Esto resulta de suma importancia cuando el número de solicitudes definidas es demasiado extenso. Si desea listar la totalidad de las solicitudes utilice un rango de fecha amplio y deje en blanco el casillero de estado.

## Estado de una solicitud de trabajo
Una vez emitida una solicitud de trabajo, esta es sometida a estudio. A medida que esto se realiza la solicitud va variando su estado hasta llegar al punto donde se aprueba, o sea, se emite una O.T. en base a la misma, o se rechaza.

## Los pasos generales para realizar esta operación son los siguientes:
Seleccione las solicitudes que desee modificar su estado. Manteniendo presionada la tecla Control podrá seleccionar más de una solicitud.
Haga un clic sobre el botón Estado --, de esta manera aparecerá la ventana para realizar la operación (figura SOT3).

## Localice la solicitud a la que desea modificar su estado.

> **Figura SOT3**
Una vez localizada, en la columna Estado, haga un doble clic, de esta forma aparecerá una lista con los distintos tipos de estado, seleccione el que corresponda, repita la operación todas las veces que sea necesario.
Completada toda la operación, haga clic sobre la opción confirmar -para guardar la modificación, o cierre la ventana sin confirmar para desechar lo realizado y volver a la ventana de gestión

## Conformidad de una solicitud de trabajo
Una vez finalizada una orden de trabajo emitida en base a una solicitud de trabajo, es posible prestar conformidad a dicha solicitud

> **Figura SOT4**

## Los pasos generales para realizar esta operación son los siguientes:
Localice la solicitud que desea modificar, ya sea en forma manual o utilizando los métodos descriptos en

### “Buscar una solicitud”.
Haga un clic sobre el botón Conformidad -  -, de esta manera aparecerá la ventana para realizar la operación (figura SOT4).
Seleccione la Calificación desde la lista desplegable. Los valores de calificación que podrá elegir son :

## Muy Bueno

## Bueno

## Regular

## Malo
En Observación podrá ingresar algún comentario adicional sobre la calificación de la Solicitud de trabajo.
Completada toda la operación, haga clic sobre el botón Confirmar para guardar la calificación, o en Cancelar para desechar lo realizado y volver a la ventana de gestión.

## Agregar observaciones a una solicitud de trabajo
En todo momento podrá agregar observaciones a una Solicitud de Trabajo. Tenga en cuenta que no se podrán borrar las observaciones previas, sino que las observaciones nuevas se irán agregando a estas, junto con el usuario que realizó la observación, y la fecha de la misma.

## Los pasos generales para realizar esta operación son los siguientes:
Localice la solicitud que desea modificar, ya sea en forma manual o utilizando los métodos descriptos en

### “Buscar una solicitud”.
Haga un clic sobre el botón Observaciones -  - , de esta manera aparecerá la ventana para realizar la operación.

## Ingrese las observaciones que desee realizar.
Completada toda la operación, haga clic sobre el botón Aceptar para guardar la calificación, o en
Cancelar para desechar lo realizado y volver a la ventana de gestión.

## Emitir O.T. en base a una solicitud de trabajo
Los pasos generales para emitir una O.T. en base a una solicitud de trabajo desde la ventana de gestión de Solicitudes son los siguientes:
Localice la (o las) solicitud para la cual desea emitir la O.T., ya sea en forma manual o utilizando los métodos descriptos en “Buscar una solicitud”.
Selecciones las Solicitudes APROBADAS. Puede seleccionar más de una manteniendo presionada la tecla
. Si la solicitud no se encontrase aprobada realice los pasos indicados en la “Estado de una solicitud de trabajo”.
Haga clic sobre el botón Emitir O.T. -  - y sigua los pasos de la sección Emitir convencionalmente

### O.T. no periódicas.
Puede asociar más de una solicitud de trabajo a una O.T. Cuando hagan referencia a un mismo equipo o tarea.

## Abrir la O.T. emitida en base a una solicitud de trabajo
Los pasos generales para visualizar una O.T. emitida en base a una solicitud de trabajo son los siguientes:
Localice la solicitud desde la cual ha emitido la O.T., ya sea en forma manual o utilizando los métodos descriptos en “Buscar una solicitud”.

## Haga clic sobre el botón Abrir O.T. -  -

## CONTADORES
Podrá administrar el estado de los contadores de eventos (odómetros, cuentakilómetros, etc.) de los equipos cuyos contadores sean propios.
Para acceder a la gestión de contadores, elija la opción Programación | Contadores, del menú principal o
haga un clic sobre la opción Contadores -, de la barra de herramientas, de esta manera aparecerá la ventana de gestión (figura C1), una vez en la misma podrá: buscar, reiniciar un contador, agregar una lectura, modificar una lectura, y borrar una lectura, además de poder graficar las lecturas cargadas (figura C1A).

> **Figura C1**

> **Figura C1A**

## Buscar un equipo
Para ubicar un equipo posee dos formas de hacerlo, mediante búsqueda simple o búsqueda avanzada.

### Búsqued a simple

## Los pasos generales para buscar un equipo son los siguientes:
1 Seleccione el equipo en la lista de Equipos con contadores habilitados al equipo el cual desea localizar. Podrá ver que el árbol comienza a expandirse hasta llegar al nivel donde se encuentra el equipo que desea ubicar y en el listado Registro de lecturas realizadas a:…, las lecturas cargadas.

### Búsqued a avanz ada
Tenga en cuenta que la búsqueda se basa sólo sobre los equipos que poseen contador propio.
En el cuadro de búsqueda, haga un clic sobre la flecha del control Buscar por, de esta forma indicará cual será el filtrado de la búsqueda.
Luego en Buscar, escriba la descripción, que puede ser texto, código, o alguna palabra clave que contenga el o los ítem que desea ubicar, o en el caso de que sea una búsqueda que realizó anteriormente, haciendo un clic sobre la flecha del control, podrá seleccionar del listado, cualquiera de ellas.
El sistema guarda siempre las últimas 10 búsquedas realizadas, las cuales están a su disposición para utilizarlas.
Por ultima hago un clic sobre el botón Buscar, si la búsqueda trae algún resultado, el listado se llenará y en la parte inferior del mismo se indicará la cantidad de registros involucrados, caso contrario, la lista permanecerá deshabilitada.
Si desea acceder directamente desde la búsqueda a un equipo encontrado, seleccione en la listado del resultado de la búsqueda, el equipo y luego haga un doble clic sobre él, podrá ver que en la ventana de gestión, en el listado de Equipos con contadores habilitados, se posicionará en el registro correspondiente al equipo que seleccionó y en el listado Registro de lecturas realizadas a:…, las lecturas cargadas.
Después de realizada la búsqueda, la ventana de búsqueda, permanece abierta en el caso de que desee realizar una nueva búsqueda.

## Reiniciar un contador
En el caso de que un contador llegara al tope de su capacidad o "dió la vuelta", o si se produce el cambio de un contador por rotura o algún otro motivo, podrá registrarlo.

## Los pasos generales para reiniciar un contador son los siguientes:
Localice el equipo con contador habilitado que desea reiniciar, ya sea en forma manual o utilizando los métodos descriptos en “Buscar un equipo”.
Una vez localizado, haga un clic sobre la opción reiniciar -  , de la barra de herramientas, de esta manera aparecerá la ventana de reinicio (figura C3), donde podrá cargar los datos de reinicio del contador.

> **Figura C3**
Ingrese en Fecha de inicio, la fecha en la que se produce el cambio.
Ingrese en Lectura contador viejo, la lectura del contador que se retira, y si dio la vuelta, la lectura máxima posible.
Ingrese en Lectura contador nuevo, la lectura del contador que se coloca o la actual. Esta deberá ser como mínimo 1.
Completada toda la operación haga clic sobre el botón Confirmar para guardar los datos, o haga un clic sobre el botón Cancelar para desechar lo realizado y volver a la ventana de gestión
Una vez ingresado el cambio, el sistema tomará la fecha y las lecturas ingresadas para calcular cuándo son necesarias de emitir nuevamente las O.T. correspondientes al equipo.

## Agregar una lectura

## Los pasos generales para agregar una lectura del contador son los siguientes:
Localice el equipo con contador habilitado, ya sea en forma manual o utilizando los métodos descriptos en

### "Buscar un equipo".
Una vez localizado, haga un clic sobre la opción agregar -  , de la barra de herramientas correspondiente al Registro de lecturas realizadas a:…, de esta manera aparecerá la ventana de edición (figura C4), donde podrá cargar los datos de la lectura.

> **Figura C4**
Ingrese en Fecha y Hora, la fecha y la hora en la que se tomó la lectura del contador.
Ingrese en Contador, la lectura que se tomó del contador.
Completada toda la operación haga clic sobre el botón Confirmar, para guardar los datos, o haga un clic sobre el botón Cancelar para desechar lo realizado y volver a la ventana de gestión.

## Modificar una lectura

## Los pasos generales para modificar una lectura del contador son los siguientes:
Localice el equipo con contador habilitado, ya sea en forma manual o utilizando los métodos descriptos en

### "Buscar un equipo".
Una vez localizado, en la lista Registro de lecturas realizadas a:…, seleccione la lectura a modificar.
Una vez localizada, haga un clic sobre la opción modificar -  , de la barra de herramientas correspondiente al Registro de lecturas realizadas a:…, de esta manera aparecerá la ventana de edición, donde podrá realizar todas las modificaciones que estime conveniente siguiendo los pasos descriptos en "Agregar una lectura".

## Borrar una lectura

## Los pasos generales para borrar una lectura del contador son los siguientes:
Localice el equipo con contador habilitado, ya sea en forma manual o utilizando los métodos descriptos en

### "Buscar un equipo".
Una vez localizado, en la lista Registro de lecturas realizadas a:…, seleccione la lectura a borrar.
Una vez localizada, haga un clic sobre la opción borrar -  , de la barra de herramientas correspondiente al Registro de lecturas realizadas a:…
Tenga en cuenta que si la lectura fue cargada desde una O.T. y esta se cerró, el sistema le indicará que no se puede borrar la lectura.

## Graficar lecturas

## Los pasos generales para graficar lecturas del contador son los siguientes:
Localice el equipo con contador habilitado, ya sea en forma manual o utilizando los métodos descriptos en

### "Buscar un equipo".
Una vez localizado, haga un clic sobre la opción graficar -  , de la barra de herramientas correspondiente al Registro de lecturas realizadas a:…, de esta manera aparecerá la ventana de consulta.
Una vez en la ventana de consulta, en la sección Filtrar por…, deberá indicar entre que fechas desea filtra la información:
Desde: Ingrese la fecha de la lectura, desde la cual desea graficar.
Hasta: Ingrese la fecha de la lectura, hasta donde desea graficar.
Una vez que ha determinado el filtrado que desea, haga clic sobre el botón Graficar, o haga un clic sobre el botón Cancelar para volver a la ventana de consulta.
Tenga en cuenta que una vez obtenida la gráfica, podrá contar con una serie de opciones y herramientas. Para mayor información sobre el manejo de la gráfica, vea el capítulo “10.ANEXO 3”

## PRESUPUESTO DE TRABAJOS
Para acceder a la emisión de presupuesto de trabajos, elija la opción Programación | Presupuesto, del menú principal. De esta manera aparecerá la ventana de gestión (figura PT1), una vez en la misma podrá emitir un presupuesto de trabajos, agrupado por órdenes de trabajo programadas que se emitirán, o por los materiales que se utilizarán en estas O.T.

> **Figura PT1**

## Los pasos generales para realizar esta operación son los siguientes:
Seleccione en Equipos, el equipo al que desea realizar la consulta. Al seleccionar uno verá la información de él y de todos sus componentes si los tuviera. Si no selecciona ninguno, el sistema interpretará que la información a listar será la que corresponde a todo el equipamiento.
Ingrese en Desde la fecha de inicio del período a presupuestar.

## Ingrese en Hasta la fecha a la cual desea conocer el presupuesto de los trabajos.
Si desea filtrar por el Sector Responsable, haga un clic sobre la flecha del control y se desplegará la lista general de responsables. Ud. podrá seleccionar alguno de ellos y al listar se mostrarán solo los trabajos que estén bajo la supervisión del responsable seleccionado.
Seleccione si desea agrupar el presupuesto por órdenes de trabajo a emitir o por los materiales que se utilizarán en dichas órdenes.
Una vez que ha determinado el filtrado que desea, podrá visualizar la información de las siguientes maneras:
Si desea visualizar la información cómo un listado, haga clic sobre el botón Listar.
Si en cambio desea visualizar la información en forma gráfica, haga clic sobre el botón Gantt
(figura PT2).
Si desea visualizar la información en una planilla de cálculos, haga clic sobre el botón Excel.

> **Figura PT2**

## PROGRAMADO VS. REALIZADO
Podrá realizar una gráfica comparativa entre las O.T. periódicas que se debería haber programado y las que finalmente fueron realizadas en un periodo de tiempo. Esto permite visualizar rápidamente la aproximación a la programación ideal del preventivo (típicamente); así como también, las demoras en la realización de las O.T.
Para realizar la gráfica de Programado vs. Realizado, elija la opción Programación | Programado vs. Realizado del menú principal. De esta manera aparecerá la ventana de la figura PVR1.

> **Figura PVR1**

## Los pasos generales son los siguientes:
Seleccione el Equipo al que desea realizar la consulta. Al seleccionar uno verá la información de él y de todos sus componentes si los tuviera. Si no selecciona ninguno, el sistema interpretará que la información a listar será la que corresponda a todo el equipamiento.
Ingrese el rango de fechas para el cual desea obtener la información.
Si desea filtrar por el Sector Responsable, haga un clic sobre la flecha del control y se desplegará la lista general de responsables. Ud. podrá seleccionar alguno de ellos y al listar se mostrarán sólo los trabajos que estén bajo la supervisión del responsable seleccionado.
Una vez que ha determinado el filtrado que desea, haga clic sobre el botón Gantt. De esta manera aparecerá una gráfica comparativa (figura PVR2).
Las O.T. en amarillo indican la fecha en que debieron ser realizadas, mientras que las O.T. en blanco indican la fecha en que efectivamente fueron realizadas. Además, la flecha ayuda a relacionar la O.T. programada con su correspondiente O.T. realizada.

> **Figura PVR2**
Además de graficar los trabajos programados vs los trabajos realizados en forma de Gantt, usted cuenta con la opción Líneas, que le devolverá una gráfica comparativa entre lo que se programó y lo que se llevó a cabo, ordenado en la línea del tiempo, semana por semana. Figura PVR3. Usted puede filtrar los trabajos por fechas, por sector responsable, por tipo de procedimiento, y definir sectores y equipos.

> **Figura PVR3**

## TRABAJOS ATRASADOS (BACKLOG)
En el mismo menú de Programación usted cuenta con la opción Trabajos Atrasados, o Backlog, que le permitirá tener una clara noción de la cantidad de horas hombre atrasadas con las que cuenta. Este índice suma todas las horas hombre de los trabajos pendientes, así como las horas hombre restantes en los trabajos en ejecución. De la misma forma que en Programado vs. Realizado, esta búsqueda puede hacerse por equipos, por sectores, por responsables, por procedimiento, y definir las fechas entre las que se busca conocer dichos datos. La gráfica muestra la comparación semana por semana Figura PVR4.

> **Figura PVR4**
RESUMEN DE LA SITUACIÓN
Podrá visualizar en forma rápida la situación actual del sistema, en cuanto al trabajo atrasado (O.T. Pendientes), en curso (O.T. en Ejecución) y al necesario de programar (O.T. Necesarias de Emitir) y la solicitud de trabajos (Solicitudes de OT).
Para acceder al resumen, elija la opción Programación | Resumen del menú principal. De esta manera aparecerá la ventana de gestión (figura RS1).

> **Figura RS1**

## 5. Análisis de la Información de los Trabajos
En este capítulo se analiza la información resultante de las operaciones registradas en el sistema y formato de listado, como así también formato de gráficas.

## Costos

## Materiales utilizados

## Mano de obra utilizada

## Fallas

## Detalles

## Lecturas

## Gráficas

## Gráficas de Pareto de fallas