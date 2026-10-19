import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/api/google_sheet_api.dart';
import '../../../data/models/placed_order.dart';
import '../../../providers/app_state.dart';
import '../widgets/payment_dialog.dart';

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
    final tableNo = context.read<AppState>().tableNo!;
    showDialog(
      context: context,
      builder: (_) => PaymentDialog(
        tableNo: tableNo,
        total: _total,
        onPaidSuccess: _load,
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
            onPressed:
                (orders == null || orders.isEmpty) ? null : _showPayment,
            child: Text('ชำระเงิน $_total บาท'),
          ),
        ),
      ),
    );
  }
}