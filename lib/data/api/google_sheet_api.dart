import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_config.dart';
import '../models/placed_order.dart';

class Api {
  static Future<bool> _post(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse(Config.scriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonEncode(body),
      );
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