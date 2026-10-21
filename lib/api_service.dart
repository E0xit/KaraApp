import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String webAppUrl =
      'https://script.google.com/macros/s/AKfycby7g7bMvt79YkLVC25Klk-MjyGFtlUog4BHKR27OstB1Ju221f4cKLxFHWzeL2NVUDZjA/exec';

  static Future<Map<String, dynamic>> sendOrder(
      String tableNo, String itemDetails, int totalPrice,
      {String status = 'จ่ายแล้ว'}) async {
    try {
      debugPrint('--- START SEND ORDER ---');
      final payload = jsonEncode({
        'action': 'create_order',
        'table_no': 'Table_$tableNo',
        'item_details': itemDetails,
        'total_price': totalPrice,
        'status': status,
      });
      debugPrint('Payload: $payload');

      final response = await http.post(
        Uri.parse(webAppUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: payload,
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 302) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return {'success': true, 'message': 'สำเร็จ'};
        } else {
          return {
            'success': false,
            'message': data['error'] ?? 'เกิดข้อผิดพลาดฝั่ง Server'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}'
        };
      }
    } catch (e, stackTrace) {
      debugPrint('CATCH ERROR: $e');
      debugPrint('STACKTRACE: $stackTrace');
      return {'success': false, 'message': 'App Error: $e'};
    }
  }

  static Future<List<dynamic>> fetchOrders(String tableNo) async {
    try {
      final url = '$webAppUrl?action=orders&table_no=Table_$tableNo';
      debugPrint('Fetching orders from: $url');

      final response = await http.get(Uri.parse(url));
      debugPrint('Fetch Status Code: ${response.statusCode}');
      debugPrint('Fetch Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      }
    } catch (e) {
      debugPrint('Fetch Orders Error: $e');
    }
    return [];
  }
}
