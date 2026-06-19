# Inventario de Bodega (Flutter / Android)

App de conteo fisico de inventario que importa el catalogo desde un Excel
exportado de SICAR, permite contar por escaneo de codigo de barras, por
paquetes, por peso, o de forma manual, y exporta un reporte de diferencias
(faltantes/sobrantes) en Excel.

## Que contiene este proyecto

```
inventario_bodega/
├── lib/
│   ├── main.dart
│   ├── theme/app_theme.dart
│   ├── models/
│   │   ├── product.dart
│   │   ├── conteo_record.dart
│   │   └── report_row.dart
│   ├── database/
│   │   └── database_helper.dart        (SQLite: catalogo + conteos + reporte)
│   ├── services/
│   │   ├── excel_import_service.dart   (lee .xlsx de SICAR)
│   │   └── excel_export_service.dart   (genera .xlsx de reporte)
│   ├── widgets/
│   │   ├── product_info_card.dart
│   │   └── big_number_field.dart
│   └── screens/
│       ├── home_screen.dart
│       ├── scanner_screen.dart         (camara + mobile_scanner)
│       ├── count_capture_screen.dart   (modos: unidad / paquete / peso)
│       ├── manual_search_screen.dart   (busqueda sin escaneo)
│       └── reports_screen.dart         (diferencias + exportar)
├── pubspec.yaml
├── analysis_options.yaml
├── .gitignore
├── MANIFEST_REFERENCE.xml              (permisos que debe tener el manifest)
└── .github/workflows/build-apk.yml     (compila el APK en la nube)
```

**Importante:** este paquete NO incluye la carpeta nativa `android/`. Eso es
intencional: se genera automaticamente (paso 3 abajo) con la version exacta
de Flutter/Gradle/Kotlin que se use para compilar, evitando el error mas
comun al armar un proyecto Flutter a mano (versiones de Gradle/AGP que no
combinan). El workflow de GitHub Actions ya incluido la genera solo.

---

## Como compilar el APK usando UNICAMENTE el telefono (recomendado)

No necesitas Android Studio ni una computadora. Vamos a usar **GitHub** para
que la compilacion ocurra en la nube (gratis) y descargar el APK ya
compilado desde el navegador del telefono.

### Paso 1 — Crea una cuenta de GitHub (si no tienes)

Desde el navegador del telefono, entra a https://github.com y registrate.

### Paso 2 — Crea un repositorio nuevo

1. Toca el boton **+** → **New repository**.
2. Nombre: `inventario-bodega` (o el que prefieras).
3. Visibilidad: Public o Private, ambas funcionan.
4. Crea el repositorio (no hace falta marcar "Add README").

### Paso 3 — Sube los archivos del proyecto

La forma mas facil desde el telefono es con la app **Termux** (terminal de
Android, gratis, sin necesidad de root):

1. Instala **Termux** desde F-Droid (recomendado) o Google Play.
2. Abre Termux y ejecuta:
   ```sh
   pkg update && pkg install git -y
   ```
3. Copia esta carpeta de proyecto a tu telefono (por ejemplo, descarga el
   .zip que te compartio Claude, ponlo en la carpeta `Download`, y en
   Termux):
   ```sh
   pkg install unzip -y
   cd ~
   cp /sdcard/Download/inventario_bodega.zip .
   unzip inventario_bodega.zip
   cd inventario_bodega
   ```
   (La primera vez que uses una carpeta de `/sdcard`, Termux te pedira
   permiso de almacenamiento: ejecuta `termux-setup-storage` y acepta.)
4. Conecta con tu repositorio y sube el codigo:
   ```sh
   git init
   git add .
   git commit -m "Primera version"
   git branch -M main
   git remote add origin https://github.com/TU_USUARIO/inventario-bodega.git
   git push -u origin main
   ```
   GitHub te pedira usuario y, en vez de contrasena, un **Personal Access
   Token** (Settings → Developer settings → Personal access tokens →
   Generate new token, marca el permiso `repo`, y usalo como contrasena).

**Alternativa sin Termux:** en la pagina del repositorio en GitHub, toca
"Add file" → "Upload files" y arrastra/selecciona todos los archivos y
carpetas del proyecto descomprimido desde el explorador de archivos del
telefono. Es mas lento con muchos archivos pero funciona igual.

### Paso 4 — Deja que GitHub compile el APK

En cuanto el codigo llega a la rama `main`, el workflow
`.github/workflows/build-apk.yml` se ejecuta automaticamente:

1. Ve a tu repositorio en GitHub → pestaña **Actions**.
2. Veras "Build APK" corriendo (circulo amarillo). Tarda entre 5 y 10
   minutos la primera vez.
3. Si no arranco solo, entra a Actions → "Build APK" → **Run workflow**.

### Paso 5 — Descarga el APK

1. Cuando el workflow termine con una palomita verde, entra a esa
   ejecucion.
2. Baja hasta la seccion **Artifacts** y toca `inventario-bodega-apk`.
3. Se descarga un .zip con el `app-release.apk` dentro. Extraelo con
   cualquier administrador de archivos.
4. Toca el `.apk` para instalarlo (Android te pedira permitir "instalar
   apps de origen desconocido" la primera vez — es normal, acepta solo
   para este archivo).

¡Listo! La app queda instalada como cualquier otra.

Cada vez que quieras actualizar la app: edita los archivos en `lib/`, vuelve
a subirlos a GitHub (`git add . && git commit -m "cambios" && git push`), y
repite el paso 5 para bajar el nuevo APK.

---

## Alternativa: compilar 100% offline en el telefono con Termux

Es posible instalar el SDK de Flutter completo dentro de Termux y compilar
sin depender de internet/GitHub, pero es un proceso pesado (varios GB de
descarga, 30-60+ minutos, y requiere bastante RAM/almacenamiento libre).
Se recomienda solo si no tienes forma de usar GitHub Actions. Pasos
generales:

```sh
pkg update && pkg install git unzip wget openjdk-17 -y
pkg install flutter      # algunos repos de Termux ya empaquetan Flutter
# o, manualmente:
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$PATH:$HOME/flutter/bin"
flutter doctor           # te dira que falta (Android SDK, licencias, etc.)
```

Tendras que instalar tambien las Android command-line tools y aceptar las
licencias (`sdkmanager --licenses`), lo cual en Termux requiere pasos
adicionales (paquete `proot-distro` con Ubuntu es lo mas estable). Por la
cantidad de pasos especificos del dispositivo, **se recomienda el metodo de
GitHub Actions del Paso 1-5** salvo que tengas experiencia previa con
Termux.

---

## Si en algun momento SI tienes acceso a una computadora con Android Studio

1. Instala Flutter SDK y Android Studio normalmente.
2. Copia esta carpeta del proyecto a tu equipo.
3. Abre una terminal dentro de la carpeta `inventario_bodega` y ejecuta:
   ```sh
   flutter create --platforms=android .
   ```
   Esto genera la carpeta `android/` nativa basada en tu version instalada
   de Flutter (sin sobreescribir tu `lib/` ni `pubspec.yaml`).
4. Abre `android/app/src/main/AndroidManifest.xml` y agrega los permisos
   indicados en `MANIFEST_REFERENCE.xml` (permiso de camara).
5. Ejecuta:
   ```sh
   flutter pub get
   flutter build apk --release
   ```
6. El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.
7. O abre la carpeta completa en Android Studio (File → Open) y usa
   Build → Build APK(s) desde el menu.

---

## Columnas esperadas en el Excel de SICAR

La app busca, en las primeras 10 filas, una fila de encabezados que
contenga al menos `clave1` y `descripcion` (no distingue mayusculas,
acentos, ni si llevan asterisco `*`). Columnas reconocidas:

| Campo        | Nombres de columna aceptados                          | Obligatorio |
|--------------|--------------------------------------------------------|:-----------:|
| clave1       | clave1, clave, codigo, sku                              | Si |
| descripcion  | descripcion, desc, nombre, articulo, producto            | Si |
| costo        | costo, preciocosto                                       | No |
| precio1      | precio1, precio, precioventa                              | No |
| existencia   | existencia, existencias, stock, inventario, cantidad      | No |

Si reimportas un Excel actualizado, los productos se actualizan (por
`clave1`) sin borrar los conteos fisicos ya capturados.

## Flujo de uso recomendado

1. **Importar Excel** desde la pantalla principal.
2. **Escanear codigo** para contar producto por producto; al guardar,
   regresa solo a la camara para seguir con el siguiente.
3. Para piezas dificiles de escanear o agotadas, usa **Buscar producto**.
4. En la pantalla de captura, cambia entre pestañas **Unidad / Paquete /
   Peso** segun como estes contando ese producto.
5. Al terminar, entra a **Reportes** para ver faltantes/sobrantes y
   exportar el Excel final (Codigo, Descripcion, Existencia sistema,
   Existencia fisica, Diferencia).
6. Para iniciar un inventario nuevo sin perder el catalogo, usa el icono
   de "Nueva sesion de conteo" (♻) en la pantalla principal — borra solo
   los conteos, no los productos importados.
