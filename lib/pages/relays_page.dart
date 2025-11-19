import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/relay.dart';
import '../services/relay_service.dart';
import '../services/log_service.dart';
import '../services/relay_discovery_service.dart';
import '../services/profile_service.dart';
import '../services/i18n_service.dart';

class RelaysPage extends StatefulWidget {
  const RelaysPage({super.key});

  @override
  State<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends State<RelaysPage> {
  final RelayService _relayService = RelayService();
  final ProfileService _profileService = ProfileService();
  final I18nService _i18n = I18nService();
  List<Relay> _allRelays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRelays();
    _ensureUserLocation();
  }

  /// Ensure user location is set, auto-detect if not
  Future<void> _ensureUserLocation() async {
    try {
      final profile = _profileService.getProfile();

      // If location is already set, we're done
      if (profile.latitude != null && profile.longitude != null) {
        LogService().log('User location already set: ${profile.latitude}, ${profile.longitude}');
        return;
      }

      // Auto-detect location from IP
      LogService().log('User location not set, detecting from IP...');
      final location = await _detectLocationFromIP();

      if (location != null) {
        await _profileService.updateProfile(
          latitude: location['lat'],
          longitude: location['lon'],
          locationName: location['locationName'],
        );
        LogService().log('User location auto-detected and saved: ${location['lat']}, ${location['lon']}');

        // Reload relays to show distances
        _loadRelays();
      } else {
        LogService().log('Unable to auto-detect user location (offline?)');
      }
    } catch (e) {
      LogService().log('Error ensuring user location: $e');
    }
  }

  /// Detect location from IP address
  Future<Map<String, dynamic>?> _detectLocationFromIP() async {
    try {
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final lat = data['lat'] as double;
          final lon = data['lon'] as double;
          final city = data['city'] as String?;
          final country = data['country'] as String?;

          return {
            'lat': lat,
            'lon': lon,
            'locationName': (city != null && country != null) ? '$city, $country' : null,
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadRelays() async {
    setState(() => _isLoading = true);

    try {
      final relays = _relayService.getAllRelays();
      setState(() {
        _allRelays = relays;
        _isLoading = false;
      });
      LogService().log('Loaded ${relays.length} relays');
    } catch (e) {
      LogService().log('Error loading relays: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCustomRelay() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _AddRelayDialog(),
    );

    if (result != null) {
      try {
        final relay = Relay(
          url: result['url']!,
          name: result['name']!,
          status: 'available',
          location: result['location'],
          latitude: result['latitude'] != null ? double.tryParse(result['latitude']!) : null,
          longitude: result['longitude'] != null ? double.tryParse(result['longitude']!) : null,
        );

        await _relayService.addRelay(relay);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_i18n.t('added_relay', params: [relay.name]))),
          );
        }

        _loadRelays();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_i18n.t('error_adding_relay', params: [e.toString()])),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _setPreferred(Relay relay) async {
    try {
      await _relayService.setPreferred(relay.url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_i18n.t('set_preferred_success', params: [relay.name]))),
      );
      _loadRelays();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_i18n.t('error', params: [e.toString()])),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setBackup(Relay relay) async {
    try {
      await _relayService.setBackup(relay.url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_i18n.t('added_to_backup', params: [relay.name]))),
      );
      _loadRelays();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_i18n.t('error', params: [e.toString()])),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setAvailable(Relay relay) async {
    try {
      await _relayService.setAvailable(relay.url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_i18n.t('removed_from_selection', params: [relay.name]))),
      );
      _loadRelays();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_i18n.t('error', params: [e.toString()])),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRelay(Relay relay) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_i18n.t('delete_relay')),
        content: Text(_i18n.t('delete_relay_confirm', params: [relay.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_i18n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(_i18n.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _relayService.deleteRelay(relay.url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_i18n.t('deleted_relay', params: [relay.name]))),
          );
        }
        _loadRelays();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_i18n.t('error_deleting_relay', params: [e.toString()])),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllRelays() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_i18n.t('clear_all_relays_title')),
        content: Text(_i18n.t('clear_all_relays_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_i18n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(_i18n.t('clear_all')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final relays = _relayService.getAllRelays();
        for (var relay in relays) {
          await _relayService.deleteRelay(relay.url);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_i18n.t('all_relays_cleared'))),
          );
        }
        _loadRelays();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_i18n.t('error_clearing_relays', params: [e.toString()])),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _scanNow() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_i18n.t('scanning_relays')),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await RelayDiscoveryService().discover();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_i18n.t('scan_complete')),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadRelays();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_i18n.t('error_during_scan', params: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testConnection(Relay relay) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_i18n.t('connecting_to_relay', params: [relay.name])),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      // Use new connectRelay method with hello handshake
      final success = await _relayService.connectRelay(relay.url);
      _loadRelays();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_i18n.t('connected_success', params: [relay.name])),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_i18n.t('connection_failed')),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_i18n.t('connection_error', params: [e.toString()])),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Relay> get _selectedRelays {
    return _allRelays.where((r) => r.status == 'preferred' || r.status == 'backup').toList()
      ..sort((a, b) {
        // Preferred first
        if (a.status == 'preferred') return -1;
        if (b.status == 'preferred') return 1;
        return 0;
      });
  }

  List<Relay> get _availableRelays {
    return _allRelays.where((r) => r.status == 'available').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_i18n.t('internet_relays')),
        actions: [
          IconButton(
            icon: const Icon(Icons.radar),
            onPressed: _scanNow,
            tooltip: _i18n.t('scan_local_network'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAllRelays,
            tooltip: _i18n.t('clear_all_relays'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRelays,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info Card
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _i18n.t('internet_relay_config'),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _i18n.t('relay_instructions'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Selected Relay Section
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedRelays.length == 1 ? _i18n.t('selected_relay') : _i18n.t('selected_relays'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_selectedRelays.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            _i18n.t('no_relays_selected'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._selectedRelays.map((relay) {
                      final profile = _profileService.getProfile();
                      return _RelayCard(
                        relay: relay,
                        userLatitude: profile.latitude,
                        userLongitude: profile.longitude,
                        onSetPreferred: () => _setPreferred(relay),
                        onSetBackup: () => _setBackup(relay),
                        onSetAvailable: () => _setAvailable(relay),
                        onDelete: () => _deleteRelay(relay),
                        onTest: () => _testConnection(relay),
                      );
                    }),

                  const SizedBox(height: 32),

                  // Available Relays Section
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _i18n.t('available_relays'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_availableRelays.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            _i18n.t('all_relays_selected'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._availableRelays.map((relay) {
                      final profile = _profileService.getProfile();
                      return _RelayCard(
                        relay: relay,
                        userLatitude: profile.latitude,
                        userLongitude: profile.longitude,
                        onSetPreferred: () => _setPreferred(relay),
                        onSetBackup: () => _setBackup(relay),
                        onSetAvailable: null, // Already available
                        onDelete: () => _deleteRelay(relay),
                        onTest: () => _testConnection(relay),
                        isAvailableRelay: true,
                      );
                    }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomRelay,
        icon: const Icon(Icons.add),
        label: Text(_i18n.t('add_relay')),
      ),
    );
  }
}

// Relay Card Widget
class _RelayCard extends StatelessWidget {
  final Relay relay;
  final double? userLatitude;
  final double? userLongitude;
  final VoidCallback onSetPreferred;
  final VoidCallback onSetBackup;
  final VoidCallback? onSetAvailable;
  final VoidCallback onDelete;
  final VoidCallback onTest;
  final bool isAvailableRelay;

  const _RelayCard({
    required this.relay,
    this.userLatitude,
    this.userLongitude,
    required this.onSetPreferred,
    required this.onSetBackup,
    required this.onSetAvailable,
    required this.onDelete,
    required this.onTest,
    this.isAvailableRelay = false,
  });

  I18nService get _i18n => I18nService();

  String _getStatusDisplayText() {
    switch (relay.status) {
      case 'preferred':
        return _i18n.t('preferred');
      case 'backup':
        return _i18n.t('backup');
      default:
        return _i18n.t('available');
    }
  }

  String _getConnectionStatusText() {
    if (relay.isConnected) {
      return relay.latency != null
        ? _i18n.translate('connected_with_latency', params: [relay.latency.toString()])
        : _i18n.t('connected');
    }
    return _i18n.t('disconnected');
  }

  String? _getDistanceText(double? userLat, double? userLon) {
    final distance = relay.calculateDistance(userLat, userLon);
    if (distance == null) return null;

    if (distance < 1) {
      final meters = (distance * 1000).round();
      return _i18n.translate('meters_away', params: [meters.toString()]);
    } else {
      final km = distance.round();
      return _i18n.translate('kilometers_away', params: [km.toString()]);
    }
  }

  Color _getStatusColor(BuildContext context) {
    switch (relay.status) {
      case 'preferred':
        return Colors.green;
      case 'backup':
        return Colors.orange;
      default:
        // Show green if relay is online/reachable (has device count data)
        return relay.connectedDevices != null
            ? Colors.green
            : Theme.of(context).colorScheme.outline;
    }
  }

  IconData _getStatusIcon() {
    switch (relay.status) {
      case 'preferred':
        return Icons.star;
      case 'backup':
        return Icons.check_circle;
      default:
        return Icons.cloud_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(context),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        relay.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        relay.url,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (relay.location != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              relay.location!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            if (relay.latitude != null && relay.longitude != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(${relay.latitude!.toStringAsFixed(4)}, ${relay.longitude!.toStringAsFixed(4)})',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      // Display distance if available
                      if (_getDistanceText(userLatitude, userLongitude) != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              size: 14,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getDistanceText(userLatitude, userLongitude)!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isAvailableRelay)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(context),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusDisplayText(),
                      style: TextStyle(
                        color: _getStatusColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Connection Status (hide for available relays)
            if (relay.lastChecked != null && !isAvailableRelay)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          relay.isConnected ? Icons.check_circle : Icons.error,
                          size: 16,
                          color: relay.isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getConnectionStatusText(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          _i18n.translate('last_checked', params: [_formatTime(relay.lastChecked!)]),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    // Show connected devices count if available
                    if (relay.connectedDevices != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.devices,
                            size: 14,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${relay.connectedDevices} ${relay.connectedDevices == 1 ? _i18n.t("device") : _i18n.t("devices_connected")}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Only show Set Preferred if NOT already preferred
                if (relay.status != 'preferred')
                  OutlinedButton.icon(
                    onPressed: onSetPreferred,
                    icon: const Icon(Icons.star, size: 16),
                    label: Text(_i18n.t('set_preferred')),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (relay.status != 'backup')
                  OutlinedButton.icon(
                    onPressed: onSetBackup,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(_i18n.t('set_as_backup')),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (onSetAvailable != null)
                  OutlinedButton.icon(
                    onPressed: onSetAvailable,
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: Text(_i18n.t('remove')),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: onTest,
                  icon: const Icon(Icons.network_check, size: 16),
                  label: Text(_i18n.t('test')),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  tooltip: _i18n.t('delete'),
                  color: Theme.of(context).colorScheme.error,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

// Add Relay Dialog
class _AddRelayDialog extends StatefulWidget {
  const _AddRelayDialog();

  @override
  State<_AddRelayDialog> createState() => _AddRelayDialogState();
}

class _AddRelayDialogState extends State<_AddRelayDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _add() {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final location = _locationController.text.trim();
    final latText = _latitudeController.text.trim();
    final lonText = _longitudeController.text.trim();

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in name and URL')),
      );
      return;
    }

    if (!url.startsWith('wss://') && !url.startsWith('ws://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL must start with wss:// or ws://')),
      );
      return;
    }

    final result = <String, String>{
      'name': name,
      'url': url,
    };

    if (location.isNotEmpty) {
      result['location'] = location;
    }

    if (latText.isNotEmpty && lonText.isNotEmpty) {
      final lat = double.tryParse(latText);
      final lon = double.tryParse(lonText);

      if (lat == null || lon == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid coordinates. Use decimal format.')),
        );
        return;
      }

      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coordinates out of range')),
        );
        return;
      }

      result['latitude'] = latText;
      result['longitude'] = lonText;
    }

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Relay'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Relay Name *',
                  hintText: 'e.g., My Custom Relay',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Relay URL *',
                  hintText: 'wss://relay.example.com',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Optional Location Information',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Tokyo, Japan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: '35.6762',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: '139.6503',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '* Required fields',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _add,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
