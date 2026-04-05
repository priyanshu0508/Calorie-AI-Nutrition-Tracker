import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'food_camera_screen.dart';
import 'qr_scan_screen.dart';
import 'qr_result_screen.dart';
import 'barcode_scan_screen.dart';
import 'barcode_result_screen.dart';
import 'photo_result_screen.dart';
import '../../diary/presentation/manual_entry_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  Future<void> _startPhotoFlow(BuildContext context) async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FoodCameraScreen(camera: cameras.first),
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoResultScreen(imagePath: picked.path),
      ),
    );
  }

  Future<void> _startBarcodeFlow(BuildContext context) async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScanScreen(),
      ),
    );

    if (barcode == null) return;
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BarcodeResultScreen(barcode: barcode),
      ),
    );
  }

  Future<void> _startQrFlow(BuildContext context) async {
    final qrPayload = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QrScanScreen(),
      ),
    );

    if (qrPayload == null) return;
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrResultScreen(qrPayload: qrPayload),
      ),
    );
  }

  void _startManualFlow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ManualEntryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & log'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.insights,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Use AI-powered vision, barcodes or QR codes to log your meals in real time.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose an action',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _ScanOptionTile(
                icon: Icons.search,
                color: Colors.orange,
                title: 'Search manually',
                subtitle: 'Type any food name (e.g. "Apple")',
                onTap: () => _startManualFlow(context),
              ),
              const SizedBox(height: 12),
              _ScanOptionTile(
                icon: Icons.camera_alt,
                color: colorScheme.primary,
                title: 'Upload photo of food',
                subtitle: 'Detect multiple foods and estimate nutrition',
                onTap: () => _startPhotoFlow(context),
              ),
              const SizedBox(height: 12),
              _ScanOptionTile(
                icon: Icons.qr_code_scanner,
                color: Colors.blue,
                title: 'Scan barcode',
                subtitle: 'Instantly log packaged food from barcode',
                onTap: () => _startBarcodeFlow(context),
              ),
              const SizedBox(height: 12),
              _ScanOptionTile(
                icon: Icons.qr_code_2,
                color: Colors.deepPurple,
                title: 'Scan QR code',
                subtitle: 'Support for smart menus and meal QR codes',
                onTap: () => _startQrFlow(context),
              ),
              const Spacer(),
              const Text(
                'Tip: for best accuracy, capture your plate from above with good lighting.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ScanOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}