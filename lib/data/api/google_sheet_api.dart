import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_config.dart';
import '../models/placed_order.dart';

class Api {
  static Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    final bodyJson = jsonEncode(body);
    debugPrint('➡️ [API POST Request] URL: ${Config.scriptUrl}');
    debugPrint('📦 [API POST Body]: $bodyJson');

    try {
      final res = await http.post(
        Uri.parse(Config.scriptUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: bodyJson,
      );

      debugPrint('⬅️ [API Response Status]: ${res.statusCode}');
      debugPrint('📄 [API Response Body]: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 302) {
        if (res.body.isNotEmpty) {
          try {
            final data = jsonDecode(res.body) as Map<String, dynamic>;
            return data;
          } catch (_) {
            // กรณี Apps Script ตอบกลับเป็น HTML Redirect หน้าแรก
            return {'ok': true, 'note': 'Redirected HTML Response'};
          }
        }
        return {'ok': true};
      } else {
        return {'ok': false, 'error': 'HTTP Status ${res.statusCode}'};
      }
    } catch (e, stack) {
      debugPrint('❌ [API Exception]: $e');
      debugPrint('🔍 [Stack Trace]: $stack');
      return {'ok': false, 'error': e.toString()};
    }
  }

  static Future<bool> createOrder(String table, String details, int total) async {
    final res = await _post({
      'action': 'create_order',
      'table_no': table,
      'item_details': details,
      'total_price': total,
    });
    return res['ok'] == true;
  }

  /// ระบบชำระเงิน (รองรับ Placeholder Mode)
  static Future<Map<String, dynamic>> pay(String table, int total, String method) async {
    return await _post({
      'action': 'pay',
      'table_no': table,
      'total_amount': total,
      'payment_method': method,
    });
  }

  static Future<List<PlacedOrder>?> fetchOrders(String table) async {
    debugPrint('➡️ [API GET Fetch Orders] Table: $table');
    try {
      final uri = Uri.parse(
        Config.scriptUrl,
      ).replace(queryParameters: {'action': 'orders', 'table_no': table});
      final res = await http.get(uri);
      
      debugPrint('⬅️ [API GET Status]: ${res.statusCode}');
      debugPrint('📄 [API GET Body]: ${res.body}');

      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => PlacedOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [API GET Exception]: $e');
      return null;
    }
  }
}