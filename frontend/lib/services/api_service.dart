import 'package:dio/dio.dart';

import '../core/constants/app_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../core/network/paginated_response.dart';

/// Cliente HTTP centralizado para FastAPI.
class ApiService {
  ApiService({Dio? dio}) : _dio = dio ?? DioClient.create();

  final Dio _dio;

  Future<UserProfile> fetchProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/me',
      );

      return UserProfile.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<UserProfile> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/v1/me',
        data: {
          if (fullName != null) 'full_name': fullName,
          if (phone != null) 'phone': phone,
        },
      );

      return UserProfile.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<bool> sendOnboarding({
    required double budget,
    required String operationType,
    required String preferredZone,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/onboarding',
        data: {
          'budget': budget,
          'operation_type': operationType,
          'preferred_zone': preferredZone,
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  // Weather Endpoint
  Future<Map<String, dynamic>> fetchWeatherForecast(String zone, {double? lat, double? lon, String? simulate}) async {
    try {
      final queryParams = <String, dynamic>{'zone': zone};
      if (lat != null && lon != null) {
        queryParams['lat'] = lat;
        queryParams['lon'] = lon;
      }
      if (simulate != null) {
        queryParams['simulate'] = simulate;
      }
      
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/weather/forecast',
        queryParameters: queryParams,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

class UserProfile {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String role;
  final bool isPremium;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.isPremium = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      fullName: json['full_name']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'user',
      isPremium: json['is_premium'] == true,
    );
  }
}
