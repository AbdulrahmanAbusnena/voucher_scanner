// lib/core/utils/camera_ml_translator.dart
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraMlTranslator {
  static InputImage? inputImageFromCameraImage({
    required CameraImage image,
    required CameraDescription camera,
    required InputImageRotation rotation,
  }) {
    if (image.planes.isEmpty) return null;

    // 1. Samsung S23 Ultra Performance Override:
    // If the device streams multiple planes but throws format errors, we bypass the full
    // YUV plane stitching entirely and feed ML Kit a high-speed grayscale NV21 matrix
    // constructed directly from Plane 0 (The Y/Luminance channel).
    // For text recognition, color channels (Planes 1 & 2) aren't even needed!
    if (image.planes.length == 3) {
      final Plane yPlane = image.planes[0];

      return InputImage.fromBytes(
        bytes: yPlane.bytes, // Pure luminance byte matrix
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21, // Treat as NV21 grayscale
          bytesPerRow: yPlane.bytesPerRow,
        ),
      );
    }

    // 2. Standard Fallback Path for non-Samsung standard devices
    final passthroughFormats = [
      InputImageFormat.nv21,
      InputImageFormat.bgra8888,
      InputImageFormat.yuv_420_888,
      InputImageFormat.yuv420,
    ];

    InputImageFormat? format = InputImageFormatValue.fromRawValue(
      image.format.raw as int,
    );
    format ??= (image.planes.length == 1
        ? InputImageFormat.nv21
        : InputImageFormat.yuv_420_888);

    if (!passthroughFormats.contains(format)) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

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
