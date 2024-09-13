import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/provider/app_provider.dart';
import 'package:dal_vacation_home/room-booking/rooms_available_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardPropertyAgent extends StatefulWidget {
  const DashboardPropertyAgent({super.key});

  @override
  State<DashboardPropertyAgent> createState() => _DashboardPropertyAgentState();
}

class _DashboardPropertyAgentState extends State<DashboardPropertyAgent> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUserSignedIn =
        context.select((AppProvider value) => value.isUserSignedIn);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Text('Dal Vacation Home - CSCI 5410'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await CognitoManager().signOut();
                context.read<AppProvider>().isUserSignedIn = false;
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
              'Welcome ${isUserSignedIn ? CognitoManager.customUser?.name ?? 'Property Agent' : 'Property Agent'}',
              style: theme.textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RoomsAvailableDashboardView(
                isPropertyAgent: true,
                context: context,
              ),
            ),
          )
        ],
      ),
    );
  }
}
