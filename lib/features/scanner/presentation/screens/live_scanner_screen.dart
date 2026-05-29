// lib/features/scanner/presentation/screens/live_scanner_screen.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:odfinance/core/constants/carrier_configs.dart';
import 'package:odfinance/core/services/service_providers.dart';
import 'package:odfinance/features/history/presentation/providers/history_provider.dart';
import 'package:odfinance/features/history/domain/models/voucher.dart';

class LiveScannerScreen extends ConsumerStatefulWidget {
  final List<CameraDescription> cameras;
  const LiveScannerScreen({super.key, required this.cameras});

  @override
  ConsumerState<LiveScannerScreen> createState() => _LiveScannerScreenState();
}

class _LiveScannerScreenState extends ConsumerState<LiveScannerScreen> {
  late CameraController _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    // Use ResolutionPreset.max for taking high-resolution static pictures
    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.max,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Camera hardware setup failed: $e");
    }
  }

  /// This function captures a single static photo and scans it for numbers instantly
  Future<void> _captureAndScanImage() async {
    if (_isProcessing || !_cameraController.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photoFile = await _cameraController.takePicture();

      final InputImage inputImage = InputImage.fromFilePath(photoFile.path);

      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      String? detectedCode;

      // 4. Extract digits loop
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String cleanText = line.text.replaceAll(' ', '');
          cleanText = cleanText.replaceAll('o', '0').replaceAll('O', '0');
          cleanText = cleanText.replaceAll('l', '1').replaceAll('I', '1');

          final RegExp voucherRegex = RegExp(r'\d{13,15}');
          if (voucherRegex.hasMatch(cleanText)) {
            detectedCode = voucherRegex.stringMatch(cleanText);
            break;
          }
        }
        if (detectedCode != null) break;
      }

      // 5. Handle Results
      if (detectedCode != null) {
        _handleDetectedVoucher(detectedCode);
      } else {
        // Inform the user if the picture didn't yield a valid card number sequence
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "لم يتم العثور على كود شحن واضح. حاول مجدداً مع إضاءة أفضل.",
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Snapshot processing failure: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handleDetectedVoucher(String serialCode) async {
    final voucherNotifier = ref.read(historyProvider.notifier);
    final savedVoucher = await voucherNotifier.addVoucher(serialCode);

    if (!mounted) return;

    final fullUssdCode = CarrierConfigs.generateCode(
      savedVoucher.carrier,
      savedVoucher.serialCode,
    );
    final isLibyana = savedVoucher.carrier == CarrierType.libyana;
    final carrierColor = isLibyana
        ? Colors.blue.shade700
        : (savedVoucher.carrier == CarrierType.almadar
              ? Colors.orange.shade700
              : Colors.teal.shade700);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "تم التعرف على بطاقة شحن!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: carrierColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: carrierColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      serialCode,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: carrierColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullUssdCode,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await ref
                            .read(dialerServiceProvider)
                            .launchUssd(fullUssdCode);
                        if (success) {
                          await ref
                              .read(historyProvider.notifier)
                              .toggleVoucherStatus(savedVoucher.id);
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "تعبئة الرصيد الآن",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("إغلاق"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_cameraController)),

          // Top Back Menu Bar Layout
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Central Visual Focus Targets
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Prominent Manual Shutter Trigger Button Placement at the Bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _captureAndScanImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(
                  _isProcessing ? "جاري القراءة..." : "إضغط لمسح الكرت ضوئياً",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
