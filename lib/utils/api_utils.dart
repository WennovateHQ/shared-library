import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// API error types for better handling across the app
enum ApiErrorType {
  network,
  unauthorized,
  notFound,
  serverError,
  badRequest,
  unknown
}

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;
  final Map<String, dynamic>? data;

  ApiException({
    required this.message,
    required this.type,
    this.statusCode,
    this.data,
  });

  @override
  String toString() {
    return 'ApiException: $message (Type: $type, Status: $statusCode)';
  }
}

/// Helper class for API calls across the app
class ApiUtils {
  /// Check if the device has internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('api.freshfarmily.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Handle HTTP response and throw appropriate errors
  static T handleResponse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(response.body);
        return fromJson(jsonData);
      } else {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      
      debugPrint('Error parsing response: $e');
      throw ApiException(
        message: 'Failed to process response data',
        type: ApiErrorType.unknown,
      );
    }
  }

  /// Handle list response from API
  static List<T> handleListResponse<T>(
      http.Response response, T Function(Map<String, dynamic>) fromJson) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => fromJson(item)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      
      debugPrint('Error parsing list response: $e');
      throw ApiException(
        message: 'Failed to process response data',
        type: ApiErrorType.unknown,
      );
    }
  }

  /// Helper to create appropriate API exception from HTTP response
  static ApiException _handleErrorResponse(http.Response response) {
    Map<String, dynamic>? errorData;
    String errorMessage = 'Unknown error occurred';
    
    try {
      errorData = json.decode(response.body);
      errorMessage = errorData?['message'] ?? errorData?['error'] ?? errorMessage;
    } catch (_) {
      // If response body is not valid JSON, use default error message
    }

    switch (response.statusCode) {
      case 400:
        return ApiException(
          message: errorMessage,
          type: ApiErrorType.badRequest,
          statusCode: response.statusCode,
          data: errorData,
        );
      case 401:
      case 403:
        return ApiException(
          message: 'Authentication error. Please log in again.',
          type: ApiErrorType.unauthorized,
          statusCode: response.statusCode,
          data: errorData,
        );
      case 404:
        return ApiException(
          message: 'Resource not found',
          type: ApiErrorType.notFound,
          statusCode: response.statusCode,
          data: errorData,
        );
      case 500:
      case 502:
      case 503:
        return ApiException(
          message: 'Server error. Please try again later.',
          type: ApiErrorType.serverError,
          statusCode: response.statusCode,
          data: errorData,
        );
      default:
        return ApiException(
          message: errorMessage,
          type: ApiErrorType.unknown,
          statusCode: response.statusCode,
          data: errorData,
        );
    }
  }

  /// Create standard authorization headers
  static Map<String, String> createAuthHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Handle connection errors in a standardized way
  static Future<T> withConnectionHandling<T>(Future<T> Function() apiCall) async {
    try {
      // Check for internet connection first
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        throw ApiException(
          message: 'No internet connection. Please check your network settings and try again.',
          type: ApiErrorType.network,
        );
      }
      
      // Execute the API call
      return await apiCall();
    } on SocketException {
      throw ApiException(
        message: 'Connection error. Please check your internet connection and try again.',
        type: ApiErrorType.network,
      );
    } on HttpException {
      throw ApiException(
        message: 'HTTP error occurred. Please try again.',
        type: ApiErrorType.network,
      );
    } on FormatException {
      throw ApiException(
        message: 'Invalid response format. Please contact support if this issue persists.',
        type: ApiErrorType.unknown,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      
      debugPrint('Unexpected error: $e');
      throw ApiException(
        message: 'An unexpected error occurred. Please try again later.',
        type: ApiErrorType.unknown,
      );
    }
  }
}
