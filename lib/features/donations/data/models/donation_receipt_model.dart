class DonationReceiptModel {
  final String id;
  final String donorName;
  final String recipientOrg;
  final String causeTitle;
  final double amount;
  final String currency;
  final DateTime date;
  final String agent;

  const DonationReceiptModel({
    required this.id,
    required this.donorName,
    required this.recipientOrg,
    required this.causeTitle,
    required this.amount,
    required this.currency,
    required this.date,
    required this.agent,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'donor_name': donorName,
    'recipient_org': recipientOrg,
    'cause_title': causeTitle,
    'amount': amount,
    'currency': currency,
    'date': date.toIso8601String(),
    'agent': agent,
  };

  factory DonationReceiptModel.fromJson(Map<String, dynamic> json) {
    return DonationReceiptModel(
      id: json['id'] as String,
      donorName: json['donor_name'] as String,
      recipientOrg: json['recipient_org'] as String,
      causeTitle: json['cause_title'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      date: DateTime.parse(json['date'] as String),
      agent: json['agent'] as String,
    );
  }

  String get formattedAmount => '${amount.toStringAsFixed(0)} $currency';
}
