/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */

/// Represents a chat channel (main group, direct message, or custom group)
class ChatChannel {
  /// Unique channel identifier (e.g., "main", "X135AS", "team-alpha")
  final String id;

  /// Channel type
  final ChatChannelType type;

  /// Display name
  final String name;

  /// Folder name (relative to collection root)
  final String folder;

  /// List of participant callsigns ("*" for public main channel)
  final List<String> participants;

  /// Channel description
  final String? description;

  /// When channel was created
  final DateTime created;

  /// Last message timestamp (for sorting)
  DateTime? lastMessageTime;

  /// Unread message count
  int unreadCount;

  /// Is channel favorited/pinned
  bool isFavorite;

  /// Channel configuration (from config.json)
  final ChatChannelConfig? config;

  ChatChannel({
    required this.id,
    required this.type,
    required this.name,
    required this.folder,
    required this.participants,
    this.description,
    required this.created,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isFavorite = false,
    this.config,
  });

  /// Create main group channel
  factory ChatChannel.main({
    String name = 'Main Chat',
    String? description,
    ChatChannelConfig? config,
  }) {
    return ChatChannel(
      id: 'main',
      type: ChatChannelType.group,
      name: name,
      folder: 'main',
      participants: ['*'], // Public for everyone
      description: description ?? 'Public group chat for everyone',
      created: DateTime.now(),
      config: config,
    );
  }

  /// Create direct message channel
  factory ChatChannel.direct({
    required String callsign,
    ChatChannelConfig? config,
  }) {
    return ChatChannel(
      id: callsign,
      type: ChatChannelType.direct,
      name: callsign,
      folder: callsign,
      participants: [callsign], // Will add owner when created
      description: 'Direct message with $callsign',
      created: DateTime.now(),
      config: config,
    );
  }

  /// Create custom group channel
  factory ChatChannel.group({
    required String id,
    required String name,
    required List<String> participants,
    String? description,
    ChatChannelConfig? config,
  }) {
    return ChatChannel(
      id: id,
      type: ChatChannelType.group,
      name: name,
      folder: id,
      participants: participants,
      description: description,
      created: DateTime.now(),
      config: config,
    );
  }

  /// Check if channel is the main group
  bool get isMain => id == 'main';

  /// Check if channel is a direct message
  bool get isDirect => type == ChatChannelType.direct;

  /// Check if channel is a custom group
  bool get isGroup => type == ChatChannelType.group;

  /// Check if channel is public (main channel with "*")
  bool get isPublic => participants.contains('*');

  /// Get icon name for channel type
  String get iconName {
    switch (type) {
      case ChatChannelType.group:
        return isMain ? 'forum' : 'group';
      case ChatChannelType.direct:
        return 'person';
    }
  }

  /// Get display subtitle (participant count or last message preview)
  String get subtitle {
    if (isDirect) {
      return 'Direct message';
    } else if (isMain) {
      return 'Public group chat';
    } else {
      int count = participants.length;
      return '$count participant${count != 1 ? 's' : ''}';
    }
  }

  /// Create from JSON
  factory ChatChannel.fromJson(Map<String, dynamic> json) {
    return ChatChannel(
      id: json['id'] as String,
      type: ChatChannelType.values.firstWhere(
        (t) => t.name == (json['type'] as String),
        orElse: () => ChatChannelType.group,
      ),
      name: json['name'] as String,
      folder: json['folder'] as String,
      participants: List<String>.from(json['participants'] as List? ?? []),
      description: json['description'] as String?,
      created: DateTime.parse(json['created'] as String),
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      config: json['config'] != null
          ? ChatChannelConfig.fromJson(json['config'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'folder': folder,
      'participants': participants,
      if (description != null) 'description': description,
      'created': created.toIso8601String(),
      if (lastMessageTime != null)
        'lastMessageTime': lastMessageTime!.toIso8601String(),
      'unreadCount': unreadCount,
      'isFavorite': isFavorite,
      if (config != null) 'config': config!.toJson(),
    };
  }

  /// Create a copy with modified fields
  ChatChannel copyWith({
    String? id,
    ChatChannelType? type,
    String? name,
    String? folder,
    List<String>? participants,
    String? description,
    DateTime? created,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isFavorite,
    ChatChannelConfig? config,
  }) {
    return ChatChannel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      folder: folder ?? this.folder,
      participants: participants ?? List<String>.from(this.participants),
      description: description ?? this.description,
      created: created ?? this.created,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isFavorite: isFavorite ?? this.isFavorite,
      config: config ?? this.config,
    );
  }

  @override
  String toString() {
    return 'ChatChannel(id: $id, type: ${type.name}, name: $name, '
        'participants: ${participants.length})';
  }
}

/// Channel type enumeration
enum ChatChannelType {
  group, // Group chat (main or custom)
  direct, // Direct 1:1 message
}

/// Channel configuration (from config.json)
class ChatChannelConfig {
  /// Channel ID
  final String id;

  /// Channel name
  final String name;

  /// Description
  final String? description;

  /// Visibility (PUBLIC, PRIVATE, RESTRICTED)
  final String visibility;

  /// Is read-only
  final bool readonly;

  /// Allow file uploads
  final bool fileUpload;

  /// Max files per message
  final int filesPerPost;

  /// Max file size in MB
  final int maxFileSize;

  /// Max message text size in characters
  final int maxSizeText;

  /// List of moderator callsigns
  final List<String> moderators;

  ChatChannelConfig({
    required this.id,
    required this.name,
    this.description,
    this.visibility = 'PUBLIC',
    this.readonly = false,
    this.fileUpload = true,
    this.filesPerPost = 3,
    this.maxFileSize = 10,
    this.maxSizeText = 500,
    this.moderators = const [],
  });

  /// Create default config for a channel
  factory ChatChannelConfig.defaults({
    required String id,
    required String name,
    String? description,
  }) {
    return ChatChannelConfig(
      id: id,
      name: name,
      description: description,
      visibility: 'PUBLIC',
      readonly: false,
      fileUpload: true,
      filesPerPost: 3,
      maxFileSize: 10,
      maxSizeText: 500,
      moderators: [],
    );
  }

  /// Create from JSON
  factory ChatChannelConfig.fromJson(Map<String, dynamic> json) {
    return ChatChannelConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      visibility: json['visibility'] as String? ?? 'PUBLIC',
      readonly: json['readonly'] as bool? ?? false,
      fileUpload: json['file_upload'] as bool? ?? true,
      filesPerPost: json['files_per_post'] as int? ?? 3,
      maxFileSize: json['max_file_size'] as int? ?? 10,
      maxSizeText: json['max_size_text'] as int? ?? 500,
      moderators: List<String>.from(json['moderators'] as List? ?? []),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'visibility': visibility,
      'readonly': readonly,
      'file_upload': fileUpload,
      'files_per_post': filesPerPost,
      'max_file_size': maxFileSize,
      'max_size_text': maxSizeText,
      'moderators': moderators,
    };
  }

  @override
  String toString() {
    return 'ChatChannelConfig(id: $id, name: $name, visibility: $visibility)';
  }
}
