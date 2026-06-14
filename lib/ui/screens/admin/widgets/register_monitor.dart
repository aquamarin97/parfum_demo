import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parfume_app/core/strings/app_strings.dart';
import 'package:parfume_app/infrastructure/plc/plc_service_manager.dart';
import 'package:parfume_app/infrastructure/plc/config/register_config.dart';
import 'package:parfume_app/ui/theme/app_admin_colors.dart';

/// Live register value monitor for the admin panel.
///
/// Polls watched registers every second while [_isPolling] is true.
/// Polling is paused automatically when the PLC is disconnected.
class RegisterMonitor extends StatefulWidget {
  const RegisterMonitor({
    super.key,
    required this.plcService,
    required this.adminStrings,
  });

  final PLCServiceManager plcService;
  final AppStrings adminStrings;

  @override
  State<RegisterMonitor> createState() => _RegisterMonitorState();
}

class _RegisterMonitorState extends State<RegisterMonitor> {
  Timer? _pollTimer;
  final Map<int, int> _registerValues = {};
  final Map<int, DateTime> _lastUpdate = {};
  List<RegisterAddress> _watchedRegisters = [];
  bool _isPolling = false;

  AppStrings get _s => widget.adminStrings;

  @override
  void initState() {
    super.initState();
    _loadWatchedRegisters();
    _startPolling();
  }

  void _loadWatchedRegisters() {
    _watchedRegisters = [
      RegisterAddress(
        group: 'commands',
        name: 'action',
        address: 100,
        type: RegisterType.write,
        description: 'CMD_ACTION',
      ),
      RegisterAddress(
        group: 'commands',
        name: 'sequence_id',
        address: 102,
        type: RegisterType.write,
        description: 'CMD_SEQUENCE_ID',
      ),
      RegisterAddress(
        group: 'system_status',
        name: 'system',
        address: 200,
        type: RegisterType.read,
        description: 'STATUS_SYSTEM',
      ),
      RegisterAddress(
        group: 'system_status',
        name: 'last_cmd_seq_id',
        address: 201,
        type: RegisterType.read,
        description: 'STATUS_LAST_CMD_SEQ_ID',
      ),
      RegisterAddress(
        group: 'system_status',
        name: 'last_cmd_result',
        address: 202,
        type: RegisterType.read,
        description: 'STATUS_LAST_CMD_RESULT',
      ),
      RegisterAddress(
        group: 'payment',
        name: 'status',
        address: 300,
        type: RegisterType.readWrite,
        description: 'PAYMENT_STATUS',
      ),
      RegisterAddress(
        group: 'payment',
        name: 'sale_completed',
        address: 303,
        type: RegisterType.readWrite,
        description: 'SALE_COMPLETED',
      ),
      RegisterAddress(
        group: 'sensors',
        name: 'presence',
        address: 400,
        type: RegisterType.read,
        description: 'SENSOR_PRESENCE',
      ),
      RegisterAddress(
        group: 'errors',
        name: 'error_code',
        address: 500,
        type: RegisterType.read,
        description: 'ERROR_CODE',
      ),
      RegisterAddress(
        group: 'errors',
        name: 'error_slot',
        address: 501,
        type: RegisterType.read,
        description: 'ERROR_SLOT',
      ),
      RegisterAddress(
        group: 'heartbeat',
        name: 'plc_heartbeat',
        address: 600,
        type: RegisterType.read,
        description: 'PLC_HEARTBEAT',
      ),
      RegisterAddress(
        group: 'heartbeat',
        name: 'flutter_heartbeat',
        address: 601,
        type: RegisterType.write,
        description: 'FLUTTER_HEARTBEAT',
      ),
    ];
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

    for (final reg in _watchedRegisters) {
      if (!reg.isReadable || !mounted) continue;
      try {
        final val = await widget.plcService.readRegister(reg.address);
        if (mounted) {
          setState(() {
            _registerValues[reg.address] = val;
            _lastUpdate[reg.address] = DateTime.now();
          });
        }
      } catch (e) {
        debugPrint('R${reg.address} read error: $e');
      }
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
              Text(
                _s.t('admin_monitor_title'),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AdminColors.primaryText,
                ),
              ),
              Row(
                children: [
                  Text(
                    _isPolling ? _s.t('admin_monitor_live') : _s.t('admin_monitor_stopped'),
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
              ? Center(
                  child: Text(
                    _s.t('admin_monitor_empty'),
                    style: const TextStyle(
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
      return '${diff.inSeconds}${_s.t('admin_monitor_sec_ago')}';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}${_s.t('admin_monitor_min_ago')}';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}:'
          '${time.second.toString().padLeft(2, '0')}';
    }
  }
}
