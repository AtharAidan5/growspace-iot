import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'theme.dart';

void main() {
  runApp(const IoeDashboardApp());
}

class IoeDashboardApp extends StatelessWidget {
  const IoeDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowSpace',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const DashboardScreen(),
    );
  }
}
