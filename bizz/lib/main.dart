import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/constants.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow self-signed / untrusted certs in debug when using HTTPS to an IP (e.g. https://10.x.x.x)
  if (kDebugMode && AppConstants.baseUrl.startsWith('https://') && _isIpHost(AppConstants.baseUrl)) {
    HttpOverrides.global = _DevHttpOverrides();
  }

  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'HRMS',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme.copyWith(
            textTheme: themeProvider.lightTheme.textTheme.apply(fontFamily: 'Inter'),
          ),
          darkTheme: themeProvider.darkTheme.copyWith(
            textTheme: themeProvider.darkTheme.textTheme.apply(fontFamily: 'Inter'),
          ),
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

/// True if [url] is an HTTPS URL whose host is an IP address (e.g. https://10.179.221.36:9001/api).
bool _isIpHost(String url) {
  try {
    final uri = Uri.parse(url);
    final host = uri.host;
    if (host.isEmpty) return false;
    return RegExp(r'^[\d.]+$').hasMatch(host) || host.contains(':');
  } catch (_) {
    return false;
  }
}

/// In debug, allow TLS handshake with servers using self-signed or hostname-mismatch certs.
class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
