class Patient {
  String serviceNumber;
  String clientId;

  Patient({
    required this.serviceNumber,
    required this.clientId,
  });

  factory Patient.fromMap(Map<String, dynamic> json) {
    Patient patient = Patient(
      serviceNumber: json['service_number'],
      clientId: json['client_id'],
    );
    return patient;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> data = {
      'service_number': serviceNumber,
      'client_id': clientId,
    };
    return data;
  }
}
