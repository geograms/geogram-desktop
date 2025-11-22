/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */

import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';
import '../services/profile_service.dart';
import '../services/i18n_service.dart';

/// Full-page form for adding or editing a contact
class AddEditContactPage extends StatefulWidget {
  final String collectionPath;
  final Contact? contact; // null for new contact, non-null for edit

  const AddEditContactPage({
    Key? key,
    required this.collectionPath,
    this.contact,
  }) : super(key: key);

  @override
  State<AddEditContactPage> createState() => _AddEditContactPageState();
}

class _AddEditContactPageState extends State<AddEditContactPage> {
  final ContactService _contactService = ContactService();
  final ProfileService _profileService = ProfileService();
  final I18nService _i18n = I18nService();
  final _formKey = GlobalKey<FormState>();

  // Controllers for single-value fields
  late TextEditingController _displayNameController;
  late TextEditingController _callsignController;
  late TextEditingController _npubController;
  late TextEditingController _notesController;

  // Lists for multi-value fields
  List<TextEditingController> _emailControllers = [];
  List<TextEditingController> _phoneControllers = [];
  List<TextEditingController> _addressControllers = [];
  List<TextEditingController> _websiteControllers = [];
  List<Map<String, TextEditingController>> _locationControllers = [];

  String? _selectedGroup;
  List<ContactGroup> _groups = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadGroups();
  }

  void _initializeControllers() {
    final contact = widget.contact;

    _displayNameController = TextEditingController(text: contact?.displayName ?? '');
    _callsignController = TextEditingController(text: contact?.callsign ?? '');
    _npubController = TextEditingController(text: contact?.npub ?? '');
    _notesController = TextEditingController(text: contact?.notes ?? '');

    // Initialize multi-value fields
    if (contact != null) {
      _emailControllers = contact.emails.map((e) => TextEditingController(text: e)).toList();
      _phoneControllers = contact.phones.map((p) => TextEditingController(text: p)).toList();
      _addressControllers = contact.addresses.map((a) => TextEditingController(text: a)).toList();
      _websiteControllers = contact.websites.map((w) => TextEditingController(text: w)).toList();
      _locationControllers = contact.locations.map((loc) => {
        'name': TextEditingController(text: loc.name),
        'lat': TextEditingController(text: loc.latitude?.toString() ?? ''),
        'long': TextEditingController(text: loc.longitude?.toString() ?? ''),
      }).toList();
      _selectedGroup = contact.groupPath;
    }

    // Add at least one empty field for each multi-value type
    if (_emailControllers.isEmpty) _emailControllers.add(TextEditingController());
    if (_phoneControllers.isEmpty) _phoneControllers.add(TextEditingController());
    if (_addressControllers.isEmpty) _addressControllers.add(TextEditingController());
    if (_websiteControllers.isEmpty) _websiteControllers.add(TextEditingController());
    if (_locationControllers.isEmpty) {
      _locationControllers.add({
        'name': TextEditingController(),
        'lat': TextEditingController(),
        'long': TextEditingController(),
      });
    }
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      await _contactService.initializeCollection(widget.collectionPath);
      final groups = await _contactService.loadGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _callsignController.dispose();
    _npubController.dispose();
    _notesController.dispose();

    for (var controller in _emailControllers) controller.dispose();
    for (var controller in _phoneControllers) controller.dispose();
    for (var controller in _addressControllers) controller.dispose();
    for (var controller in _websiteControllers) controller.dispose();
    for (var controllers in _locationControllers) {
      controllers['name']?.dispose();
      controllers['lat']?.dispose();
      controllers['long']?.dispose();
    }

    super.dispose();
  }

  void _addField(List<dynamic> controllers) {
    setState(() {
      if (controllers == _locationControllers) {
        controllers.add({
          'name': TextEditingController(),
          'lat': TextEditingController(),
          'long': TextEditingController(),
        });
      } else {
        controllers.add(TextEditingController());
      }
    });
  }

  void _removeField(List<dynamic> controllers, int index) {
    setState(() {
      if (controllers == _locationControllers) {
        final loc = controllers[index] as Map<String, TextEditingController>;
        loc['name']?.dispose();
        loc['lat']?.dispose();
        loc['long']?.dispose();
      } else {
        (controllers[index] as TextEditingController).dispose();
      }
      controllers.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Collect values
      final displayName = _displayNameController.text.trim();
      final callsign = _callsignController.text.trim().toUpperCase();
      final npub = _npubController.text.trim();
      final notes = _notesController.text.trim();

      final emails = _emailControllers
          .map((c) => c.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final phones = _phoneControllers
          .map((c) => c.text.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      final addresses = _addressControllers
          .map((c) => c.text.trim())
          .where((a) => a.isNotEmpty)
          .toList();

      final websites = _websiteControllers
          .map((c) => c.text.trim())
          .where((w) => w.isNotEmpty)
          .toList();

      final locations = _locationControllers
          .where((loc) => loc['name']!.text.trim().isNotEmpty)
          .map((loc) {
            final name = loc['name']!.text.trim();
            final latText = loc['lat']!.text.trim();
            final longText = loc['long']!.text.trim();

            double? lat;
            double? long;

            if (latText.isNotEmpty) {
              lat = double.tryParse(latText);
            }
            if (longText.isNotEmpty) {
              long = double.tryParse(longText);
            }

            return ContactLocation(
              name: name,
              latitude: lat,
              longitude: long,
            );
          })
          .toList();

      // Create timestamp
      final now = DateTime.now();
      final timestamp = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}_${now.second.toString().padLeft(2, '0')}';

      // Create contact object
      final contact = Contact(
        displayName: displayName,
        callsign: callsign,
        npub: npub,
        created: timestamp,
        firstSeen: timestamp,
        emails: emails,
        phones: phones,
        addresses: addresses,
        websites: websites,
        locations: locations,
        notes: notes,
        groupPath: _selectedGroup,
      );

      // Save contact
      final error = await _contactService.saveContact(
        contact,
        groupPath: _selectedGroup,
      );

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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.contact != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? _i18n.t('edit') : _i18n.t('new_contact')),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
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

                  TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: '${_i18n.t('display_name')} *',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _i18n.t('field_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _callsignController,
                    decoration: InputDecoration(
                      labelText: '${_i18n.t('callsign')} *',
                      border: const OutlineInputBorder(),
                      hintText: 'CR7BBQ',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _i18n.t('field_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _npubController,
                    decoration: InputDecoration(
                      labelText: '${_i18n.t('npub')} *',
                      border: const OutlineInputBorder(),
                      hintText: 'npub1...',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _i18n.t('field_required');
                      }
                      if (!value.startsWith('npub1')) {
                        return _i18n.t('invalid_npub');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Group Selection
                  DropdownButtonFormField<String>(
                    value: _selectedGroup,
                    decoration: InputDecoration(
                      labelText: _i18n.t('group_optional'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(_i18n.t('no_group')),
                      ),
                      ..._groups.map((group) {
                        return DropdownMenuItem<String>(
                          value: group.path,
                          child: Text(group.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedGroup = value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Optional Fields Section
                  Text(
                    _i18n.t('optional_fields'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Email addresses
                  _buildMultiValueSection(
                    _i18n.t('email_addresses'),
                    _emailControllers,
                    Icons.email,
                    TextInputType.emailAddress,
                    'user@example.com',
                  ),

                  // Phone numbers
                  _buildMultiValueSection(
                    _i18n.t('phone_numbers'),
                    _phoneControllers,
                    Icons.phone,
                    TextInputType.phone,
                    '+1-555-0123',
                  ),

                  // Addresses
                  _buildMultiValueSection(
                    _i18n.t('addresses'),
                    _addressControllers,
                    Icons.home,
                    TextInputType.streetAddress,
                    '123 Main St, City, Country',
                  ),

                  // Websites
                  _buildMultiValueSection(
                    _i18n.t('websites'),
                    _websiteControllers,
                    Icons.link,
                    TextInputType.url,
                    'https://example.com',
                  ),

                  // Locations
                  _buildLocationsSection(),

                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: _i18n.t('notes'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 5,
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

  Widget _buildMultiValueSection(
    String label,
    List<TextEditingController> controllers,
    IconData icon,
    TextInputType keyboardType,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addField(controllers),
              tooltip: _i18n.t('add_another'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: hint,
                    ),
                    keyboardType: keyboardType,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: controllers.length > 1
                      ? () => _removeField(controllers, index)
                      : null,
                  color: Colors.red,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLocationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, size: 20),
            const SizedBox(width: 8),
            Text(
              _i18n.t('typical_locations'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addField(_locationControllers),
              tooltip: _i18n.t('add_another'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_locationControllers.length, (index) {
          final controllers = _locationControllers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controllers['name'],
                          decoration: InputDecoration(
                            labelText: _i18n.t('location_name'),
                            border: const OutlineInputBorder(),
                            hintText: 'Home, Office, etc.',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _locationControllers.length > 1
                            ? () => _removeField(_locationControllers, index)
                            : null,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controllers['lat'],
                          decoration: InputDecoration(
                            labelText: _i18n.t('latitude_optional'),
                            border: const OutlineInputBorder(),
                            hintText: '38.7223',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: controllers['long'],
                          decoration: InputDecoration(
                            labelText: _i18n.t('longitude_optional'),
                            border: const OutlineInputBorder(),
                            hintText: '-9.1393',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
