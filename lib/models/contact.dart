/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */

/// Model representing a contact location for postcard delivery
class ContactLocation {
  final String name;
  final double? latitude;
  final double? longitude;

  ContactLocation({
    required this.name,
    this.latitude,
    this.longitude,
  });

  /// Get display string for location
  String get displayString {
    if (latitude != null && longitude != null) {
      return '$name ($latitude,$longitude)';
    }
    return name;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

  /// Create from JSON
  factory ContactLocation.fromJson(Map<String, dynamic> json) {
    return ContactLocation(
      name: json['name'] as String,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }
}

/// Model representing a contact (person or machine)
class Contact {
  final String displayName;
  final String callsign;
  final String npub;
  final String created; // Format: YYYY-MM-DD HH:MM_ss
  final String firstSeen; // Format: YYYY-MM-DD HH:MM_ss

  // Optional contact information
  final List<String> emails;
  final List<String> phones;
  final List<String> addresses;
  final List<String> websites;
  final List<ContactLocation> locations;
  final String? profilePicture;

  // Identity management
  final bool revoked;
  final String? revocationReason;
  final String? successor; // Callsign or npub
  final String? successorSince; // Format: YYYY-MM-DD HH:MM_ss
  final String? previousIdentity; // Callsign or npub
  final String? previousIdentitySince; // Format: YYYY-MM-DD HH:MM_ss

  // Notes
  final String notes;

  // Metadata
  final String? metadataNpub;
  final String? signature;

  // File path (for editing)
  final String? filePath;
  final String? groupPath; // Relative path within contacts/ (e.g., "family", "", "work/engineering")

  Contact({
    required this.displayName,
    required this.callsign,
    required this.npub,
    required this.created,
    required this.firstSeen,
    this.emails = const [],
    this.phones = const [],
    this.addresses = const [],
    this.websites = const [],
    this.locations = const [],
    this.profilePicture,
    this.revoked = false,
    this.revocationReason,
    this.successor,
    this.successorSince,
    this.previousIdentity,
    this.previousIdentitySince,
    this.notes = '',
    this.metadataNpub,
    this.signature,
    this.filePath,
    this.groupPath,
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

  /// Parse firstSeen timestamp to DateTime
  DateTime get firstSeenDateTime {
    try {
      final normalized = firstSeen.replaceAll('_', ':');
      return DateTime.parse(normalized);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Parse successorSince timestamp to DateTime
  DateTime? get successorSinceDateTime {
    if (successorSince == null) return null;
    try {
      final normalized = successorSince!.replaceAll('_', ':');
      return DateTime.parse(normalized);
    } catch (e) {
      return null;
    }
  }

  /// Parse previousIdentitySince timestamp to DateTime
  DateTime? get previousIdentitySinceDateTime {
    if (previousIdentitySince == null) return null;
    try {
      final normalized = previousIdentitySince!.replaceAll('_', ':');
      return DateTime.parse(normalized);
    } catch (e) {
      return null;
    }
  }

  /// Get display timestamp (formatted for UI)
  String get displayCreated => created.replaceAll('_', ':');
  String get displayFirstSeen => firstSeen.replaceAll('_', ':');
  String? get displaySuccessorSince => successorSince?.replaceAll('_', ':');
  String? get displayPreviousIdentitySince => previousIdentitySince?.replaceAll('_', ':');

  /// Get filename for this contact
  String get filename => '$callsign.txt';

  /// Get profile picture path relative to contacts/profile-pictures/
  String? get profilePicturePath {
    if (profilePicture == null) return null;
    return 'contacts/profile-pictures/$profilePicture';
  }

  /// Check if this is a machine contact (heuristic based on notes or metadata)
  bool get isProbablyMachine {
    final lowerNotes = notes.toLowerCase();
    return lowerNotes.contains('machine') ||
        lowerNotes.contains('device') ||
        lowerNotes.contains('iot') ||
        lowerNotes.contains('bot') ||
        lowerNotes.contains('server');
  }

  /// Get group display name
  String get groupDisplayName {
    if (groupPath == null || groupPath!.isEmpty) {
      return 'All Contacts';
    }
    return groupPath!.split('/').last;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'callsign': callsign,
        'npub': npub,
        'created': created,
        'firstSeen': firstSeen,
        if (emails.isNotEmpty) 'emails': emails,
        if (phones.isNotEmpty) 'phones': phones,
        if (addresses.isNotEmpty) 'addresses': addresses,
        if (websites.isNotEmpty) 'websites': websites,
        if (locations.isNotEmpty) 'locations': locations.map((l) => l.toJson()).toList(),
        if (profilePicture != null) 'profilePicture': profilePicture,
        'revoked': revoked,
        if (revocationReason != null) 'revocationReason': revocationReason,
        if (successor != null) 'successor': successor,
        if (successorSince != null) 'successorSince': successorSince,
        if (previousIdentity != null) 'previousIdentity': previousIdentity,
        if (previousIdentitySince != null) 'previousIdentitySince': previousIdentitySince,
        if (notes.isNotEmpty) 'notes': notes,
        if (metadataNpub != null) 'metadataNpub': metadataNpub,
        if (signature != null) 'signature': signature,
        if (filePath != null) 'filePath': filePath,
        if (groupPath != null) 'groupPath': groupPath,
      };

  /// Create from JSON
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      displayName: json['displayName'] as String,
      callsign: json['callsign'] as String,
      npub: json['npub'] as String,
      created: json['created'] as String,
      firstSeen: json['firstSeen'] as String,
      emails: json['emails'] != null ? List<String>.from(json['emails'] as List) : const [],
      phones: json['phones'] != null ? List<String>.from(json['phones'] as List) : const [],
      addresses: json['addresses'] != null ? List<String>.from(json['addresses'] as List) : const [],
      websites: json['websites'] != null ? List<String>.from(json['websites'] as List) : const [],
      locations: json['locations'] != null
          ? (json['locations'] as List).map((l) => ContactLocation.fromJson(l as Map<String, dynamic>)).toList()
          : const [],
      profilePicture: json['profilePicture'] as String?,
      revoked: json['revoked'] as bool? ?? false,
      revocationReason: json['revocationReason'] as String?,
      successor: json['successor'] as String?,
      successorSince: json['successorSince'] as String?,
      previousIdentity: json['previousIdentity'] as String?,
      previousIdentitySince: json['previousIdentitySince'] as String?,
      notes: json['notes'] as String? ?? '',
      metadataNpub: json['metadataNpub'] as String?,
      signature: json['signature'] as String?,
      filePath: json['filePath'] as String?,
      groupPath: json['groupPath'] as String?,
    );
  }

  /// Create a copy with updated fields
  Contact copyWith({
    String? displayName,
    String? callsign,
    String? npub,
    String? created,
    String? firstSeen,
    List<String>? emails,
    List<String>? phones,
    List<String>? addresses,
    List<String>? websites,
    List<ContactLocation>? locations,
    String? profilePicture,
    bool? revoked,
    String? revocationReason,
    String? successor,
    String? successorSince,
    String? previousIdentity,
    String? previousIdentitySince,
    String? notes,
    String? metadataNpub,
    String? signature,
    String? filePath,
    String? groupPath,
  }) {
    return Contact(
      displayName: displayName ?? this.displayName,
      callsign: callsign ?? this.callsign,
      npub: npub ?? this.npub,
      created: created ?? this.created,
      firstSeen: firstSeen ?? this.firstSeen,
      emails: emails ?? this.emails,
      phones: phones ?? this.phones,
      addresses: addresses ?? this.addresses,
      websites: websites ?? this.websites,
      locations: locations ?? this.locations,
      profilePicture: profilePicture ?? this.profilePicture,
      revoked: revoked ?? this.revoked,
      revocationReason: revocationReason ?? this.revocationReason,
      successor: successor ?? this.successor,
      successorSince: successorSince ?? this.successorSince,
      previousIdentity: previousIdentity ?? this.previousIdentity,
      previousIdentitySince: previousIdentitySince ?? this.previousIdentitySince,
      notes: notes ?? this.notes,
      metadataNpub: metadataNpub ?? this.metadataNpub,
      signature: signature ?? this.signature,
      filePath: filePath ?? this.filePath,
      groupPath: groupPath ?? this.groupPath,
    );
  }
}

/// Model representing a contact group (folder)
class ContactGroup {
  final String name; // Folder name (e.g., "family", "work")
  final String path; // Full path relative to contacts/ (e.g., "family", "work/engineering")
  final String? description;
  final String? created;
  final String? author;
  final int contactCount;

  ContactGroup({
    required this.name,
    required this.path,
    this.description,
    this.created,
    this.author,
    this.contactCount = 0,
  });

  /// Parse created timestamp to DateTime
  DateTime? get createdDateTime {
    if (created == null) return null;
    try {
      final normalized = created!.replaceAll('_', ':');
      return DateTime.parse(normalized);
    } catch (e) {
      return null;
    }
  }

  /// Get display timestamp
  String? get displayCreated => created?.replaceAll('_', ':');

  /// Get filename for group metadata
  String get metadataFilename => 'group.txt';

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        if (description != null) 'description': description,
        if (created != null) 'created': created,
        if (author != null) 'author': author,
        'contactCount': contactCount,
      };

  /// Create from JSON
  factory ContactGroup.fromJson(Map<String, dynamic> json) {
    return ContactGroup(
      name: json['name'] as String,
      path: json['path'] as String,
      description: json['description'] as String?,
      created: json['created'] as String?,
      author: json['author'] as String?,
      contactCount: json['contactCount'] as int? ?? 0,
    );
  }
}
