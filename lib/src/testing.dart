import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:firebase_admin_sdk/src/auth/credential.dart';
import 'package:firebase_admin_sdk/src/auth/token_verifier.dart';
import 'package:firebase_admin_sdk/firebase_admin.dart';
import 'package:firebase_admin_sdk/src/app.dart';
import 'package:jose/jose.dart';
import 'package:openid_client/openid_client.dart' hide Credential;

class ServiceAccountMockCredential extends ServiceAccountCredential
    with MockCredentialMixin {
  ServiceAccountMockCredential()
      : super.fromJson({
          'type': 'service_account',
          'project_id': 'project_id',
          'private_key_id': 'aaaaaaaaaabbbbbbbbbbccccccccccdddddddddd',
          'private_key': '',
          'client_email': 'foo@project_id.iam.gserviceaccount.com',
          'client_id': 'client_id'
        });

  @override
  AccessToken Function() get tokenFactory {
    return () {
      return MockAccessToken.fromJson(<String, dynamic>{
        'access_token': (JsonWebSignatureBuilder()
              ..content = JsonWebTokenClaims.fromJson(
                <String, String>{'sub': 'mock-user', 'provider_id': 'testing'},
              ).toJson()
              ..addRecipient(certificate.privateKey, algorithm: 'RS256'))
            .build()
            .toCompactSerialization(),
        'expires_in': 3600,
      });
    };
  }
}

class MockCredential extends Credential with MockCredentialMixin {
  @override
  final AccessToken Function() tokenFactory;

  MockCredential([this.tokenFactory = MockCredentialMixin.defaultFactory]);
}

mixin MockCredentialMixin on Credential {
  AccessToken Function() get tokenFactory;

  static AccessToken defaultFactory() {
    return MockAccessToken.fromJson(<String, dynamic>{
      'access_token': 'mock-access-token',
      'expires_in': 3600,
    });
  }

  int _callCount = 0;

  static int getCallCount(App app) {
    return (app.internals.credential as MockCredentialMixin)._callCount;
  }

  static void resetCallCount(App app) {
    (app.internals.credential as MockCredentialMixin)._callCount = 0;
  }

  @override
  Future<AccessToken> getAccessToken() async {
    _callCount++;
    return tokenFactory();
  }
}

class MockTokenVerifier extends FirebaseTokenVerifier {
  MockTokenVerifier(super.app);

  @override
  Future<Client> getOpenIdClient() async {
    final Map<String, dynamic> config = <String, dynamic>{
      'issuer': 'https://securetoken.google.com/project_id',
      'jwks_uri': Uri.dataFromString(
        json.encode(<String, dynamic>{
          'keys': [
            <String, dynamic>{
              'kty': 'RSA',
              'n':
                  'wJENcRev-eXZKvhhWLiV3Lz2MvO-naQRHo59g3vaNQnbgyduN_L4krlrJ5c6FiikXdtJNb_QrsAHSyJWCu8j3T9CruiwbidGAk2W0RuViTVspjHUTsIHExx9euWM0UomGvYkoqXahdhPL_zViVSJt-Rt8bHLsMvpb8RquTIb9iKY3SMV2tCofNmyCSgVbghq_y7lKORtV_IRguWs6R22fbkb0r2MCYoNAbZ9dqnbRIFNZBC7itYtUoTEresRWcyFMh0zfAIJycWOJlVLDLqkY2SmIx8u7fuysCg1wcoSZoStuDq02nZEMw1dx8HGzE0hynpHlloRLByuIuOAfMCCYw',
              'e': 'AQAB',
              'alg': 'RS256',
              'kid': 'aaaaaaaaaabbbbbbbbbbccccccccccdddddddddd',
            }
          ]
        }),
        mimeType: 'application/json',
      ).toString(),
      'response_types_supported': ['id_token'],
      'subject_types_supported': ['public'],
      'id_token_signing_alg_values_supported': ['RS256'],
    };

    final Issuer issuer = Issuer(OpenIdProviderMetadata.fromJson(config));
    return Client(issuer, projectId);
  }
}

class MockAccessToken implements AccessToken {
  @override
  final String accessToken;

  @override
  final DateTime expirationTime;

  MockAccessToken({required this.accessToken, required Duration expiresIn})
      : expirationTime = clock.now().add(expiresIn);

  MockAccessToken.fromJson(Map<String, dynamic> json)
      : this(
          accessToken: json['access_token'],
          expiresIn: Duration(seconds: json['expires_in']),
        );
}
