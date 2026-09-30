/// Permanentka / předplatné klienta.
///
/// * [PassType.visits] – počet vstupů (osobní trénink, masáž…),
/// * [PassType.period] – časové (online koučink na měsíc…).
enum PassType { visits, period }

class ClientPass {
  final String id;
  final String clientId;
  final String clientName;
  final PassType type;
  final String title;

  /// Počet vstupů (jen [PassType.visits]).
  final int totalVisits;

  /// Data využitých vstupů.
  final List<DateTime> uses;

  final DateTime validFrom;

  /// Konec platnosti (u časové permanentky povinný, u vstupů nepovinný).
  final DateTime? validUntil;

  final double? price;
  final bool paid;
  final DateTime? paidAt;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClientPass({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.type,
    required this.title,
    required this.totalVisits,
    required this.uses,
    required this.validFrom,
    required this.validUntil,
    required this.price,
    required this.paid,
    required this.paidAt,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  int get remaining =>
      type == PassType.visits ? (totalVisits - uses.length).clamp(0, 9999) : 0;

  /// Dní do konce platnosti (záporné = po platnosti), null = bez omezení.
  int? get daysLeft {
    final u = validUntil;
    if (u == null) return null;
    return _day(u).difference(_day(DateTime.now())).inDays;
  }

  bool get isExpired => (daysLeft ?? 1) < 0;

  bool get isUsedUp => type == PassType.visits && remaining <= 0;

  /// Aktivní = dá se ještě čerpat.
  bool get isActive => !isExpired && !isUsedUp;

  /// Brzy dojde / skončí – čas domluvit další.
  bool get isEndingSoon {
    if (!isActive) return false;
    if (type == PassType.visits && remaining <= 2) return true;
    final d = daysLeft;
    return d != null && d <= 7;
  }

  ClientPass copyWith({
    String? title,
    PassType? type,
    int? totalVisits,
    List<DateTime>? uses,
    DateTime? validFrom,
    DateTime? validUntil,
    bool clearValidUntil = false,
    double? price,
    bool clearPrice = false,
    bool? paid,
    DateTime? paidAt,
    bool clearPaidAt = false,
    String? note,
    String? clientName,
    DateTime? updatedAt,
  }) {
    return ClientPass(
      id: id,
      clientId: clientId,
      clientName: clientName ?? this.clientName,
      type: type ?? this.type,
      title: title ?? this.title,
      totalVisits: totalVisits ?? this.totalVisits,
      uses: uses ?? this.uses,
      validFrom: validFrom ?? this.validFrom,
      validUntil: clearValidUntil ? null : (validUntil ?? this.validUntil),
      price: clearPrice ? null : (price ?? this.price),
      paid: paid ?? this.paid,
      paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'clientName': clientName,
        'type': type.name,
        'title': title,
        'totalVisits': totalVisits,
        'uses': [for (final u in uses) u.toIso8601String()],
        'validFrom': validFrom.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'price': price,
        'paid': paid,
        'paidAt': paidAt?.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ClientPass.fromJson(Map<String, dynamic> j) {
    DateTime? d(Object? v) => DateTime.tryParse((v ?? '').toString());
    return ClientPass(
      id: (j['id'] ?? '').toString(),
      clientId: (j['clientId'] ?? '').toString(),
      clientName: (j['clientName'] ?? '').toString(),
      type: j['type'] == 'period' ? PassType.period : PassType.visits,
      title: (j['title'] ?? '').toString(),
      totalVisits: (j['totalVisits'] as num?)?.toInt() ?? 0,
      uses: [
        for (final u in (j['uses'] as List? ?? const []))
          if (d(u) != null) d(u)!,
      ],
      validFrom: d(j['validFrom']) ?? DateTime.now(),
      validUntil: d(j['validUntil']),
      price: (j['price'] as num?)?.toDouble(),
      paid: j['paid'] == true,
      paidAt: d(j['paidAt']),
      note: (j['note'] ?? '').toString(),
      createdAt: d(j['createdAt']) ?? DateTime.now(),
      updatedAt: d(j['updatedAt']) ?? DateTime.now(),
    );
  }
}
