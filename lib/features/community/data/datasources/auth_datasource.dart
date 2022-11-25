import 'package:firebase_auth/firebase_auth.dart';
import 'package:game_note/core/common/exception.dart';
import 'package:game_note/features/community/domain/entities/user_model.dart';

class AuthDatasource {
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      var abc = credential.user;
      if (abc != null) {
        return UserModel(uid: abc.uid, email: abc.email);
      }
      throw ServerException('User empty');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw ServerException('User not found');
      } else if (e.code == 'wrong-password') {
        throw ServerException('Wrong password provided for that user.');
      } else {
        throw ServerException(e.code);
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<UserModel> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      var abc = credential.user;
      if (abc != null) {
        return UserModel(uid: abc.uid, email: abc.email);
      }
      throw ServerException('User empty');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw ServerException('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw ServerException('The account already exists for that email.');
      } else {
        throw ServerException(e.code);
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<bool> signOut() async {
    await FirebaseAuth.instance.signOut();
    return true;
  }
}
