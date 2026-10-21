import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String webAppUrl =
      'https://script.google.com/macros/s/AKfycbw6lAkmsfbBoYGRmIQeO9W61DAaF_0-8KjRlDJ8t4RqrN1LXpBT7ngwTrnbKUAkYT6CEw/exec';

  // ส่งออเดอร์พร้อมสถานะการจ่ายเงิน
  static Future<bool> sendOrder(
      String tableNo, String itemDetails, int totalPrice,
      {String status = 'จ่ายแล้ว'}) async {
    try {
      final response = await http.post(
        Uri.parse(webAppUrl),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonEncode({
          'action': 'create_order',
          'table_no': 'Table_$tableNo',
          'item_details': itemDetails,
          'total_price': totalPrice,
          'status': status, // เพิ่มส่งคอลัมน์สถานะจ่ายเงิน
        }),
      );
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (_) {
      return false;
    }
  }

  // ดึงรายการออเดอร์ของโต๊ะ
  static Future<List<dynamic>> fetchOrders(String tableNo) async {
    try {
      final response = await http.get(
        Uri.parse('$webAppUrl?action=orders&table_no=Table_$tableNo'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }
}
