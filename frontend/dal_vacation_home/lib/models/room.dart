import 'feedback.dart';

enum RoomType { small, medium, large, swimmingPool, gym, conferenceRoom }

class Room {
  int roomId;
  RoomType roomType;
  int price;
  List<DateTime> bookedDates;
  String image;
  List<Feedback> feedbacks = [];
  List<String> facilities = [];
  int discount = 0;

  Room(
      {required this.roomId,
      required this.roomType,
      this.price = 0,
      this.bookedDates = const [],
      this.image = '',
      this.feedbacks = const [],
      this.facilities = const [],
      this.discount = 0});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: int.tryParse(json['roomId'].toString()) ?? 0,
      roomType: RoomType.values.firstWhere(
        (e) => e.toString() == "RoomType.${json['roomType']}",
      ),
      // convert float to int
      price: int.parse(json['price'].toString()),
      bookedDates: json['bookedDates'] != null
          ? List<DateTime>.from(
              json['bookedDates'].map((x) => DateTime.parse(x)),
            )
          : [],
      image: json['image'],
      feedbacks: json['feedbacks'] != null
          ? List<Feedback>.from(
              json['feedbacks'].map((x) => Feedback.fromJson(x)),
            )
          : [],
      facilities: json['facilities'] != null
          ? List<String>.from(json['facilities'])
          : [],
      discount: json['discount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomType': roomType.name,
      'price': price,
      'bookedDates':
          bookedDates.map((x) => x.toIso8601String().substring(0, 10)).toList(),
      'image': image,
      'feedbacks': feedbacks.map((x) => x.toJson()).toList(),
      'facilities': facilities,
      'discount': discount,
    };
  }
}
