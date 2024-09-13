import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/chatbot/chat_message.dart';
import 'package:dal_vacation_home/provider/app_provider.dart';
import 'package:dal_vacation_home/provider/chat_provider.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class DialogFlowView extends StatefulWidget {
  final DialogAuthCredentials? dialogAuthCredentials;
  const DialogFlowView({super.key, required this.dialogAuthCredentials});

  @override
  State<DialogFlowView> createState() => _DialogFlowViewState();
}

class _DialogFlowViewState extends State<DialogFlowView> {
  // message text controller
  final TextEditingController _textController = TextEditingController();

  // list of messages that will be displayed on the screen
  List<ChatMessage> _messages = <ChatMessage>[];

  DialogFlowtter? dialogFlowtterInstance;

  QueryInput queryInput = QueryInput(
    text: TextInput(
      text: "Hi",
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initDialogFlowInstance();
    });
  }

  @override
  void dispose() {
    dialogFlowtterInstance?.dispose();
    super.dispose();
  }

  void initDialogFlowInstance() {
    try {
      DialogAuthCredentials? dialogAuthCredentials =
          widget.dialogAuthCredentials;

      if (dialogAuthCredentials != null) {
        context.read<AppProvider>().dialogFlowCreds =
            widget.dialogAuthCredentials;

        dialogFlowtterInstance = DialogFlowtter(
            projectId: "csci5410-groupproject",
            credentials: dialogAuthCredentials,
            sessionId: "guest");

        // Getting any previous conversations from the current session
        _messages = context.read<ChatProvider>().messages;
        UserType userType =
            CognitoManager.customUser?.userType ?? UserType.customer;

        if (_messages.isEmpty) {
          ChatMessage botMessage = ChatMessage(
            text: userType == UserType.customer
                ? '''
				Hi, you can ask the following questions:
				- How do I register?
				- What is the duration of my stay?
				- Types of rooms?
				- Room availability?
				- I have other concerns.
				- I need to speak to a property agent.'''
                : '''
        Hi, you can ask the following questions:
        - How do I register?
        - How do I add a room?
        - How do I edit a room?
        - How do I view tickets?
        ''',
            name: "Bot",
            type: false,
          );
          _messages.insert(0, botMessage);
        }
        setState(() {});
        // sendInputToBot();
      } else {
        throw Exception("Dialog Flow Auth Creds is Null");
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> addBotMessage(DetectIntentResponse response) async {
    List<Message> messages = response.queryResult?.fulfillmentMessages ?? [];

    for (Message message in messages) {
      String text = (message.text?.text ?? [])[0];

      if (text.isNotEmpty) {
        ChatMessage botMessage = ChatMessage(
          text: text,
          name: "Bot",
          type: false,
        );
        _messages.insert(0, botMessage);
        setState(() {});
      }
    }
  }

  Future<void> sendInputToBot() async {
    DetectIntentResponse response = await dialogFlowtterInstance!.detectIntent(
      queryInput: queryInput,
    );

    await addBotMessage(response);
  }

  void handleSubmitted(text) async {
    _textController.clear();

    ChatMessage message = ChatMessage(
      text: text,
      name: "You",
      type: true,
    );
    _messages.insert(0, message);
    queryInput = QueryInput(
      text: TextInput(
        text: text,
      ),
    );
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 100));

    // callling dialogflow api
    sendInputToBot();
    focusNode.requestFocus();
  }

  FocusNode focusNode = FocusNode();

  bool isFirstTime = true;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(
          width: 1.0, // Adjust border width as needed
        ),
      ),
      child: ClipRRect(
        child: SizedBox(
          height: size.height * 0.8,
          width: 400,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: theme.primaryColor,
              title: const Text(
                "DALVacationHome ChatBot",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    context.read<AppProvider>().isChatOpen = false;
                  },
                )
              ],
            ),
            body: Column(
              children: [
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    reverse: true,
                    itemBuilder: (ctx, int index) => _messages[index],
                    itemCount: _messages.length,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: theme.primaryColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15)
                          .copyWith(top: 0),
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: TextField(
                          autofocus: true,
                          focusNode: focusNode,
                          controller: _textController,
                          onSubmitted: handleSubmitted,
                          decoration: const InputDecoration.collapsed(
                              hintText: "Send a message"),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () =>
                              handleSubmitted(_textController.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
