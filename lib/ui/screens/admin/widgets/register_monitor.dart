import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parfume_app/infrastructure/plc/plc_service_manager.dart';
import 'package:parfume_app/infrastructure/plc/config/register_config.dart';
import 'package:parfume_app/ui/theme/app_admin_colors.dart';

/// Live register value monitor for the admin panel.
///
/// Polls watched registers every second while [_isPolling] is true.
/// Polling is paused automatically when the PLC is disconnected.
/// Register reads are currently mocked pending direct client access.
class RegisterMonitor extends StatefulWidget {
  const RegisterMonitor({super.key, required this.plcService});

  final PLCServiceManager plcService;

  @override
  State<RegisterMonitor> createState() => _RegisterMonitorState();
}

class _RegisterMonitorState extends State<RegisterMonitor> {
  Timer? _pollTimer;
  final Map<int, int> _registerValues = {};
  final Map<int, DateTime> _lastUpdate = {};
  List<RegisterAddress> _watchedRegisters = [];
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _loadWatchedRegisters();
    _startPolling();
  }

  void _loadWatchedRegisters() {
    if (widget.plcService.isConnected) {
      // Hard-coded key registers — replace with config-driven list when available.
      _watchedRegisters = [
        RegisterAddress(
          group: 'recommendations',
          name: 'first',
          address: 0,
          type: RegisterType.write,
          description: 'First recommendation',
        ),
        RegisterAddress(
          group: 'tester_control',
          name: 'testers_ready',
          address: 10,
          type: RegisterType.readWrite,
          description: 'Testers ready',
        ),
        RegisterAddress(
          group: 'payment',
          name: 'status',
          address: 20,
          type: RegisterType.readWrite,
          description: 'Payment status',
        ),
        RegisterAddress(
          group: 'perfume_dispenser',
          name: 'ready',
          address: 30,
          type: RegisterType.readWrite,
          description: 'Perfume ready',
        ),
        RegisterAddress(
          group: 'system',
          name: 'heartbeat',
          address: 100,
          type: RegisterType.readWrite,
          description: 'Heartbeat',
        ),
      ];
    }
  }

  void _startPolling() {
    _isPolling = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.plcService.isConnected) {
        _pollRegisters();
      }
    });
    if (mounted) setState(() {});
  }

  void _stopPolling() {
    _isPolling = false;
    _pollTimer?.cancel();
    if (mounted) setState(() {});
  }

  Future<void> _pollRegisters() async {
    if (!widget.plcService.isConnected) return;

    try {
      // TODO: activate when direct read method is available on PLCServiceManager
      for (final reg in _watchedRegisters) {
        if (reg.isReadable) {
          try {
            // final val = await widget.plcService.readRegister(reg.address);
            // setState(() {
            //   _registerValues[reg.address] = val;
            //   _lastUpdate[reg.address] = DateTime.now();
            // });
          } catch (e) {
            debugPrint('Register ${reg.address} read error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Register Monitor',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AdminColors.primaryText,
                ),
              ),
              Row(
                children: [
                  Text(
                    _isPolling ? '● LIVE' : '○ STOPPED',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _isPolling
                          ? AdminColors.success
                          : AdminColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    iconSize: 48,
                    color: AdminColors.primaryText,
                    icon: Icon(_isPolling ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      setState(() {
                        _isPolling ? _stopPolling() : _startPolling();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: _watchedRegisters.isEmpty
              ? const Center(
                  child: Text(
                    'PLC not connected or no registers found',
                    style: TextStyle(
                      fontSize: 40,
                      color: AdminColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _watchedRegisters.length,
                  itemBuilder: (context, index) {
                    final reg = _watchedRegisters[index];
                    final value = _registerValues[reg.address];
                    final lastUpdate = _lastUpdate[reg.address];

                    return Card(
                      color: AdminColors.cardBackground,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        isThreeLine: true,
                        minVerticalPadding: 16,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        leading: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AdminColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'R${reg.address}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AdminColors.accent,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          reg.description,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${reg.fullPath} (${reg.type.toJson()})',
                          style: const TextStyle(
                            fontSize: 22,
                            color: AdminColors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 120),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                value?.toString() ?? '--',
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: AdminColors.primaryText,
                                  height: 1.0,
                                ),
                              ),
                              if (lastUpdate != null)
                                Text(
                                  _formatTime(lastUpdate),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.secondaryText,
                                    height: 1.0,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}:'
          '${time.second.toString().padLeft(2, '0')}';
    }
  }
}
