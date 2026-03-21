import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/supabase_client.dart';

class PayOSService {
  static const String _baseUrl = 'https://api-merchant.payos.vn/v2';
  final Dio _dio = Dio();

  String _generateSignature(Map<String, dynamic> data, String checksumKey) {
    // Sort keys alphabetically
    final sortedKeys = data.keys.toList()..sort();
    
    // Create query string: key1=value1&key2=value2...
    final queryString = sortedKeys.map((key) {
      final value = data[key];
      return '$key=$value';
    }).join('&');

    // HMAC_SHA256
    final keyBytes = utf8.encode(checksumKey);
    final dataBytes = utf8.encode(queryString);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);
    
    return digest.toString();
  }

  Future<Map<String, dynamic>> createPaymentLink({
    required int orderCode,
    required int amount,
    required String description,
    required String returnUrl,
    required String cancelUrl,
  }) async {
    final clientId = SupabaseClientManager.payosClientId;
    final apiKey = SupabaseClientManager.payosApiKey;
    final checksumKey = SupabaseClientManager.payosChecksumKey;

    final requestBody = {
      'orderCode': orderCode,
      'amount': amount,
      'description': description,
      'cancelUrl': cancelUrl,
      'returnUrl': returnUrl,
    };

    final signature = _generateSignature(requestBody, checksumKey);
    requestBody['signature'] = signature;

    try {
      final response = await _dio.post(
        '$_baseUrl/payment-requests',
        data: requestBody,
        options: Options(
          headers: {
            'x-client-id': clientId,
            'x-api-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.data['code'] == '00') {
        return response.data['data'];
      } else {
        throw Exception(response.data['desc'] ?? 'Failed to create payment link');
      }
    } on DioException catch (e) {
      debugPrint('PayOS createPaymentLink error: ${e.response?.data}');
      throw Exception(e.response?.data?['desc'] ?? 'PayOS API Error');
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(int orderCode) async {
    final clientId = SupabaseClientManager.payosClientId;
    final apiKey = SupabaseClientManager.payosApiKey;

    try {
      final response = await _dio.get(
        '$_baseUrl/payment-requests/$orderCode',
        options: Options(
          headers: {
            'x-client-id': clientId,
            'x-api-key': apiKey,
          },
        ),
      );

      if (response.data['code'] == '00') {
        return response.data['data'];
      } else {
        throw Exception(response.data['desc'] ?? 'Failed to get payment status');
      }
    } on DioException catch (e) {
      debugPrint('PayOS getPaymentStatus error: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        throw Exception('Payment link not found');
      }
      throw Exception(e.response?.data?['desc'] ?? 'PayOS API Error');
    }
  }

  Future<void> cancelPaymentLink(int orderCode) async {
    final clientId = SupabaseClientManager.payosClientId;
    final apiKey = SupabaseClientManager.payosApiKey;

    try {
      final response = await _dio.post(
        '$_baseUrl/payment-requests/$orderCode/cancel',
        options: Options(
          headers: {
            'x-client-id': clientId,
            'x-api-key': apiKey,
          },
        ),
      );

      if (response.data['code'] != '00') {
        throw Exception(response.data['desc'] ?? 'Failed to cancel payment link');
      }
    } on DioException catch (e) {
      debugPrint('PayOS cancelPaymentLink error: ${e.response?.data}');
      throw Exception(e.response?.data?['desc'] ?? 'PayOS API Error');
    }
  }
}
