import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'photo_result_screen.dart';

class CropData {
  final String imagePath;
  final double screenWidth;
  final double screenHeight;

  CropData(this.imagePath, this.screenWidth, this.screenHeight);
}

Future<String> _cropImage(CropData data) async {
  final bytes = await File(data.imagePath).readAsBytes();
  img.Image? originalImage = img.decodeImage(bytes);
  if (originalImage == null) return data.imagePath;

  // Fix orientation issue (some devices capture in landscape natively)
  originalImage = img.bakeOrientation(originalImage);

  final double zoom = [
    data.screenWidth / originalImage.width,
    data.screenHeight / originalImage.height
  ].reduce((a, b) => a > b ? a : b);

  final int cropSize = (280.0 / zoom).round();

  // Clamp crop rectangle to prevent out-of-bounds error
  final int cropX = ((originalImage.width - cropSize) / 2).clamp(0, originalImage.width).round();
  final int cropY = ((originalImage.height - cropSize) / 2).clamp(0, originalImage.height).round();

  final croppedImage = img.copyCrop(
    originalImage,
    x: cropX,
    y: cropY,
    width: cropSize,
    height: cropSize,
  );

  final croppedBytes = img.encodeJpg(croppedImage, quality: 85);
  final croppedPath = '${data.imagePath}_cropped.jpg';
  final outFile = File(croppedPath);
  await outFile.writeAsBytes(croppedBytes);

  return outFile.path;
}

class FoodCameraScreen extends StatefulWidget {
  const FoodCameraScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<FoodCameraScreen> createState() => _FoodCameraScreenState();
}

class _FoodCameraScreenState extends State<FoodCameraScreen> {
  late CameraController _controller;
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final previewSize = _controller.value.previewSize;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (previewSize != null)
                Builder(
                  builder: (context) {
                    var cameraRatio = _controller.value.aspectRatio;
                    var isPortrait =
                        MediaQuery.of(context).orientation == Orientation.portrait;
                    if (isPortrait && cameraRatio > 1) {
                      cameraRatio = 1 / cameraRatio;
                    } else if (!isPortrait && cameraRatio < 1) {
                      cameraRatio = 1 / cameraRatio;
                    }

                    final size = MediaQuery.of(context).size;
                    final screenRatio = size.aspectRatio;

                    var scale = 1.0;
                    if (cameraRatio < screenRatio) {
                      scale = screenRatio / cameraRatio;
                    } else {
                      scale = cameraRatio / screenRatio;
                    }

                    return ClipRect(
                      child: Transform.scale(
                        scale: scale,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: cameraRatio,
                            child: CameraPreview(_controller),
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                CameraPreview(_controller),

              // Lens-style corner frame overlay (Google Lens style)
              Center(
                child: SizedBox(
                  width: 280,
                  height: 280, 
                  child: CustomPaint(
                    painter: _CornerFramePainter(
                      color: Colors.white,
                      strokeWidth: 3,
                      cornerRadius: 24,
                      cornerLength: 32,
                    ),
                  ),
                ),
              ),

              // Top helper text
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Place the meal inside the frame',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              // Capture button area (bottom)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    onPressed: () async {
                      try {
                        // Optimistically trigger capture visually
                        final fileFuture = _controller.takePicture();

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                        );

                        final file = await fileFuture;
                        final size = MediaQuery.of(context).size;

                        // Crop heavily on a separate isolate
                        final croppedPath = await compute(
                          _cropImage,
                          CropData(file.path, size.width, size.height),
                        );

                        if (!mounted) return;
                        Navigator.of(context).pop(); // Remove dialog
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PhotoResultScreen(imagePath: croppedPath),
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          Navigator.of(context).pop(); // Remove dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to capture or crop image: $e')),
                          );
                        }
                      }
                    },
                    child: const Icon(Icons.camera_alt, color: Colors.black),
                  ),
                ),
              ),
            ],
          );
        },
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
