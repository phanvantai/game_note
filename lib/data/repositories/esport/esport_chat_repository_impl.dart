import 'package:pes_arena/domain/repositories/esport/esport_chat_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/chat/gn_esport_message.dart';
import 'package:pes_arena/firebase/firestore/esport/chat/gn_firestore_esport_message.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/injection_container.dart';

class EsportChatRepositoryImpl implements EsportChatRepository {
  @override
  Stream<List<GNEsportMessage>> getMessages() {
    return getIt<GNFirestore>().listenForNewMessages();
  }

  @override
  Future<void> sendMessage(String message) async {
    final currentUser = getIt<GNFirestore>().currentUser;
    return getIt<GNFirestore>().sendMessage(currentUser.uid, message);
  }

  @override
  Future<void> deleteMessage(GNEsportMessage message) {
    return getIt<GNFirestore>().deleteMessage(message.id);
  }
}
