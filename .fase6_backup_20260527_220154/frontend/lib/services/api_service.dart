import 'package:dio/dio.dart';

import '../core/constants/app_constants.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../core/network/paginated_response.dart';
import '../features/market/data/dto/market_evaluation_dto.dart';
import '../features/properties/data/dto/property_dto.dart';
import '../features/properties/domain/entities/property.dart';

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

  Future<UserProfile> becomeOwner() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/me/become-owner',
      );

      final data = response.data ?? <String, dynamic>{};
      final profile = data['profile'];

      if (profile is Map<String, dynamic>) {
        return UserProfile.fromJson(profile);
      }

      return UserProfile.fromJson(data);
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

  Future<List<String>> fetchAmenities() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/v1/amenities',
      );

      return (response.data ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<Property>> fetchProperties() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/properties',
        queryParameters: {
          'page': 1,
          'page_size': AppConstants.defaultPageSize,
        },
      );

      final data = response.data ?? <String, dynamic>{};

      final paginated = PaginatedResponse<Property>.fromJson(
        data,
        (json) => PropertyDto.fromJson(json).toEntity(),
      );

      return paginated.items;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PropertyDetailData> fetchPropertyDetail(String propertyId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/properties/$propertyId',
      );

      return PropertyDetailData.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> sendSwipeAction(
    String propertyId,
    String action,
  ) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/v1/swipes',
        data: {
          'property_id': propertyId,
          'action': action,
        },
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<MarketEvaluationResult> evaluateMarketPrice(
    double price,
    String operationType, {
    String? zone,
    String? propertyType,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/market/evaluate',
        data: {
          'price': price,
          'operation_type': operationType,
          'zone': zone,
          'property_type': propertyType,
        },
      );

      return MarketEvaluationResult.fromJson(
        response.data ?? <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<Property>> fetchMatches() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/matches',
        queryParameters: {
          'page': 1,
          'page_size': AppConstants.defaultPageSize,
        },
      );

      final data = response.data ?? <String, dynamic>{};

      final paginated = PaginatedResponse<Property>.fromJson(
        data,
        (json) => PropertyDto.fromJson(json).toEntity(),
      );

      return paginated.items;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PropertyDetailData> createOwnerProperty(
    OwnerPropertyCreateInput input,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/owner/properties',
        data: input.toJson(),
      );

      return PropertyDetailData.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<Property>> fetchOwnerProperties() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/owner/properties',
        queryParameters: {
          'page': 1,
          'page_size': AppConstants.defaultPageSize,
        },
      );

      final data = response.data ?? <String, dynamic>{};

      final paginated = PaginatedResponse<Property>.fromJson(
        data,
        (json) => PropertyDto.fromJson(json).toEntity(),
      );

      return paginated.items;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> updateOwnerPropertyStatus(
    String propertyId,
    String status,
  ) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/api/v1/owner/properties/$propertyId/status',
        data: {
          'status': status,
        },
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteOwnerProperty(String propertyId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/api/v1/owner/properties/$propertyId',
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<OwnerMatchItem>> fetchOwnerMatches() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/owner/matches',
        queryParameters: {
          'page': 1,
          'page_size': AppConstants.defaultPageSize,
        },
      );

      final data = response.data ?? <String, dynamic>{};
      final items = data['items'];

      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(OwnerMatchItem.fromJson)
            .toList();
      }

      return [];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> updateMatchStatus(String matchId, String status) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/api/v1/matches/$matchId/status',
        data: {
          'status': status,
        },
      );
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

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      fullName: json['full_name']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'buyer',
    );
  }

  bool get isOwnerOrAdmin => role == 'owner' || role == 'admin';
}

class OwnerPropertyImageInput {
  final String imageUrl;
  final String? storagePath;

  const OwnerPropertyImageInput({
    required this.imageUrl,
    this.storagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'storage_path': storagePath,
    };
  }
}

class OwnerPropertyCreateInput {
  final String title;
  final String description;
  final double price;
  final String operationType;
  final String propertyType;
  final String zone;
  final List<String> amenities;
  final List<OwnerPropertyImageInput> images;

  const OwnerPropertyCreateInput({
    required this.title,
    required this.description,
    required this.price,
    required this.operationType,
    required this.propertyType,
    required this.zone,
    required this.amenities,
    required this.images,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'operation_type': operationType,
      'property_type': propertyType,
      'zone': zone,
      'amenities': amenities,
      'images': images.map((image) => image.toJson()).toList(),
    };
  }
}

class PropertyDetailData {
  final Property property;
  final String? ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final String? status;
  final List<String> images;

  const PropertyDetailData({
    required this.property,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.status,
    required this.images,
  });

  factory PropertyDetailData.fromJson(Map<String, dynamic> json) {
    final property = PropertyDto.fromJson(json).toEntity();

    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList()
        : property.imageUrls;

    return PropertyDetailData(
      property: property,
      ownerId: json['owner_id']?.toString(),
      ownerName: json['owner_name']?.toString(),
      ownerPhone: json['owner_phone']?.toString(),
      status: json['status']?.toString(),
      images: images.isEmpty ? [property.imageUrl] : images,
    );
  }
}

class OwnerMatchItem {
  final String matchId;
  final String status;
  final String buyerId;
  final String? buyerName;
  final String? buyerEmail;
  final Property property;

  const OwnerMatchItem({
    required this.matchId,
    required this.status,
    required this.buyerId,
    required this.buyerName,
    required this.buyerEmail,
    required this.property,
  });

  factory OwnerMatchItem.fromJson(Map<String, dynamic> json) {
    final propertyJson = json['property'];

    return OwnerMatchItem(
      matchId: json['match_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      buyerId: json['buyer_id']?.toString() ?? '',
      buyerName: json['buyer_name']?.toString(),
      buyerEmail: json['buyer_email']?.toString(),
      property: PropertyDto.fromJson(
        propertyJson is Map<String, dynamic>
            ? propertyJson
            : <String, dynamic>{},
      ).toEntity(),
    );
  }
}
