class TravelMark {
  final int? id;
  final int locationId;
  final DateTime date;
  final String? note;

  const TravelMark({
    this.id,
    required this.locationId,
    required this.date,
    this.note,
  });

  TravelMark copyWith({
    int? id,
    int? locationId,
    DateTime? date,
    String? note,
  }) {
    return TravelMark(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'locationId': locationId,
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'note': note,
      };

  factory TravelMark.fromJson(Map<String, dynamic> json) => TravelMark(
        id: json['id'] as int?,
        locationId: json['locationId'] as int,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
      );
}
