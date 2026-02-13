class Hospital {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final int capacity;
  final String? imageUrl;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.capacity = 100,
    this.imageUrl,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Hospital(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      capacity: json['capacity'] ?? 100,
      imageUrl: json['image_url'],
    );
  }
}
