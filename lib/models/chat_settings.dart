/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */

/// Chat settings for user preferences
class ChatSettings {
  /// Enable message signing by default
  final bool signMessages;

  ChatSettings({
    this.signMessages = true,
  });

  /// Create from JSON
  factory ChatSettings.fromJson(Map<String, dynamic> json) {
    return ChatSettings(
      signMessages: json['signMessages'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'signMessages': signMessages,
    };
  }

  /// Copy with modifications
  ChatSettings copyWith({
    bool? signMessages,
  }) {
    return ChatSettings(
      signMessages: signMessages ?? this.signMessages,
    );
  }
}
