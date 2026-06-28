import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String apiKey = "954923814699169";
  static const String apiSecret = "s8oK9h7w1QGLWtaWwghtgvOGrg8";
  static const String cloudName = "dus8mvmah";
  static const String uploadPreset = "ml_default";

  /// Uploads binary file bytes and returns the secure URL
  static Future<String> uploadImage(List<int> bytes, String filename) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Sort parameters alphabetically: timestamp, upload_preset
    final signatureInput = 'timestamp=$timestamp&upload_preset=$uploadPreset$apiSecret';
    final signatureBytes = utf8.encode(signatureInput);
    final signature = sha1.convert(signatureBytes).toString();

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url);
    
    request.fields['api_key'] = apiKey;
    request.fields['timestamp'] = timestamp.toString();
    request.fields['upload_preset'] = uploadPreset;
    request.fields['signature'] = signature;
    
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errBody = jsonDecode(response.body);
      throw Exception(errBody['error']?['message'] ?? 'Image upload to Cloudinary failed.');
    }

    final data = jsonDecode(response.body);
    return data['secure_url'] as String;
  }
}
