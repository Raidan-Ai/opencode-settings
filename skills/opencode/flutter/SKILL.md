---
name: flutter
description: Flutter/Dart cross-platform development including Flutter CLI (create, run, build), Dart language basics, widget tree, state management (Provider/Riverpod/Bloc), Material/Cupertino, hot reload, platforms (Android/iOS/Web/Desktop), pub.dev packages, testing (widget/unit/integration), performance (DevTools), and release builds. Activate for any Flutter or Dart mobile/app development task.
---

# Flutter/Dart Development Skill

## Purpose
Provides comprehensive Flutter and Dart development capabilities: project scaffolding, widget building, state management (Provider/Riverpod/Bloc), Material/Cupertino design, cross-platform builds (Android/iOS/Web/Desktop), pub.dev packages, testing, performance profiling with DevTools, and release build signing.

## When to Activate
- Creating a new Flutter project
- Writing Dart code or Flutter widgets
- Choosing/implementing state management (Provider, Riverpod, Bloc)
- Building Material or Cupertino UIs
- Running on Android, iOS, Web, or Desktop targets

## Core Knowledge

### Flutter CLI
```bash
flutter create --org com.example --platforms=android,ios,web my_app
flutter run -d emulator-5554          # or -d chrome / -d linux
flutter analyze ; dart format . ; flutter pub get
flutter devices ; flutter doctor -v ; flutter pub outdated
```

### Dart Basics
```dart
final name = 'Flutter';                // runtime-immutable
String? maybe;                         // null safety
Future<void> fetch() async { await httpGet(); }
final mapped = ['a','b'].map((n) => n.toUpperCase()).toList();
```

### Widgets
```dart
void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.blue),
    home: const CounterScreen(),
  );
}
// Stateful: State<T> + setState(() {}) for local UI state
// Layout: Column, Row, Stack, Expanded, Padding, ListView.builder
// Navigate: Navigator.push(context, MaterialPageRoute(builder: (_) => const Page()));
```

### State Management
**Provider** (simple): `ChangeNotifier` + `notifyListeners()`; provide via `ChangeNotifierProvider`, consume via `context.watch<T>()` / `context.read<T>()`.
**Riverpod** (compile-safe, testable): `StateNotifierProvider<CounterNotifier, int>` + `ref.watch(p)`.
**Bloc** (predictable): `CounterCubit extends Cubit<int>` + `emit(state + 1)` + `BlocBuilder`.

### Cross-Platform Builds
```bash
flutter build appbundle --release      # Android Play (AAB)
flutter build apk --release            # Android direct
flutter build ios --release            # iOS (macOS only)
flutter build web / linux / windows    # web/desktop
```

### pub.dev
```yaml
# pubspec.yaml
dependencies:
  flutter: { sdk: flutter }
  provider: ^6.1.2
  http: ^1.2.2
dev_dependencies:
  flutter_test: { sdk: flutter }
  flutter_lints: ^4.0.0
```
```bash
flutter pub add http provider
flutter pub add --dev flutter_lints
```

### Testing
```dart
test('add adds numbers', () { expect(add(2, 3), 5); });
testWidgets('counter increments', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump();
  expect(find.text('1'), findsOneWidget);
});
```
```bash
flutter test                       # all unit/widget tests
flutter test integration_test -d emulator-5554
```

### Performance & Release
```bash
flutter run --profile               # DevTools: rebuild storms, jank
# Signing keystore: keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -alias upload
```

## Workflow

### 1. Scaffold a Project
```bash
flutter create --org com.example --platforms=android,ios,web my_app
cd my_app && flutter pub add provider http intl
```

### 2. Build a Feature
1. Define model + state (Provider/ChangeNotifier)
2. Build widgets, split into `screens/`, `widgets/`, `models/`, `services/`
3. Wire navigation; write widget test; `flutter test`
4. Run on device, hot reload (`r`) / hot restart (`R`), iterate

### 3. Quality Gate & Release
```bash
flutter analyze && dart format . && flutter test
flutter build appbundle --release
```

## Tools
```bash
flutter doctor -v          # env check
flutter devices / emulators   # connected devices & simulators
flutter analyze            # static analysis
dart format .              # formatting
```

### MCP Requirements
**No official MCP server exists** for Flutter/Dart. Community options (e.g. `flutter-mcp` npm wrapper) are NOT official — verify security and maintenance before use; do not add to config.

## Best Practices
1. **State management first**: Provider (simple) / Riverpod (robust) / Bloc (predictable)
2. **Keep widgets small**: split into focused, reusable widgets
3. **const constructors** to avoid unnecessary rebuilds
4. **Lazy lists**: `ListView.builder` / `GridView.builder`
5. **Test as you go**: unit + widget tests in `test/`
6. **Follow lints**: `flutter_lints`; run `dart format`
7. **Prefer `final`**; use null safety
8. **Isolate I/O** behind services (no inline `http` in widgets)

## Anti-patterns
- ❌ All logic in `build()` / giant stateful widgets
- ❌ `setState` for app-wide state
- ❌ Ignoring `const` (rebuild waste)
- ❌ `ListView` without `.builder` for long data
- ❌ Importing `dart:html` (breaks non-web platforms)
- ❌ Hardcoding strings/colors (use l10n and ThemeData)
- ❌ Synchronous `http` blocking the UI
- ❌ Committing signing keys / skipping `flutter test`

## Verification

### Unit Verification
```bash
flutter analyze                          # Expected: No issues found!
dart format --set-exit-if-changed .      # Expected: no files need formatting
flutter test                             # Expected: All tests passed!
flutter build apk --debug                # Expected: built successfully
```

### Integration Checks
```bash
flutter run -d <device>    # app launches; hot reload works; no console exceptions
```

## Examples

### Counter with Provider
```dart
class CounterModel extends ChangeNotifier {
  int _count = 0; int get count => _count;
  void increment() { _count++; notifyListeners(); }
}
void main() => runApp(ChangeNotifierProvider(
  create: (_) => CounterModel(), child: const MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(home: Scaffold(body: Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Consumer<CounterModel>(builder: (_, c, __) => Text('${c.count}')),
      ElevatedButton(onPressed: () => context.read<CounterModel>().increment(),
        child: const Text('Increment')),
    ]))));
}
```

### HTTP Fetch
```dart
Future<String> fetchGreeting() async {
  final res = await http.get(Uri.parse('https://api.example.com/greet'));
  return res.body;
}
// In build: FutureBuilder<String>(future: _greeting,
//   builder: (c, s) => s.connectionState == ConnectionState.waiting
//     ? const CircularProgressIndicator() : Text(s.data ?? 'Error'))
```