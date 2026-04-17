import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class VisionService {
  String _getMimeType(String imagePath) {
    final lowerPath = imagePath.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.gif')) return 'image/gif';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg'; // default
  }

  Future<Map<String, String>?> encodeImageToBase64(String imagePath) async {
    // Guard against null, empty, or non-existent file paths
    if (imagePath.isEmpty || !File(imagePath).existsSync()) {
      debugPrint('No image selected.');
      return null;
    }

    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64String = base64Encode(bytes).replaceAll('\n', '').replaceAll('\r', '');
      final mimeType = _getMimeType(imagePath);

      return {
        'base64': base64String,
        'mimeType': mimeType,
      };
    } catch (e) {
      debugPrint('Image Encoding Error: $e');
      return null;
    }
  }
}

