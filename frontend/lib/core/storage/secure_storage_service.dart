import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio central para almacenamiento seguro.
///
/// No guardar aquí service_role keys ni secretos privados.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  Future<void> write({
    required String key,
    required String value,
  }) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  Future<void> clear() {
    return _storage.deleteAll();
  }
}
