import 'dart:math';

/// Internet relay model
class Relay {
  String url;
  String name;
  String status; // 'preferred', 'backup', 'available'
  bool isConnected;
  int? latency; // in milliseconds
  DateTime? lastChecked;
  double? latitude; // Relay disclosed location
  double? longitude; // Relay disclosed location
  String? location; // Human-readable location (e.g., "New York, USA")
  int? connectedDevices; // Number of connected devices (cached)

  Relay({
    required this.url,
    required this.name,
    this.status = 'available',
    this.isConnected = false,
    this.latency,
    this.lastChecked,
    this.latitude,
    this.longitude,
    this.location,
    this.connectedDevices,
  });

  /// Create a Relay from JSON map
  factory Relay.fromJson(Map<String, dynamic> json) {
    return Relay(
      url: json['url'] as String,
      name: json['name'] as String,
      status: json['status'] as String? ?? 'available',
      isConnected: json['isConnected'] as bool? ?? false,
      latency: json['latency'] as int?,
      lastChecked: json['lastChecked'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastChecked'] as int)
          : null,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      location: json['location'] as String?,
      connectedDevices: json['connectedDevices'] as int?,
    );
  }

  /// Convert Relay to JSON map
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'name': name,
      'status': status,
      'isConnected': isConnected,
      if (latency != null) 'latency': latency,
      if (lastChecked != null) 'lastChecked': lastChecked!.millisecondsSinceEpoch,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (location != null) 'location': location,
      if (connectedDevices != null) 'connectedDevices': connectedDevices,
    };
  }

  /// Create a copy of this relay
  Relay copyWith({
    String? url,
    String? name,
    String? status,
    bool? isConnected,
    int? latency,
    DateTime? lastChecked,
    double? latitude,
    double? longitude,
    String? location,
    int? connectedDevices,
  }) {
    return Relay(
      url: url ?? this.url,
      name: name ?? this.name,
      status: status ?? this.status,
      isConnected: isConnected ?? this.isConnected,
      latency: latency ?? this.latency,
      lastChecked: lastChecked ?? this.lastChecked,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      connectedDevices: connectedDevices ?? this.connectedDevices,
    );
  }

  /// Get status display text
  String get statusDisplay {
    switch (status) {
      case 'preferred':
        return 'Preferred';
      case 'backup':
        return 'Backup';
      default:
        return 'Available';
    }
  }

  /// Get connection status text
  String get connectionStatus {
    if (isConnected) {
      return latency != null ? 'Connected (${latency}ms)' : 'Connected';
    }
    return 'Disconnected';
  }

  /// Calculate distance from given coordinates using Haversine formula
  /// Returns distance in kilometers, or null if relay or user location is unavailable
  double? calculateDistance(double? userLat, double? userLon) {
    if (latitude == null || longitude == null || userLat == null || userLon == null) {
      return null;
    }

    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(userLat - latitude!);
    final dLon = _degreesToRadians(userLon - longitude!);

    final lat1 = _degreesToRadians(latitude!);
    final lat2 = _degreesToRadians(userLat);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
              (sin(dLon / 2) * sin(dLon / 2)) * cos(lat1) * cos(lat2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Get human-readable distance string
  String? getDistanceString(double? userLat, double? userLon) {
    final distance = calculateDistance(userLat, userLon);
    if (distance == null) return null;

    if (distance < 1) {
      return '${(distance * 1000).round()} meters away';
    } else {
      return '${distance.round()} kilometers away';
    }
  }
}
