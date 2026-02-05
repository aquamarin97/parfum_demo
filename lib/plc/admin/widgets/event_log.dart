// lib/plc/admin/widgets/event_log.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parfume_app/plc/admin/models/plc_event.dart';

/// Kiosk/32" uyumlu sabit renk & boyut sistemi (diğer tablarla aynı)
const Color kBgDark = Color(0xFF0B1020);
const Color kCardBg = Color(0xFF141A2E);
const Color kPrimaryText = Colors.white;
const Color kSecondaryText = Color(0xFFB9C0D4);
const Color kAccent = Color(0xFF4DA3FF);
const Color kLiveGreen = Color(0xFF4CAF50);
const Color kDangerRed = Color(0xFFE53935);
const Color kWarnOrange = Color(0xFFFB8C00);

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
      color: kBgDark,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Event Log',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: kPrimaryText,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${events.length} event',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: kSecondaryText,
                    ),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    iconSize: 52,
                    color: kPrimaryText,
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () => _clearLogs(),
                    tooltip: 'Temizle',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _BigFilterChip(
                  label: 'TÜMÜ',
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

          // Event list
          Expanded(
            child: events.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz event yok',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: kSecondaryText,
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
        backgroundColor: kCardBg,
        titleTextStyle: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: kPrimaryText,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: kSecondaryText,
        ),
        title: const Text('Log Temizle'),
        content: const Text('Tüm event logları silinecek.\nEmin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: kSecondaryText,
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
              backgroundColor: kDangerRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              textStyle:
                  const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }
}

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

      // ❌ checkmark iptal – kiosk’ta gereksiz ve karışık
      showCheckmark: false,

      // 🎯 NET KONTRAST
      backgroundColor: kCardBg,
      selectedColor: kAccent, // TAM RENK

      side: BorderSide(
        color: selected ? kAccent : kSecondaryText.withOpacity(0.35),
        width: selected ? 3 : 2,
      ),

      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,

            // 👇 kritik kontrast
            color: selected ? Colors.black : kSecondaryText,

            height: 1.0,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}


class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final PLCEvent event;

  @override
  Widget build(BuildContext context) {
    final badgeColor = event.color; // modelden gelen renk (tip rengi)

    return Card(
      color: kCardBg,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        isThreeLine: true,
        minVerticalPadding: 16,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        leading: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.14),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: badgeColor.withOpacity(0.45), width: 2),
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
                  color: kPrimaryText,
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
            ? const Icon(Icons.error, color: kDangerRed, size: 46)
            : null,
      ),
    );
  }
}

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
        color: kSecondaryText.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kSecondaryText.withOpacity(0.18), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: kSecondaryText),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: kSecondaryText,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
