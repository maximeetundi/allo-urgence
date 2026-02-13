import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/queue_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/nurse_provider.dart';
import 'providers/doctor_provider.dart';
import 'services/nurse_service.dart';
import 'services/doctor_service.dart';
import 'screens/splash_screen.dart';

import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enforce portrait mode and transparent system UI
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // For light background
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const AlloUrgenceApp());
}

class AlloUrgenceApp extends StatelessWidget {
  const AlloUrgenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => QueueProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        // Nurse provider — re-created when auth token changes
        ChangeNotifierProxyProvider<AuthProvider, NurseProvider>(
          create: (_) => NurseProvider(NurseService(
            baseUrl: AppConstants.apiBaseUrl,
            token: '',
          )),
          update: (_, auth, previous) => NurseProvider(NurseService(
            baseUrl: AppConstants.apiBaseUrl,
            token: auth.token ?? '',
          )),
        ),
        // Doctor provider — re-created when auth token changes
        ChangeNotifierProxyProvider<AuthProvider, DoctorProvider>(
          create: (_) => DoctorProvider(DoctorService(
            baseUrl: AppConstants.apiBaseUrl,
            token: '',
          )),
          update: (_, auth, previous) => DoctorProvider(DoctorService(
            baseUrl: AppConstants.apiBaseUrl,
            token: auth.token ?? '',
          )),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Allo Urgence',
            debugShowCheckedModeBanner: false,
            theme: AlloUrgenceTheme.lightTheme,
            darkTheme: AlloUrgenceTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
