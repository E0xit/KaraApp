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

      final response = await http.post(
        Uri.parse(webAppUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: payload,
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: "${response.body}"');

      // 1. เช็กก่อนว่า Response Body ว่างเปล่าหรือไม่
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message':
              'Google Apps Script ตอบกลับเป็นข้อความว่างเปล่า (Empty Body)'
        };
      }

      // 2. เช็กว่า Response เป็น HTML หรือไม่ (กรณีติดหน้าบล็อกหรือ Redirect)
      if (response.body.startsWith('<!DOCTYPE html>') ||
          response.body.startsWith('<html')) {
        return {
          'success': false,
          'message':
              'ได้รับหน้าเว็บ HTML แทนที่จะเป็น JSON (กรุณาเช็กการ Deploy ของ Apps Script)'
        };
      }

      // 3. เมื่อมั่นใจว่ามีข้อมูล ค่อยทำการ jsonDecode
      final data = jsonDecode(response.body);
      if (data is Map && data['ok'] == true) {
        return {'success': true, 'message': 'สำเร็จ'};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'เกิดข้อผิดพลาดจากฝั่ง Server'
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
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
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
