import '../../core/constants/app_config.dart';
import 'menu_item.dart';

class CartItem {
  final MenuItem item;
  String size;
  String noodle;
  String soup;
  String spice;
  List<String> extras;
  int qty;

  CartItem(
    this.item, {
    this.size = '',
    this.noodle = '',
    this.soup = '',
    this.spice = '',
    this.extras = const [],
    this.qty = 1,
  });

  int get unitPrice {
    var p = item.price;
    if (size == 'พิเศษกะลายักษ์') p += Config.specialSizeExtra;
    p += extras.length * Config.toppingPrice;
    return p;
  }

  int get total => unitPrice * qty;

  String get detail {
    if (!item.customizable) return '${item.name} (x$qty)';
    final ex = extras.isEmpty ? '' : ' + ${extras.join(', ')}';
    return '${item.name} | $size | $noodle | $soup | $spice$ex (x$qty)';
  }
}