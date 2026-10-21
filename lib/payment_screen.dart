import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'main.dart';
import 'tracking_screen.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    String itemDetails = provider.cart
        .map((e) => "${e['name']} (${e['option']}) x${e['qty']}")
        .join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text('ชำระเงิน — โต๊ะ ${provider.selectedTable}'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'สแกน QR Code เพื่อชำระเงิน',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Image.asset('assets/qr-code-scan-me-placeholder.png',
                  width: 220, height: 220),
              const SizedBox(height: 20),
              Text(
                'ยอดชำระรวม: ${provider.totalPrice} บาท',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () async {
                  await ApiService.sendOrder(
                    provider.selectedTable,
                    itemDetails,
                    provider.totalPrice,
                  );
                  if (!context.mounted) return;
                  provider.clearCart();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const TrackingScreen()),
                  );
                },
                child: const Text(
                  'ชำระเงินสำเร็จแล้ว',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
