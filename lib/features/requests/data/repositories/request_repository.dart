import 'package:flutter/foundation.dart';

import '../models/request_model.dart';

class RequestRepository {
  // هنا يتم الربط مع Laravel API
  Future<void> submitNewRequest(RequestModel request) async {
    try {
      // محاكاة الاتصال بالسيرفر
      await Future.delayed(const Duration(seconds: 2));

      debugPrint('Sending Request Type: ${request.type} to Server...');

      /*
      مثال باستخدام Dio لرفع البيانات والملفات:
      var formData = FormData.fromMap({
        ...request.toJson(),
        'id_photo': await MultipartFile.fromFile(request.idPhotoPath!),
        'document': await MultipartFile.fromFile(request.documentPath1!),
      });
      await _dio.post('/requests/submit', data: formData);
      */

    } catch (e) {
      throw Exception("Failed to submit request: $e");
    }
  }
}