import 'package:openid_client/openid_client.dart'
    show Client, IdToken, Credential, Issuer;
import '../../firebase_admin.dart' show App, FirebaseAuthError;
import '../app/app_extension.dart';
import 'package:meta/meta.dart';
import '../utils/validator.dart' as validator;

/// Class for verifying general purpose Firebase JWTs.
///
/// This verifies ID tokens and session cookies.
class FirebaseTokenVerifier {
  final App app;
  final String projectId;

  final String _jwtName = 'ID token';

  static FirebaseTokenVerifier Function(App app) factory =
      (app) => FirebaseTokenVerifier(app);

  FirebaseTokenVerifier(this.app) : projectId = app.projectId;

  /// Verifies the format and signature of a Firebase Auth JWT token.
  Future<IdToken> verifyJwt(String jwtToken) async {
    final Client client = await getOpenIdClient();

    final Credential credential = client.createCredential(idToken: jwtToken);

    await for (Exception e in credential.validateToken()) {
      throw FirebaseAuthError.invalidArgument(
        'Validating $_jwtName failed: $e',
      );
    }

    if (!validator.isUid(credential.idToken.claims.subject)) {
      throw FirebaseAuthError.invalidArgument(
        '$_jwtName has "sub" (subject) claim which is not a valid uid',
      );
    }

    return credential.idToken;
  }

  @visibleForTesting
  Future<Client> getOpenIdClient() async {
    final Issuer issuer = await Issuer.discover(Issuer.firebase(projectId));
    return Client(issuer, projectId);
  }
}
