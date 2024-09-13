class Feedback {
  final DateTime feedbackDate;
  final String feedback;
  final int rating;
  final String username;

  Feedback({
    required this.feedbackDate,
    required this.feedback,
    required this.rating,
    required this.username,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      feedbackDate: DateTime.parse(json['feedback_date']),
      feedback: json['feedback'],
      rating: json['rating'],
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedback_date': feedbackDate.toIso8601String().substring(0,10),
      'feedback': feedback,
      'rating': rating,
      'username': username,
    };
  }
}