/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../services/place_service.dart';
import '../services/profile_service.dart';
import '../services/i18n_service.dart';
import 'location_picker_page.dart';

/// Full-page form for adding or editing a place
class AddEditPlacePage extends StatefulWidget {
  final String collectionPath;
  final Place? place; // null for new place, non-null for edit

  const AddEditPlacePage({
    Key? key,
    required this.collectionPath,
    this.place,
  }) : super(key: key);

  @override
  State<AddEditPlacePage> createState() => _AddEditPlacePageState();
}

class _AddEditPlacePageState extends State<AddEditPlacePage> {
  final PlaceService _placeService = PlaceService();
  final ProfileService _profileService = ProfileService();
  final I18nService _i18n = I18nService();
  final _formKey = GlobalKey<FormState>();

  // Controllers for fields
  late TextEditingController _nameController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _radiusController;
  late TextEditingController _addressController;
  late TextEditingController _typeController;
  late TextEditingController _foundedController;
  late TextEditingController _hoursController;
  late TextEditingController _descriptionController;
  late TextEditingController _historyController;

  bool _isSaving = false;

  // Common place types for quick selection
  final List<String> _commonTypes = [
    'restaurant',
    'cafe',
    'monument',
    'landmark',
    'park',
    'museum',
    'shop',
    'store',
    'hotel',
    'hospital',
    'school',
    'church',
    'library',
    'theater',
    'cinema',
    'gallery',
    'beach',
    'viewpoint',
    'market',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final place = widget.place;

    _nameController = TextEditingController(text: place?.name ?? '');
    _latitudeController = TextEditingController(text: place?.latitude.toString() ?? '');
    _longitudeController = TextEditingController(text: place?.longitude.toString() ?? '');
    _radiusController = TextEditingController(text: place?.radius.toString() ?? '50');
    _addressController = TextEditingController(text: place?.address ?? '');
    _typeController = TextEditingController(text: place?.type ?? '');
    _foundedController = TextEditingController(text: place?.founded ?? '');
    _hoursController = TextEditingController(text: place?.hours ?? '');
    _descriptionController = TextEditingController(text: place?.description ?? '');
    _historyController = TextEditingController(text: place?.history ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    _addressController.dispose();
    _typeController.dispose();
    _foundedController.dispose();
    _hoursController.dispose();
    _descriptionController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Collect values
      final name = _nameController.text.trim();
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());
      final radius = int.parse(_radiusController.text.trim());
      final address = _addressController.text.trim();
      final type = _typeController.text.trim();
      final founded = _foundedController.text.trim();
      final hours = _hoursController.text.trim();
      final description = _descriptionController.text.trim();
      final history = _historyController.text.trim();

      // Create timestamp
      final now = DateTime.now();
      final timestamp = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}_${now.second.toString().padLeft(2, '0')}';

      // Get current user as author
      final profile = _profileService.getProfile();
      final author = profile.callsign.isNotEmpty ? profile.callsign : 'ANONYMOUS';

      // Create place object
      final place = Place(
        name: name,
        created: widget.place?.created ?? timestamp,
        author: widget.place?.author ?? author,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        address: address.isNotEmpty ? address : null,
        type: type.isNotEmpty ? type : null,
        founded: founded.isNotEmpty ? founded : null,
        hours: hours.isNotEmpty ? hours : null,
        description: description,
        history: history.isNotEmpty ? history : null,
      );

      // Save place
      final error = await _placeService.savePlace(place);

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _getCurrentLocation() {
    // TODO: Implement GPS location fetching
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_i18n.t('gps_not_implemented'))),
    );
  }

  Future<void> _openMapPicker() async {
    // Get current coordinates if available
    LatLng? initialPosition;
    final lat = double.tryParse(_latitudeController.text.trim());
    final lon = double.tryParse(_longitudeController.text.trim());
    if (lat != null && lon != null && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
      initialPosition = LatLng(lat, lon);
    }

    // Open location picker
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          initialPosition: initialPosition,
        ),
      ),
    );

    // Update coordinates if location was selected
    if (result != null) {
      setState(() {
        _latitudeController.text = result.latitude.toStringAsFixed(6);
        _longitudeController.text = result.longitude.toStringAsFixed(6);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.place != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? _i18n.t('edit_place') : _i18n.t('new_place')),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _save,
              child: Text(
                _i18n.t('save'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Required Fields Section
            Text(
              _i18n.t('required_fields'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Place Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '${_i18n.t('place_name')} *',
                border: const OutlineInputBorder(),
                hintText: 'Historic Café Landmark',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return _i18n.t('field_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Coordinates Section
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: InputDecoration(
                      labelText: '${_i18n.t('latitude')} *',
                      border: const OutlineInputBorder(),
                      hintText: '38.7223',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _i18n.t('field_required');
                      }
                      final lat = double.tryParse(value.trim());
                      if (lat == null || lat < -90 || lat > 90) {
                        return _i18n.t('invalid_latitude');
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: InputDecoration(
                      labelText: '${_i18n.t('longitude')} *',
                      border: const OutlineInputBorder(),
                      hintText: '-9.1393',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _i18n.t('field_required');
                      }
                      final lon = double.tryParse(value.trim());
                      if (lon == null || lon < -180 || lon > 180) {
                        return _i18n.t('invalid_longitude');
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _getCurrentLocation,
                  tooltip: _i18n.t('use_current_location'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Radius
            TextFormField(
              controller: _radiusController,
              decoration: InputDecoration(
                labelText: '${_i18n.t('radius')} (${_i18n.t('meters')}) *',
                border: const OutlineInputBorder(),
                hintText: '50',
                helperText: _i18n.t('radius_help'),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return _i18n.t('field_required');
                }
                final radius = int.tryParse(value.trim());
                if (radius == null || radius < 10 || radius > 1000) {
                  return _i18n.t('radius_range_error');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Optional Fields Section
            Text(
              _i18n.t('optional_fields'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: _i18n.t('address'),
                border: const OutlineInputBorder(),
                hintText: '123 Main Street, Lisbon, Portugal',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Type (with suggestions)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _typeController,
                    decoration: InputDecoration(
                      labelText: _i18n.t('place_type'),
                      border: const OutlineInputBorder(),
                      hintText: 'restaurant, monument, park...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  tooltip: _i18n.t('select_type'),
                  onSelected: (type) {
                    setState(() {
                      _typeController.text = type;
                    });
                  },
                  itemBuilder: (context) => _commonTypes.map((type) {
                    return PopupMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Founded
            TextFormField(
              controller: _foundedController,
              decoration: InputDecoration(
                labelText: _i18n.t('founded'),
                border: const OutlineInputBorder(),
                hintText: '1782, 12th century, circa 1500, Roman era',
              ),
            ),
            const SizedBox(height: 16),

            // Hours
            TextFormField(
              controller: _hoursController,
              decoration: InputDecoration(
                labelText: _i18n.t('hours'),
                border: const OutlineInputBorder(),
                hintText: 'Mon-Fri 9:00-17:00, Sat-Sun 10:00-16:00',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: _i18n.t('description'),
                border: const OutlineInputBorder(),
                helperText: _i18n.t('place_description_help'),
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 16),

            // History
            TextFormField(
              controller: _historyController,
              decoration: InputDecoration(
                labelText: _i18n.t('history'),
                border: const OutlineInputBorder(),
                helperText: _i18n.t('place_history_help'),
              ),
              maxLines: 8,
            ),

            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_i18n.t('save')),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
