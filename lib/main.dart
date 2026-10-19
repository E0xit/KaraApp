import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'menu_screen.dart';

void main() => runApp(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MaterialApp(
          home: HomeScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );

class AppProvider extends ChangeNotifier {
  String selectedTable = '01';

  final Map<String, List<Map<String, dynamic>>> ordersByTable = {};

  void setTable(String table) {
    selectedTable = table;
    notifyListeners();
  }

  List<Map<String, dynamic>> get currentCart =>
      ordersByTable[selectedTable] ?? [];

  void addToCart(String name, int price, String option) {
    ordersByTable.putIfAbsent(selectedTable, () => []);

    final index = ordersByTable[selectedTable]!.indexWhere(
      (item) => item['name'] == name && item['option'] == option,
    );

    if (index >= 0) {
      ordersByTable[selectedTable]![index]['qty'] += 1;
    } else {
      ordersByTable[selectedTable]!.add({
        'name': name,
        'price': price,
        'option': option,
        'qty': 1,
      });
    }
    notifyListeners();
  }

  void updateQty(int index, int delta) {
    final cart = currentCart;
    if (index >= 0 && index < cart.length) {
      cart[index]['qty'] += delta;
      if (cart[index]['qty'] <= 0) {
        cart.removeAt(index); // ถ้าลดเหลือ 0 ให้ลบทิ้ง
      }
      notifyListeners();
    }
  }

  void removeItem(int index) {
    final cart = currentCart;
    if (index >= 0 && index < cart.length) {
      cart.removeAt(index);
      notifyListeners();
    }
  }

  void clearCurrentCart() {
    ordersByTable[selectedTable]?.clear();
    notifyListeners();
  }

  int get totalPrice => currentCart.fold(
        0,
        (sum, item) => sum + ((item['price'] as int) * (item['qty'] as int)),
      );
}

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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.ramen_dining, size: 80, color: Colors.deepOrange),
            const SizedBox(height: 16),
            const Text(
              'กรุณาเลือกหมายเลขโต๊ะ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: provider.selectedTable,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.table_restaurant),
                labelText: 'เลือกโต๊ะ',
              ),
              items: List.generate(20, (index) {
                final tableNo = (index + 1).toString().padLeft(2, '0');
                return DropdownMenuItem(
                  value: tableNo,
                  child: Text('โต๊ะ $tableNo'),
                );
              }),
              onChanged: (val) {
                if (val != null) provider.setTable(val);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('เข้าสู่หน้าสั่งอาหาร',
                  style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MenuScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
