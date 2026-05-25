# Sistema de Asistencia - IE. Ignacia Velásquez

Aplicación móvil desarrollada en Flutter para la gestión y control de asistencia escolar de la Institución Educativa Ignacia Velásquez.

El sistema permite registrar asistencia diaria por sección, consultar reportes bimestrales, administrar estudiantes, usuarios, grados, secciones y bimestres, además de exportar reportes de asistencia.

---

## Propósito de la aplicación

La aplicación tiene como objetivo facilitar el registro y seguimiento de la asistencia de estudiantes de la IE. Ignacia Velásquez, reduciendo el trabajo manual y permitiendo que los usuarios autorizados puedan consultar y actualizar información desde un dispositivo móvil.

El sistema está pensado para ser utilizado por personal de la institución educativa, como directivos, docentes y auxiliares, y también contempla usuarios de tipo padre y estudiante para futuras funcionalidades de consulta.

---

## Funcionalidades principales

### Inicio de sesión

El sistema permite iniciar sesión usando el DNI del usuario y una contraseña asignada.

Internamente, el DNI se convierte en un correo institucional con el dominio:

```txt
@iv.edu.pe
```

Ejemplo:

```txt
DNI: 10000002
CONTRASEÑA: 123456
Email interno: 10000002@iv.edu.pe
```

---

### Gestión de usuarios

Permite administrar los usuarios del sistema.

Roles disponibles:

```txt
directivo
docente
auxiliar
padre
estudiante
```

Desde esta vista se puede:

- Crear usuarios.
- Editar datos de usuario.
- Asignar rol.
- Activar o desactivar usuarios.
- Eliminar el perfil del usuario en Firestore.

> Nota: eliminar un usuario desde la aplicación elimina su documento de Firestore, pero no necesariamente elimina la cuenta creada en Firebase Authentication.

---

### Gestión de estudiantes

Permite administrar la información de los estudiantes registrados.

Desde esta vista se puede:

- Crear estudiantes.
- Editar DNI, nombres, apellidos y sección.
- Activar o desactivar estudiantes.
- Eliminar estudiantes.
- Visualizar estudiantes con iniciales de colores para facilitar su identificación.

Los estudiantes inactivos no aparecen en las listas de asistencia.

---

### Gestión de grados

Permite registrar y administrar los grados académicos.

Desde esta vista se puede:

- Crear grados.
- Editar grados existentes.
- Eliminar grados.
- Ordenar grados mediante un campo de orden.

---

### Gestión de secciones

Permite administrar las secciones de la institución.

Desde esta vista se puede:

- Crear secciones.
- Asociar una sección a un grado.
- Asignar turno.
- Editar nombre de sección.
- Eliminar secciones.

---

### Gestión de bimestres

Permite administrar los periodos bimestrales usados para los reportes.

Desde esta vista se puede:

- Crear bimestres.
- Editar nombre, número, fecha de inicio y fecha de fin.
- Eliminar bimestres.
- Consultar el estado del bimestre.

---

### Registro de asistencia rápida

Permite registrar asistencia por sección y fecha.

Estados disponibles:

| Código | Descripción |
|---|---|
| A | Asistió |
| T | Tardanza |
| TJ | Tardanza justificada |
| F | Falta |
| FJ | Falta justificada |
| R | Retiro |

Características:

- Selección de fecha.
- Búsqueda de estudiantes por nombre o DNI.
- Registro masivo de asistencia.
- Carga automática de registros existentes por sección y fecha.
- Actualización de asistencia previamente registrada.
- Registro de justificación cuando el estado lo requiere.

---

### Reporte bimestral

Permite consultar la asistencia de una sección según el bimestre seleccionado.

Desde esta vista se puede:

- Seleccionar un bimestre.
- Visualizar asistencia por estudiante y fecha.
- Identificar estados mediante colores.
- Exportar el reporte de asistencia en formato CSV.
- Compartir el archivo exportado desde el dispositivo.

El archivo exportado incluye:

- Nombre de la institución.
- Nombre del reporte.
- Bimestre.
- Sección.
- Fecha de exportación.
- Lista de estudiantes.
- Estados por fecha.
- Totales por estado.
- Leyenda de códigos.

---

## Tecnologías utilizadas

La aplicación utiliza las siguientes tecnologías:

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Flutter Localizations
- Intl
- Share Plus

---

## Estructura general del proyecto

```txt
lib/
│
├── main.dart
├── firebase_options.dart
│
├── models/
│   ├── app_user.dart
│   ├── asistencia.dart
│   ├── bimestre.dart
│   ├── estudiante.dart
│   ├── grado.dart
│   └── seccion.dart
│
├── pages/
│   ├── auth_gate.dart
│   ├── login_page.dart
│   ├── home_page.dart
│   ├── asistencia_rapida_page.dart
│   ├── reporte_bimestral_page.dart
│   │
│   └── admin/
│       ├── bimestres_page.dart
│       ├── estudiantes_page.dart
│       ├── grados_page.dart
│       ├── secciones_page.dart
│       └── usuarios_page.dart
│
└── services/
    ├── auth_service.dart
    └── firestore_service.dart
```

---

## Colecciones principales en Firestore

### `usuarios`

Guarda los perfiles de usuario asociados a Firebase Authentication.

Campos principales:

```txt
uid
dni
nombres
correo
email
rol
activo
estudianteId
seccionesIds
creadoEn
actualizadoEn
```

---

### `estudiantes`

Guarda la información de estudiantes.

Campos principales:

```txt
dni
nombres
apellidos
nombreCompleto
seccionId
activo
creadoEn
actualizadoEn
```

---

### `grados`

Guarda los grados académicos.

Campos principales:

```txt
nombre
orden
nivel
activo
creadoEn
```

---

### `secciones`

Guarda las secciones asociadas a grados.

Campos principales:

```txt
gradoId
nombre
turno
activo
creadoEn
```

---

### `bimestres`

Guarda los periodos bimestrales.

Campos principales:

```txt
nombre
numero
fechaInicio
fechaFin
cerrado
creadoEn
actualizadoEn
```

---

### `asistencias`

Guarda los registros de asistencia.

Campos principales:

```txt
fechaKey
fecha
horaIngresoReferencia
bimestre
estudianteId
seccionId
estado
justificacion
marcadoPorUid
actualizadoEn
```

El ID recomendado para cada documento de asistencia es:

```txt
fechaKey_estudianteId
```

Ejemplo:

```txt
20260524_ID_DEL_ESTUDIANTE
```

---

## Credenciales de prueba

Estas credenciales sirven para probar el acceso según el tipo de usuario.

| Rol | DNI | Email interno |
|---|---:|---|
| Auxiliar | 10000001 | 10000001@iv.edu.pe |
| Directivo | 10000002 | 10000002@iv.edu.pe |
| Docente | 10000003 | 10000003@iv.edu.pe |
| Padre | 20000001 | 20000001@iv.edu.pe |
| Alumno | 70000001 | 70000001@iv.edu.pe |

> Para iniciar sesión desde la aplicación se usa el DNI.  
> El sistema convierte internamente el DNI al correo institucional correspondiente.

La contraseña será la que esté configurada para cada usuario en Firebase Authentication.

---

## Requisitos previos

Antes de ejecutar el proyecto, se necesita tener instalado:

- Flutter SDK
- Dart SDK
- Android Studio o Visual Studio Code
- Emulador Android o dispositivo físico
- Proyecto Firebase configurado
- Archivo `google-services.json` agregado en Android
- Dependencias instaladas con `flutter pub get`

---

## Configuración de Firebase

El proyecto usa Firebase para autenticación y base de datos.

Servicios necesarios:

1. Firebase Authentication
2. Cloud Firestore

En Firebase Authentication debe estar habilitado el proveedor:

```txt
Email/Password
```

Cada usuario debe existir en Firebase Authentication con su correo interno.

Ejemplo:

```txt
10000002@iv.edu.pe
```

Además, debe existir un documento en Firestore en la colección:

```txt
usuarios
```

con el mismo UID del usuario autenticado.

---

## Instalación del proyecto

Clonar o descargar el proyecto.

Luego ejecutar:

```bash
flutter pub get
```

Verificar dispositivos disponibles:

```bash
flutter devices
```

Ejecutar la aplicación:

```bash
flutter run
```

---

## Limpieza y reconstrucción

Si se agregan plugins nuevos, íconos o dependencias nativas, ejecutar:

```bash
flutter clean
flutter pub get
flutter run
```

Esto evita errores como:

```txt
MissingPluginException
```

---

## Cómo probar la aplicación

### 1. Iniciar sesión

Abrir la aplicación e ingresar con un DNI de prueba.

Ejemplo:

```txt
DNI: 10000002
Contraseña: la contraseña configurada en Firebase Authentication
```

---

### 2. Probar usuario directivo

Con el rol directivo se debe poder acceder a las opciones administrativas:

- Grados
- Secciones
- Bimestres
- Usuarios
- Estudiantes
- Asistencia rápida
- Reporte bimestral

---

### 3. Registrar grados y secciones

Crear al menos:

- Un grado.
- Una sección asociada al grado.
- Un turno.

---

### 4. Registrar estudiantes

Crear estudiantes y asociarlos a una sección.

Verificar que estén activos para que aparezcan en la asistencia.

---

### 5. Registrar bimestres

Crear un bimestre con:

```txt
Nombre: I Bimestre
Número: 1
Fecha inicio: fecha inicial del periodo
Fecha fin: fecha final del periodo
```

---

### 6. Registrar asistencia

Ir a:

```txt
Asistencia rápida
```

Seleccionar:

- Sección
- Fecha

Registrar estados de asistencia para los estudiantes y guardar.

Si se vuelve a seleccionar la misma sección y fecha, la aplicación debe cargar los datos registrados anteriormente para permitir su actualización.

---

### 7. Consultar reporte bimestral

Ir a:

```txt
Reporte bimestral
```

Seleccionar el bimestre.

La aplicación mostrará la asistencia de los estudiantes según las fechas del bimestre.

---

### 8. Exportar asistencia

Desde el reporte bimestral, presionar:

```txt
Exportar asistencia
```

La aplicación generará un archivo CSV con la asistencia consultada.

El archivo puede compartirse desde el dispositivo.

---

## Estados de asistencia

| Código | Significado | Requiere justificación |
|---|---|---|
| A | Asistió | No |
| T | Tardanza | No |
| TJ | Tardanza justificada | Sí |
| F | Falta | No |
| FJ | Falta justificada | Sí |
| R | Retiro | Sí |

---

## Consideraciones importantes

- No se permite registrar asistencia los fines de semana.
- Los estudiantes inactivos no aparecen en la lista de asistencia.
- Los usuarios inactivos pueden conservarse en Firestore, pero se recomienda validar su acceso según el campo `activo`.
- El rol usado para directivos debe ser `directivo`, no `director`.
- El documento de usuario en Firestore debe tener como ID el UID generado por Firebase Authentication.
- El campo `seccionesIds` permite limitar las secciones visibles para un usuario.
- Si `seccionesIds` está vacío, el usuario puede visualizar todas las secciones disponibles.

---

## Reglas sugeridas para pruebas

Durante desarrollo, se puede trabajar con reglas más abiertas solo de forma temporal.

Para producción, se recomienda definir reglas de seguridad que permitan:

- Leer usuarios solo si están autenticados.
- Permitir administración solo a usuarios con rol `directivo`.
- Permitir registro de asistencia a roles `directivo`, `docente` y `auxiliar`.
- Restringir acceso de padres y estudiantes solo a su información relacionada.

---

## Problemas frecuentes

### La aplicación no cambia de Login a Home

Verificar que se esté usando una pantalla tipo `AuthGate` que escuche:

```dart
FirebaseAuth.instance.authStateChanges()
```

---

### El usuario inicia sesión, pero queda cargando

Verificar que exista un documento en Firestore:

```txt
usuarios/{uid}
```

El ID del documento debe ser exactamente el UID del usuario autenticado.

---

### Error con el rol del usuario

Verificar que el campo `rol` tenga uno de estos valores:

```txt
directivo
docente
auxiliar
padre
estudiante
```

No usar:

```txt
director
```

Usar:

```txt
directivo
```

---

### Error `MissingPluginException`

Detener completamente la aplicación y ejecutar:

```bash
flutter clean
flutter pub get
flutter run
```

No basta con hot reload cuando se agregan plugins nuevos.

---

### El ícono de la app no cambia

Después de generar el ícono, desinstalar la aplicación del dispositivo y volver a ejecutar:

```bash
flutter run
```

---

## Convenciones del proyecto

### Correos internos

Todos los usuarios usan el dominio:

```txt
@iv.edu.pe
```

Ejemplo:

```txt
DNI: 10000003
Email interno: 10000003@iv.edu.pe
```

---

### Formato de fechaKey

Los registros de asistencia usan el formato:

```txt
yyyyMMdd
```

Ejemplo:

```txt
20260524
```

---

### Formato de nombre completo

Para estudiantes se recomienda guardar:

```txt
Apellidos, Nombres
```

Ejemplo:

```txt
Pérez Ramos, Juan Carlos
```

---

## Futuras mejoras sugeridas

- Validar el campo `activo` al iniciar sesión.
- Crear pantalla especial para padres.
- Crear pantalla especial para estudiantes.
- Permitir que padres consulten asistencia de sus hijos.
- Permitir que estudiantes consulten su historial.
- Exportar reportes en PDF.
- Agregar filtros por grado, sección y estudiante.
- Mejorar reglas de seguridad en Firestore.
- Agregar recuperación de contraseña.
- Agregar control de permisos por rol.
- Agregar auditoría de cambios en asistencia.
- Agregar soporte para feriados y días no laborables.

---

## Institución

```txt
IE. Ignacia Velásquez
```

Aplicación desarrollada para apoyar la gestión de asistencia escolar de la institución.

---

## Autoría

Proyecto desarrollado como aplicación Flutter para la gestión de asistencia escolar.

---

## Licencia

Uso interno educativo.
