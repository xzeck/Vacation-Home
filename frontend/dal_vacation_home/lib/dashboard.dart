import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/provider/app_provider.dart';
import 'package:dal_vacation_home/room-booking/rooms_available_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:provider/provider.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUserSignedIn =
        context.select((AppProvider value) => value.isUserSignedIn);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Text('Dal Vacation Home - CSCI 5410'),
        actions: [
          if (isUserSignedIn)
            Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await CognitoManager().signOut();
                  context.read<AppProvider>().isUserSignedIn = false;
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: IconButton(
                icon: const Row(
                  children: [
                    Icon(Icons.login),
                    Text(
                      'Login',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              'Welcome ${isUserSignedIn ? CognitoManager.customUser?.name ?? 'Guest' : 'Guest'}',
              style: theme.textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RoomsAvailableDashboardView(
                isPropertyAgent: false,
                context: context,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
