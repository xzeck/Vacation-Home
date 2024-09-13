import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/foundation.dart';

class AppProvider extends ChangeNotifier {
  late DialogAuthCredentials? _dialogFlowCreds;
  DialogAuthCredentials? get dialogFlowCreds => _dialogFlowCreds;
  set dialogFlowCreds(DialogAuthCredentials? value) {
    _dialogFlowCreds = value;
    notifyListeners();
  }

  bool _isChatOpen = false;
  bool get isChatOpen => _isChatOpen;
  set isChatOpen(bool value) {
    _isChatOpen = value;
    notifyListeners();
  }

  bool _isUserSignedIn = false;
  bool get isUserSignedIn => _isUserSignedIn;
  set isUserSignedIn(bool value) {
    _isUserSignedIn = value;
    notifyListeners();
  }

  bool _isShowChatBot = true;
  bool get isShowChatBot => _isShowChatBot;
  set isShowChatBot(bool value) {
    _isShowChatBot = value;
    notifyListeners();
  }

  void hideChatBot() {
    isShowChatBot = false;
    isChatOpen = false;
  }

  void showChatBot() {
    isShowChatBot = true;
  }
}
