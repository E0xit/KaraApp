import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'main.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late Future<List<dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final tableNo = context.read<AppProvider>().selectedTable;
    setState(() {
      _ordersFuture = ApiService.fetchOrders(tableNo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tableNo = context.watch<AppProvider>().selectedTable;

    return Scaffold(
      appBar: AppBar(
        title: Text('ติดตามออเดอร์ — โต๊ะ $tableNo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีรายการที่สั่งสำหรับโต๊ะนี้'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'รหัสออเดอร์: ${order['order_id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Chip(
                            label: Text(
                              order['status'] ?? 'Cooking',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: order['status'] == 'Paid'
                                ? Colors.green
                                : Colors.deepOrange,
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('รายการ: ${order['item_details']}'),
                      const SizedBox(height: 8),
                      Text(
                        'ราคารวม: ${order['total_price']} บาท',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
