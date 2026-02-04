// lib/plc/admin/widgets/event_log.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parfume_app/plc/admin/models/plc_event.dart';

/// Event log görüntüleme widget
class EventLog extends StatefulWidget {
  const EventLog({super.key});

  @override
  State<EventLog> createState() => _EventLogState();
}

class _EventLogState extends State<EventLog> {
  Timer? _refreshTimer;
  PLCEventType? _filterType;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Her saniye güncelle
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Event Log',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  '${events.length} event',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _clearLogs(),
                  tooltip: 'Temizle',
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Tümü'),
                selected: _filterType == null,
                onSelected: (_) {
                  setState(() => _filterType = null);
                },
              ),
              const SizedBox(width: 8),
              ...PLCEventType.values.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type.name.toUpperCase()),
                    selected: _filterType == type,
                    onSelected: (_) {
                      setState(() => _filterType = type);
                    },
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Event list
        Expanded(
          child: events.isEmpty
              ? const Center(
                  child: Text(
                    'Henüz event yok',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
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
    );
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Log Temizle',
          style: TextStyle(fontSize: 28),
        ),
        content: const Text(
          'Tüm event logları silinecek. Emin misiniz?',
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(fontSize: 20)),
          ),
          ElevatedButton(
            onPressed: () {
              PLCEventLogger.instance.clear();
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Temizle', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final PLCEvent event;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Icon(
          event.icon,
          color: event.color,
          size: 24,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: event.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                event.type.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: event.color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event.message,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              event.formattedTime,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (event.register != null) ...[
              const SizedBox(width: 12),
              Text(
                'R${event.register}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (event.value != null) ...[
              const SizedBox(width: 8),
              Text(
                '= ${event.value}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        trailing: event.error != null
            ? const Icon(Icons.error, color: Colors.red, size: 20)
            : null,
      ),
    );
  }
}
