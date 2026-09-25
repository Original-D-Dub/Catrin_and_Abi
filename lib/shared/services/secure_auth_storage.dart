import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Backs Supabase's session persistence with the platform Keychain
/// (iOS/macOS) / Keystore-encrypted storage (Android) instead of the
/// SDK's default plain `SharedPreferences`, so the JWT access token and
/// refresh token aren't left in an unencrypted app-data file.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _sessionKey = 'sb-auth-token';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _sessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);
}

/// Backs the PKCE code verifier (generated during Hwb/Azure OAuth sign-in)
/// with the same secure storage, rather than `SharedPreferences`.
class SecurePkceStorage extends GotrueAsyncStorage {
  SecurePkceStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: key);
}
