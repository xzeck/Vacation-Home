import 'package:dal_vacation_home/models/room.dart';

import 'feedback.dart';

enum BookingStatus { confirmed, pending, canceled, reserved }

// {"room_number": 101.0, "booking_number": 1720199139372.0, "booking_status": "confirmed", "check_out_date": "2024-12-18", "total_cost": 500.0, "check_in_date": "2024-12-15", "room": {"roomId": 101.0, "price": 500.0, "image": "https://media.designcafe.com/wp-content/uploads/2023/07/05141750/aesthetic-room-decor.jpg", "roomType": "small", "isBooked": true}}
class Booking {
  final int roomNumber;
  final int bookingNumber;
  final BookingStatus bookingStatus;
  final DateTime checkOutDate;
  final double totalCost;
  final DateTime checkInDate;
  final Room room;
  Feedback? feedbacks;

  Booking({
    required this.roomNumber,
    required this.bookingNumber,
    required this.bookingStatus,
    required this.checkOutDate,
    required this.totalCost,
    required this.checkInDate,
    required this.room,
    required this.feedbacks,
  });

  // convert double to int
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      roomNumber: int.parse(json['room_number'].toString()),
      bookingNumber: int.parse(json['booking_number'].toString()),
      bookingStatus: BookingStatus.values.firstWhere(
          (e) => e.toString() == 'BookingStatus.${json['booking_status']}'),
      checkOutDate: DateTime.parse(json['check_out_date']),
      totalCost: json['total_cost'],
      checkInDate: DateTime.parse(json['check_in_date']),
      room: Room.fromJson(json['room']),
      feedbacks: json['feedbacks'] != null? Feedback.fromJson(json['feedbacks']): null,
    );
  }
}
