import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/relay.dart';
import '../services/config_service.dart';
import '../services/log_service.dart';
import '../services/websocket_service.dart';
import '../services/profile_service.dart';

/// Service for managing internet relays
class RelayService {
  static final RelayService _instance = RelayService._internal();
  factory RelayService() => _instance;
  RelayService._internal();

  List<Relay> _relays = [];
  bool _initialized = false;
  WebSocketService? _wsService;

  /// Default relays
  static final List<Relay> _defaultRelays = [];

  /// Initialize relay service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _loadRelays();
      _initialized = true;
      LogService().log('RelayService initialized with ${_relays.length} relays');

      // Auto-connect to preferred relay
      final preferredRelay = getPreferredRelay();
      if (preferredRelay != null && preferredRelay.url.isNotEmpty) {
        LogService().log('Auto-connecting to preferred relay: ${preferredRelay.name}');
        connectRelay(preferredRelay.url);
      }
    } catch (e) {
      LogService().log('Error initializing RelayService: $e');
    }
  }

  /// Load relays from config
  Future<void> _loadRelays() async {
    final config = ConfigService().getAll();

    if (config.containsKey('relays')) {
      final relaysData = config['relays'] as List<dynamic>;
      _relays = relaysData.map((data) => Relay.fromJson(data as Map<String, dynamic>)).toList();
      LogService().log('Loaded ${_relays.length} relays from config');
    } else {
      // First time - use default relays
      _relays = _defaultRelays.map((r) => r.copyWith()).toList();

      // Set first as preferred
      if (_relays.isNotEmpty) {
        _relays[0] = _relays[0].copyWith(status: 'preferred');
      }

      await _saveRelays();
      LogService().log('Created default relay configuration');
    }
  }

  /// Save relays to config
  Future<void> _saveRelays() async {
    final relaysData = _relays.map((r) => r.toJson()).toList();
    await ConfigService().set('relays', relaysData);
    LogService().log('Saved ${_relays.length} relays to config');
  }

  /// Get all relays
  List<Relay> getAllRelays() {
    if (!_initialized) {
      throw Exception('RelayService not initialized');
    }
    return List.unmodifiable(_relays);
  }

  /// Get preferred relay
  Relay? getPreferredRelay() {
    return _relays.firstWhere(
      (r) => r.status == 'preferred',
      orElse: () => _relays.isNotEmpty ? _relays[0] : Relay(url: '', name: ''),
    );
  }

  /// Get backup relays
  List<Relay> getBackupRelays() {
    return _relays.where((r) => r.status == 'backup').toList();
  }

  /// Get available relays (not selected)
  List<Relay> getAvailableRelays() {
    return _relays.where((r) => r.status == 'available').toList();
  }

  /// Add a new relay
  Future<void> addRelay(Relay relay) async {
    // Check if URL already exists
    final exists = _relays.any((r) => r.url == relay.url);
    if (exists) {
      throw Exception('Relay URL already exists');
    }

    _relays.add(relay);
    await _saveRelays();
    LogService().log('Added relay: ${relay.name}');
  }

  /// Update relay
  Future<void> updateRelay(String url, Relay updatedRelay) async {
    final index = _relays.indexWhere((r) => r.url == url);
    if (index == -1) {
      throw Exception('Relay not found');
    }

    _relays[index] = updatedRelay;
    await _saveRelays();
    LogService().log('Updated relay: ${updatedRelay.name}');
  }

  /// Set relay as preferred
  Future<void> setPreferred(String url) async {
    // Remove preferred status from all relays
    for (var i = 0; i < _relays.length; i++) {
      if (_relays[i].status == 'preferred') {
        _relays[i] = _relays[i].copyWith(status: 'available');
      }
    }

    // Set new preferred
    final index = _relays.indexWhere((r) => r.url == url);
    if (index != -1) {
      _relays[index] = _relays[index].copyWith(status: 'preferred');
      await _saveRelays();
      LogService().log('Set preferred relay: ${_relays[index].name}');
    }
  }

  /// Set relay as backup
  /// Automatically switches preferred relay if current preferred is being set as backup
  Future<void> setBackup(String url) async {
    final index = _relays.indexWhere((r) => r.url == url);
    if (index == -1) return;

    final wasPreferred = _relays[index].status == 'preferred';

    // Set the relay as backup
    _relays[index] = _relays[index].copyWith(status: 'backup');

    // If this was the preferred relay, we need to select a new preferred
    if (wasPreferred) {
      LogService().log('Current preferred relay being set as backup, selecting new preferred...');

      // First, try to find another backup relay
      Relay? newPreferred;
      for (var relay in _relays) {
        if (relay.status == 'backup' && relay.url != url) {
          newPreferred = relay;
          break;
        }
      }

      // If no backup relay, find closest available relay
      if (newPreferred == null) {
        final profile = ProfileService().getProfile();
        final availableRelays = _relays.where((r) => r.status == 'available').toList();

        if (availableRelays.isNotEmpty) {
          if (profile.latitude != null && profile.longitude != null) {
            // Sort by distance
            availableRelays.sort((a, b) {
              final distA = a.calculateDistance(profile.latitude, profile.longitude) ?? double.infinity;
              final distB = b.calculateDistance(profile.latitude, profile.longitude) ?? double.infinity;
              return distA.compareTo(distB);
            });
            newPreferred = availableRelays.first;
            LogService().log('Selected closest available relay: ${newPreferred.name}');
          } else {
            // No location available, just pick the first available
            newPreferred = availableRelays.first;
            LogService().log('No location available, selected first available relay: ${newPreferred.name}');
          }
        }
      } else {
        LogService().log('Selected next backup relay as preferred: ${newPreferred.name}');
      }

      // Set the new preferred relay
      if (newPreferred != null) {
        final newIndex = _relays.indexWhere((r) => r.url == newPreferred!.url);
        if (newIndex != -1) {
          _relays[newIndex] = _relays[newIndex].copyWith(status: 'preferred');
        }
      } else {
        LogService().log('WARNING: No other relay available to set as preferred!');
      }
    }

    await _saveRelays();
    LogService().log('Set backup relay: ${_relays[index].name}');
  }

  /// Set relay as available (unselect)
  Future<void> setAvailable(String url) async {
    final index = _relays.indexWhere((r) => r.url == url);
    if (index != -1) {
      _relays[index] = _relays[index].copyWith(status: 'available');
      await _saveRelays();
      LogService().log('Set relay as available: ${_relays[index].name}');
    }
  }

  /// Delete relay
  Future<void> deleteRelay(String url) async {
    final index = _relays.indexWhere((r) => r.url == url);
    if (index != -1) {
      final relay = _relays[index];
      _relays.removeAt(index);
      await _saveRelays();
      LogService().log('Deleted relay: ${relay.name}');
    }
  }

  /// Test relay connection (stub for now)
  Future<void> testConnection(String url) async {
    final index = _relays.indexWhere((r) => r.url == url);
    if (index != -1) {
      // Simulate connection test
      await Future.delayed(const Duration(seconds: 1));

      // For now, just update last checked time
      _relays[index] = _relays[index].copyWith(
        lastChecked: DateTime.now(),
        isConnected: true,
        latency: 50 + (url.hashCode % 100), // Simulated latency
      );

      await _saveRelays();
      LogService().log('Tested relay: ${_relays[index].name}');
    }
  }

  /// Connect to relay with hello handshake
  Future<bool> connectRelay(String url) async {
    try {
      LogService().log('');
      LogService().log('══════════════════════════════════════');
      LogService().log('RELAY CONNECTION REQUEST');
      LogService().log('══════════════════════════════════════');
      LogService().log('URL: $url');

      // Disconnect existing connection if any
      if (_wsService != null) {
        LogService().log('Disconnecting previous connection...');
        _wsService!.disconnect();
        _wsService = null;
      }

      // Create new WebSocket service
      _wsService = WebSocketService();

      // Attempt connection with hello handshake
      final startTime = DateTime.now();
      final success = await _wsService!.connectAndHello(url);

      if (success) {
        final latency = DateTime.now().difference(startTime).inMilliseconds;

        // Fetch relay status to get connected devices count
        int? connectedDevices;
        try {
          final httpUrl = url.replaceFirst('ws://', 'http://').replaceFirst('wss://', 'https://');
          final response = await http.get(Uri.parse(httpUrl));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            connectedDevices = data['connected_devices'] as int?;
            LogService().log('Fetched relay status: $connectedDevices devices connected');
          }
        } catch (e) {
          LogService().log('Warning: Could not fetch relay status: $e');
        }

        // Update relay status
        final index = _relays.indexWhere((r) => r.url == url);
        if (index != -1) {
          _relays[index] = _relays[index].copyWith(
            lastChecked: DateTime.now(),
            isConnected: true,
            latency: latency,
            connectedDevices: connectedDevices,
          );
          await _saveRelays();

          LogService().log('');
          LogService().log('✓ CONNECTION SUCCESSFUL');
          LogService().log('Relay: ${_relays[index].name}');
          LogService().log('Latency: ${latency}ms');
          if (connectedDevices != null) {
            LogService().log('Connected devices: $connectedDevices');
          }
          LogService().log('══════════════════════════════════════');
        }

        return true;
      } else {
        LogService().log('');
        LogService().log('✗ CONNECTION FAILED');
        LogService().log('══════════════════════════════════════');

        // Update relay as disconnected
        final index = _relays.indexWhere((r) => r.url == url);
        if (index != -1) {
          _relays[index] = _relays[index].copyWith(
            lastChecked: DateTime.now(),
            isConnected: false,
          );
          await _saveRelays();
        }

        return false;
      }
    } catch (e) {
      LogService().log('');
      LogService().log('CONNECTION ERROR');
      LogService().log('══════════════════════════════════════');
      LogService().log('Error: $e');
      LogService().log('══════════════════════════════════════');
      return false;
    }
  }

  /// Disconnect from current relay
  void disconnect() {
    if (_wsService != null) {
      LogService().log('Disconnecting from relay...');
      _wsService!.disconnect();
      _wsService = null;

      // Update all relays as disconnected
      for (var i = 0; i < _relays.length; i++) {
        if (_relays[i].isConnected) {
          _relays[i] = _relays[i].copyWith(isConnected: false);
        }
      }
      _saveRelays();
    }
  }
}
