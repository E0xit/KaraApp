import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'payment_screen.dart';
import 'tracking_screen.dart';

const meats = [
  'รวมหมู',
  'หมูหมัก',
  'ตับหวาน',
  'กระดูกอ่อน',
  'ไส้หวาน',
  'ตีนไก่ตุ๋น',
  'หมูตุ๋น',
  'ซุปเปอร์ (รวมทุกอย่าง)',
];
const noodles = ['เส้นเล็ก', 'เส้นหมี่', 'วุ้นเส้น', 'บะหมี่', 'ไวไว'];
const soups = ['น้ำตก', 'แห้ง'];
const specialMenus = ['ตีนไก่ลอยน้ำ', 'เกาเหลา', 'หม้อไฟ'];
const extras = {'น้ำอัดลม': 15, 'ข้าวเปล่า': 10, 'แคปหมู': 15};

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
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ก๋วยเตี๋ยวเรือชามกะลา',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('ราคาเริ่มต้น 45 บาท'),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          _openNoodleDialog(context, 'ก๋วยเตี๋ยวเรือ'),
                      child: const Text('สั่งอาหาร'),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ลวกจิ้ม',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('ราคาเริ่มต้น 70 บาท'),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _openNoodleDialog(context, 'ลวกจิ้ม'),
                      child: const Text('สั่งอาหาร'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('เมนูพิเศษ (189 บาท)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          for (final name in specialMenus)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name),
                TextButton(
                  onPressed: () => _add(context, 'เมนูพิเศษ: $name', 189, '-'),
                  child: const Text('เพิ่ม'),
                ),
              ],
            ),
          const SizedBox(height: 16),
          const Text('เครื่องเคียง',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          for (final e in extras.entries)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${e.key} (${e.value} บาท)'),
                TextButton(
                  onPressed: () => _add(context, e.key, e.value, '-'),
                  child: const Text('เพิ่ม'),
                ),
              ],
            ),
          const Text('ข้าวเกรียบ / ผักสด ฟรี!!',
              style: TextStyle(color: Colors.green)),
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

  void _add(BuildContext context, String name, int price, String option) {
    context.read<AppProvider>().addToCart(name, price, option);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เพิ่ม $name แล้ว'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openNoodleDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (_) => NoodleDialog(type: type),
    );
  }
}

class NoodleDialog extends StatefulWidget {
  final String type;
  const NoodleDialog({super.key, required this.type});

  @override
  State<NoodleDialog> createState() => _NoodleDialogState();
}

class _NoodleDialogState extends State<NoodleDialog> {
  String meat = meats[0];
  String size = 'ธรรมดา';
  String noodle = noodles[0];
  String soup = soups[0];

  bool get isBoat => widget.type == 'ก๋วยเตี๋ยวเรือ';

  int get price {
    final isSpecial = size == 'พิเศษ';
    final isSuper = meat.startsWith('ซุปเปอร์');
    if (isBoat) {
      if (isSuper) return isSpecial ? 55 : 50;
      return isSpecial ? 50 : 45;
    }
    return isSpecial ? 80 : 70;
  }

  Widget dropdown(List<String> items, String value, Function(String) onPick) {
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => setState(() => onPick(v!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.type),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            dropdown(meats, meat, (v) => meat = v),
            dropdown(['ธรรมดา', 'พิเศษ'], size, (v) => size = v),
            dropdown(noodles, noodle, (v) => noodle = v),
            if (isBoat) dropdown(soups, soup, (v) => soup = v),
            const SizedBox(height: 10),
            Text('ราคา $price บาท',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            final option =
                isBoat ? '$size / $noodle / $soup' : '$size / $noodle';
            context
                .read<AppProvider>()
                .addToCart('${widget.type} $meat', price, option);
            Navigator.pop(context);
          },
          child: const Text('ตกลง'),
        ),
      ],
    );
  }
}
