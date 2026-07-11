class SparePart {
  final String id;
  final String partName;
  final String partNumber;
  final String category;
  final String compatibleVehicleModel;
  final double unitCost;
  final int stockQty;
  final int reorderLevel;

  const SparePart({
    required this.id,
    required this.partName,
    required this.partNumber,
    required this.category,
    required this.compatibleVehicleModel,
    required this.unitCost,
    required this.stockQty,
    required this.reorderLevel,
  });

  SparePart copyWith({int? stockQty}) => SparePart(
        id: id,
        partName: partName,
        partNumber: partNumber,
        category: category,
        compatibleVehicleModel: compatibleVehicleModel,
        unitCost: unitCost,
        stockQty: stockQty ?? this.stockQty,
        reorderLevel: reorderLevel,
      );

  factory SparePart.fromJson(Map<String, dynamic> json) => SparePart(
        id: json['id'],
        partName: json['partName'],
        partNumber: json['partNumber'],
        category: json['category'],
        compatibleVehicleModel: json['compatibleVehicleModel'],
        unitCost: (json['unitCost'] as num).toDouble(),
        stockQty: json['stockQty'],
        reorderLevel: json['reorderLevel'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'partName': partName,
        'partNumber': partNumber,
        'category': category,
        'compatibleVehicleModel': compatibleVehicleModel,
        'unitCost': unitCost,
        'stockQty': stockQty,
        'reorderLevel': reorderLevel,
      };
}
