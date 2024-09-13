import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/chatbot/chat_message.dart';
import 'package:dal_vacation_home/models/ticket.dart';
import 'package:dal_vacation_home/provider/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TicketQueryChat extends StatefulWidget {
  const TicketQueryChat({super.key});

  @override
  State<TicketQueryChat> createState() => _TicketQueryChatState();
}

class _TicketQueryChatState extends State<TicketQueryChat> {
  final ValueNotifier<Ticket?> _selectedTicketNotifier =
      ValueNotifier<Ticket?>(null);
  final TextEditingController _messageController = TextEditingController();
  final bool isPropertyAgent =
      CognitoManager.customUser?.userType == UserType.propertyAgent;

  void _sendMessage() {
    if (_selectedTicketNotifier.value != null &&
        _messageController.text.isNotEmpty) {
      final message = {
        'message': _messageController.text,
        'email': CognitoManager.customUser?.email,
        'name': CognitoManager.customUser?.name,
      };

      FirebaseFirestore.instance
          .collection(_selectedTicketNotifier.value!.ticketNumber.toString())
          .doc('messages')
          .update({
        'messages': FieldValue.arrayUnion([message])
      });

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // back button
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            context.read<AppProvider>().showChatBot();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Text(
                        isPropertyAgent ? 'Tickets received' : 'Queries raised',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: isPropertyAgent
                          ? FirebaseFirestore.instance
                              .collection(
                                  CognitoManager.customUser?.email ?? '')
                              .doc('tickets')
                              .snapshots()
                          : FirebaseFirestore.instance
                              .collection('queries')
                              .doc(CognitoManager.customUser?.email ?? '')
                              .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Error fetching data'),
                          );
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Center(
                            child: Text('No messages found'),
                          );
                        }

                        List<Ticket> tickets =
                            (snapshot.data!.get('tickets') as List<dynamic>)
                                .map((e) {
                          return Ticket.fromJson(e);
                        }).toList();

                        return ListView.builder(
                          itemCount: tickets.length,
                          itemBuilder: (BuildContext context, int index) {
                            return GestureDetector(
                              onTap: () {
                                _selectedTicketNotifier.value = tickets[index];
                              },
                              child: ValueListenableBuilder<Ticket?>(
                                valueListenable: _selectedTicketNotifier,
                                builder: (context, selectedTicket, child) {
                                  return Card(
                                    shape: const RoundedRectangleBorder(),
                                    color: selectedTicket?.ticketNumber ==
                                            tickets[index].ticketNumber
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.2)
                                        : null,
                                    child: ListTile(
                                      selected: selectedTicket?.ticketNumber ==
                                          tickets[index].ticketNumber,
                                      title: Text(
                                          'Ticket Id: ${tickets[index].ticketNumber}'),
                                      subtitle: Text(isPropertyAgent
                                          ? '${tickets[index].message}\nUser: ${tickets[index].customerName}'
                                          : '${tickets[index].message}\nAgent: ${tickets[index].agentName}'),
                                      trailing: const Icon(
                                          Icons.chevron_right_outlined),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: ValueListenableBuilder<Ticket?>(
              valueListenable: _selectedTicketNotifier,
              builder: (context, selectedTicket, child) {
                if (selectedTicket == null) {
                  return const Center(
                      child: Text('Select a ticket to view messages'));
                } else {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(selectedTicket.ticketNumber.toString())
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error fetching data'),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        FirebaseFirestore.instance
                            .collection(selectedTicket.ticketNumber.toString())
                            .doc('messages')
                            .set({
                          'messages': [
                            {
                              'message': 'Hello, how can I help you?',
                              'email': selectedTicket.agentEmail,
                              'name': selectedTicket.agentName,
                            },
                          ],
                        });
                      }

                      var messages = (snapshot.data?.docs[0].get('messages')
                          as List<dynamic>);
                      messages = messages.reversed.toList();

                      return Column(
                        children: [
                          Card(
                            shape: const RoundedRectangleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              color: Colors.grey[200],
                              width: double.infinity,
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Ticket Details',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall),
                                      BoldTitleText(
                                        title: 'Ticket Id: ',
                                        text: selectedTicket.ticketNumber
                                            .toString(),
                                      ),
                                      BoldTitleText(
                                        title: 'Issue: ',
                                        text: selectedTicket.message,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              reverse: true,
                              itemBuilder: (ctx, int index) {
                                var data = messages[index];
                                return ChatMessage(
                                  text: data['message'],
                                  name: data['name'],
                                  type: data['email'] ==
                                      CognitoManager.customUser?.email,
                                );
                              },
                              itemCount: messages.length,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    maxLines: null,
                                    minLines: 1,
                                    controller: _messageController,
                                    onSubmitted: (v) => _sendMessage(),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Type a message',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: _sendMessage,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BoldTitleText extends StatelessWidget {
  const BoldTitleText({
    super.key,
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        text: title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
        children: <TextSpan>[
          TextSpan(
            text: text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
