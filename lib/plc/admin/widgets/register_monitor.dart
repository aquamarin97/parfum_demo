// lib/plc/admin/widgets/register_monitor.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parfume_app/plc/plc_service_manager.dart';
import 'package:parfume_app/plc/config/register_config.dart';

/// Canlı register monitoring widget
class RegisterMonitor extends StatefulWidget {
  const RegisterMonitor({
    super.key,
    required this.plcService,
  });

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
    // Config'den önemli register'ları al
    if (widget.plcService.isConnected) {
      final client = widget.plcService;
      // ModbusPLCClient'tan config al
      // TODO: Config access metodunu ekle
      
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
  }

  void _stopPolling() {
    _isPolling = false;
    _pollTimer?.cancel();
  }

  Future<void> _pollRegisters() async {
    if (!widget.plcService.isConnected) return;

    try {
      final client = widget.plcService;
      
      // Her watched register'ı oku
      for (final reg in _watchedRegisters) {
        if (reg.isReadable) {
          try {
            // ModbusPLCClient'tan oku
            // TODO: Direct read metodunu ekle
            // Şimdilik skip
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Register Monitor',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  _isPolling ? '● LIVE' : '○ STOPPED',
                  style: TextStyle(
                    fontSize: 20,
                    color: _isPolling ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isPolling ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    setState(() {
                      if (_isPolling) {
                        _stopPolling();
                      } else {
                        _startPolling();
                      }
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
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _watchedRegisters.length,
                  itemBuilder: (context, index) {
                    final reg = _watchedRegisters[index];
                    final value = _registerValues[reg.address];
                    final lastUpdate = _lastUpdate[reg.address];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'R${reg.address}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          reg.description,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${reg.fullPath} (${reg.type.toJson()})',
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              value?.toString() ?? '--',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (lastUpdate != null)
                              Text(
                                _formatTime(lastUpdate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
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
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
