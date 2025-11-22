/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */

/// Model representing a place in the places collection
class Place {
  final String name; // Place name (single language or primary)
  final Map<String, String> names; // Multilingual names (e.g., {'EN': 'name', 'PT': 'nome'})
  final String created; // Format: YYYY-MM-DD HH:MM_ss
  final String author; // Callsign
  final double latitude;
  final double longitude;
  final int radius; // In meters (10-1000)

  // Optional fields
  final String? address;
  final String? type; // Category (restaurant, monument, park, etc.)
  final String? founded; // Year, century, or era
  final String? hours; // Operating hours

  // Content
  final String description; // Single language or primary
  final Map<String, String> descriptions; // Multilingual descriptions
  final String? history; // Single language or primary
  final Map<String, String> histories; // Multilingual histories

  // Permissions
  final List<String> admins; // List of npubs
  final List<String> moderators; // List of npubs

  // Metadata
  final String? metadataNpub;
  final String? signature;

  // File/folder paths
  final String? filePath; // Path to place.txt
  final String? folderPath; // Path to place folder
  final String? regionPath; // Region folder (e.g., "38.7_-9.1")

  // Photo/media count
  final int photoCount;
  final int contributorCount;

  Place({
    required this.name,
    this.names = const {},
    required this.created,
    required this.author,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.address,
    this.type,
    this.founded,
    this.hours,
    this.description = '',
    this.descriptions = const {},
    this.history,
    this.histories = const {},
    this.admins = const [],
    this.moderators = const [],
    this.metadataNpub,
    this.signature,
    this.filePath,
    this.folderPath,
    this.regionPath,
    this.photoCount = 0,
    this.contributorCount = 0,
  });

  /// Parse created timestamp to DateTime
  DateTime get createdDateTime {
    try {
      final normalized = created.replaceAll('_', ':');
      return DateTime.parse(normalized);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Get display timestamp
  String get displayCreated => created.replaceAll('_', ':');

  /// Get coordinates as string
  String get coordinatesString => '$latitude,$longitude';

  /// Get region folder name from coordinates
  String get regionFolder {
    final latRounded = (latitude * 10).round() / 10;
    final lonRounded = (longitude * 10).round() / 10;
    return '${latRounded}_$lonRounded';
  }

  /// Get place folder name
  String get placeFolderName {
    final sanitized = _sanitizeName(name);
    return '${latitude}_${longitude}_$sanitized';
  }

  /// Sanitize name for folder name
  static String _sanitizeName(String name) {
    String sanitized = name.toLowerCase();
    sanitized = sanitized.replaceAll(RegExp(r'[\s_]+'), '-');
    sanitized = sanitized.replaceAll(RegExp(r'[^a-z0-9-]'), '');
    sanitized = sanitized.replaceAll(RegExp(r'-+'), '-');
    sanitized = sanitized.replaceAll(RegExp(r'^-+|-+$'), '');
    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }
    return sanitized;
  }

  /// Get name in specified language (with fallback)
  String getName(String langCode) {
    if (names.containsKey(langCode)) {
      return names[langCode]!;
    }
    if (names.containsKey('EN')) {
      return names['EN']!;
    }
    if (names.isNotEmpty) {
      return names.values.first;
    }
    return name;
  }

  /// Get description in specified language (with fallback)
  String getDescription(String langCode) {
    if (descriptions.containsKey(langCode)) {
      return descriptions[langCode]!;
    }
    if (descriptions.containsKey('EN')) {
      return descriptions['EN']!;
    }
    if (descriptions.isNotEmpty) {
      return descriptions.values.first;
    }
    return description;
  }

  /// Get history in specified language (with fallback)
  String? getHistory(String langCode) {
    if (histories.containsKey(langCode)) {
      return histories[langCode]!;
    }
    if (histories.containsKey('EN')) {
      return histories['EN']!;
    }
    if (histories.isNotEmpty) {
      return histories.values.first;
    }
    return history;
  }

  /// Check if user is admin
  bool isAdmin(String npub) {
    return admins.contains(npub);
  }

  /// Check if user is moderator
  bool isModerator(String npub) {
    return moderators.contains(npub);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        if (names.isNotEmpty) 'names': names,
        'created': created,
        'author': author,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        if (address != null) 'address': address,
        if (type != null) 'type': type,
        if (founded != null) 'founded': founded,
        if (hours != null) 'hours': hours,
        'description': description,
        if (descriptions.isNotEmpty) 'descriptions': descriptions,
        if (history != null) 'history': history,
        if (histories.isNotEmpty) 'histories': histories,
        if (admins.isNotEmpty) 'admins': admins,
        if (moderators.isNotEmpty) 'moderators': moderators,
        if (metadataNpub != null) 'metadataNpub': metadataNpub,
        if (signature != null) 'signature': signature,
        if (filePath != null) 'filePath': filePath,
        if (folderPath != null) 'folderPath': folderPath,
        if (regionPath != null) 'regionPath': regionPath,
        'photoCount': photoCount,
        'contributorCount': contributorCount,
      };

  /// Create from JSON
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      name: json['name'] as String,
      names: json['names'] != null
          ? Map<String, String>.from(json['names'] as Map)
          : const {},
      created: json['created'] as String,
      author: json['author'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: json['radius'] as int,
      address: json['address'] as String?,
      type: json['type'] as String?,
      founded: json['founded'] as String?,
      hours: json['hours'] as String?,
      description: json['description'] as String? ?? '',
      descriptions: json['descriptions'] != null
          ? Map<String, String>.from(json['descriptions'] as Map)
          : const {},
      history: json['history'] as String?,
      histories: json['histories'] != null
          ? Map<String, String>.from(json['histories'] as Map)
          : const {},
      admins: json['admins'] != null
          ? List<String>.from(json['admins'] as List)
          : const [],
      moderators: json['moderators'] != null
          ? List<String>.from(json['moderators'] as List)
          : const [],
      metadataNpub: json['metadataNpub'] as String?,
      signature: json['signature'] as String?,
      filePath: json['filePath'] as String?,
      folderPath: json['folderPath'] as String?,
      regionPath: json['regionPath'] as String?,
      photoCount: json['photoCount'] as int? ?? 0,
      contributorCount: json['contributorCount'] as int? ?? 0,
    );
  }

  /// Create a copy with updated fields
  Place copyWith({
    String? name,
    Map<String, String>? names,
    String? created,
    String? author,
    double? latitude,
    double? longitude,
    int? radius,
    String? address,
    String? type,
    String? founded,
    String? hours,
    String? description,
    Map<String, String>? descriptions,
    String? history,
    Map<String, String>? histories,
    List<String>? admins,
    List<String>? moderators,
    String? metadataNpub,
    String? signature,
    String? filePath,
    String? folderPath,
    String? regionPath,
    int? photoCount,
    int? contributorCount,
  }) {
    return Place(
      name: name ?? this.name,
      names: names ?? this.names,
      created: created ?? this.created,
      author: author ?? this.author,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      address: address ?? this.address,
      type: type ?? this.type,
      founded: founded ?? this.founded,
      hours: hours ?? this.hours,
      description: description ?? this.description,
      descriptions: descriptions ?? this.descriptions,
      history: history ?? this.history,
      histories: histories ?? this.histories,
      admins: admins ?? this.admins,
      moderators: moderators ?? this.moderators,
      metadataNpub: metadataNpub ?? this.metadataNpub,
      signature: signature ?? this.signature,
      filePath: filePath ?? this.filePath,
      folderPath: folderPath ?? this.folderPath,
      regionPath: regionPath ?? this.regionPath,
      photoCount: photoCount ?? this.photoCount,
      contributorCount: contributorCount ?? this.contributorCount,
    );
  }
}
