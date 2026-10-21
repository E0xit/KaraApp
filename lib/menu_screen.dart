import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'payment_screen.dart';
import 'tracking_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cart = provider.cart;

    return Scaffold(
      appBar: AppBar(
        title: Text('โต๊ะ ${provider.selectedTable}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrackingScreen()),
              );
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ก๋วยเตี๋ยวเรือชามกะลา',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('ราคาเริ่มต้น 50 บาท'),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _openOptionDialog(context),
                  child: const Text('สั่งอาหาร'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('รายการในตะกร้า:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          if (cart.isEmpty)
            const Center(child: Text('\nยังไม่มีรายการในตะกร้า'))
          else
            for (int i = 0; i < cart.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cart[i]['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(cart[i]['option'],
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          Text(
                              'ราคารวม: ${cart[i]['price'] * cart[i]['qty']} บาท'),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => provider.updateQty(i, -1),
                    ),
                    Text('${cart[i]['qty']}'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => provider.updateQty(i, 1),
                    ),
                  ],
                ),
              ),
        ],
      ),

      // ปุ่มกดไปหน้าชำระเงิน
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            padding: const EdgeInsets.all(16),
          ),
          onPressed: cart.isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentScreen()),
                  );
                },
          child: Text(
            'ไปที่หน้าชำระเงิน (${provider.totalPrice} บาท)',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _openOptionDialog(BuildContext context) {
    String noodle = 'เส้นเล็ก';
    String soup = 'น้ำตกเข้มข้น';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('เลือกรายละเอียด'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: noodle,
                  isExpanded: true,
                  items: ['เส้นเล็ก', 'เส้นใหญ่', 'หมี่ขาว', 'บะหมี่']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => noodle = v!),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: soup,
                  isExpanded: true,
                  items: ['น้ำตกเข้มข้น', 'ต้มยำ', 'น้ำใส', 'แห้ง']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => soup = v!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<AppProvider>().addToCart(
                        'ก๋วยเตี๋ยวเรือ',
                        50,
                        '$noodle / $soup',
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('ตกลง'),
              ),
            ],
          );
        },
      ),
    );
  }
}
