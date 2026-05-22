import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:odfinance/core/utils/camera_ml_translator.dart';
import 'package:odfinance/core/constants/carrier_configs.dart';
import 'package:odfinance/core/services/service_providers.dart';
import 'package:odfinance/features/history/domain/models/voucher.dart';
import 'package:odfinance/features/history/presentation/providers/history_provider.dart';

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
  bool _hasFoundVoucher = false;

  // Regex patterns tailored to Libyan carrier voucher structures:
  // Al-Madar (13 digits), Libyana (14 digits), LTT (15 digits)
  final RegExp _voucherRegex = RegExp(r'\b\d{13,15}\b');

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    // Medium preset scales down resolutions (~480p/720p) to keep byte matrices small.
    // This allows on-device machine learning models to run at higher frames per second.
    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController.initialize();
      if (!mounted) return;

      // Mount the real-time hardware frame pipeline
      await _cameraController.startImageStream((CameraImage image) {
        if (_isProcessing || _hasFoundVoucher) return;
        _processFrame(image);
      });

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Camera hardware setup failed: $e");
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    // Acquire atomic processing lock
    _isProcessing = true;

    try {
      final rotation = CameraMlTranslator.rotationFromDescription(
        widget.cameras.first,
      );
      final inputImage = CameraMlTranslator.inputImageFromCameraImage(
        image: image,
        camera: widget.cameras.first,
        rotation: rotation,
      );

      if (inputImage != null) {
        final RecognizedText recognizedText = await _textRecognizer
            .processImage(inputImage);

        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            // Strip any accidental spaces introduced by card design layouts
            final String cleanText = line.text.replaceAll(' ', '');

            if (_voucherRegex.hasMatch(cleanText)) {
              final String? matchedSerial = _voucherRegex.stringMatch(
                cleanText,
              );

              if (matchedSerial != null && !_hasFoundVoucher) {
                _hasFoundVoucher = true;

                // Break out of stream loops before running async operations
                _cameraController.stopImageStream();
                _handleDetectedVoucher(matchedSerial);
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Frame pipeline inference error: $e");
    } finally {
      // Release processing lock for next hardware frame payload
      _isProcessing = false;
    }
  }

  void _handleDetectedVoucher(String serialCode) async {
    // 1. Instantly write code to our local cache using our Riverpod state manager
    final voucherNotifier = ref.read(historyProvider.notifier);
    final savedVoucher = await voucherNotifier.addVoucher(serialCode);

    if (!mounted) return;

    // 2. Display an overlay modal showing the recognized voucher details
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

              // Code display details
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

              // Control action buttons
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
                        _resetScanner();
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
                      onPressed: () {
                        Navigator.pop(context);
                        _resetScanner();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("حفظ ومسح آخر"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.pop(
                    context,
                  ); // Exit scanner screen back to history list view dashboard
                },
                child: const Text(
                  "الرجوع للقائمة الرئيسية",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetScanner() async {
    setState(() {
      _hasFoundVoucher = false;
    });
    // Restart the video image loop configuration
    await _cameraController.startImageStream((CameraImage image) {
      if (_isProcessing || _hasFoundVoucher) return;
      _processFrame(image);
    });
  }

  @override
  void dispose() {
    // Step back to release native camera frames safely before destroying context locks
    if (_cameraController.value.isStreamingImages) {
      _cameraController.stopImageStream();
    }
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
          // 1. Live camera viewport output preview box
          Positioned.fill(child: CameraPreview(_cameraController)),

          // 2. Semi-transparent black masking layer to draw emphasis into scan target zone box
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.55),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Clear green/white bounding frame box overlay outline
          Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _hasFoundVoucher
                      ? Colors.green
                      : Colors.white.withOpacity(0.8),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // 4. Interface control labels overlay layout top menu bars
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "وجه الكاميرا نحو رقم الكود",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 40,
                ), // Balances out the back button layout placement symmetry
              ],
            ),
          ),
        ],
      ),
    );
  }
}
