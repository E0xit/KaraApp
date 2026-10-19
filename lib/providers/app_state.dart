import 'package:flutter/material.dart';
import '../data/api/google_sheet_api.dart';
import '../data/models/cart_item.dart';

class AppState extends ChangeNotifier {
  String? tableNo;
  final List<CartItem> cart = [];
  String note = '';

  int get cartTotal => cart.fold(0, (s, c) => s + c.total);
  int get cartCount => cart.fold(0, (s, c) => s + c.qty);

  void selectTable(String t) {
    tableNo = t;
    cart.clear();
    note = '';
    notifyListeners();
  }

  void add(CartItem c) {
    cart.add(c);
    notifyListeners();
  }

  void changeQty(CartItem c, int delta) {
    c.qty += delta;
    if (c.qty <= 0) cart.remove(c);
    notifyListeners();
  }

  Future<bool> submit() async {
    final details = cart.map((c) => c.detail).join(' ; ') +
        (note.trim().isEmpty ? '' : ' [โน้ต: ${note.trim()}]');
    final ok = await Api.createOrder('Table_$tableNo', details, cartTotal);
    if (ok) {
      cart.clear();
      note = '';
      notifyListeners();
    }
    return ok;
  }
}