import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../status/screens/status_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _sending = false;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    setState(() => _sending = true);
    final ok = await context.read<AppState>().submit();
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StatusScreen()),
      );
    } else {
      _snack('ส่งออเดอร์ไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text('ตะกร้า — โต๊ะ ${state.tableNo}')),
      body: state.cart.isEmpty
          ? const Center(child: Text('ตะกร้ายังว่างอยู่'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final c in state.cart)
                  Card(
                    child: ListTile(
                      title: Text(c.item.name),
                      subtitle: Text(
                        [
                          if (c.item.customizable)
                            '${c.size} | ${c.noodle} | ${c.soup} | ${c.spice}',
                          if (c.extras.isNotEmpty) '+ ${c.extras.join(', ')}',
                          '${c.total} บาท',
                        ].join('\n'),
                      ),
                      isThreeLine: c.item.customizable,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => state.changeQty(c, -1),
                          ),
                          Text('${c.qty}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => state.changeQty(c, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'โน้ตพิเศษ (เช่น ไม่ใส่ถั่วงอก)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => state.note = v,
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: state.cart.isEmpty || _sending ? null : _submit,
            child: _sending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('สั่งอาหารเลย! — ${state.cartTotal} บาท'),
          ),
        ),
      ),
    );
  }
}