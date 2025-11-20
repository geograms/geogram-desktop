/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */

import 'package:flutter/material.dart';
import '../models/chat_channel.dart';

/// Dialog for creating a new chat channel (DM or group)
class NewChannelDialog extends StatefulWidget {
  final List<String> existingChannelIds;
  final List<String> knownCallsigns;

  const NewChannelDialog({
    Key? key,
    required this.existingChannelIds,
    this.knownCallsigns = const [],
  }) : super(key: key);

  @override
  State<NewChannelDialog> createState() => _NewChannelDialogState();
}

class _NewChannelDialogState extends State<NewChannelDialog> {
  final _formKey = GlobalKey<FormState>();
  ChatChannelType _channelType = ChatChannelType.direct;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _callsignController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _selectedParticipants = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _callsignController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('New Channel'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel type selector
                Text(
                  'Channel Type',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<ChatChannelType>(
                  segments: const [
                    ButtonSegment(
                      value: ChatChannelType.direct,
                      label: Text('Direct Message'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: ChatChannelType.group,
                      label: Text('Group'),
                      icon: Icon(Icons.group),
                    ),
                  ],
                  selected: {_channelType},
                  onSelectionChanged: (Set<ChatChannelType> newSelection) {
                    setState(() {
                      _channelType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Direct message fields
                if (_channelType == ChatChannelType.direct) ...[
                  TextFormField(
                    controller: _callsignController,
                    decoration: const InputDecoration(
                      labelText: 'Callsign',
                      hintText: 'Enter callsign (e.g., CR7BBQ)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a callsign';
                      }
                      final callsign = value.trim().toUpperCase();
                      if (widget.existingChannelIds.contains(callsign)) {
                        return 'Channel with this callsign already exists';
                      }
                      return null;
                    },
                  ),
                ],

                // Group fields
                if (_channelType == ChatChannelType.group) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'Enter group name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a group name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Enter group description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Participants (simplified - can be enhanced)
                  Text(
                    'Participants',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (widget.knownCallsigns.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.knownCallsigns.map((callsign) {
                          final isSelected =
                              _selectedParticipants.contains(callsign);
                          return FilterChip(
                            label: Text(callsign),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedParticipants.add(callsign);
                                } else {
                                  _selectedParticipants.remove(callsign);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    )
                  else
                    Text(
                      'No known participants yet. Start chatting to add participants!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isCreating ? null : _handleCreate,
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  /// Handle create button press
  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      ChatChannel channel;

      if (_channelType == ChatChannelType.direct) {
        // Create direct message channel
        final callsign = _callsignController.text.trim().toUpperCase();
        channel = ChatChannel.direct(callsign: callsign);
      } else {
        // Create group channel
        final name = _nameController.text.trim();
        final description = _descriptionController.text.trim();
        final id = _generateGroupId(name);

        // Check if ID already exists
        if (widget.existingChannelIds.contains(id)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('A group with this name already exists'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isCreating = false;
          });
          return;
        }

        channel = ChatChannel.group(
          id: id,
          name: name,
          participants: _selectedParticipants,
          description: description.isNotEmpty ? description : null,
        );
      }

      // Return the created channel
      if (mounted) {
        Navigator.pop(context, channel);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating channel: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  /// Generate a unique group ID from name
  String _generateGroupId(String name) {
    return name
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
