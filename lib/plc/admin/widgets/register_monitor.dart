// lib/plc/admin/widgets/register_monitor.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parfume_app/plc/plc_service_manager.dart';
import 'package:parfume_app/plc/config/register_config.dart';

/// Kiosk/32" uyumlu sabit renk & boyut sistemi
const Color kBgDark = Color(0xFF0B1020);
const Color kCardBg = Color(0xFF141A2E);
const Color kPrimaryText = Colors.white;
const Color kSecondaryText = Color(0xFFB9C0D4);
const Color kAccent = Color(0xFF4DA3FF);
const Color kLiveGreen = Color(0xFF4CAF50);

/// Canlı register monitoring widget
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
      // Şimdilik hard-coded önemli register'lar
      _watchedRegisters = [
        RegisterAddress(
          group: 'recommendations',
          name: 'first',
          address: 0,
          type: RegisterType.write,
          description: 'İlk öneri',
        ),
        RegisterAddress(
          group: 'tester_control',
          name: 'testers_ready',
          address: 10,
          type: RegisterType.readWrite,
          description: 'Testerlar hazır',
        ),
        RegisterAddress(
          group: 'payment',
          name: 'status',
          address: 20,
          type: RegisterType.readWrite,
          description: 'Ödeme durumu',
        ),
        RegisterAddress(
          group: 'perfume_dispenser',
          name: 'ready',
          address: 30,
          type: RegisterType.readWrite,
          description: 'Parfüm hazır',
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
      final client = widget.plcService;

      // TODO: Direct read metodunu ekleyince burayı aktif edeceksin.
      // Şimdilik örnek amaçlı "skip".
      for (final reg in _watchedRegisters) {
        if (reg.isReadable) {
          try {
            // final val = await client.readRegister(reg.address);
            // setState(() {
            //   _registerValues[reg.address] = val;
            //   _lastUpdate[reg.address] = DateTime.now();
            // });
          } catch (e) {
            debugPrint('Register ${reg.address} okuma hatası: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Polling hatası: $e');
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                'Register Monitor',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: kPrimaryText,
                ),
              ),
              Row(
                children: [
                  Text(
                    _isPolling ? '● LIVE' : '○ STOPPED',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _isPolling ? kLiveGreen : kSecondaryText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    iconSize: 48,
                    color: kPrimaryText,
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

          const SizedBox(height: 16),

          // Register list
          Expanded(
            child: _watchedRegisters.isEmpty
                ? const Center(
                    child: Text(
                      'PLC bağlı değil veya register bulunamadı',
                      style: TextStyle(
                        fontSize: 40,
                        color: kSecondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _watchedRegisters.length,
                    itemBuilder: (context, index) {
                      final reg = _watchedRegisters[index];
                      final value = _registerValues[reg.address];
                      final lastUpdate = _lastUpdate[reg.address];

                      return Card(
                        color: kCardBg,
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
                              color: kAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'R${reg.address}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: kAccent,
                                ),
                              ),
                            ),
                          ),

                          title: Text(
                            reg.description,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: kPrimaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          subtitle: Text(
                            '${reg.fullPath} (${reg.type.toJson()})',
                            style: const TextStyle(
                              fontSize: 22,
                              color: kSecondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // 🔥 Overflow’un asıl çıktığı yer burası
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 120),
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // <-- kritik
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  value?.toString() ?? '--',
                                  style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: kPrimaryText,
                                    height: 1.0,
                                  ),
                                ),
                                if (lastUpdate != null)
                                  Text(
                                    _formatTime(lastUpdate),
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                      color: kSecondaryText,
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
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '- ${diff.inSeconds} sn';
    } else if (diff.inMinutes < 60) {
      return '- ${diff.inMinutes} dk';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}:'
          '${time.second.toString().padLeft(2, '0')}';
    }
  }
}
