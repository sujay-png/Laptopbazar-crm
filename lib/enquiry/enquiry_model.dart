class EnquiryModel {
  final int id;
  final int? customerId;
  final String? customerName;
  final String? phoneNo;
  final String channel;
  final DateTime createdAt;
  final List<EnquiryUpdate> updates;

  EnquiryModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.channel,
    required this.createdAt,
    required this.updates,
    this.phoneNo,
  });

  EnquiryUpdate get latestUpdate =>
      updates.isNotEmpty ? updates.last : EnquiryUpdate.initial();

  factory EnquiryModel.fromMap(Map<String, dynamic> json) {
    final rawUpdates = json['updates'] as List? ?? [];

    return EnquiryModel(
      id: json['id'],
      customerId: json['nameofCustomer'] as int?,
      customerName: json['customer_name'],
      phoneNo: json['phone'],
      channel: json['channel'] ?? '-',
      createdAt: DateTime.parse(json['created_at']),
      updates: rawUpdates.map((e) => EnquiryUpdate.fromMap(e)).toList(),
    );
  }
}

class EnquiryUpdate {
  final DateTime date;
  final String note;
  final String status;

  EnquiryUpdate({required this.date, required this.note, required this.status});

  factory EnquiryUpdate.fromMap(Map<String, dynamic> json) {
    return EnquiryUpdate(
      date: DateTime.parse(json['date']),
      note: json['note'],
      status: json['status'],
    );
  }

  factory EnquiryUpdate.initial() {
    return EnquiryUpdate(
      date: DateTime.now(),
      note: 'Initial enquiry',
      status: 'new',
    );
  }
}
