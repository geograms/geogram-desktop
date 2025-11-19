import 'dart:convert';

/// User profile model
class Profile {
  String callsign;
  String nickname;
  String description;
  String? profileImagePath;
  String npub; // NOSTR public key
  String nsec; // NOSTR private key (secret)
  String preferredColor;
  double? latitude; // User's current latitude
  double? longitude; // User's current longitude
  String? locationName; // Human-readable location

  Profile({
    this.callsign = '',
    this.nickname = '',
    this.description = '',
    this.profileImagePath,
    this.npub = '',
    this.nsec = '',
    this.preferredColor = 'blue',
    this.latitude,
    this.longitude,
    this.locationName,
  });

  /// Create a Profile from JSON map
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      callsign: json['callsign'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      description: json['description'] as String? ?? '',
      profileImagePath: json['profileImagePath'] as String?,
      npub: json['npub'] as String? ?? '',
      nsec: json['nsec'] as String? ?? '',
      preferredColor: json['preferredColor'] as String? ?? 'blue',
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      locationName: json['locationName'] as String?,
    );
  }

  /// Convert Profile to JSON map
  Map<String, dynamic> toJson() {
    return {
      'callsign': callsign,
      'nickname': nickname,
      'description': description,
      if (profileImagePath != null) 'profileImagePath': profileImagePath,
      'npub': npub,
      'nsec': nsec,
      'preferredColor': preferredColor,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationName != null) 'locationName': locationName,
    };
  }

  /// Create a copy of this profile
  Profile copyWith({
    String? callsign,
    String? nickname,
    String? description,
    String? profileImagePath,
    String? npub,
    String? nsec,
    String? preferredColor,
    double? latitude,
    double? longitude,
    String? locationName,
  }) {
    return Profile(
      callsign: callsign ?? this.callsign,
      nickname: nickname ?? this.nickname,
      description: description ?? this.description,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      npub: npub ?? this.npub,
      nsec: nsec ?? this.nsec,
      preferredColor: preferredColor ?? this.preferredColor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
    );
  }
}
