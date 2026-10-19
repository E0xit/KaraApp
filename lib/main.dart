import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/table/screens/table_select_screen.dart';
import 'providers/app_state.dart';

void main() => runApp(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const NoodleApp(),
      ),
    );

class NoodleApp extends StatelessWidget {
  const NoodleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ก๋วยเตี๋ยวเรือชามกะลา',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const TableSelectScreen(),
    );
  }
}