import 'package:clock/clock.dart';
import 'package:firebase_admin_sdk/firebase_admin.dart';
import 'package:firebase_admin_sdk/src/auth/credential.dart';
import 'package:jose/jose.dart';

import '../utils/validator.dart' as validator;

/// Class for generating different types of Firebase Auth tokens (JWTs).
class FirebaseTokenGenerator {
  final App app;

  static FirebaseTokenGenerator Function(App app) factory =
      (app) => FirebaseTokenGenerator(app);

  FirebaseTokenGenerator(this.app);

  Certificate get certificate =>
      (app.options.credential as ServiceAccountCredential).certificate;

  // List of blacklisted claims which cannot be provided when creating a custom token
  static const blacklistedClaims = [
    'acr',
    'amr',
    'at_hash',
    'aud',
    'auth_time',
    'azp',
    'cnf',
    'c_hash',
    'exp',
    'iat',
    'iss',
    'jti',
    'nbf',
    'nonce',
  ];

  // Audience to use for Firebase Auth Custom tokens
  static const String firebaseAudience =
      'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit';

  /// Creates a new Firebase Auth Custom token.
  Future<String> createCustomToken(
      String uid, Map<String, dynamic> developerClaims) async {
    if (!validator.isUid(uid)) {
      throw FirebaseAuthError.invalidArgument(
          'First argument to createCustomToken() must be a non-empty string uid.');
    }

    for (var key in developerClaims.keys) {
      if (blacklistedClaims.contains(key)) {
        throw FirebaseAuthError.invalidArgument(
            'Developer claim "$key" is reserved and cannot be specified.');
      }
    }

    final DateTime iat = clock.now();
    final Map<String, dynamic> claims = {
      'aud': firebaseAudience,
      'iat': iat.millisecondsSinceEpoch ~/ 1000,
      'exp': iat.add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      'iss': certificate.clientEmail,
      'sub': certificate.clientEmail,
      'uid': uid,
      ...developerClaims
    };

    final JsonWebSignatureBuilder builder = JsonWebSignatureBuilder()
      ..jsonContent = claims
      ..setProtectedHeader('typ', 'JWT')
      ..addRecipient(certificate.privateKey, algorithm: 'RS256');

    return builder.build().toCompactSerialization();
  }
}
