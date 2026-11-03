// Prepara el proyecto Android para publicar el APK:
//   1. Baja la versión mínima a Android 5.0 (API 21) para que abra en más teléfonos.
//   2. Firma el APK con una clave propia (no con la de depuración).
//      La primera vez crea la clave en la carpeta `firma/` y la usa siempre.
//
// Lo ejecutan los compiladores automáticos. Uso manual:
//   dart run tool/preparar_android.dart "Nombre App"
//
// IMPORTANTE: guarda una copia de la carpeta `firma/` (por ejemplo en Drive).
// Si se pierde la clave, las apps instaladas no se podrán actualizar.
import 'dart:io';
import 'dart:math';

const int minSdk = 21; // Android 5.0
const String marca = '// firma-propia (tool/preparar_android.dart)';

void main(List<String> args) {
  final nombre = args.isEmpty ? 'App' : args.join(' ');
  final gradleKts = File('android/app/build.gradle.kts');
  final gradleGroovy = File('android/app/build.gradle');
  final File gradle;
  if (gradleKts.existsSync()) {
    gradle = gradleKts;
  } else if (gradleGroovy.existsSync()) {
    gradle = gradleGroovy;
  } else {
    stderr.writeln('No existe android/app/build.gradle(.kts). Ejecuta primero flutter create.');
    exit(1);
  }
  final kts = gradle.path.endsWith('.kts');
  var texto = gradle.readAsStringSync();

  // ---------------- 1. Versión mínima de Android ----------------
  texto = texto.replaceAllMapped(
    RegExp(kts
        ? r'minSdk(Version)?\s*=\s*[^\n]+'
        : r'minSdk(Version)?\s*(=\s*)?[^\n]+'),
    (_) => kts ? 'minSdk = $minSdk' : 'minSdkVersion $minSdk',
  );
  stdout.writeln('   Android mínimo: 5.0 (API $minSdk)');

  // ---------------- 2. Clave de firma propia ----------------
  final propiedades = File('android/key.properties');
  if (!propiedades.existsSync()) {
    if (Platform.environment['CI'] == 'true') {
      stdout.writeln('   (Nube) Sin clave propia: se firma con la clave de depuración.');
    } else {
      _crearClave(nombre, propiedades);
    }
  } else {
    stdout.writeln('   Clave de firma: se usa la existente (android/key.properties)');
  }

  if (!texto.contains(marca)) {
    texto = kts ? _parcheKts(texto) : _parcheGroovy(texto);
  }
  gradle.writeAsStringSync(texto);
  _ignorarEnGit();
}

void _crearClave(String nombre, File propiedades) {
  final keytool = _buscarKeytool();
  if (keytool == null) {
    stderr.writeln('   [AVISO] No se encontró "keytool" (viene con Java / Android Studio).\n'
        '   El APK se firmará con la clave de depuración esta vez.');
    return;
  }
  final archivo = nombre.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  final dir = Directory('firma')..createSync(recursive: true);
  final jks = File('${dir.path}/${archivo.isEmpty ? 'app' : archivo}.jks');
  final clave = _claveAleatoria();
  if (!jks.existsSync()) {
    final r = Process.runSync(keytool, [
      '-genkeypair', '-noprompt',
      '-keystore', jks.path,
      '-alias', 'upload',
      '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000',
      '-storepass', clave, '-keypass', clave,
      '-dname', 'CN=$nombre, O=$nombre, C=VE',
    ]);
    if (r.exitCode != 0) {
      stderr.writeln('   [AVISO] No se pudo crear la clave: ${r.stderr}');
      return;
    }
  } else {
    stderr.writeln('   [AVISO] Existe ${jks.path} pero falta android/key.properties.\n'
        '   Restaura android/key.properties desde firma/LEEME_CLAVE.txt.');
    return;
  }
  final ruta = jks.absolute.path.replaceAll(r'\', '/');
  propiedades.writeAsStringSync('storePassword=$clave\n'
      'keyPassword=$clave\n'
      'keyAlias=upload\n'
      'storeFile=$ruta\n');
  File('${dir.path}/LEEME_CLAVE.txt').writeAsStringSync('''
CLAVE DE FIRMA DE "$nombre"  -  ¡GUÁRDALA EN UN LUGAR SEGURO!
==============================================================
Con esta clave se firman todas las versiones del APK. Si la pierdes,
los teléfonos que ya tienen la app NO podrán actualizarla (habría que
desinstalar), y en la Play Store tendrías que publicar una app nueva.

Haz una copia de esta carpeta "firma" en Google Drive o en un pendrive.

Archivo de clave : ${jks.path}
Alias            : upload
Contraseña       : $clave

Si un día copias el proyecto a otra PC, copia también esta carpeta y
crea el archivo android/key.properties con este contenido
(cambia la ruta si la carpeta quedó en otro lugar):

storePassword=$clave
keyPassword=$clave
keyAlias=upload
storeFile=$ruta
''');
  stdout.writeln('   Clave de firma NUEVA creada en ${jks.path}');
  stdout.writeln('   >>> Guarda una copia de la carpeta "firma" (lee firma/LEEME_CLAVE.txt) <<<');
}

String? _buscarKeytool() {
  final exe = Platform.isWindows ? 'keytool.exe' : 'keytool';
  final candidatos = <String>[];
  final javaHome = Platform.environment['JAVA_HOME'];
  if (javaHome != null && javaHome.isNotEmpty) candidatos.add('$javaHome/bin/$exe');
  if (Platform.isWindows) {
    for (final base in [
      Platform.environment['ProgramFiles'] ?? r'C:\Program Files',
      Platform.environment['LOCALAPPDATA'] ?? '',
    ]) {
      if (base.isEmpty) continue;
      candidatos.add('$base\\Android\\Android Studio\\jbr\\bin\\$exe');
      candidatos.add('$base\\Android\\Android Studio\\jre\\bin\\$exe');
      candidatos.add('$base\\Programs\\Android Studio\\jbr\\bin\\$exe');
    }
  } else {
    candidatos.add('/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool');
    candidatos.add('/opt/android-studio/jbr/bin/keytool');
  }
  for (final c in candidatos) {
    if (File(c).existsSync()) return c;
  }
  // Último intento: el que esté en el PATH.
  try {
    final r = Process.runSync(exe, ['-help']);
    if (r.exitCode == 0 || '${r.stdout}${r.stderr}'.contains('keytool')) return exe;
  } catch (_) {}
  return null;
}

String _claveAleatoria() {
  const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  final r = Random.secure();
  return List.generate(20, (_) => letras[r.nextInt(letras.length)]).join();
}

String _parcheKts(String t) {
  if (!t.contains('import java.util.Properties')) {
    t = 'import java.io.FileInputStream\nimport java.util.Properties\n\n$t';
  }
  t = t.replaceFirst(
    RegExp(r'\nandroid\s*\{'),
    '''

$marca
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    if (keystorePropertiesFile.exists()) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
''',
  );
  t = t.replaceFirst(
    RegExp(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)'),
    'signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")',
  );
  return t;
}

String _parcheGroovy(String t) {
  t = t.replaceFirst(
    RegExp(r'\nandroid\s*\{'),
    '''

$marca
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            release {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }
''',
  );
  t = t.replaceFirst(
    RegExp(r'signingConfig\s*=?\s*signingConfigs\.debug'),
    'signingConfig keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug',
  );
  return t;
}

void _ignorarEnGit() {
  final gi = File('.gitignore');
  final actual = gi.existsSync() ? gi.readAsStringSync() : '';
  final faltan = ['firma/', 'android/key.properties']
      .where((l) => !actual.split('\n').map((x) => x.trim()).contains(l))
      .toList();
  if (faltan.isEmpty) return;
  gi.writeAsStringSync(
      '${actual.isEmpty || actual.endsWith('\n') ? actual : '$actual\n'}'
      '# Clave de firma (no subir a GitHub)\n${faltan.join('\n')}\n');
}
