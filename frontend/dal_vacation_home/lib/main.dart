import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/chatbot/chat_bot_view.dart';
import 'package:dal_vacation_home/commands/dialog_flow_commands.dart';
import 'package:dal_vacation_home/dashboard.dart';
import 'package:dal_vacation_home/firebase_options.dart';
import 'package:dal_vacation_home/launch.dart';
import 'package:dal_vacation_home/property-agents/dashboard_property_agent.dart';
import 'package:dal_vacation_home/provider/app_provider.dart';
import 'package:dal_vacation_home/provider/chat_provider.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // init dialog_flow auth creds
    DialogAuthCredentials? dialogAuthCredentials =
        await DialogFlowCommands.init();

    // firebase initialization
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    // main entry point of the app
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: MyApp(
          dialogAuthCredentials: dialogAuthCredentials,
        ),
      ),
    );
  } catch (e) {
    log(e.toString());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.dialogAuthCredentials});
  final DialogAuthCredentials? dialogAuthCredentials;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final CognitoManager _cognitoManager;
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    _cognitoManager = CognitoManager();
    _initCognitoManager();
  }

  Future<void> _initCognitoManager() async {
    bool isUserLoggedIn = await _cognitoManager.init();

    context.read<AppProvider>().isUserSignedIn = isUserLoggedIn;
    setState(() {
      initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isChatOpen = context.select((AppProvider ap) => ap.isChatOpen);
    final bool isShowChatBot =
        context.select((AppProvider ap) => ap.isShowChatBot);
    final bool isUserSignedIn =
        context.select((AppProvider ap) => ap.isUserSignedIn);
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Add this line
      title: 'DALVacationHome',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey.shade900,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blueGrey.shade50,
        ),
        primaryColor: Colors.blueGrey.shade900,
        useMaterial3: true,
      ),
      home: initialized
          ? Stack(
              children: [
                Navigator(
                  onGenerateRoute: (settings) {
                    // Define your routes here, e.g.,
                    return MaterialPageRoute(
                        builder: (context) => isUserSignedIn
                            ? CognitoManager.customUser?.userType ==
                                    UserType.propertyAgent
                                ? const DashboardPropertyAgent()
                                : const Dashboard()
                            : const Dashboard());
                  },
                ),
                if (isChatOpen)
                  Positioned(
                    bottom: 80,
                    right: 10,
                    child: DialogFlowView(
                      dialogAuthCredentials: widget.dialogAuthCredentials,
                    ),
                  ),
                if (isShowChatBot)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: SizedBox(
                      height: 50,
                      child: FittedBox(
                        child: FloatingActionButton.extended(
                            icon:
                                const Icon(Icons.chat_bubble_outline_outlined),
                            label: const Text('DALVacationHome Chat Bot'),
                            onPressed: () {
                              context.read<AppProvider>().isChatOpen = !context
                                  .read<AppProvider>()
                                  .isChatOpen; // Toggle chat open/close
                            }),
                      ),
                    ),
                  ),
              ],
            )
          : const LaunchScreen(),
    );
  }
}
