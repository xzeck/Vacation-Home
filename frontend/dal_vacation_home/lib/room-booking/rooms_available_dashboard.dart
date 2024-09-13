import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/commands/rooms_commands.dart';
import 'package:dal_vacation_home/models/room.dart';
import 'package:dal_vacation_home/property-agents/add_room.dart';
import 'package:dal_vacation_home/property-agents/lookerstudio_webview.dart';
import 'package:dal_vacation_home/provider/app_provider.dart';
import 'package:dal_vacation_home/room-booking/room_details_view.dart';
import 'package:dal_vacation_home/room-booking/user_bookings_view.dart';
import 'package:dal_vacation_home/tickets-module/ticket_query_chat.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoomsAvailableDashboardView extends StatefulWidget {
  const RoomsAvailableDashboardView(
      {super.key, required this.isPropertyAgent, required this.context});
  final bool isPropertyAgent;
  final BuildContext context;

  @override
  State<RoomsAvailableDashboardView> createState() =>
      _RoomsAvailableDashboardViewState();
}

class _RoomsAvailableDashboardViewState
    extends State<RoomsAvailableDashboardView> {
  bool isLoading = false;
  DateTime checkInDate = DateTime.now();
  DateTime checkOutDate = DateTime.now().add(const Duration(days: 1));
  bool isPropertyAgent = false;
  List<Room> rooms = [];

  @override
  void initState() {
    super.initState();
    isPropertyAgent = widget.isPropertyAgent;
    init();
  }

  void init() async {
    isLoading = true;
    setState(() {});
    rooms = await Rooms.getRooms();
    isLoading = false;
    setState(() {});
  }

  Future<void> bookRoom(Room room) async {
    try {
      List<DateTime> bookedDates = List.from(room.bookedDates);
      for (DateTime date = checkInDate;
          date.isBefore(checkOutDate);
          date = date.add(const Duration(days: 1))) {
        bookedDates.add(date);
      }
      await Rooms.bookRoom(
          context, room, checkInDate, checkOutDate, bookedDates);
    } on CognitoServiceException catch (e) {
      showInSnackBar(e.message, context);
    }
  }

  @override
  BuildContext get context => widget.context;

  @override
  Widget build(BuildContext ctx) {
    final isUserSignedIn = ctx.select((AppProvider ap) => ap.isUserSignedIn);

    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUserSignedIn)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPropertyAgent)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0).copyWith(top: 0.0),
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<AppProvider>().hideChatBot();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LookerstudioWebview(),
                            ),
                          );
                        },
                        child: const Text('View Analytics'),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0).copyWith(top: 0.0),
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AppProvider>().hideChatBot();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TicketQueryChat(),
                          ),
                        );
                      },
                      child: const Text('View Concerns'),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0).copyWith(top: 0.0),
                    child: ElevatedButton(
                      onPressed: isPropertyAgent
                          ? () async {
                              bool isSuccess = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                            title: const Text('Add new room'),
                                            content: AddRoom(
                                              rooms: rooms,
                                            ),
                                          )) ??
                                  false;
                              if (isSuccess) {
                                init();
                              }
                            }
                          : () {
                              context.read<AppProvider>().hideChatBot();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UserBookingsView(),
                                ),
                              );
                            },
                      child: Text(isPropertyAgent
                          ? 'Add new room'
                          : 'View Your Bookings'),
                    ),
                  ),
                ),
              ],
            ),
          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (rooms.isEmpty)
            const Expanded(
              child: Center(
                  child: Text(
                      'No rooms are available at the moment. Please check back later.')),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.start,
                    spacing: 20,
                    runSpacing: 20,
                    children: List.generate(
                      rooms.length,
                      (index) {
                        bool isHovering = false;
                        return StatefulBuilder(builder: (context, ksetState) {
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) {
                              isHovering = true;
                              ksetState(() {});
                            },
                            onExit: (_) {
                              isHovering = false;
                              ksetState(() {});
                            },
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RoomDetailsView(
                                      room: rooms[index],
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                color: isHovering
                                    ? Colors.grey.shade200
                                    : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 16.0),
                                  child: SizedBox(
                                    width: 280,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.network(
                                              rooms[index].image,
                                              height: 200,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        Text(
                                            'Room Number: ${rooms[index].roomId}'),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                            'Room Type: ${rooms[index].roomType.name}'),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text('Price: \$${rooms[index].price}'),
                                        if (isUserSignedIn)
                                          Row(
                                            children: [
                                              const Spacer(),
                                              if (isPropertyAgent)
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    bool isSuccess =
                                                        await showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        AlertDialog(
                                                                          title:
                                                                              const Text('Edit Room'),
                                                                          content:
                                                                              AddRoom(
                                                                            rooms:
                                                                                rooms,
                                                                            room:
                                                                                rooms[index],
                                                                            isEdit:
                                                                                true,
                                                                          ),
                                                                        )) ??
                                                            false;
                                                    if (isSuccess) {
                                                      init();
                                                    }
                                                  },
                                                  child:
                                                      const Text('Edit Room'),
                                                )
                                              else
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    // bookRoom(rooms[index]);
                                                    await showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          bool isBooking =
                                                              false;

                                                          return StatefulBuilder(
                                                              builder: (context,
                                                                  setState) {
                                                            return AlertDialog(
                                                              title: const Text(
                                                                  'Book Room'),
                                                              content: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  const Text(
                                                                      'Check In Date'),
                                                                  TextFormField(
                                                                    readOnly:
                                                                        true,
                                                                    controller: TextEditingController(
                                                                        text: checkInDate
                                                                            .toIso8601String()
                                                                            .substring(0,
                                                                                10)),
                                                                    onTap:
                                                                        () async {
                                                                      final DateTime?
                                                                          picked =
                                                                          await showDatePicker(
                                                                        context:
                                                                            context,
                                                                        selectableDayPredicate:
                                                                            (day) {
                                                                          for (DateTime bookedDate
                                                                              in rooms[index].bookedDates) {
                                                                            if (bookedDate.year == day.year &&
                                                                                bookedDate.month == day.month &&
                                                                                bookedDate.day == day.day) {
                                                                              return false;
                                                                            }
                                                                          }
                                                                          return true;
                                                                        },
                                                                        initialDate:
                                                                            checkInDate,
                                                                        firstDate:
                                                                            DateTime.now(),
                                                                        lastDate:
                                                                            DateTime.now().add(const Duration(days: 365)),
                                                                      );
                                                                      if (picked !=
                                                                              null &&
                                                                          picked !=
                                                                              checkInDate) {
                                                                        setState(
                                                                            () {
                                                                          checkInDate =
                                                                              picked;
                                                                          checkOutDate =
                                                                              checkInDate.add(const Duration(days: 1));
                                                                        });
                                                                      }
                                                                    },
                                                                    decoration: const InputDecoration(
                                                                        hintText:
                                                                            'Check In Date',
                                                                        suffix:
                                                                            Icon(Icons.calendar_today)),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          12),
                                                                  const Text(
                                                                      'Check Out Date'),
                                                                  // make sure that checkout date is only after checkin date
                                                                  TextFormField(
                                                                    readOnly:
                                                                        true,
                                                                    controller: TextEditingController(
                                                                        text: checkOutDate
                                                                            .toIso8601String()
                                                                            .substring(0,
                                                                                10)),
                                                                    onTap:
                                                                        () async {
                                                                      final DateTime?
                                                                          picked =
                                                                          await showDatePicker(
                                                                        context:
                                                                            context,
                                                                        selectableDayPredicate:
                                                                            (day) {
                                                                          for (DateTime bookedDate
                                                                              in rooms[index].bookedDates) {
                                                                            if (bookedDate.year == day.year &&
                                                                                bookedDate.month == day.month &&
                                                                                bookedDate.day == day.day) {
                                                                              return false;
                                                                            }
                                                                          }
                                                                          return true;
                                                                        },
                                                                        initialDate:
                                                                            checkOutDate,
                                                                        firstDate:
                                                                            checkOutDate,
                                                                        lastDate:
                                                                            DateTime.now().add(const Duration(days: 365)),
                                                                      );
                                                                      if (picked !=
                                                                              null &&
                                                                          picked !=
                                                                              checkOutDate) {
                                                                        setState(
                                                                            () {
                                                                          checkOutDate =
                                                                              picked;
                                                                        });
                                                                      }
                                                                    },
                                                                    decoration: const InputDecoration(
                                                                        hintText:
                                                                            'Check Out Date',
                                                                        suffix:
                                                                            Icon(Icons.calendar_today)),
                                                                  ),
                                                                ],
                                                              ),
                                                              actions: [
                                                                ElevatedButton(
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                  child: const Text(
                                                                      'Cancel'),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed:
                                                                      isBooking
                                                                          ? null
                                                                          : () async {
                                                                              isBooking = true;
                                                                              setState(() {});
                                                                              await bookRoom(rooms[index]);
                                                                              isBooking = false;
                                                                              setState(() {});
                                                                              Navigator.of(context).pop();
                                                                              await showDialog(
                                                                                  context: context,
                                                                                  builder: (context) => AlertDialog(
                                                                                        title: Text('Booking Request Sent'),
                                                                                        content: Text('You will receive an email regarding the booking status'),
                                                                                        actions: [
                                                                                          TextButton(
                                                                                            onPressed: () {
                                                                                              Navigator.of(context).pop();
                                                                                            },
                                                                                            child: Text('OK'),
                                                                                          ),
                                                                                        ],
                                                                                      ));
                                                                            },
                                                                  child: Text(isBooking
                                                                      ? 'Confirming...'
                                                                      : 'Request Booking'),
                                                                ),
                                                              ],
                                                            );
                                                          });
                                                        });
                                                  },
                                                  child:
                                                      const Text('Book Room'),
                                                ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        });
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
