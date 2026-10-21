import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'menu_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(
                  1.3), // 1.0 = ปกติ, 1.3 = ใหญ่ขึ้น 30%
            ),
            child: child!,
          );
        },
      ),
    ),
  );
}

// จัดการสถานะ (State) ของแอปพลิเคชัน
class AppProvider extends ChangeNotifier {
  String selectedTable = '01';
  final List<Map<String, dynamic>> cart = [];

  void setTable(String table) {
    selectedTable = table;
    cart.clear(); // เปลี่ยนโต๊ะแล้วล้างตะกร้า
    notifyListeners();
  }

  void addToCart(String name, int price, String option) {
    cart.add({
      'name': name,
      'price': price,
      'option': option,
      'qty': 1,
    });
    notifyListeners();
  }

  void updateQty(int index, int change) {
    cart[index]['qty'] += change;
    if (cart[index]['qty'] <= 0) {
      cart.removeAt(index);
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  int get totalPrice {
    int total = 0;
    for (var item in cart) {
      total += (item['price'] as int) * (item['qty'] as int);
    }
    return total;
  }
}

// หน้าเลือกโต๊ะ
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ร้านก๋วยเตี๋ยวเรือชามกะลา'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.ramen_dining,
                  size: 80, color: Colors.deepOrange),
              const SizedBox(height: 20),
              const Text(
                'เลือกหมายเลขโต๊ะ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Dropdown เลือกโต๊ะ
              DropdownButton<String>(
                value: provider.selectedTable,
                items: List.generate(20, (i) {
                  String num = (i + 1).toString().padLeft(2, '0');
                  return DropdownMenuItem(value: num, child: Text('โต๊ะ $num'));
                }),
                onChanged: (val) {
                  if (val != null) provider.setTable(val);
                },
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MenuScreen()),
                  );
                },
                child: const Text(
                  'เข้าสู่หน้าสั่งอาหาร',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
