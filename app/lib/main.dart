import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CareerServicesPortalApp());
}

class CareerServicesPortalApp extends StatefulWidget {
  const CareerServicesPortalApp({super.key});

  @override
  State<CareerServicesPortalApp> createState() =>
      _CareerServicesPortalAppState();
}

class _CareerServicesPortalAppState extends State<CareerServicesPortalApp> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _appState,
      child: MaterialApp(
        title: 'Career Services Portal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
