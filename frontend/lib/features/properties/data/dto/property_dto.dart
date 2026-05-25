import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/property.dart';

part 'property_dto.freezed.dart';

/// DTO de propiedad recibido desde FastAPI.
///
/// Usa Freezed para inmutabilidad, pero el parseo JSON se hace manualmente
/// para soportar tanto el contrato nuevo como campos heredados del CSV.
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
    final normalized = _normalizeJson(json);

    return PropertyDto(
      id: normalized['id'] as String,
      title: normalized['title'] as String,
      description: normalized['description'] as String,
      price: normalized['price'] as double,
      currency: normalized['currency'] as String,
      operationType: normalized['operation_type'] as String,
      propertyType: normalized['property_type'] as String,
      zone: normalized['zone'] as String,
      imageUrl: normalized['image_url'] as String,
      imageUrls: List<String>.from(normalized['image_urls'] as List),
      amenities: List<String>.from(normalized['amenities'] as List),
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

  static Map<String, dynamic> _normalizeJson(Map<String, dynamic> json) {
    final amenities = _readStringList(json['amenities'])
        .ifEmpty(_splitLegacyText(json['amenidades']));

    final images = _readStringList(json['images'])
        .ifEmpty(_readStringList(json['image_urls']))
        .ifEmpty(_splitLegacyText(json['imagenes']))
        .ifEmpty([_readString(json['image_url'] ?? json['imagen_url'])])
        .where((value) => value.isNotEmpty)
        .toList();

    final fallbackImage = images.isNotEmpty
        ? images.first
        : 'https://via.placeholder.com/800x600.png?text=Rent+App';

    final propertyType = _readString(
      json['property_type'] ?? json['tipo_inmueble'],
      fallback: 'Inmueble',
    );

    final zone = _readString(
      json['zone'] ?? json['zona'],
      fallback: 'Sin zona',
    );

    return {
      'id': _readString(json['id'] ?? json['id_inmueble'], fallback: 'N/A'),
      'title': _readString(
        json['title'] ?? json['titulo'],
        fallback: '$propertyType en $zone',
      ),
      'description': _readString(
        json['description'] ?? json['descripcion'],
        fallback: amenities.isEmpty ? 'Sin descripción' : amenities.join(', '),
      ),
      'price': _readDouble(json['price'] ?? json['precio_bs']),
      'currency': _readString(json['currency'], fallback: 'BOB'),
      'operation_type': _readString(
        json['operation_type'] ?? json['tipo_operacion'],
        fallback: 'Alquiler',
      ),
      'property_type': propertyType,
      'zone': zone,
      'image_url': _readString(
        json['image_url'] ?? json['imagen_url'],
        fallback: fallbackImage,
      ),
      'image_urls': images.isEmpty ? [fallbackImage] : images,
      'amenities': amenities,
    };
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<String> _splitLegacyText(Object? value) {
    if (value == null) return [];

    return value
        .toString()
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

extension _ListFallbackExtension<T> on List<T> {
  List<T> ifEmpty(List<T> fallback) {
    return isEmpty ? fallback : this;
  }
}
