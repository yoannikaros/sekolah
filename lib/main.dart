import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/event_provider.dart';
import 'providers/post_provider.dart';
import 'config/routes.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: 'Seangkatan.id',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: AppRoutes.router,
          );
        },
      ),
    );
  }
}
