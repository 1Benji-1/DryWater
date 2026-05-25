import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/property.dart';

part 'property_dto.freezed.dart';

/// DTO de propiedad recibido desde FastAPI.
///
/// Contrato único oficial:
/// - id
/// - title
/// - description
/// - price
/// - currency
/// - operation_type
/// - property_type
/// - zone
/// - image_url
/// - images
/// - amenities
@freezed
class PropertyDto with _$PropertyDto {
  const PropertyDto._();

  const factory PropertyDto({
    required String id,
    required String title,
    required String description,
    required double price,
    required String currency,
    required String operationType,
    required String propertyType,
    required String zone,
    required String imageUrl,
    required List<String> imageUrls,
    required List<String> amenities,
  }) = _PropertyDto;

  factory PropertyDto.fromJson(Map<String, dynamic> json) {
    final imageUrl = _readRequiredString(json, 'image_url');
    final images = _readStringList(json['images']);

    return PropertyDto(
      id: _readRequiredString(json, 'id'),
      title: _readRequiredString(json, 'title'),
      description: _readRequiredString(json, 'description'),
      price: _readRequiredDouble(json, 'price'),
      currency: _readString(json['currency'], fallback: 'BOB'),
      operationType: _readRequiredString(json, 'operation_type'),
      propertyType: _readRequiredString(json, 'property_type'),
      zone: _readRequiredString(json, 'zone'),
      imageUrl: imageUrl,
      imageUrls: images.isEmpty ? [imageUrl] : images,
      amenities: _readStringList(json['amenities']),
    );
  }

  Property toEntity() {
    return Property(
      id: id,
      title: title,
      description: description,
      price: price,
      currency: currency,
      zone: zone,
      operationType: operationType,
      propertyType: propertyType,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      amenities: amenities,
    );
  }

  static String _readRequiredString(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = _readString(json[key]);

    if (value.isEmpty) {
      throw FormatException('Campo requerido faltante o vacío: $key');
    }

    return value;
  }

  static double _readRequiredDouble(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];

    if (value is num) return value.toDouble();

    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw FormatException('Campo numérico inválido: $key');
    }

    return parsed;
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
