import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parfume_app/core/strings/app_strings.dart';
import 'package:parfume_app/data/models/plc/plc_event.dart';
import 'package:parfume_app/ui/theme/app_admin_colors.dart';

/// Scrollable, filterable log of [PLCEvent] entries.
///
/// Refreshes every second and supports per-type filtering via chip buttons.
/// Entries can be cleared via the delete button in the header.
class EventLog extends StatefulWidget {
  const EventLog({super.key, required this.adminStrings});

  final AppStrings adminStrings;

  @override
  State<EventLog> createState() => _EventLogState();
}

class _EventLogState extends State<EventLog> {
  Timer? _refreshTimer;
  PLCEventType? _filterType;
  final _scrollController = ScrollController();

  AppStrings get _s => widget.adminStrings;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  List<PLCEvent> get _filteredEvents {
    final events = PLCEventLogger.instance.events;
    if (_filterType == null) return events;
    return events.where((e) => e.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final events = _filteredEvents;

    return Container(
      color: AdminColors.background,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _s.t('admin_event_log_title'),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AdminColors.primaryText,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${events.length}${_s.t('admin_event_count_suffix')}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    iconSize: 52,
                    color: AdminColors.primaryText,
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () => _clearLogs(),
                    tooltip: _s.t('admin_event_clear_tooltip'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _BigFilterChip(
                  label: _s.t('admin_event_filter_all'),
                  selected: _filterType == null,
                  onSelected: () => setState(() => _filterType = null),
                ),
                const SizedBox(width: 10),
                ...PLCEventType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _BigFilterChip(
                      label: type.name.toUpperCase(),
                      selected: _filterType == type,
                      onSelected: () => setState(() => _filterType = type),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Text(
                      _s.t('admin_event_empty'),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.secondaryText,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _EventTile(event: event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.cardBackground,
        titleTextStyle: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: AdminColors.primaryText,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AdminColors.secondaryText,
        ),
        title: Text(_s.t('admin_event_clear_title')),
        content: Text(_s.t('admin_event_clear_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _s.t('admin_cancel'),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AdminColors.secondaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              PLCEventLogger.instance.clear();
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              textStyle:
                  const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            child: Text(_s.t('admin_event_clear_confirm')),
          ),
        ],
      ),
    );
  }
}

/// Large touchable filter chip for the admin panel event type selector.
class _BigFilterChip extends StatelessWidget {
  const _BigFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      backgroundColor: AdminColors.cardBackground,
      selectedColor: AdminColors.accent,
      side: BorderSide(
        color: selected
            ? AdminColors.accent
            : AdminColors.secondaryText.withValues(alpha: 0.35),
        width: selected ? 3 : 2,
      ),
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.black : AdminColors.secondaryText,
            height: 1.0,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// A single row in the event log list.
class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final PLCEvent event;

  @override
  Widget build(BuildContext context) {
    final badgeColor = event.color;

    return Card(
      color: AdminColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        isThreeLine: true,
        minVerticalPadding: 16,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        leading: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            event.icon,
            color: badgeColor,
            size: 52,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.45),
                  width: 2,
                ),
              ),
              child: Text(
                event.type.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: badgeColor,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.message,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.primaryText,
                  height: 1.05,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 16,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaPill(
                icon: Icons.schedule,
                text: event.formattedTime,
              ),
              if (event.register != null)
                _MetaPill(
                  icon: Icons.memory,
                  text: 'R${event.register}',
                ),
              if (event.value != null)
                _MetaPill(
                  icon: Icons.numbers,
                  text: '= ${event.value}',
                ),
            ],
          ),
        ),
        trailing: event.error != null
            ? const Icon(Icons.error, color: AdminColors.danger, size: 46)
            : null,
      ),
    );
  }
}

/// A small pill-shaped metadata tag showing an icon and a text value.
class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AdminColors.secondaryText.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AdminColors.secondaryText.withValues(alpha: 0.18),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: AdminColors.secondaryText),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AdminColors.secondaryText,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
