# flutter_signing_init

A Dart CLI tool to automatically set up Android release signing for your Flutter projects. It generates a keystore, creates `key.properties`, and configures your `build.gradle` or `build.gradle.kts` files seamlessly!

## 🚀 How to Use

Any Flutter developer can easily set up their project for release signing by running this tool.

### 1. Install the CLI Package globally

Run the following command in your terminal to install the package globally from GitHub:

```bash
dart pub global activate --source git https://github.com/ranasheikh64/flutter_signing_init.git
```

### 2. Run the Command

Navigate to the root directory of your Flutter project and simply run:

```bash
dart pub global run flutter_signing_init:main
```

That's it! 🎉 

The script will automatically:
- Generate a new `key.jks` keystore inside `android/app/`.
- Create the `android/key.properties` file with default secure passwords.
- Detect whether you are using Groovy (`build.gradle`) or Kotlin (`build.gradle.kts`).
- Auto-inject the keystore properties loading script.
- Auto-inject the `signingConfigs.release` block.
- Map your release build to use this new signing config.
- *If you already have a keystore or configuration, it will safely skip those steps without breaking your project!*

### 3. Get your SHA-1 and SHA-256

Once the setup is done, you can easily get your SHA fingerprints for Firebase/Google APIs by running:

```bash
cd android && ./gradlew signingReport
```
*(Look for the `Variant: release` section!)*

---

**Made with ❤️ by Rana Sheikh (Jronix - A Software Solution)**
