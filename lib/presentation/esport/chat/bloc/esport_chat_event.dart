part of 'esport_chat_bloc.dart';

abstract class EsportChatEvent extends Equatable {
  const EsportChatEvent();

  @override
  List<Object?> get props => [];
}

class SendEsportMessageEvent extends EsportChatEvent {
  final String message;

  const SendEsportMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class NewMessagesReceived extends EsportChatEvent {
  final List<GNEsportMessage> messages;

  const NewMessagesReceived(this.messages);

  @override
  List<Object?> get props => [messages];
}
