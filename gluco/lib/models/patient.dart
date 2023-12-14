class Patient {
  String volunteerId;
  String clientId;

  Patient({
    required this.volunteerId,
    required this.clientId,
  });

  factory Patient.fromMap(Map<String, dynamic> json) {
    Patient patient = Patient(
      volunteerId: json['volunteer_id'],
      clientId: json['client_id'],
    );
    return patient;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> data = {
      'volunteer_id': volunteerId,
      'client_id': clientId,
    };
    return data;
  }
}
