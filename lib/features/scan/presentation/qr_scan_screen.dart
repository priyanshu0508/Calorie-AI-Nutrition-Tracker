import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final value = barcode?.rawValue;
    if (value == null) return;

    _handled = true;
    Navigator.of(context).pop(value); // return QR payload
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR code')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),

          // Hint text at top
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Align the QR code within the frame',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          // Centered corner frame (Google Lens / GPay style)
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: CustomPaint(
                painter: _CornerFramePainter(
                  color: Colors.white,
                  strokeWidth: 4,
                  cornerRadius: 24,
                  cornerLength: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerFramePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerRadius;
  final double cornerLength;

  _CornerFramePainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerRadius,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final left = 0.0;
    final top = 0.0;
    final right = size.width;
    final bottom = size.height;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top + cornerRadius),
      Offset(left, top + cornerLength),
      paint,
    );
    canvas.drawLine(
      Offset(left + cornerRadius, top),
      Offset(left + cornerLength, top),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(right, top + cornerRadius),
      Offset(right, top + cornerLength),
      paint,
    );
    canvas.drawLine(
      Offset(right - cornerRadius, top),
      Offset(right - cornerLength, top),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, bottom - cornerRadius),
      Offset(left, bottom - cornerLength),
      paint,
    );
    canvas.drawLine(
      Offset(left + cornerRadius, bottom),
      Offset(left + cornerLength, bottom),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(right, bottom - cornerRadius),
      Offset(right, bottom - cornerLength),
      paint,
    );
    canvas.drawLine(
      Offset(right - cornerRadius, bottom),
      Offset(right - cornerLength, bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}