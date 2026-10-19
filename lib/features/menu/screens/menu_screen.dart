import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/menu_data.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/menu_item.dart';
import '../../../providers/app_state.dart';
import '../../cart/screens/cart_screen.dart';
import '../../status/screens/status_screen.dart';
import '../../table/screens/table_select_screen.dart';
import '../widgets/noodle_customizer_sheet.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _openCustomizer(BuildContext context, MenuItem m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => NoodleCustomizerSheet(menuItem: m),
    );
  }

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
}