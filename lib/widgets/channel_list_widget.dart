/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */

import 'package:flutter/material.dart';
import '../models/chat_channel.dart';

/// Widget for displaying the list of chat channels in sidebar
class ChannelListWidget extends StatelessWidget {
  final List<ChatChannel> channels;
  final String? selectedChannelId;
  final Function(ChatChannel) onChannelSelect;
  final VoidCallback onNewChannel;

  const ChannelListWidget({
    Key? key,
    required this.channels,
    this.selectedChannelId,
    required this.onChannelSelect,
    required this.onNewChannel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sort channels: favorites first, then by last message time
    final sortedChannels = List<ChatChannel>.from(channels);
    sortedChannels.sort((a, b) {
      // Favorites first
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;

      // Main channel always at top (after favorites)
      if (a.isMain && !b.isMain) return -1;
      if (!a.isMain && b.isMain) return 1;

      // Then by last message time (newest first)
      if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
      if (a.lastMessageTime == null) return 1;
      if (b.lastMessageTime == null) return -1;
      return b.lastMessageTime!.compareTo(a.lastMessageTime!);
    });

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with new channel button
          _buildHeader(theme),
          const Divider(height: 1),
          // Channel list
          Expanded(
            child: sortedChannels.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    itemCount: sortedChannels.length,
                    itemBuilder: (context, index) {
                      final channel = sortedChannels[index];
                      final isSelected = channel.id == selectedChannelId;

                      return _ChannelTile(
                        channel: channel,
                        isSelected: isSelected,
                        onTap: () => onChannelSelect(channel),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Build header with title and new channel button
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.forum,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Channels',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onNewChannel,
            tooltip: 'New channel',
            iconSize: 24,
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No channels yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a channel to start chatting',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual channel tile widget
class _ChannelTile extends StatelessWidget {
  final ChatChannel channel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.channel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withOpacity(0.5)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Channel icon
              _buildChannelIcon(theme),
              const SizedBox(width: 12),
              // Channel info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Channel name
                        Expanded(
                          child: Text(
                            channel.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Unread badge
                        if (channel.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              channel.unreadCount > 99
                                  ? '99+'
                                  : channel.unreadCount.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Subtitle
                    Text(
                      channel.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Favorite star
              if (channel.isFavorite)
                Icon(
                  Icons.star,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build channel icon based on type
  Widget _buildChannelIcon(ThemeData theme) {
    IconData icon;
    Color? color;

    if (channel.isMain) {
      icon = Icons.forum;
      color = theme.colorScheme.primary;
    } else if (channel.isDirect) {
      icon = Icons.person;
      color = theme.colorScheme.secondary;
    } else {
      icon = Icons.group;
      color = theme.colorScheme.tertiary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }
}
