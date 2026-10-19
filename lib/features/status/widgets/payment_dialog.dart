import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/utils/promptpay_builder.dart';
import '../../../data/api/google_sheet_api.dart';

class PaymentDialog extends StatefulWidget {
  final String tableNo; // รับค่า เช่น "01" หรือ "Table_01"
  final int total;
  final VoidCallback onPaidSuccess;

  const PaymentDialog({
    super.key,
    required this.tableNo,
    required this.total,
    required this.onPaidSuccess,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    // ปรับ Format ให้ตรงกับ 'Table_XX' เสมอ
    final formattedTable = widget.tableNo.startsWith('Table_')
        ? widget.tableNo
        : 'Table_${widget.tableNo}';

    final payload = buildPromptPayPayload(
      Config.promptPayPhone,
      widget.total.toDouble(),
    );

    return AlertDialog(
      title: Text('ชำระเงิน ${widget.total} บาท'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: QrImageView(data: payload),
          ),
          const SizedBox(height: 8),
          const Text(
            '[ Placeholder Mode ]\nสแกน QR หรือกดปุ่มจำลองการจ่ายเงินด้านล่าง',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _isProcessing
              ? null
              : () async {
                  setState(() => _isProcessing = true);

                  debugPrint('💳 [Payment Attempt] Table: $formattedTable, Amount: ${widget.total}');

                  // ยิง API ชำระเงิน
                  final result = await Api.pay(
                    formattedTable,
                    widget.total,
                    'PromptPay_Placeholder',
                  );

                  if (!mounted) return;
                  setState(() => _isProcessing = false);

                  if (result['ok'] == true) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ จำลองการจ่ายเงินสำเร็จ! ขอบคุณครับ 🙏'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    widget.onPaidSuccess();
                  } else {
                    final errorMsg = result['error'] ?? 'ไม่ทราบสาเหตุ';
                    debugPrint('❌ [Payment Error Details]: $errorMsg');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ ชำระเงินไม่สำเร็จ: $errorMsg'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('จำลองการจ่ายเงิน (Paid)'),
        ),
      ],
    );
  }
}