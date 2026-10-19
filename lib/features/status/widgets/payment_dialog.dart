import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/utils/promptpay_builder.dart';
import '../../../data/api/google_sheet_api.dart';

class PaymentDialog extends StatelessWidget {
  final String tableNo;
  final int total;
  final VoidCallback onPaidSuccess;

  const PaymentDialog({
    super.key,
    required this.tableNo,
    required this.total,
    required this.onPaidSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final payload = buildPromptPayPayload(
      Config.promptPayPhone,
      total.toDouble(),
    );

    return AlertDialog(
      title: Text('ชำระเงิน $total บาท'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: QrImageView(data: payload),
          ),
          const SizedBox(height: 8),
          const Text('สแกนด้วยแอพธนาคารเพื่อจ่ายผ่าน PromptPay'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            final ok = await Api.pay('Table_$tableNo', total, 'PromptPay');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok ? 'บันทึกการชำระเงินแล้ว ขอบคุณครับ 🙏' : 'บันทึกไม่สำเร็จ',
                ),
              ),
            );
            onPaidSuccess();
          },
          child: const Text('จ่ายเงินแล้ว'),
        ),
      ],
    );
  }
}