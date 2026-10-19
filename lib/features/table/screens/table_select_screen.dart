import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_config.dart';
import '../../../providers/app_state.dart';
import '../../menu/screens/menu_screen.dart';

class TableSelectScreen extends StatelessWidget {
  const TableSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🍜 เลือกโต๊ะของคุณ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'แตะเลขโต๊ะที่นั่งอยู่ได้เลย',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: Config.tableCount,
                itemBuilder: (_, i) {
                  final n = (i + 1).toString().padLeft(2, '0');
                  return FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      context.read<AppState>().selectTable(n);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MenuScreen()),
                      );
                    },
                    child: Text(
                      n,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}