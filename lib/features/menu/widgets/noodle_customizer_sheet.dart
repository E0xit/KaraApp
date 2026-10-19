import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/menu_data.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/menu_item.dart';
import '../../../providers/app_state.dart';

class NoodleCustomizerSheet extends StatefulWidget {
  final MenuItem menuItem;

  const NoodleCustomizerSheet({super.key, required this.menuItem});

  @override
  State<NoodleCustomizerSheet> createState() => _NoodleCustomizerSheetState();
}

class _NoodleCustomizerSheetState extends State<NoodleCustomizerSheet> {
  late String size;
  late String noodle;
  late String soup;
  late String spice;
  final Set<String> extras = {};

  @override
  void initState() {
    super.initState();
    size = sizes.first;
    noodle = noodles.first;
    soup = soups.first;
    spice = spicy[1];
  }

  Widget _buildGroup(
    String title,
    List<String> opts,
    String sel,
    void Function(String) onSel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final o in opts)
              ChoiceChip(
                label: Text(o),
                selected: sel == o,
                onSelected: (_) => setState(() => onSel(o)),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final price = widget.menuItem.price +
        (size == 'พิเศษกะลายักษ์' ? Config.specialSizeExtra : 0) +
        extras.length * Config.toppingPrice;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.menuItem.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildGroup('ขนาด', sizes, size, (v) => size = v),
            _buildGroup('เส้น', noodles, noodle, (v) => noodle = v),
            _buildGroup('ซุป', soups, soup, (v) => soup = v),
            _buildGroup('ความเผ็ด', spicy, spice, (v) => spice = v),
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                'ท็อปปิ้งเพิ่ม',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final t in toppings)
                  FilterChip(
                    label: Text('$t +${Config.toppingPrice}'),
                    selected: extras.contains(t),
                    onSelected: (on) => setState(
                      () => on ? extras.add(t) : extras.remove(t),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  state.add(
                    CartItem(
                      widget.menuItem,
                      size: size,
                      noodle: noodle,
                      soup: soup,
                      spice: spice,
                      extras: extras.toList(),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: Text('เพิ่มลงตะกร้า — $price บาท'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}