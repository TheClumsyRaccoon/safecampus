class InvitationCode {
  final String code;
  final String groupId;
  final DateTime expiresAt;
  final int maxUses;
  final int currentUses;

  InvitationCode({
    required this.code,
    required this.groupId,
    required this.expiresAt,
    this.maxUses = 10,
    this.currentUses = 0,
  });

  Map<String, dynamic> toMap() => {
        'code': code,
        'groupId': groupId,
        'expiresAt': expiresAt.toIso8601String(),
        'maxUses': maxUses,
        'currentUses': currentUses,
      };

  factory InvitationCode.fromMap(Map<String, dynamic> map) {
    return InvitationCode(
      code: map['code'],
      groupId: map['groupId'],
      expiresAt: DateTime.parse(map['expiresAt']),
      maxUses: map['maxUses'],
      currentUses: map['currentUses'],
    );
  }

  InvitationCode copyWith({
    String? code,
    String? groupId,
    DateTime? expiresAt,
    int? maxUses,
    int? currentUses,
  }) {
    return InvitationCode(
      code: code ?? this.code,
      groupId: groupId ?? this.groupId,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
    );
  }
}
