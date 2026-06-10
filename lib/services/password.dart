import 'dart:convert';
import 'package:crypto/crypto.dart';

// Passwords are stored as 'sha256:<hash>' salted with workspace + username.
// Legacy plaintext values still verify (and are upgraded on first login),
// so no existing account breaks.
const _prefix = 'sha256:';

String _hash(String password, String salt) => sha256.convert(utf8.encode('$salt:$password')).toString();

String encodePassword(String password, String salt) => '$_prefix${_hash(password, salt)}';

bool isHashed(String stored) => stored.startsWith(_prefix);

bool verifyPassword(String input, String stored, String salt) {
  if (isHashed(stored)) return stored == encodePassword(input, salt);
  return stored == input; // legacy plaintext
}
