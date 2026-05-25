import 'package:freezed_annotation/freezed_annotation.dart';

part 'property.freezed.dart';

/// Entidad de dominio para una propiedad.
///
/// Esta clase representa el modelo que usa la UI.
/// No depende directamente del JSON del backend.
@freezed
class Property with _$Property {
  const Property._();

  const factory Property({
    required String id,
    required String title,
    required String description,
    required double price,
    required String currency,
    required String zone,
    required String operationType,
    required String propertyType,
    required String imageUrl,
    required List<String> imageUrls,
    required List<String> amenities,
  }) = _Property;

  /// Getter temporal para no romper pantallas antiguas que usan `zona`.
  String get zona => zone;
}
