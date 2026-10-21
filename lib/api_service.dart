import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String webAppUrl =
      'https://script.google.com/macros/s/AKfycbwCikXxix3359EN81zYOnNuMbtn6rF13m_OtlZNK5w-RSJovrHvPnUm9tdLr_PzNP8vPA/exec';

  static Future<void> sendOrder(
      String tableNo, String itemDetails, int totalPrice,
      {String status = 'จ่ายแล้ว'}) async {
    await http.post(
      Uri.parse(webAppUrl),
      headers: {'Content-Type': 'text/plain;charset=utf-8'},
      body: jsonEncode({
        'action': 'create_order',
        'table_no': 'Table_$tableNo',
        'item_details': itemDetails,
        'total_price': totalPrice,
        'status': status,
      }),
    );
  }

  static Future<List<dynamic>> fetchOrders(String tableNo) async {
    final response = await http
        .get(Uri.parse('$webAppUrl?action=orders&table_no=Table_$tableNo'));
    return jsonDecode(response.body);
  }
}
