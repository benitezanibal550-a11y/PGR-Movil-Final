import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../app_config.dart';

class CloudinaryService {
  Future<String> uploadImage(Uint8List bytes, String filename) async {
    if (!AppConfig.cloudinaryConfigured) {
      throw StateError(
        'Falta configurar CLOUDINARY_CLOUD_NAME y CLOUDINARY_UPLOAD_PRESET '
        'en config.local.json.',
      );
    }
    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String detail = 'HTTP ${response.statusCode}';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        detail =
            (body['error'] as Map<String, dynamic>?)?['message']?.toString() ??
            detail;
      } catch (_) {}
      throw Exception('Cloudinary rechazó la imagen: $detail');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final url = body['secure_url']?.toString() ?? '';
    final parsed = Uri.tryParse(url);
    if (parsed == null ||
        parsed.scheme != 'https' ||
        parsed.host != 'res.cloudinary.com') {
      throw Exception('Cloudinary no devolvió una URL segura válida.');
    }
    return url;
  }
}
