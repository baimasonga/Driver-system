class AuditLog {
  final String id;
  final String timestamp;
  final String userId;
  final String userRole;
  final String action;
  final String entityType;
  final String entityId;
  final String details;

  const AuditLog({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.userRole,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.details,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id'],
        timestamp: json['timestamp'],
        userId: json['userId'],
        userRole: json['userRole'],
        action: json['action'],
        entityType: json['entityType'],
        entityId: json['entityId'],
        details: json['details'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'userId': userId,
        'userRole': userRole,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'details': details,
      };
}
