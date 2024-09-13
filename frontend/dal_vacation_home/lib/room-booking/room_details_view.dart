import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/commands/rooms_commands.dart';
import 'package:dal_vacation_home/models/room.dart';
import 'package:dal_vacation_home/utils.dart';
import 'package:flutter/material.dart';

class RoomDetailsView extends StatefulWidget {
  const RoomDetailsView({super.key, required this.room});
  final Room room;

  @override
  State<RoomDetailsView> createState() => _RoomDetailsViewState();
}

class _RoomDetailsViewState extends State<RoomDetailsView> {
  late Room room;
  bool isLoading = false;
  DateTime checkInDate = DateTime.now();
  DateTime checkOutDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    room = widget.room;
  }

  Future<void> bookRoom(Room room) async {
    try {
      List<DateTime> bookedDates = List.from(room.bookedDates);
      for (DateTime date = checkInDate;
          date.isBefore(checkOutDate);
          date = date.add(const Duration(days: 1))) {
        bookedDates.add(date);
      }
      if ((await Rooms.bookRoom(
          context, room, checkInDate, checkOutDate, bookedDates))) {
        showInSnackBar('Room booked successfully', context);
      }
    } on CognitoServiceException catch (e) {
      showInSnackBar(e.message, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Details'),
      ),
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
              child: ListView(
                children: [
                  Center(
                    child: SizedBox(
                      width: size.width * 0.5,
                      height: size.width * 0.5 * 9 / 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(room.image, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ReadOnlyTextField(
                          theme: theme,
                          title: 'Room Number',
                          text: room.roomId.toString(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ReadOnlyTextField(
                          theme: theme,
                          title: 'Room Type',
                          text: room.roomType.name,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ReadOnlyTextField(
                          theme: theme,
                          title: 'Price',
                          text: '\$${room.price}',
                        ),
                      ),
                    ],
                  ),
                  if (room.discount != 0) ...[
                    const SizedBox(height: 16),
                    ReadOnlyTextField(
                      theme: theme,
                      title: 'Discount',
                      text: '${room.discount}%',
                    ),
                  ],
                  if (room.facilities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Facilities',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: room.facilities
                          .map((facility) => Chip(
                                label: Text(facility),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) {
                          bool isBooking = false;

                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: const Text('Book Room'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Check In Date'),
                                    TextFormField(
                                      readOnly: true,
                                      controller: TextEditingController(
                                        text: checkInDate
                                            .toIso8601String()
                                            .substring(0, 10),
                                      ),
                                      onTap: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                          context: context,
                                          selectableDayPredicate: (day) {
                                            for (DateTime bookedDate
                                                in room.bookedDates) {
                                              if (bookedDate.year == day.year &&
                                                  bookedDate.month ==
                                                      day.month &&
                                                  bookedDate.day == day.day) {
                                                return false;
                                              }
                                            }
                                            return true;
                                          },
                                          initialDate: checkInDate,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now()
                                              .add(const Duration(days: 365)),
                                        );
                                        if (picked != null &&
                                            picked != checkInDate) {
                                          setState(() {
                                            checkInDate = picked;
                                            checkOutDate = checkInDate
                                                .add(const Duration(days: 1));
                                          });
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Check In Date',
                                        suffix: Icon(Icons.calendar_today),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('Check Out Date'),
                                    TextFormField(
                                      readOnly: true,
                                      controller: TextEditingController(
                                        text: checkOutDate
                                            .toIso8601String()
                                            .substring(0, 10),
                                      ),
                                      onTap: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                          context: context,
                                          selectableDayPredicate: (day) {
                                            for (DateTime bookedDate
                                                in room.bookedDates) {
                                              if (bookedDate.year == day.year &&
                                                  bookedDate.month ==
                                                      day.month &&
                                                  bookedDate.day == day.day) {
                                                return false;
                                              }
                                            }
                                            return true;
                                          },
                                          initialDate: checkOutDate,
                                          firstDate: checkOutDate,
                                          lastDate: DateTime.now()
                                              .add(const Duration(days: 365)),
                                        );
                                        if (picked != null &&
                                            picked != checkOutDate) {
                                          setState(() {
                                            checkOutDate = picked;
                                          });
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Check Out Date',
                                        suffix: Icon(Icons.calendar_today),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: isBooking
                                        ? null
                                        : () async {
                                            isBooking = true;
                                            setState(() {});
                                            await bookRoom(room);
                                            isBooking = false;
                                            setState(() {});
                                            Navigator.of(context).pop();
                                          },
                                    child: Text(isBooking
                                        ? 'Confirming...'
                                        : 'Confirm Booking'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    child: Container(
                      width: size.width * 0.3,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Book Now',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text('Feedbacks',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Theme.of(context).primaryColor)),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: room.feedbacks.length,
                    itemBuilder: (context, index) {
                      return Card(
                        shape: const RoundedRectangleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      child: Text(
                                          room.feedbacks[index].username[0]),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          room.feedbacks[index].username,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          room.feedbacks[index].feedbackDate
                                              .toIso8601String()
                                              .substring(0, 10),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                        'Rating: ${room.feedbacks[index].rating}'),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.star,
                                        color: Colors.yellow),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(room.feedbacks[index].feedback),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReadOnlyTextField extends StatelessWidget {
  const ReadOnlyTextField({
    super.key,
    required this.theme,
    required this.text,
    required this.title,
  });

  final ThemeData theme;
  final String text;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextFormField(
          initialValue: StringUtils.capitalize(text),
          decoration: InputDecoration(
            fillColor: Colors.grey.shade200,
            filled: true,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
          ),
          readOnly: true,
        ),
      ],
    );
  }
}
