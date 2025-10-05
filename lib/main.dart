import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_cutter/views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    themeProvider.getThemeMode();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieSlicer',
      theme: ThemeData.light().copyWith(
        primaryColor: const Color(0xFF3F51B5),
        colorScheme: ColorScheme.light(primary: const Color(0xFF3F51B5)),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: const Color(0xFF3F51B5)),
      ),
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void getThemeMode() async {
    final shared = await SharedPreferences.getInstance();
    bool updatedDark = await shared.getBool("isDart") ?? false;
    _themeMode = updatedDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme(bool isDark) async {
    final shared = await SharedPreferences.getInstance();
    bool updatedDark = await shared.setBool("isDart", isDark);
    _themeMode = updatedDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
