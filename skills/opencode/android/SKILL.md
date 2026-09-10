---
name: android
description: Android development with Android Studio including Gradle/AGP, Kotlin, Jetpack Compose, ADB (devices, logcat, install), emulator AVDs, APK/AAB builds, manifest, SDK manager, debugging (StrictMode, Profiler), and Play signing. Also covers Android Studio's built-in MCP server (2025.2+). Activate for any Android app development, build, debugging, or Android Studio task.
---

# Android Development Skill

## Purpose
Provides comprehensive Android development capabilities using Android Studio and the Android toolchain: Gradle/AGP builds, Kotlin, Jetpack Compose, ADB device management and debugging, emulator AVDs, APK/AAB packaging, SDK manager, manifests, crash analysis, StrictMode, and Play signing. Documents the built-in Android Studio MCP server (2025.2+).

## When to Activate
- Creating/building an Android app; running Gradle tasks & dependencies (Gradle/AGP)
- Writing Kotlin or Jetpack Compose UI
- Using ADB (devices, logcat, install, shell) and emulator AVDs
- Building release APK/AAB and Play signing
- Debugging crashes, StrictMode violations, memory issues
- Enabling/using Android Studio's built-in MCP server (2025.2+)

## Core Knowledge

### Android Studio & SDK
- IntelliJ-based IDE; auto-handles SDK/Gradle
- **MCP**: since **2025.2**, built-in (`Settings > Tools > MCP Server`); standalone `@jetbrains/mcp-proxy` is **DEPRECATED**
- Layout: `app/src/main/java|kotlin`, `app/src/main/res`, `app/build.gradle.kts`, `gradle/libs.versions.toml`

### Gradle / AGP
```kotlin
// app/build.gradle.kts
plugins { id("com.android.application"); id("org.jetbrains.kotlin.android") }
android {
    namespace = "com.example.myapp"
    compileSdk = 35
    defaultConfig {
        applicationId = "com.example.myapp"; minSdk = 24; targetSdk = 35
        versionCode = 1; versionName = "1.0" }
    buildTypes { release { isMinifyEnabled = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt")) } }
}
```
```bash
./gradlew assembleDebug / assembleRelease / installDebug / lint / test / clean
./gradlew :app:assembleDebug --stacktrace     # verbose on failure
```

### Kotlin Basics
```kotlin
val name: String = "App"; var count: Int = 0
fun add(a: Int, b: Int) = a + b
lifecycleScope.launch { val r = withContext(Dispatchers.IO) { fetch() }; updateUi(r) }
```

### Jetpack Compose
```kotlin
@Composable fun Greeting(name: String, modifier: Modifier = Modifier) {
    Column(modifier = modifier.padding(16.dp)) {
        Text(text = "Hello, $name!"); Button(onClick = { }) { Text("Click") }
    }
}
@Composable fun MyApp() = MaterialTheme {
    Scaffold(topBar = { TopAppBar(title = { Text("My App") }) }) { p ->
        Greeting("World", Modifier.padding(p))
    }
}
```

### ADB
```bash
adb devices ; adb install app-debug.apk ; adb uninstall com.example.myapp
adb shell am force-stop com.example.myapp
adb logcat                    # stream | -c clear | *:E errors | -b crash
adb logcat -s MyTag           # by tag
adb reverse tcp:8080 tcp:8080 # local dev port forwarding
adb exec-out screencap -p > s.png
# AVDs: avdmanager list avd ; avdmanager create avd -n pixel -k "system-images;android-35;google_apis;x86_64" ; emulator -avd pixel
```

### Manifest, Build, Debug
```xml
<uses-permission android:name="android.permission.INTERNET" />
<application android:label="@string/app_name" android:icon="@mipmap/ic_launcher">
    <activity android:name=".MainActivity" android:exported="true">
        <intent-filter>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent-filter>
    </activity>
</application>
```
```bash
./gradlew assembleDebug ; adb install app/build/outputs/apk/debug/app-debug.apk
./gradlew bundleRelease        # AAB -> Play Store
StrictMode.enableDefaults()    # debug: policy violations; Profiler & Layout Inspector in Studio
```

## Workflow

### 1. Create / Open Project
- New: Android Studio -> New Project (Empty Activity, Compose template); Existing: File -> Open

### 2. Build & Run
```bash
./gradlew assembleDebug
./gradlew installDebug
adb shell am start -n com.example.myapp/.MainActivity
```

### 3. Iterate with Debugging
1. Edit Kotlin/Compose; build + install (or Studio Run)
2. Watch logcat (`adb logcat *:E`); use Profiler (CPU/memory) + Layout Inspector
3. Fix and re-run

### 4. Release
1. Bump versionCode/versionName
2. Configure signing (keystore.properties + signingConfig)
3. `./gradlew lint && ./gradlew bundleRelease`
4. Upload AAB to Play Console

## Tools
```bash
adb devices ; ./gradlew tasks ; ./gradlew :app:dependencies
sdkmanager --list              # SDK components
avdmanager list avd
```
Android Studio panes: SDK Manager, Build Variants, Gradle, Profiler, Device File Explorer.

### MCP Requirements
**Android Studio 2025.2+ has MCP BUILT-IN**: `Settings > Tools > MCP Server`. Docs: https://www.jetbrains.com/help/idea/mcp-server.html. Standalone `@jetbrains/mcp-proxy` is **DEPRECATED** — do NOT configure it. Community third-party servers (e.g. muxi1998/android-studio-mcp-server) are NOT official.

## Best Practices
1. **Kotlin + Compose** for new apps; View system for legacy
2. **StrictMode** in debug builds to catch leaks/policy violations
3. **`./gradlew lint`** before release
4. **Never hardcode secrets** — keystore.properties (gitignored) or BuildConfig
5. **No main-thread I/O**: coroutines + lifecycleScope/WorkManager
6. **Version catalog** (`gradle/libs.versions.toml`) for dependencies
7. **Enable R8/ProGuard** for release; **ViewModel** for state hoisting
8. **Monitor crash reports** (Play Console / Crashlytics) routinely

## Anti-patterns
- ❌ Network/DB on the main thread (ANR)
- ❌ Hardcoding API keys/secrets in source or manifest
- ❌ Ignoring ProGuard rules -> release-only crashes
- ❌ Leaks: Activity/Context in static fields or singletons
- ❌ Skipping lint/test before release
- ❌ Deprecated `@jetbrains/mcp-proxy` instead of built-in MCP
- ❌ Committing `local.properties`, keystores, or secrets files

## Verification

### Unit Verification
```bash
./gradlew assembleDebug       # Expected: BUILD SUCCESSFUL
./gradlew lint && ./gradlew test    # Expected: 0 errors, all pass
adb devices                   # Expected: device/emulator listed
```

### Integration Checks
```bash
adb shell am start -n com.example.myapp/.MainActivity   # app launches
adb logcat *:E -d                                       # no unexpected exceptions
```

## Examples

### Launch & Debug a Build
```bash
./gradlew assembleDebug && adb install app/build/outputs/apk/debug/app-debug.apk
adb logcat -c ; adb shell am start -n com.example.myapp/.MainActivity
adb logcat -d *:E
```

### Compose Screen with ViewModel
```kotlin
class CounterViewModel : ViewModel() {
    private val _count = MutableStateFlow(0)
    val count: StateFlow<Int> = _count.asStateFlow()
    fun increment() { _count.value++ }
}
@Composable
fun CounterScreen(vm: CounterViewModel = viewModel()) {
    val count by vm.count.collectAsState()
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text("Count: $count"); Button(onClick = vm::increment) { Text("Increment") }
    }
}
```

### Release Signing
```kotlin
// keystore.properties (gitignored): storeFile / storePassword / keyAlias / keyPassword
val props = Properties().apply { rootProject.file("keystore.properties").takeIf { it.exists() }?.inputStream()?.use { load(it) } }
signingConfigs { create("release") { if (props.isNotEmpty()) {
    storeFile = file(props["storeFile"] as String)
    storePassword = props["storePassword"] as String
    keyAlias = props["keyAlias"] as String
    keyPassword = props["keyPassword"] as String } } }
buildTypes { release { signingConfig = signingConfigs.getByName("release") } }
```