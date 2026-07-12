class FuelRequest {
  final String id;
  final String vehicleId;
  final String driverId;
  final double odometer;
  final double requestedLiters;
  final double estimatedCost;
  final String stationName;
  final String timestamp;
  final String status; // Pending | Approved | Rejected | Completed
  final double? approvedLiters;
  final String? voucherCode;
  final String? receiptPhotoUrl;
  final String? pumpPhotoUrl;
  final double? actualCost;
  final double? actualLiters;
  final bool? varianceFlagged;
  final String? varianceReason;
  final String paymentMethod; // Cash | Fuel Card
  final String? receiptNumber;
  final String? cardTransactionReference;
  final double? unitPrice;
  final double? distanceSincePreviousFuelKm;
  final double? calculatedKmPerLiter;

  const FuelRequest({
    required this.id,
    required this.vehicleId,
    required this.driverId,
    required this.odometer,
    required this.requestedLiters,
    required this.estimatedCost,
    required this.stationName,
    required this.timestamp,
    required this.status,
    this.approvedLiters,
    this.voucherCode,
    this.receiptPhotoUrl,
    this.pumpPhotoUrl,
    this.actualCost,
    this.actualLiters,
    this.varianceFlagged,
    this.varianceReason,
    this.paymentMethod = 'Cash',
    this.receiptNumber,
    this.cardTransactionReference,
    this.unitPrice,
    this.distanceSincePreviousFuelKm,
    this.calculatedKmPerLiter,
  });

  FuelRequest copyWith({
    String? status,
    double? approvedLiters,
    String? voucherCode,
    String? receiptPhotoUrl,
    String? pumpPhotoUrl,
    double? actualCost,
    double? actualLiters,
    bool? varianceFlagged,
    String? varianceReason,
    String? paymentMethod,
    String? receiptNumber,
    String? cardTransactionReference,
    double? unitPrice,
    double? distanceSincePreviousFuelKm,
    double? calculatedKmPerLiter,
  }) {
    return FuelRequest(
      id: id,
      vehicleId: vehicleId,
      driverId: driverId,
      odometer: odometer,
      requestedLiters: requestedLiters,
      estimatedCost: estimatedCost,
      stationName: stationName,
      timestamp: timestamp,
      status: status ?? this.status,
      approvedLiters: approvedLiters ?? this.approvedLiters,
      voucherCode: voucherCode ?? this.voucherCode,
      receiptPhotoUrl: receiptPhotoUrl ?? this.receiptPhotoUrl,
      pumpPhotoUrl: pumpPhotoUrl ?? this.pumpPhotoUrl,
      actualCost: actualCost ?? this.actualCost,
      actualLiters: actualLiters ?? this.actualLiters,
      varianceFlagged: varianceFlagged ?? this.varianceFlagged,
      varianceReason: varianceReason ?? this.varianceReason,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      cardTransactionReference: cardTransactionReference ?? this.cardTransactionReference,
      unitPrice: unitPrice ?? this.unitPrice,
      distanceSincePreviousFuelKm: distanceSincePreviousFuelKm ?? this.distanceSincePreviousFuelKm,
      calculatedKmPerLiter: calculatedKmPerLiter ?? this.calculatedKmPerLiter,
    );
  }

  factory FuelRequest.fromJson(Map<String, dynamic> json) => FuelRequest(
        id: json['id'],
        vehicleId: json['vehicleId'],
        driverId: json['driverId'],
        odometer: (json['odometer'] as num).toDouble(),
        requestedLiters: (json['requestedLiters'] as num).toDouble(),
        estimatedCost: (json['estimatedCost'] as num).toDouble(),
        stationName: json['stationName'],
        timestamp: json['timestamp'],
        status: json['status'],
        approvedLiters: (json['approvedLiters'] as num?)?.toDouble(),
        voucherCode: json['voucherCode'],
        receiptPhotoUrl: json['receiptPhotoUrl'],
        pumpPhotoUrl: json['pumpPhotoUrl'],
        actualCost: (json['actualCost'] as num?)?.toDouble(),
        actualLiters: (json['actualLiters'] as num?)?.toDouble(),
        varianceFlagged: json['varianceFlagged'],
        varianceReason: json['varianceReason'],
        paymentMethod: json['paymentMethod'] ?? 'Cash',
        receiptNumber: json['receiptNumber'],
        cardTransactionReference: json['cardTransactionReference'],
        unitPrice: (json['unitPrice'] as num?)?.toDouble(),
        distanceSincePreviousFuelKm: (json['distanceSincePreviousFuelKm'] as num?)?.toDouble(),
        calculatedKmPerLiter: (json['calculatedKmPerLiter'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'driverId': driverId,
        'odometer': odometer,
        'requestedLiters': requestedLiters,
        'estimatedCost': estimatedCost,
        'stationName': stationName,
        'timestamp': timestamp,
        'status': status,
        'approvedLiters': approvedLiters,
        'voucherCode': voucherCode,
        'receiptPhotoUrl': receiptPhotoUrl,
        'pumpPhotoUrl': pumpPhotoUrl,
        'actualCost': actualCost,
        'actualLiters': actualLiters,
        'varianceFlagged': varianceFlagged,
        'varianceReason': varianceReason,
        'paymentMethod': paymentMethod,
        'receiptNumber': receiptNumber,
        'cardTransactionReference': cardTransactionReference,
        'unitPrice': unitPrice,
        'distanceSincePreviousFuelKm': distanceSincePreviousFuelKm,
        'calculatedKmPerLiter': calculatedKmPerLiter,
      };
}
