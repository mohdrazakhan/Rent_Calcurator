import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/theme/app_theme.dart';
import 'src/providers/bill_provider.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/history_screen.dart';
import 'src/screens/settings_screen.dart';
import 'src/screens/result_screen.dart';

void main() {
  runApp(const RentApp());
}

class RentApp extends StatelessWidget {
  const RentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BillProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Room Rent Calculator",
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
        routes: {
          HistoryScreen.routeName: (_) => const HistoryScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
          ResultScreen.routeName: (_) => const ResultScreen(),
        },
      ),
    );
  }
}
