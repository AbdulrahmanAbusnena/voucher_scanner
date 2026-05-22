// lib/core/utils/camera_ml_translator.dart
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraMlTranslator {
  static InputImage? inputImageFromCameraImage({
    required CameraImage image,
    required CameraDescription camera,
    required InputImageRotation rotation,
  }) {
    // 1. Map raw image formats safely
    final passthroughFormats = [
      InputImageFormat.nv21,
      InputImageFormat.bgra8888,
      InputImageFormat.yuv_420_888,
    ];

    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null || !passthroughFormats.contains(format)) return null;
    if (image.planes.isEmpty) return null;

    // 2. Concat all image planes into a unified byte buffer
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // 3. Metadata structural breakdown
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  static InputImageRotation rotationFromDescription(CameraDescription camera) {
    switch (camera.sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }
}
