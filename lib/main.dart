// lib/main.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odfinance/features/history/presentation/screens/history_dashboard.dart';
import 'package:odfinance/features/scanner/presentation/screens/live_scanner_screen.dart';

// Global variable to hold the list of available hardware cameras
List<CameraDescription> cameras = [];

Future<void> main() async {
  // Ensure that plugin services are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Query the operating system for available physical cameras
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Failed to locate device hardware cameras: $e");
  }

  runApp(
    // ProviderScope houses all your Riverpod state providers
    const ProviderScope(child: VoucherScannerApp()),
  );
}

class VoucherScannerApp extends StatelessWidget {
  const VoucherScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محفظة الكروت', // Localized app name
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      // The application starts directly on our History Dashboard home screen
      initialRoute: '/',
      routes: {
        '/': (context) => const HistoryDashboardScreen(),
        '/scanner': (context) => LiveScannerScreen(cameras: cameras),
      },
    );
  }
}
