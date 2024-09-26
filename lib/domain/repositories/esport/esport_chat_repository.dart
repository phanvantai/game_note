import '../../../firebase/firestore/esport/chat/gn_esport_message.dart';

abstract class EsportChatRepository {
  Future<void> sendMessage(String message);
  Stream<List<GNEsportMessage>> getMessages();
  Future<void> deleteMessage(GNEsportMessage message);
}
