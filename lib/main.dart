import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'features/diary/presentation/home_screen.dart';
import 'features/scan/presentation/scan_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/nav_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox('sessionBox');
  await Hive.openBox('diaryBox');
  
  runApp(
    const ProviderScope(
      child: NutritionAiApp(),
    ),
  );
}

class NutritionAiApp extends ConsumerWidget {
  const NutritionAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cal AI Nutrition Tracker',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: Colors.black87),
        ),

      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

      ),
      home: userId == null ? const WelcomeScreen() : const _MainShell(),
    );
  }
}

class _MainShell extends ConsumerWidget {
  const _MainShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainShellTabProvider);
    
    final pages = [
      HomeScreen(
        onAddMeal: () => ref.read(mainShellTabProvider.notifier).state = 1,
      ),
      const ScanScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(mainShellTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}