import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/domain/repositories/esport/esport_chat_repository.dart';
import 'package:game_note/domain/repositories/user_repository.dart';

import '../../../../firebase/firestore/esport/chat/gn_esport_message.dart';
import '../../../../service/user_cache.dart';

part 'esport_chat_event.dart';
part 'esport_chat_state.dart';

class EsportChatBloc extends Bloc<EsportChatEvent, EsportChatState> {
  final EsportChatRepository _chatRepository;
  final UserRepository _userRepository;
  final UserCache _userCache = UserCache();
  EsportChatBloc(this._chatRepository, this._userRepository)
      : super(const EsportChatState()) {
    on<SendEsportMessageEvent>(_onSendMessage);
    on<NewMessagesReceived>(_onNewMessagesReceived);

    _messagesSubscription =
        _chatRepository.getMessages().listen((messages) async {
      List<GNEsportMessage> newMessages = [];
      for (var message in messages) {
        final userId = message.userId;
        if (!_userCache.containsUser(userId)) {
          final user = await _userRepository.getUser(userId);
          if (user != null) {
            _userCache.addUser(user);
          }
        }
        newMessages.add(message.copyWith(user: _userCache.getUser(userId)));
      }
      add(NewMessagesReceived(newMessages));
    });
  }

  StreamSubscription<List<GNEsportMessage>>? _messagesSubscription;

  void _onSendMessage(
      SendEsportMessageEvent event, Emitter<EsportChatState> emit) async {
    try {
      await _chatRepository.sendMessage(event.message);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      emit(state.copyWith(error: 'Không gửi được tin nhắn'));
    }
  }

  void _onNewMessagesReceived(
      NewMessagesReceived event, Emitter<EsportChatState> emit) {
    emit(state.copyWith(messages: event.messages));
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
