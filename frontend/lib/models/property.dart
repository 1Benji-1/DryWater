// Archivo temporal de compatibilidad.
//
// Antes la entidad Property vivía en `lib/models/property.dart`.
// En Fase 1 la movimos a features/properties/domain/entities para separar
// dominio de DTOs, pero dejamos este export para no romper imports existentes.
export '../features/properties/domain/entities/property.dart';
