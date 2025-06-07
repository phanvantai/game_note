import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:game_note/firebase/firestore/user/gn_firestore_user.dart';
import 'package:game_note/service/permission_util.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../injection_container.dart';
import '../../presentation/app/bloc/app_bloc.dart';
import '../firestore/gn_firestore.dart';

class GNAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    // Add explicit client ID configuration
    serverClientId:
        '256841801977-4gk9c14654vco9ivfsj6r94hlem7sj72.apps.googleusercontent.com',
  );

  FirebaseAuth get auth => _auth;

  User? get currentUser => _auth.currentUser;

  bool get isSignInWithEmailAndPassword => _isSignInWithEmailAndPassword;

  bool _isSignInWithEmailAndPassword = false;

  GNAuth() {
    if (kDebugMode) {
      print(
          '🔧 GNAuth: Initializing with server client ID: 256841801977-4gk9c14654vco9ivfsj6r94hlem7sj72.apps.googleusercontent.com');
    }

    // Listen to auth state changes
    _auth.authStateChanges().listen(
      (User? user) async {
        if (kDebugMode) {
          print('Auth state changed: ${user?.uid}');
        }
        getIt<AppBloc>().add(user != null
            ? const AuthStatusChanged(AppStatus.authenticated)
            : const AuthStatusChanged(AppStatus.unknown));

        // create user in Firestore if not exists
        if (user != null) {
          final gnUser = await getIt<GNFirestore>().createUserIfNeeded(user);
          getIt<PermissionUtil>().setCurrentUser(gnUser);
          checkLoginMethod();
        }
      },
      onDone: () {
        if (kDebugMode) {
          print('Auth state changes stream done');
        }
      },
    );
  }

  String _verificationId = '';

  Future<void> verifyPhoneNumber(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Sign in the user with the credential
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        // if (e.code == 'invalid-phone-number') {
        //   if (kDebugMode) {
        //     print('The provided phone number is not valid.');
        //   }
        // }
        if (kDebugMode) {
          print('taipv $e ${e.message}');
        }
        throw e;
      },
      codeSent: (String verificationId, int? resendToken) {
        if (kDebugMode) {
          print(
              'Code sent to $phoneNumber with verificationId: $verificationId and resendToken: $resendToken');
        }
        _verificationId = verificationId;
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (kDebugMode) {
          print('Code auto retrieval timeout');
        }
      },
    );
  }

  Future<UserCredential> signInWithPhoneNumber(String smsCode) async {
    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: smsCode,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kDebugMode) {
      print('🔗 GNAuth: Starting Google Sign-In...');
    }

    try {
      // Check if Google Play Services is available (Android only)
      if (kDebugMode) {
        print('📱 GNAuth: Checking Google Play Services availability...');
        final isAvailable = await googleSignIn.isSignedIn();
        print('🔍 GNAuth: Google Sign-In already signed in: $isAvailable');
      }

      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount == null) {
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
            '✅ GNAuth: Google account selected: ${googleSignInAccount.email}');
        print('🔑 GNAuth: Getting authentication tokens...');
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      if (kDebugMode) {
        print('🎫 GNAuth: Tokens received');
        print(
            '   - Access Token: ${googleSignInAuthentication.accessToken != null ? "✅" : "❌"}');
        print(
            '   - ID Token: ${googleSignInAuthentication.idToken != null ? "✅" : "❌"}');

        if (googleSignInAuthentication.accessToken == null ||
            googleSignInAuthentication.idToken == null) {
          print('⚠️ GNAuth: Missing required tokens!');
        }
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
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
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('🔥 GNAuth: Firebase Auth Exception:');
        print('   - Code: ${e.code}');
        print('   - Message: ${e.message}');
        print('   - Plugin: ${e.plugin}');
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

  // sign in with apple
  Future<UserCredential> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    return _auth.signInWithProvider(appleProvider);
  }

  // create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// sign in with email and password
  /// if user not exists, create new user
  /// return UserCredential
  Future<UserCredential> signInOrCreateUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await signInWithEmailAndPassword(email, password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // create new user
        return createUserWithEmailAndPassword(email, password);
      } else {
        rethrow;
      }
    }
  }

  // sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // sign out
  Future<void> signOut() async {
    // remove fcm token from Firestore
    await getIt<GNFirestore>().removeFcmToken();
    return _auth.signOut();
  }

  void checkLoginMethod() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Get the list of sign-in methods for the current user
      List<UserInfo> providerData = user.providerData;
      for (var provider in providerData) {
        if (provider.providerId == 'password') {
          _isSignInWithEmailAndPassword = true;
        } else {
          _isSignInWithEmailAndPassword = false;
        }
      }
    }
  }

  // change password
  Future<void> changePassword(String oldPassword, String newPassword) async {
    User? user = FirebaseAuth.instance.currentUser;

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
