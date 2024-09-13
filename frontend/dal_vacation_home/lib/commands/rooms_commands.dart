import 'dart:convert';

import 'package:dal_vacation_home/auth/cognito_manager.dart';
import 'package:dal_vacation_home/auth/login/login.dart';
import 'package:dal_vacation_home/constants/strings.dart';
import 'package:dal_vacation_home/models/booking.dart';
import 'package:dal_vacation_home/models/room.dart';
import 'package:dal_vacation_home/utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Rooms {
  /// Function to add/Edit a room to the database
  static Future<bool> addRoom(BuildContext context, Room room) async {
    final cognitoUser = CognitoManager.cognitoUser;

    try {
      User? user = CognitoManager.customUser;
      if (cognitoUser == null) {
        throw CognitoServiceException('User is not logged in');
      }

      Map<String, dynamic> roomMap = room.toJson();
      dynamic res = await http.post(Uri.parse('$apiGatewayUrl/add_room'),
          body: jsonEncode({
            'userId': user?.userId,
            'room': roomMap,
          }));

      if (res.statusCode != 200) {
        throw CognitoServiceException(jsonDecode(res.body)['message']);
      }
      showInSnackBar(jsonDecode(res.body)['message'], context);
      return true;
    } on CognitoServiceException catch (e) {
      print(e.message);
      showInSnackBar(e.message, context, isError: true);
    } catch (e) {
      print(e);
    }
    return false;
  }

  static Future<List<Room>> getRooms() async {
    try {
      dynamic res = await http.post(Uri.parse('$apiGatewayUrl/get_rooms'));

      if (res.statusCode != 200) {
        throw CognitoServiceException(jsonDecode(res.body)['message']);
      }

      List<dynamic> rooms = jsonDecode(res.body);
      return rooms.map((e) => Room.fromJson(e)).toList();
    } catch (e) {
      print(e);
    }
    return [];
  }

  static Future<bool> bookRoom(
      BuildContext context,
      Room room,
      DateTime checkInDate,
      DateTime checkOutDate,
      List<DateTime> bookedDates) async {
    final cognitoUser = CognitoManager.cognitoUser;

    try {
      User? user = CognitoManager.customUser;
      if (cognitoUser == null) {
        throw CognitoServiceException('User is not logged in');
      }

      // Duration adt = const Duration(hours: 3);
      // convert date to string format "YYYY-MM-DD"
      dynamic res = await http.post(Uri.parse('$apiGatewayUrl/Booking'),
          body: jsonEncode({
            'userId': user?.userId,
            'booking_status': BookingStatus.confirmed.name,
            'check_in_date': checkInDate.toIso8601String().substring(0, 10),
            'check_out_date': checkOutDate.toIso8601String().substring(0, 10),
            'room_number': room.roomId,
            "total_cost": room.price,
            "room_type": StringUtils.capitalize(room.roomType.name),
            "booked_dates": bookedDates
                .map((e) => e.toIso8601String().substring(0, 10))
                .toList(),
          }),
          headers: {
            'Content-Type': 'application/json',
          });

      if (res.statusCode != 200) {
        throw CognitoServiceException(jsonDecode(res.body)['message']);
      }
      return true;
    } on CognitoServiceException catch (e) {
      print(e.message);
      showInSnackBar(e.message, context, isError: true);
    } catch (e) {
      print(e);
    }
    return false;
  }

  static Future<List<Booking>> getBookings() async {
    final cognitoUser = CognitoManager.cognitoUser;
    try {
      User? user = CognitoManager.customUser;
      if (cognitoUser == null) {
        throw CognitoServiceException('User is not logged in');
      }

      dynamic res = await http
          .get(Uri.parse('$apiGatewayUrl/Booking?userId=${user?.userId}'));

      if (res.statusCode != 200) {
        throw CognitoServiceException(jsonDecode(res.body)['message']);
      }

      List<dynamic> bookings = jsonDecode(res.body)['bookings'];
      return bookings.map((e) => Booking.fromJson(e)).toList();
    } on CognitoServiceException catch (e) {
      print(e.message);
    } catch (e) {
      print(e);
    }
    return [];
  }
}
