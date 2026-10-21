import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String webAppUrl =
      'https://script.google.com/macros/s/AKfycby7g7bMvt79YkLVC25Klk-MjyGFtlUog4BHKR27OstB1Ju221f4cKLxFHWzeL2NVUDZjA/exec';

  // ส่งออเดอร์ไปยัง Google Sheets
  static Future<Map<String, dynamic>> sendOrder(
      String tableNo, String itemDetails, int totalPrice,
      {String status = 'จ่ายแล้ว'}) async {
    try {
      final payload = jsonEncode({
        'action': 'create_order',
        'table_no': 'Table_$tableNo',
        'item_details': itemDetails,
        'total_price': totalPrice,
        'status': status,
      });

      final response = await http.post(
        Uri.parse(webAppUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: payload,
      );

      debugPrint('Status Code: ${response.statusCode}');

      // ถ้า StatusCode เป็น 200 หรือ 302 ถือว่า Google Apps Script บันทึกสำเร็จแล้ว
      if (response.statusCode == 200 || response.statusCode == 302) {
        return {'success': true, 'message': 'บันทึกเรียบร้อย'};
      }

      return {
        'success': false,
        'message': 'HTTP Error Code: ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'App Error: $e'};
    }
  }

  // ดึงรายการออเดอร์ของโต๊ะ
  static Future<List<dynamic>> fetchOrders(String tableNo) async {
    try {
      final url = '$webAppUrl?action=orders&table_no=Table_$tableNo';
      final response = await http.get(Uri.parse(url));

      if ((response.statusCode == 200 || response.statusCode == 302) &&
          response.body.isNotEmpty) {
        if (!response.body.startsWith('<')) {
          final decoded = jsonDecode(response.body);
          if (decoded is List) return decoded;
        }
      }
    } catch (e) {
      debugPrint('Fetch Orders Error: $e');
    }
    return [];
  }
}
