import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GNAuth {
  final FirebaseAuth _auth;
  final Future<void>? _googleSignInInitialized;
  final Future<GoogleSignInAuthentication> Function()? _googleAuthenticate;
  final bool _isWebForTesting;
  static const _googleWebClientId =
      '256841801977-drek49bb40r0be92722cp4iuoah8mtni.apps.googleusercontent.com';

  FirebaseAuth get auth => _auth;

  User? get currentUser => _auth.currentUser;

  bool get isSignInWithEmailAndPassword => _isSignInWithEmailAndPassword;

  bool _isSignInWithEmailAndPassword = false;

  GNAuth({
    FirebaseAuth? auth,
    bool? isWebForTesting,
    Future<void> Function()? googleSignInInitialized,
    Future<void> Function()? googleSignInInitializer,
    Future<GoogleSignInAuthentication> Function()? googleAuthenticate,
  }) : _isWebForTesting = isWebForTesting ?? kIsWeb,
       _auth = auth ?? FirebaseAuth.instance, // coverage:ignore-line
       _googleSignInInitialized =
           (((isWebForTesting ?? kIsWeb) == false &&
                   (googleSignInInitializer ?? googleSignInInitialized) != null)
               ? (googleSignInInitializer ?? googleSignInInitialized)!()
               : null) ??
           (((isWebForTesting ?? kIsWeb) == false && googleAuthenticate == null)
               ? _initializeGoogleSignIn() // coverage:ignore-line
               : null),
       _googleAuthenticate = googleAuthenticate {
    if (!_isWebForTesting &&
        googleSignInInitialized == null &&
        googleSignInInitializer == null &&
        googleAuthenticate == null) {
      // coverage:ignore-start
      if (kDebugMode) {
        print(
          '🔧 GNAuth: Initializing Google Sign-In with $_googleWebClientId',
        );
      }
      // coverage:ignore-end
    }
  }

  // coverage:ignore-start
  static Future<void> _initializeGoogleSignIn() {
    return GoogleSignIn.instance
        .initialize(serverClientId: _googleWebClientId)
        .then((_) {});
  }
  // coverage:ignore-end

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    if (kDebugMode) {
      print('🔗 GNAuth: Starting Google Sign-In...');
    }

    try {
      if (_isWebForTesting) {
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      }

      final googleSignInInitialized = _googleSignInInitialized;
      if (googleSignInInitialized != null) {
        await googleSignInInitialized;
      }

      final GoogleSignInAuthentication googleSignInAuthentication;
      if (_googleAuthenticate != null) {
        if (kDebugMode) {
          print('🔧 GNAuth: Using test/google authenticate callback');
        }
        googleSignInAuthentication = await _googleAuthenticate();
      } else {
        googleSignInAuthentication =
            await _defaultGoogleAuthenticate(); // coverage:ignore-line
      }

      if (kDebugMode) {
        print('🎫 GNAuth: Tokens received');
        print(
          '   - ID Token: ${googleSignInAuthentication.idToken != null ? "✅" : "❌"}',
        );

        if (googleSignInAuthentication.idToken == null) {
          print('⚠️ GNAuth: Missing ID token!');
        }
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
      );

      if (kDebugMode) {
        print('🔐 GNAuth: Firebase credential created, signing in...');
      }

      final result = await _auth.signInWithCredential(credential);
      if (kDebugMode) {
        print('🎉 GNAuth: Firebase sign-in successful!');
        print('👤 User UID: ${result.user?.uid}');
      }
      return result;
    } on GoogleSignInException catch (e) {
      // v7's Android plugin maps several Credential Manager errors
      // (NoCredentialException, GetCredentialUnknownException, ...) to
      // `canceled`. Always log the full description so config issues
      // (SHA-1, serverClientId, OAuth consent screen) don't hide as
      // "user cancelled".
      if (kDebugMode) {
        print('❌ GNAuth: GoogleSignInException');
        print('   - Code: ${e.code}');
        print('   - Description: ${e.description}');
        print('   - Details: ${e.details}');
      }
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // Heuristic: a real cancellation has no description. Anything else
        // is a config/runtime error misreported as cancellation.
        final desc = e.description?.trim() ?? '';
        if (desc.isEmpty) {
          if (kDebugMode) {
            print('🚫 GNAuth: Google Sign-In cancelled by user');
          }
          throw FirebaseAuthException(
            code: 'ERROR_ABORTED_BY_USER',
            message: 'Sign in aborted by user',
          );
        }
        if (kDebugMode) {
          print(
            '⚠️ GNAuth: code=canceled but has description → likely config error, not real cancel',
          );
        }
      }
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('🔥 GNAuth: Firebase Auth Exception:');
        print('   - Code: ${e.code}');
        print('   - Message: ${e.message}');
        print('   - Plugin: ${e.plugin}');
      }
      // Web signInWithPopup throws these when the user closes/blocks the popup.
      // Normalise to the same code native flow uses so callers handle uniformly.
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('❌ GNAuth: General exception during Google Sign-In:');
        print('   - Type: ${e.runtimeType}');
        print('   - Message: $e');
      }
      rethrow;
    }
  }

  // coverage:ignore-start
  static Future<GoogleSignInAuthentication> _defaultGoogleAuthenticate() async {
    final googleSignInAccount = await GoogleSignIn.instance.authenticate();
    if (kDebugMode) {
      print('✅ GNAuth: Google account selected: ${googleSignInAccount.email}');
      print('🔑 GNAuth: Getting authentication tokens...');
    }
    return googleSignInAccount.authentication;
  }
  // coverage:ignore-end

  // sign in with apple
  Future<UserCredential> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    return _auth.signInWithProvider(appleProvider);
  }

  // create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  // sign out
  Future<void> signOut() => _auth.signOut();

  void checkLoginMethod() {
    final user = _auth.currentUser;
    _isSignInWithEmailAndPassword =
        user?.providerData.any((p) => p.providerId == 'password') ?? false;
  }

  // change password
  Future<void> changePassword(String oldPassword, String newPassword) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        // reauthenticate
        final AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      } on FirebaseAuthException catch (_) {
        rethrow;
      } catch (_) {
        rethrow;
      }
    }
  }
}
