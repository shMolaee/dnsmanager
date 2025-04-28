class DnsConfig {
  final int? id;
  final String name;
  final String primaryDns;
  final String? alternateDns;
  bool isActive;

  DnsConfig({
    this.id,
    required this.name,
    required this.primaryDns,
    this.alternateDns,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'primaryDns': primaryDns,
      'alternateDns': alternateDns,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory DnsConfig.fromMap(Map<String, dynamic> map) {
    return DnsConfig(
      id: map['id'],
      name: map['name'],
      primaryDns: map['primaryDns'],
      alternateDns: map['alternateDns'],
      isActive: map['isActive'] == 1,
    );
  }

  DnsConfig copyWith({
    int? id,
    String? name,
    String? primaryDns,
    String? alternateDns,
    bool? isActive,
  }) {
    return DnsConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryDns: primaryDns ?? this.primaryDns,
      alternateDns: alternateDns ?? this.alternateDns,
      isActive: isActive ?? this.isActive,
    );
  }
} 