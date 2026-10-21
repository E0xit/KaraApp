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
    final cart = provider.cart;

    // สรุปรายการอาหารเป็นข้อความ
    String itemDetails = cart
        .map((e) => "${e['name']} (${e['option']}) x${e['qty']}")
        .join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text('ชำระเงิน — โต๊ะ ${provider.selectedTable}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'สแกน QR Code เพื่อชำระเงิน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // แสดงรูป QR Code (คุณพี่เปลี่ยน path รูปเป็นของตัวเองได้ตรงนี้)
            Image.asset(
              'assets/qr_code.png',
              width: 220,
              height: 220,
              errorBuilder: (context, error, stackTrace) {
                // ตัวสำรองกรณีที่ยังไม่มีไฟล์รูปใน assets
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('ใส่รูป QR Code ตรงนี้'),
                    ],
                  ),
                );
              },
            ),

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

            // ปุ่มกดเพื่อสำเร็จขั้นตอนชำระเงิน
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () async {
                // ส่งข้อมูลเข้า Sheet พร้อมสถานะ "จ่ายแล้ว"
                bool success = await ApiService.sendOrder(
                  provider.selectedTable,
                  itemDetails,
                  provider.totalPrice,
                  status: 'จ่ายแล้ว',
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'ชำระเงินสำเร็จ (บันทึกสถานะ จ่ายแล้ว)'
                            : 'ส่งข้อมูลไม่สำเร็จ',
                      ),
                    ),
                  );

                  if (success) {
                    provider.clearCart();
                    // ย้ายไปหน้าประวัติออเดอร์
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const TrackingScreen()),
                    );
                  }
                }
              },
              child: const Text(
                'ชำระเงินสำเร็จแล้ว',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
