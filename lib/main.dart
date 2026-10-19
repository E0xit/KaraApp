import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ============================================================
// ⚙️ CONFIG — แก้ค่าตรงนี้ก่อนใช้งานจริง
// ============================================================
class Config {
  /// URL ของ Google Apps Script Web App (ลงท้ายด้วย /exec)
  static const String scriptUrl =
      'https://script.google.com/macros/s/AKfycbzX1Q2IpmjJmOHlRlKrPXHd88jti34nlCHT1rjwQ3f9hhu7CGQ_A6stI7BXLPew7gnn/exec';

  /// เบอร์ PromptPay ของร้าน (10 หลัก เช่น 0812345678)
  static const String promptPayPhone = '0812345678';

  /// จำนวนโต๊ะในร้าน
  static const int tableCount = 20;

  /// ราคา (ตัวเลขสมมุติ — ปรับตามเมนูจริงของร้าน)
  static const int specialSizeExtra = 20;
  static const int toppingPrice = 10;
}

// ============================================================
// 📦 MODELS
// ============================================================
class MenuItem {
  final String id;
  final String name;
  final String category;
  final int price;
  final bool customizable;
  const MenuItem(
    this.id,
    this.name,
    this.category,
    this.price, {
    this.customizable = false,
  });
}

const menuItems = <MenuItem>[
  MenuItem('n1', 'ก๋วยเตี๋ยวเรือชามกะลา', 'ก๋วยเตี๋ยว', 50, customizable: true),
  MenuItem('s1', 'แคปหมูไร้มัน', 'ของทานเล่น', 20),
  MenuItem('s2', 'เกี๊ยวกรอบ', 'ของทานเล่น', 25),
  MenuItem('s3', 'กากหมูเจียว', 'ของทานเล่น', 25),
  MenuItem('d1', 'น้ำเปล่า', 'เครื่องดื่ม', 10),
  MenuItem('d2', 'น้ำเก๊กฮวย', 'เครื่องดื่ม', 20),
  MenuItem('d3', 'ชาเย็น', 'เครื่องดื่ม', 25),
];

const categories = ['ก๋วยเตี๋ยว', 'ของทานเล่น', 'เครื่องดื่ม'];
const sizes = ['ธรรมดา', 'พิเศษกะลายักษ์'];
const noodles = ['เส้นเล็ก', 'เส้นใหญ่', 'หมี่ขาว', 'บะหมี่', 'วุ้นเส้น'];
const soups = ['น้ำตกเข้มข้น', 'ต้มยำ', 'น้ำใส', 'แห้ง'];
const spicy = ['ไม่เผ็ด', 'เผ็ดน้อย', 'ปกติ', 'เผ็ดพ่นไฟ 🌶️'];
const toppings = ['แคปหมูไร้มัน', 'เกี๊ยวกรอบ', 'กากหมูเจียว'];

class CartItem {
  final MenuItem item;
  String size;
  String noodle;
  String soup;
  String spice;
  List<String> extras;
  int qty;

  CartItem(
    this.item, {
    this.size = '',
    this.noodle = '',
    this.soup = '',
    this.spice = '',
    this.extras = const [],
    this.qty = 1,
  });

  int get unitPrice {
    var p = item.price;
    if (size == 'พิเศษกะลายักษ์') p += Config.specialSizeExtra;
    p += extras.length * Config.toppingPrice;
    return p;
  }

  int get total => unitPrice * qty;

  String get detail {
    if (!item.customizable) return '${item.name} (x$qty)';
    final ex = extras.isEmpty ? '' : ' + ${extras.join(', ')}';
    return '${item.name} | $size | $noodle | $soup | $spice$ex (x$qty)';
  }
}

class PlacedOrder {
  final String orderId;
  final String details;
  final int total;
  final String status;
  PlacedOrder(this.orderId, this.details, this.total, this.status);

  factory PlacedOrder.fromJson(Map<String, dynamic> j) => PlacedOrder(
        '${j['order_id']}',
        '${j['item_details']}',
        int.tryParse('${j['total_price']}') ?? 0,
        '${j['status']}',
      );
}

// ============================================================
// 🌐 API (Google Apps Script)
// ============================================================
class Api {
  static Future<bool> _post(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse(Config.scriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonEncode(body),
      );
      // Apps Script ตอบ 302 redirect หลังรันเสร็จ ถือว่าสำเร็จ
      return res.statusCode == 200 || res.statusCode == 302;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> createOrder(String table, String details, int total) =>
      _post({
        'action': 'create_order',
        'table_no': table,
        'item_details': details,
        'total_price': total,
      });

  static Future<bool> pay(String table, int total, String method) => _post({
        'action': 'pay',
        'table_no': table,
        'total_amount': total,
        'payment_method': method,
      });

  static Future<List<PlacedOrder>?> fetchOrders(String table) async {
    try {
      final uri = Uri.parse(
        Config.scriptUrl,
      ).replace(queryParameters: {'action': 'orders', 'table_no': table});
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => PlacedOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}

// ============================================================
// 💳 PromptPay payload (EMVCo + CRC16)
// ============================================================
String _tlv(String tag, String value) =>
    '$tag${value.length.toString().padLeft(2, '0')}$value';

int _crc16(String s) {
  var crc = 0xFFFF;
  for (final unit in s.codeUnits) {
    crc ^= unit << 8;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) : (crc << 1);
      crc &= 0xFFFF;
    }
  }
  return crc;
}

String buildPromptPayPayload(String phone, double amount) {
  final target = '0066${phone.substring(1)}'; // 0812345678 -> 0066812345678
  final merchant = _tlv(
    '29',
    _tlv('00', 'A000000677010111') + _tlv('01', target),
  );
  final data = _tlv('00', '01') +
      _tlv('01', '12') + // 12 = ใช้ครั้งเดียว (มียอดเงิน)
      merchant +
      _tlv('58', 'TH') +
      _tlv('53', '764') +
      _tlv('54', amount.toStringAsFixed(2)) +
      '6304';
  final crc = _crc16(data).toRadixString(16).toUpperCase().padLeft(4, '0');
  return data + crc;
}

// ============================================================
// 🧠 STATE
// ============================================================
class AppState extends ChangeNotifier {
  String? tableNo;
  final List<CartItem> cart = [];
  String note = '';

  int get cartTotal => cart.fold(0, (s, c) => s + c.total);
  int get cartCount => cart.fold(0, (s, c) => s + c.qty);

  void selectTable(String t) {
    tableNo = t;
    cart.clear();
    note = '';
    notifyListeners();
  }

  void add(CartItem c) {
    cart.add(c);
    notifyListeners();
  }

  void changeQty(CartItem c, int delta) {
    c.qty += delta;
    if (c.qty <= 0) cart.remove(c);
    notifyListeners();
  }

  Future<bool> submit() async {
    final details = cart.map((c) => c.detail).join(' ; ') +
        (note.trim().isEmpty ? '' : ' [โน้ต: ${note.trim()}]');
    final ok = await Api.createOrder('Table_$tableNo', details, cartTotal);
    if (ok) {
      cart.clear();
      note = '';
      notifyListeners();
    }
    return ok;
  }
}

// ============================================================
// 🚀 APP
// ============================================================
void main() => runApp(
      ChangeNotifierProvider(
          create: (_) => AppState(), child: const NoodleApp()),
    );

class NoodleApp extends StatelessWidget {
  const NoodleApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ก๋วยเตี๋ยวเรือชามกะลา',
        debugShowCheckedModeBanner: false,
        theme:
            ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
        home: const TableSelectScreen(),
      );
}

void _snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

// ============================================================
// 🪑 SCREEN 1 — เลือกโต๊ะ (กดเลือกเท่านั้น ไม่มีสแกน)
// ============================================================
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

// ============================================================
// 🍜 SCREEN 2 — เมนู + ปรับแต่งก๋วยเตี๋ยว
// ============================================================
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('โต๊ะ ${state.tableNo}'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const TableSelectScreen()),
              ),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('เปลี่ยนโต๊ะ'),
            ),
            IconButton(
              tooltip: 'สถานะ / ชำระเงิน',
              icon: const Icon(Icons.receipt_long),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const StatusScreen())),
            ),
          ],
          bottom: TabBar(tabs: [for (final c in categories) Tab(text: c)]),
        ),
        body: TabBarView(
          children: [
            for (final cat in categories)
              ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final m in menuItems.where((m) => m.category == cat))
                    Card(
                      child: ListTile(
                        title: Text(m.name),
                        subtitle: Text('${m.price} บาท'),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => m.customizable
                            ? _openCustomizer(context, m)
                            : context.read<AppState>().add(CartItem(m)),
                      ),
                    ),
                ],
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
          icon: Badge(
            isLabelVisible: state.cartCount > 0,
            label: Text('${state.cartCount}'),
            child: const Icon(Icons.shopping_cart),
          ),
          label: Text('ตะกร้า ${state.cartTotal} ฿'),
        ),
      ),
    );
  }

  void _openCustomizer(BuildContext context, MenuItem m) {
    final state = context.read<AppState>();
    var size = sizes.first;
    var noodle = noodles.first;
    var soup = soups.first;
    var spice = spicy[1];
    final extras = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          Widget group(
            String title,
            List<String> opts,
            String sel,
            void Function(String) onSel,
          ) =>
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final o in opts)
                        ChoiceChip(
                          label: Text(o),
                          selected: sel == o,
                          onSelected: (_) => setS(() => onSel(o)),
                        ),
                    ],
                  ),
                ],
              );

          final price = m.price +
              (size == 'พิเศษกะลายักษ์' ? Config.specialSizeExtra : 0) +
              extras.length * Config.toppingPrice;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  group('ขนาด', sizes, size, (v) => size = v),
                  group('เส้น', noodles, noodle, (v) => noodle = v),
                  group('ซุป', soups, soup, (v) => soup = v),
                  group('ความเผ็ด', spicy, spice, (v) => spice = v),
                  const Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      'ท็อปปิ้งเพิ่ม',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final t in toppings)
                        FilterChip(
                          label: Text('$t +${Config.toppingPrice}'),
                          selected: extras.contains(t),
                          onSelected: (on) =>
                              setS(() => on ? extras.add(t) : extras.remove(t)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        state.add(
                          CartItem(
                            m,
                            size: size,
                            noodle: noodle,
                            soup: soup,
                            spice: spice,
                            extras: extras.toList(),
                          ),
                        );
                        Navigator.pop(ctx);
                      },
                      child: Text('เพิ่มลงตะกร้า — $price บาท'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// 🛒 SCREEN 3 — ตะกร้า
// ============================================================
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _sending = false;

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
      _snack(context, 'ส่งออเดอร์ไม่สำเร็จ ลองใหม่อีกครั้ง');
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

// ============================================================
// 📋 SCREEN 4 — สถานะ + ชำระเงิน PromptPay
// ============================================================
class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});
  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  List<PlacedOrder>? _orders;
  Timer? _timer;

  String get _table => 'Table_${context.read<AppState>().tableNo}';

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await Api.fetchOrders(_table);
    if (mounted && r != null) setState(() => _orders = r);
  }

  int get _total => (_orders ?? []).fold(0, (s, o) => s + o.total);

  void _showPayment() {
    final payload = buildPromptPayPayload(
      Config.promptPayPhone,
      _total.toDouble(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ชำระเงิน $_total บาท'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: QrImageView(data: payload),
            ),
            const SizedBox(height: 8),
            const Text('สแกนด้วยแอพธนาคารเพื่อจ่ายผ่าน PromptPay'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await Api.pay(_table, _total, 'PromptPay');
              if (!mounted) return;
              _snack(
                context,
                ok ? 'บันทึกการชำระเงินแล้ว ขอบคุณครับ 🙏' : 'บันทึกไม่สำเร็จ',
              );
              _load();
            },
            child: const Text('จ่ายเงินแล้ว'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders;
    return Scaffold(
      appBar: AppBar(
        title: Text('สถานะ — โต๊ะ ${context.read<AppState>().tableNo}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: orders == null
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('ยังไม่มีออเดอร์ที่รอชำระ'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final o in orders)
                      Card(
                        child: ListTile(
                          title: Text(o.details),
                          subtitle: Text('${o.orderId} • ${o.total} บาท'),
                          trailing: Chip(label: Text(o.status)),
                        ),
                      ),
                  ],
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: (orders == null || orders.isEmpty) ? null : _showPayment,
            child: Text('ชำระเงิน $_total บาท'),
          ),
        ),
      ),
    );
  }
}
