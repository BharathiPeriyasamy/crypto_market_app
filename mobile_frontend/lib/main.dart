import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/crypto_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/crypto_api_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CryptoProvider(CryptoApiService())..startLiveUpdates(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Indiadits Crypto',
      theme: appTheme,
      home: const SplashScreen(),
    );
  }
}
