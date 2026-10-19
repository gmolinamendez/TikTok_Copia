import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:toktok/config/constants/cloudinary_config.dart';


class CloudinaryService {

  // Sube la foto o el video y regresa la URL pública (https) del archivo
  Future<String> upload({ required Uint8List bytes, required String fileName, required bool isVideo }) async {

    if ( !CloudinaryConfig.isConfigured ) {
      throw Exception('Falta configurar Cloudinary en lib/config/constants/cloudinary_config.dart');
    }

    final resourceType = isVideo ? 'video' : 'image';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${ CloudinaryConfig.cloudName }/$resourceType/upload' );

    final request = http.MultipartRequest( 'POST', uri )
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = 'toktik'
      ..files.add( http.MultipartFile.fromBytes( 'file', bytes, filename: fileName ) );

    final response = await http.Response.fromStream( await request.send() );
    final body = jsonDecode( response.body ) as Map<String, dynamic>;

    if ( response.statusCode != 200 ) {
      final message = ( body['error'] as Map<String, dynamic>? )?['message'] ?? response.body;
      throw Exception('Cloudinary respondió ${ response.statusCode }: $message');
    }

    return body['secure_url'] as String;
  }

}
