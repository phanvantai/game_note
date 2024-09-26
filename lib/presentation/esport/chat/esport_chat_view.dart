import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/presentation/esport/chat/bloc/esport_chat_bloc.dart';
import 'package:game_note/widgets/gn_circle_avatar.dart';
import 'package:intl/intl.dart';

class EsportChatView extends StatefulWidget {
  const EsportChatView({Key? key}) : super(key: key);

  @override
  State<EsportChatView> createState() => _EsportChatViewState();
}

class _EsportChatViewState extends State<EsportChatView> {
  final textController = TextEditingController();
  bool _isShowGuide = true;

  // Toggle the visibility
  void _toggleVisibility() {
    setState(() {
      _isShowGuide = !_isShowGuide;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EsportChatBloc, EsportChatState>(
      builder: (context, state) => Column(
        children: [
          Stack(
            children: [
              Visibility(
                visible: _isShowGuide,
                child: InkWell(
                  onTap: _toggleVisibility,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: const Text(
                      'Chào mừng đến với cộng đồng PES!\nHãy tham gia trao đổi với mọi người bằng cách gửi tin nhắn bên dưới. Kết nối với các thành viên khác và tham gia vào các nhóm để mở rộng cộng đồng PES nhé!',
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
              ),
              // Icon button to show/hide the guide
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: _toggleVisibility,
                  icon: Icon(
                      _isShowGuide ? Icons.expand_less : Icons.expand_more),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              reverse: true,
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final message = state.messages[index];
                return ListTile(
                  leading: GNCircleAvatar(
                    photoUrl: message.user?.photoUrl,
                    size: 32,
                  ),
                  minVerticalPadding: 0,
                  contentPadding: const EdgeInsets.all(0),
                  title: RichText(
                    text: TextSpan(
                        text:
                            '${message.user?.displayName ?? 'Chưa đặt tên'}: ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                              text: message.content,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal)),
                        ]),
                  ),
                  subtitle: Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      hintText: 'Nhập tin nhắn...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      hintStyle: TextStyle(color: Colors.grey[300]),
                    ),
                    onSubmitted: (text) {
                      FocusScope.of(context).unfocus();
                      if (text.isNotEmpty) {
                        context
                            .read<EsportChatBloc>()
                            .add(SendEsportMessageEvent(text));
                        textController.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.indigo[500]),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    final text = textController.text;
                    if (text.isNotEmpty) {
                      context
                          .read<EsportChatBloc>()
                          .add(SendEsportMessageEvent(text));
                      textController.clear();
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
      listener: (context, state) {
        if (state.error.isNotEmpty) {
          showToast(state.error);
        }
      },
    );
  }
}
