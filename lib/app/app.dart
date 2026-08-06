import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

class CoachApp extends StatelessWidget {
  const CoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coach App Mobile',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,

      darkTheme: AppTheme.dark,

      themeMode: ThemeMode.system,

      home: const Scaffold(
        body: Center(
          child: Text('Coach App Mobile'),
        ),
      ),
    );
  }
}