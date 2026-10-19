import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'main.dart';
import 'tracking_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cart = provider.currentCart;

    return Scaffold(
      appBar: AppBar(
        title: Text('สั่งอาหาร — โต๊ะ ${provider.selectedTable}'),
        actions: [
          //ปุ่มกดไปดูหน้าติดตาม
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'ติดตามออเดอร์',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrackingScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: ListTile(
              title: const Text(
                'ก๋วยเตี๋ยวเรือชามกะลา',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text('ราคาเริ่มต้น 50 บาท (ปรับออปชันได้)'),
              trailing: ElevatedButton(
                onPressed: () => _showNoodleCustomizer(context),
                child: const Text('สั่ง/ปรับแต่ง'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Text(
            'ตะกร้าของโต๊ะ ${provider.selectedTable} (${cart.length} รายการ):',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('ยังไม่มีรายการอาหารในตะกร้า')),
            )
          else
            //รายการอาหาร
            ...cart.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final itemTotal = (item['price'] as int) * (item['qty'] as int);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(item['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${item['option']}\nราคา: $itemTotal ฿'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //ปุ่มลดจำนวน
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.orange),
                        onPressed: () => provider.updateQty(index, -1),
                      ),
                      Text('${item['qty']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      //ปุ่มเพิ่มจำนวน
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.green),
                        onPressed: () => provider.updateQty(index, 1),
                      ),
                      //ปุ่มลบรายการทิ้ง
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => provider.removeItem(index),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: cart.isEmpty
              ? null
              : () async {
                  final details = cart
                      .map((i) => "${i['name']} [${i['option']}] x${i['qty']}")
                      .join(' ; ');

                  final ok = await ApiService.sendOrder(
                    provider.selectedTable,
                    details,
                    provider.totalPrice,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? '✅ ส่งออเดอร์เข้าครัวเรียบร้อย!'
                            : '❌ ส่งไม่สำเร็จ'),
                      ),
                    );
                    if (ok) {
                      provider.clearCurrentCart();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TrackingScreen()),
                      );
                    }
                  }
                },
          child: Text(
            'ส่งออเดอร์เข้าครัว โต๊ะ ${provider.selectedTable} (${provider.totalPrice} บาท)',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  void _showNoodleCustomizer(BuildContext context) {
    String size = 'ธรรมดา (50฿)';
    String noodle = 'เส้นเล็ก';
    String soup = 'น้ำตกเข้มข้น';
    String spice = 'เผ็ดน้อย';
    String topping = 'ไม่รับท็อปปิ้ง';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          int price = 50;
          if (size.contains('พิเศษ')) price += 15;
          if (topping != 'ไม่รับท็อปปิ้ง') price += 15;

          return AlertDialog(
            title: const Text('ปรับแต่งก๋วยเตี๋ยวเรือ'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: size,
                    decoration: const InputDecoration(labelText: 'ขนาดชาม'),
                    items: ['ธรรมดา (50฿)', 'พิเศษกะลายักษ์ (+15฿)']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => size = v!),
                  ),
                  DropdownButtonFormField<String>(
                    value: noodle,
                    decoration: const InputDecoration(labelText: 'เลือกเส้น'),
                    items: [
                      'เส้นเล็ก',
                      'เส้นใหญ่',
                      'หมี่ขาว',
                      'บะหมี่',
                      'วุ้นเส้น',
                      'เกาเหลา'
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => noodle = v!),
                  ),
                  DropdownButtonFormField<String>(
                    value: soup,
                    decoration:
                        const InputDecoration(labelText: 'ประเภทน้ำซุป'),
                    items: ['น้ำตกเข้มข้น', 'ต้มยำพริกสด', 'น้ำใส', 'แห้ง']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => soup = v!),
                  ),
                  DropdownButtonFormField<String>(
                    value: spice,
                    decoration:
                        const InputDecoration(labelText: 'ระดับความเผ็ด'),
                    items: [
                      'ไม่เผ็ด',
                      'เผ็ดน้อย',
                      'เผ็ดปกติ (สูตรเด็ด)',
                      'เผ็ดพ่นไฟ'
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => spice = v!),
                  ),
                  DropdownButtonFormField<String>(
                    value: topping,
                    decoration: const InputDecoration(
                        labelText: 'ท็อปปิ้งเสริม (+15฿)'),
                    items: [
                      'ไม่รับท็อปปิ้ง',
                      'แคปหมูไร้มัน',
                      'เกี๊ยวกรอบ',
                      'กากหมูเจียว'
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => topping = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white),
                onPressed: () {
                  final optionText = '$size, $noodle, $soup, $spice' +
                      (topping != 'ไม่รับท็อปปิ้ง' ? ' + $topping' : '');

                  context.read<AppProvider>().addToCart(
                        'ก๋วยเตี๋ยวเรือชามกะลา',
                        price,
                        optionText,
                      );
                  Navigator.pop(ctx);
                },
                child: Text('เพิ่มลงตะกร้า ($price ฿)'),
              ),
            ],
          );
        },
      ),
    );
  }
}
