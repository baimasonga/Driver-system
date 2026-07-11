import 'enums.dart';

class ReplacedPart {
  final String partName;
  final String? partNumber;
  final double cost;
  final String? serialInstalled;
  final String? serialRemoved;

  const ReplacedPart({
    required this.partName,
    this.partNumber,
    required this.cost,
    this.serialInstalled,
    this.serialRemoved,
  });

  factory ReplacedPart.fromJson(Map<String, dynamic> json) => ReplacedPart(
        partName: json['partName'],
        partNumber: json['partNumber'],
        cost: (json['cost'] as num).toDouble(),
        serialInstalled: json['serialInstalled'],
        serialRemoved: json['serialRemoved'],
      );

  Map<String, dynamic> toJson() => {
        'partName': partName,
        'partNumber': partNumber,
        'cost': cost,
        'serialInstalled': serialInstalled,
        'serialRemoved': serialRemoved,
      };
}

class MaintenanceRequest {
  final String id;
  final String vehicleId;
  final String driverId;
  final String category; // Routine | Corrective | Emergency
  final String description;
  final String severity; // Low | Medium | High
  final double odometer;
  final String timestamp;
  final MaintenanceStatus status;

  final String? garageName;
  final double? quotationAmount;
  final double? approvedAmount;
  final double? invoiceAmount;
  final String? invoicePhotoUrl;

  final List<ReplacedPart>? partsReplaced;

  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final String? completionNotes;
  final bool? testDrivePassed;

  const MaintenanceRequest({
    required this.id,
    required this.vehicleId,
    required this.driverId,
    required this.category,
    required this.description,
    required this.severity,
    required this.odometer,
    required this.timestamp,
    required this.status,
    this.garageName,
    this.quotationAmount,
    this.approvedAmount,
    this.invoiceAmount,
    this.invoicePhotoUrl,
    this.partsReplaced,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.completionNotes,
    this.testDrivePassed,
  });

  MaintenanceRequest copyWith({
    MaintenanceStatus? status,
    String? garageName,
    double? quotationAmount,
    double? approvedAmount,
    double? invoiceAmount,
    String? invoicePhotoUrl,
    List<ReplacedPart>? partsReplaced,
    String? beforePhotoUrl,
    String? afterPhotoUrl,
    String? completionNotes,
    bool? testDrivePassed,
  }) {
    return MaintenanceRequest(
      id: id,
      vehicleId: vehicleId,
      driverId: driverId,
      category: category,
      description: description,
      severity: severity,
      odometer: odometer,
      timestamp: timestamp,
      status: status ?? this.status,
      garageName: garageName ?? this.garageName,
      quotationAmount: quotationAmount ?? this.quotationAmount,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      invoiceAmount: invoiceAmount ?? this.invoiceAmount,
      invoicePhotoUrl: invoicePhotoUrl ?? this.invoicePhotoUrl,
      partsReplaced: partsReplaced ?? this.partsReplaced,
      beforePhotoUrl: beforePhotoUrl ?? this.beforePhotoUrl,
      afterPhotoUrl: afterPhotoUrl ?? this.afterPhotoUrl,
      completionNotes: completionNotes ?? this.completionNotes,
      testDrivePassed: testDrivePassed ?? this.testDrivePassed,
    );
  }

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) => MaintenanceRequest(
        id: json['id'],
        vehicleId: json['vehicleId'],
        driverId: json['driverId'],
        category: json['category'],
        description: json['description'],
        severity: json['severity'],
        odometer: (json['odometer'] as num).toDouble(),
        timestamp: json['timestamp'],
        status: MaintenanceStatus.fromLabel(json['status']),
        garageName: json['garageName'],
        quotationAmount: (json['quotationAmount'] as num?)?.toDouble(),
        approvedAmount: (json['approvedAmount'] as num?)?.toDouble(),
        invoiceAmount: (json['invoiceAmount'] as num?)?.toDouble(),
        invoicePhotoUrl: json['invoicePhotoUrl'],
        partsReplaced: (json['partsReplaced'] as List<dynamic>?)
            ?.map((e) => ReplacedPart.fromJson(e as Map<String, dynamic>))
            .toList(),
        beforePhotoUrl: json['beforePhotoUrl'],
        afterPhotoUrl: json['afterPhotoUrl'],
        completionNotes: json['completionNotes'],
        testDrivePassed: json['testDrivePassed'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'driverId': driverId,
        'category': category,
        'description': description,
        'severity': severity,
        'odometer': odometer,
        'timestamp': timestamp,
        'status': status.label,
        'garageName': garageName,
        'quotationAmount': quotationAmount,
        'approvedAmount': approvedAmount,
        'invoiceAmount': invoiceAmount,
        'invoicePhotoUrl': invoicePhotoUrl,
        'partsReplaced': partsReplaced?.map((e) => e.toJson()).toList(),
        'beforePhotoUrl': beforePhotoUrl,
        'afterPhotoUrl': afterPhotoUrl,
        'completionNotes': completionNotes,
        'testDrivePassed': testDrivePassed,
      };
}
