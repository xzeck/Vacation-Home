import 'package:dal_vacation_home/commands/rooms_commands.dart';
import 'package:dal_vacation_home/models/booking.dart';
import 'package:dal_vacation_home/provider/app_provider.dart';
import 'package:dal_vacation_home/room-booking/raise_concern_dialog.dart';
import 'package:flutter/material.dart';
import 'package:dal_vacation_home/models/feedback.dart' as feed;
import 'package:dal_vacation_home/room-booking/feedback_dialog.dart';
import 'package:provider/provider.dart';
import '../commands/feedback_commands.dart';

class UserBookingsView extends StatefulWidget {
  const UserBookingsView({super.key});

  @override
  State<UserBookingsView> createState() => _UserBookingsViewState();
}

class _UserBookingsViewState extends State<UserBookingsView> {
  List<Booking> bookings = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getBookings();
  }

  void getBookings() async {
    setState(() {
      isLoading = true;
    });
    final bookings = await Rooms.getBookings();
    for (Booking booking in bookings) {
      print(booking.feedbacks?.feedback);
    }
    setState(() {
      this.bookings = bookings;
      isLoading = false;
    });
  }

  Future<void> giveFeedback(int index) async {
    final feedback = await showDialog<feed.Feedback>(
      context: context,
      builder: (context) => FeedbackDialog(),
    );

    if (feedback != null) {
      setState(() {
        bookings[index].feedbacks = feedback;
      });
      await FeedbackCommands.addFeedback(context, bookings[index], feedback);
    }
  }

  Future<void> raiseConcern(int index) async {
    await showDialog(
      context: context,
      builder: (context) => RaiseConcernDialog(
          bookingId: bookings[index].bookingNumber.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<AppProvider>().showChatBot();

            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
              ? const Center(child: Text('No bookings found'))
              : ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return ListTile(
                      isThreeLine: true,
                      leading: Image.network(booking.room.image),
                      title: Text('Room Number: ${booking.roomNumber}'),
                      subtitle: SelectableText(
                          'Booking Number: ${booking.bookingNumber}'
                          '\t\t\tTotal Cost: \$${booking.totalCost}'
                          '\nCheck In Date: ${booking.checkInDate.toIso8601String().substring(0, 10)}'
                          '\t\t\tCheck Out Date: ${booking.checkOutDate.toIso8601String().substring(0, 10)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => raiseConcern(index),
                            child: const Text('Raise Query'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: booking.feedbacks != null
                                ? null
                                : () => giveFeedback(index),
                            child: Text(booking.feedbacks != null
                                ? 'Feedback Given'
                                : 'Give Feedback'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
