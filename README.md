# App de supermercado — demo marca blanca

App Flutter de pedidos para supermercados, **sin nombre ni logo**, lista para mostrar a cualquier negocio y personalizar en minutos.

## Qué incluye

**App del cliente**
- Inicio con buscador, banners de promociones, categorías, ofertas y "lo más pedido"
- Catálogo por categorías (con orden por precio/ofertas) y búsqueda sin acentos
- Detalle de producto con precio en $ y Bs, descuento y stock
- Carrito con barra de progreso para envío gratis
- Checkout: delivery o retiro en tienda · Pago Móvil, Zelle, efectivo (calcula vuelto) o punto de venta · datos de pago copiables · total en $ y Bs
- Seguimiento del pedido con línea de tiempo (se actualiza en vivo)
- Historial de pedidos y perfil con cuenta de usuario

**Panel del supermercado** (entra con una cuenta de empleado o administrador)
- Resumen: ventas del día, pedidos, ticket promedio, gráfico de 7 días, más vendidos y stock bajo
- Pedidos: activos / entregados / cancelados, avanzar estados, verificar pagos, cancelar (devuelve stock)
- Productos: crear, editar, eliminar, ocultar, ofertas y existencia
- Ajustes: tasa de cambio, costo y mínimo de delivery, formas de entrega, métodos de pago, datos de cobro, dirección y horario
- Botón para reiniciar los datos de la demo

> Truco para la presentación: haz un pedido como cliente, abre el panel y avánzalo de estado; al volver, el seguimiento del cliente ya cambió.

## Compilador automático → SuperMarket.apk

**Windows:** doble clic en `COMPILAR_APK.bat`. El compilador verifica Flutter, genera la carpeta Android, pone el nombre *SuperMarket*, descarga las dependencias, compila y deja el APK en la carpeta `APK/`, que se abre sola al terminar:

- `APK/SuperMarket.apk` (siempre la última versión)
- `APK/SuperMarket-v1.0.0-AAAAMMDD-HHMM.apk` (copia con fecha, como historial)

**Linux / macOS:** `./build_apk.sh`

**Sin instalar Flutter (en la nube):** sube la carpeta a un repositorio de GitHub. El flujo `.github/workflows/build-apk.yml` compila en cada push, o manualmente desde *Actions → Compilar APK SuperMarket → Run workflow*. El APK queda para descargar en *Artifacts* como `SuperMarket-apk`.

Para cambiar el nombre del APK, edita `$AppName` en `build_apk.ps1` (o `APP_NAME` en los otros scripts) y `appName` en `lib/config/brand.dart`.

## Compilación manual

Requiere Flutter 3.19 o superior.

```bash
cd super_app
flutter create --org com.tuempresa --project-name super_app --platforms android,ios .
flutter pub get
flutter run                  # en un teléfono o emulador
flutter build apk --release  # APK en build/app/outputs/flutter-apk/
```

`flutter create .` solo genera las carpetas `android/` e `ios/` que faltan; no toca `lib/`.

## Personalizar para cada supermercado

| Qué | Dónde |
|---|---|
| Nombre, eslogan, colores, WhatsApp | `lib/config/brand.dart` → `Brand` |
| Logo | Coloca `assets/logo.png`, declara el asset en `pubspec.yaml` y pon `logoAsset = 'assets/logo.png'` |
| Datos de pago, dirección, horario, tasa, delivery | `lib/config/brand.dart` → `BusinessDefaults` (o desde el panel) |
| Categorías y productos de muestra | `lib/data/sample_data.dart` |
| Nombre bajo el ícono en Android | `android/app/src/main/AndroidManifest.xml` → `android:label` |
| Ícono de la app | paquete `flutter_launcher_icons` |

## Estructura

```
lib/
  config/     marca y tema
  data/       catálogo de demostración
  models/     producto, pedido, estados y métodos de pago
  state/      AppState (Provider): carrito, pedidos, ajustes, estadísticas
  screens/
    client/   pantallas del cliente
    admin/    panel del supermercado
  widgets/    componentes reutilizables
```

## Pasar a producción

Todo vive en memoria dentro de `lib/state/app_state.dart`. Para un cliente real se reemplazan esos métodos (`placeOrder`, `setStatus`, `addProduct`, etc.) por Firebase Firestore o una API (Django), y el módulo de cuentas se conecta a Firebase Auth. Las pantallas no necesitan cambios. Las "fotos" son emojis para que la demo funcione sin internet; en producción se cambian por `Image.network` desde Firebase Storage.

## Cuentas de usuario (nuevo en v1.1)

La app ahora tiene **usuarios y perfiles completos** (módulo `lib/cuentas/`, sin paquetes externos):

- **Acceso:** iniciar sesión con correo o teléfono, crear cuenta, recuperar contraseña o entrar como **invitado**.
- **Perfil:** mis datos, varias direcciones (con principal), cambio de contraseña, eliminar cuenta, notificaciones y programa de **SuperPuntos** (las compras suman puntos).
- **Checkout:** si hay sesión, nombre, teléfono y dirección se llenan solos.
- **Roles:** cliente, empleado y administrador. El panel (Panel del supermercado) solo lo ve el personal; los clientes ya no pueden entrar.
- **Usuarios y clientes** (dentro del panel): buscar, filtrar, ver historial y puntos, crear empleados, cambiar roles, bloquear, restablecer contraseña y eliminar. El empleado solo consulta; el administrador modifica.
- El personal entra directo al panel y puede pasar a la tienda con el botón *Ver tienda*.

**Cuentas de demostración** (también aparecen como botones en la pantalla de acceso):

| Rol | Correo | Contraseña |
|---|---|---|
| Cliente | cliente@demo.com | cliente123 |
| Empleado | empleado@demo.com | empleado123 |
| Administrador | admin@demo.com | admin123 |

> Todo vive en memoria, como el resto de la demo. Para producción se reemplazan los métodos de `lib/cuentas/sesion.dart` por Firebase Auth / Firestore o la API del negocio, sin tocar las pantallas.

## Compatibilidad y firma (v1.1.1)

- **Android 5.0 o superior** (API 21). Antes el mínimo era Android 7.0.
- **Clave de firma propia.** La primera vez que compilas, el compilador crea la clave en la carpeta `firma/` (con `firma/LEEME_CLAVE.txt`, que trae la contraseña) y el archivo `android/key.properties`. Las siguientes veces usa siempre la misma clave. Lo hace `tool/preparar_android.dart`.
- **Guarda una copia de la carpeta `firma/`** (Drive o pendrive). Si se pierde, los teléfonos que ya tienen la app no podrán actualizarla.
- Quien tenga instalada una versión anterior (firmada con la clave de depuración) debe **desinstalarla una sola vez** antes de instalar la 1.1.1. De ahí en adelante las actualizaciones instalan encima.
- Para crear la clave hace falta `keytool`, que viene con Android Studio. Si no lo encuentra, el APK se firma con la clave de depuración y el compilador lo avisa.
- `firma/` y `android/key.properties` están en `.gitignore`: no se suben a GitHub. En la compilación en la nube (GitHub Actions) el APK sale con la clave de depuración.
