// 🔒 STATUS: NEW (Checking Account Entry Model)
class CheckingEntry {
  final int? id;
  final double amount;
  final String date;

  CheckingEntry({
    this.id,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date,
    };
  }

  factory CheckingEntry.fromMap(Map<String, dynamic> map) {
    return CheckingEntry(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      date: map['date'],
    );
  }
}