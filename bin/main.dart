import 'dart:io';

void main() async {
  print('================================================');
  print('🚀 Welcome to Flutter Signing Init CLI 🚀');
  print('✨ Built by Jronix Development Team ✨');
  print('================================================');
  print('Starting Android Release Signing Setup...');
  print('================================================');

  final keystoreName = 'key.jks';
  final keyAlias = 'upload';
  
  // Dynamically generate password based on the project's pubspec.yaml
  String projectName = 'my_app';
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    final lines = pubspecFile.readAsLinesSync();
    for (var line in lines) {
      if (line.startsWith('name:')) {
        projectName = line.substring(5).trim();
        break;
      }
    }
  }
  
  final storePassword = '${projectName}_secure2026';
  final keyPassword = '${projectName}_secure2026';

  final androidDir = Directory('android');
  final appDir = Directory('android/app');

  if (!androidDir.existsSync() || !appDir.existsSync()) {
    print('❌ Error: Could not find android/ or android/app/ directory.');
    print('Make sure you are running this command from the ROOT of your Flutter project.');
    return;
  }

  // 1. Generate key.jks
  final keyPath = 'android/app/$keystoreName';
  final keyFile = File(keyPath);
  
  if (keyFile.existsSync()) {
    print('✅ key.jks already exists in android/app/. Skipping key generation.');
  } else {
    print('⏳ Generating key.jks...');
    final result = await Process.run(
      'keytool',
      [
        '-genkeypair',
        '-v',
        '-keystore',
        keyPath,
        '-storepass',
        storePassword,
        '-keypass',
        keyPassword,
        '-keyalg',
        'RSA',
        '-keysize',
        '2048',
        '-validity',
        '10000',
        '-alias',
        keyAlias,
        '-dname',
        'CN=Rana, OU=Developer, O=Jronix, L=Dhaka, ST=Dhaka, C=BD'
      ],
      runInShell: true,
    );

    if (result.exitCode != 0) {
      print('❌ Failed to generate key.jks: ${result.stderr}');
      return;
    }
    print('✅ key.jks generated successfully!');
  }

  // 2. Generate key.properties
  final keyPropsFile = File('android/key.properties');
  if (keyPropsFile.existsSync()) {
    print('✅ android/key.properties already exists. Skipping properties creation.');
  } else {
    print('⏳ Creating android/key.properties...');
    keyPropsFile.writeAsStringSync('''
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$keyAlias
storeFile=../app/$keystoreName
''');
    print('✅ android/key.properties created successfully!');
  }

  // 3. Detect and configure build.gradle / build.gradle.kts
  final ktsFile = File('android/app/build.gradle.kts');
  final groovyFile = File('android/app/build.gradle');

  if (ktsFile.existsSync()) {
    _configureKotlinGradle(ktsFile);
  } else if (groovyFile.existsSync()) {
    _configureGroovyGradle(groovyFile);
  } else {
    print('❌ Error: Could not find build.gradle or build.gradle.kts in android/app/');
    return;
  }

  print('================================================');
  print('🎉 Setup complete! You are ready for Release!');
  print('Run: cd android && ./gradlew signingReport');
  print('------------------------------------------------');
  print('Thank you for using Flutter Signing Init!');
  print('✨ Built by Jronix Development Team ✨');
  print('Jronix - A Software Solution');
  print('================================================');
}

void _configureKotlinGradle(File file) {
  print('⚙️ Detected build.gradle.kts (Kotlin DSL)');
  String content = file.readAsStringSync();
  bool isModified = false;

  if (!content.contains('keystoreProperties = Properties()')) {
    final propertiesImport = '''
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

''';
    content = propertiesImport + content;
    isModified = true;
    print('✅ Added keystoreProperties loader');
  } else {
    print('ℹ️ Keystore loader already exists in build.gradle.kts');
  }

  if (!content.contains('create("release") {') && !content.contains('signingConfigs {')) {
    final signingConfigBlock = '''
    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

''';
    content = content.replaceFirst('    buildTypes {', signingConfigBlock + '    buildTypes {');
    isModified = true;
    print('✅ Added signingConfigs.release block');
  }

  if (content.contains('signingConfig = signingConfigs.getByName("debug")')) {
    content = content.replaceFirst(
      'signingConfig = signingConfigs.getByName("debug")',
      'signingConfig = signingConfigs.getByName("release")'
    );
    isModified = true;
    print('✅ Linked release buildType to release signingConfig');
  } else if (!content.contains('signingConfig = signingConfigs.getByName("release")')) {
    // Inject it manually inside buildTypes { getByName("release") { ... } }
    if (content.contains('getByName("release") {')) {
       content = content.replaceFirst(
         'getByName("release") {', 
         'getByName("release") {\\n            signingConfig = signingConfigs.getByName("release")'
       );
       isModified = true;
       print('✅ Linked release buildType to release signingConfig');
    }
  }

  if (isModified) {
    file.writeAsStringSync(content);
    print('✅ build.gradle.kts successfully updated!');
  } else {
    print('✅ build.gradle.kts is already fully configured.');
  }
}

void _configureGroovyGradle(File file) {
  print('⚙️ Detected build.gradle (Groovy DSL)');
  String content = file.readAsStringSync();
  bool isModified = false;

  if (!content.contains('keystorePropertiesFile.exists()')) {
    final propertiesImport = '''
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

''';
    content = content.replaceFirst('android {', propertiesImport + 'android {');
    isModified = true;
    print('✅ Added keystoreProperties loader');
  } else {
    print('ℹ️ Keystore loader already exists in build.gradle');
  }

  if (!content.contains('signingConfigs {') || !content.contains('release {')) {
    final signingConfigBlock = '''
    signingConfigs {
        release {
            keyAlias = keystoreProperties['keyAlias']
            keyPassword = keystoreProperties['keyPassword']
            storeFile = file(keystoreProperties['storeFile'])
            storePassword = keystoreProperties['storePassword']
        }
    }

''';
    content = content.replaceFirst('    buildTypes {', signingConfigBlock + '    buildTypes {');
    isModified = true;
    print('✅ Added signingConfigs.release block');
  }

  if (content.contains('signingConfig signingConfigs.debug')) {
    content = content.replaceFirst(
      'signingConfig signingConfigs.debug',
      'signingConfig signingConfigs.release'
    );
    isModified = true;
    print('✅ Linked release buildType to release signingConfig');
  } else if (!content.contains('signingConfig signingConfigs.release')) {
    if (content.contains('release {')) {
       // Using regular expression to find release block under buildTypes
       // It's safer to just inject it if missing inside buildTypes -> release
       content = content.replaceFirst(
         'release {', 
         'release {\\n            signingConfig signingConfigs.release'
       );
       isModified = true;
       print('✅ Linked release buildType to release signingConfig');
    }
  }

  if (isModified) {
    file.writeAsStringSync(content);
    print('✅ build.gradle successfully updated!');
  } else {
    print('✅ build.gradle is already fully configured.');
  }
}
