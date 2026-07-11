class PolicyRule {
  final String id;
  final String name;
  final String category; // Fuel | Trip | Maintenance | Audit
  final String value;
  final String description;

  const PolicyRule({
    required this.id,
    required this.name,
    required this.category,
    required this.value,
    required this.description,
  });

  PolicyRule copyWith({String? value}) => PolicyRule(
        id: id,
        name: name,
        category: category,
        value: value ?? this.value,
        description: description,
      );

  factory PolicyRule.fromJson(Map<String, dynamic> json) => PolicyRule(
        id: json['id'],
        name: json['name'],
        category: json['category'],
        value: json['value'],
        description: json['description'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'value': value,
        'description': description,
      };
}
