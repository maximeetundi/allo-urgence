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
    return Hospital(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      capacity: json['capacity'] ?? 100,
      imageUrl: json['image_url'],
    );
  }
}
