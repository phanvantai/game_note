part of 'esport_chat_bloc.dart';

class EsportChatState extends Equatable {
  final List<GNEsportMessage> messages;
  final String error;

  const EsportChatState({
    this.messages = const [],
    this.error = '',
  });

  EsportChatState copyWith({
    List<GNEsportMessage>? messages,
    String? error,
  }) {
    return EsportChatState(
      messages: messages ?? this.messages,
      error: error ?? '',
    );
  }

  @override
  List<Object?> get props => [messages, error];
}
