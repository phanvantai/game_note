import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:game_note/firebase/firestore/user/gn_firestore_user.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../injection_container.dart';
import '../../presentation/app/bloc/app_bloc.dart';
import '../firestore/gn_firestore.dart';

class GNAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  FirebaseAuth get auth => _auth;

  User? get currentUser => _auth.currentUser;

  GNAuth() {
    // Listen to auth state changes
    _auth.authStateChanges().listen(
      (User? user) {
        if (kDebugMode) {
          print('Auth state changed: ${user?.uid}');
        }
        getIt<AppBloc>().add(user != null
            ? const AuthStatusChanged(AppStatus.authenticated)
            : const AuthStatusChanged(AppStatus.unknown));

        // create user in Firestore if not exists
        if (user != null) {
          getIt<GNFirestore>().createUserIfNeeded(user);
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
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();
    if (googleSignInAccount == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    return _auth.signInWithCredential(credential);
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
}
