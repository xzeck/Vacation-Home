import 'package:dal_vacation_home/chatbot/chat_message.dart';
import 'package:flutter/foundation.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  void addMessages(ChatMessage newMessage) {
    _messages.insert(0, newMessage);
    notifyListeners();
  }

  void clearAll() {
    _messages.clear();
    notifyListeners();
  }
}
