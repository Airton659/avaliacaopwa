import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHelper {
  /// Gera um hash SHA-256 da senha.
  static String hashPassword(String password) {
    if (password.isEmpty) return '';
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifica se a senha corresponde ao hash armazenado.
  /// Suporta verificação de legado (senha em texto plano) para migração suave.
  static bool checkPassword(String inputPassword, String? storedPassword) {
    if (storedPassword == null || storedPassword.isEmpty) return false;
    
    // 1. Verificar Hash
    final inputHash = hashPassword(inputPassword);
    if (inputHash == storedPassword) {
      return true;
    }

    // 2. Fallback para legado (Texto Plano) - Caso a senha no banco não esteja hashada ainda
    if (inputPassword == storedPassword) {
      return true;
    }

    return false;
  }
}
