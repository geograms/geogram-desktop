import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Nostr Event structure (NIP-01)
class NostrEvent {
  final String pubkey; // hex public key
  final int createdAt; // unix timestamp
  final int kind; // event kind (1 = text note)
  final List<List<String>> tags; // event tags
  final String content; // event content
  String? id; // event id (sha256 hash)
  String? sig; // event signature

  NostrEvent({
    required this.pubkey,
    required this.createdAt,
    required this.kind,
    required this.tags,
    required this.content,
    this.id,
    this.sig,
  });

  /// Create hello event
  static NostrEvent createHello({
    required String npub,
    required String callsign,
  }) {
    // Extract public key from npub (remove npub1 prefix and take hex)
    final pubkeyHex = _npubToHex(npub);

    return NostrEvent(
      pubkey: pubkeyHex,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: 1, // text note
      tags: [
        ['type', 'hello'],
        ['callsign', callsign],
      ],
      content: 'Hello from Geogram Desktop',
    );
  }

  /// Calculate event ID (sha256 of serialized event)
  String calculateId() {
    final serialized = _serialize();
    final bytes = utf8.encode(serialized);
    final hash = sha256.convert(bytes);
    id = hash.toString();
    return id!;
  }

  /// Sign event with private key (simplified - using SHA256 for now)
  /// TODO: Upgrade to secp256k1 signing
  String sign(String nsec) {
    if (id == null) {
      calculateId();
    }

    // For now, use simple SHA256-based signing
    // In production, this should use secp256k1
    final privkeyHex = _nsecToHex(nsec);
    final message = id! + privkeyHex;
    final bytes = utf8.encode(message);
    final hash = sha256.convert(bytes);
    sig = hash.toString();
    return sig!;
  }

  /// Serialize event for hashing (NIP-01 format)
  String _serialize() {
    return jsonEncode([
      0, // reserved
      pubkey,
      createdAt,
      kind,
      tags,
      content,
    ]);
  }

  /// Convert to JSON for transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pubkey': pubkey,
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
      'sig': sig,
    };
  }

  /// Convert npub to hex (simplified)
  static String _npubToHex(String npub) {
    // Remove npub1 prefix and take first 64 chars as hex
    // This is simplified - real implementation needs bech32 decoding
    final data = npub.replaceAll('npub1', '');
    return data.substring(0, data.length >= 64 ? 64 : data.length).padRight(64, '0');
  }

  /// Convert nsec to hex (simplified)
  static String _nsecToHex(String nsec) {
    // Remove nsec1 prefix and take first 64 chars as hex
    // This is simplified - real implementation needs bech32 decoding
    final data = nsec.replaceAll('nsec1', '');
    return data.substring(0, data.length >= 64 ? 64 : data.length).padRight(64, '0');
  }
}
