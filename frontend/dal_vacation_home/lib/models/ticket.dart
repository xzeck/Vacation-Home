class Ticket {
  final int bookingReference;
  final int ticketNumber;
  final String message;
  final String email;
  final String agentEmail;
  final String agentName;
  final String customerName;

  Ticket({
    required this.bookingReference,
    required this.ticketNumber,
    required this.message,
    required this.email,
    required this.agentEmail,
    required this.agentName,
    required this.customerName,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      bookingReference: int.parse(json['booking_reference']),
      ticketNumber: json['ticket_number'],
      message: json['message'],
      email: json['email'],
      agentEmail: json['agent_email'],
      agentName: json['agent_name'],
      customerName: json['customer_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_reference': bookingReference.toString(),
      'ticket_number': ticketNumber,
      'message': message,
      'email': email,
      'agent_email': agentEmail,
      'agent_name': agentName,
      'customer_name': customerName,
    };
  }
}
