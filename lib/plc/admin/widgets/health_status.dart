// lib/plc/admin/widgets/health_status.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parfume_app/plc/plc_service_manager.dart';

/// Kiosk/32" uyumlu sabit renk & boyut sistemi (diğer tablarla aynı)
const Color kBgDark = Color(0xFF0B1020);
const Color kCardBg = Color(0xFF141A2E);
const Color kPrimaryText = Colors.white;
const Color kSecondaryText = Color(0xFFB9C0D4);
const Color kAccent = Color(0xFF4DA3FF);
const Color kLiveGreen = Color(0xFF4CAF50);
const Color kDangerRed = Color(0xFFE53935);
const Color kWarnOrange = Color(0xFFFB8C00);

/// PLC sağlık durumu widget
class HealthStatus extends StatefulWidget {
  const HealthStatus({
    super.key,
    required this.plcService,
  });

  final PLCServiceManager plcService;

  @override
  State<HealthStatus> createState() => _HealthStatusState();
}

class _HealthStatusState extends State<HealthStatus> {
  Timer? _checkTimer;
  bool? _lastHealthCheck;
  int _successfulChecks = 0;
  int _failedChecks = 0;
  DateTime? _lastCheckTime;
  Duration _uptime = Duration.zero;
  DateTime? _connectedSince;

  @override
  void initState() {
    super.initState();
    _startHealthChecks();
    if (widget.plcService.isConnected) {
      _connectedSince = widget.plcService.lastConnectedTime ?? DateTime.now();
    }
  }

  void _startHealthChecks() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (mounted) {
        await _performHealthCheck();
      }
    });
  }

  Future<void> _performHealthCheck() async {
    final isHealthy = await widget.plcService.checkHealth();

    setState(() {
      _lastHealthCheck = isHealthy;
      _lastCheckTime = DateTime.now();

      if (isHealthy) {
        _successfulChecks++;
        if (_connectedSince != null) {
          _uptime = DateTime.now().difference(_connectedSince!);
        }
      } else {
        _failedChecks++;
        _connectedSince = null;
        _uptime = Duration.zero;
      }
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.plcService.state;
    final isConnected = widget.plcService.isConnected;

    final connColor = isConnected ? kLiveGreen : kDangerRed;
    final healthColor = _lastHealthCheck == true
        ? kLiveGreen
        : _lastHealthCheck == false
            ? kDangerRed
            : kSecondaryText;

    return Container(
      color: kBgDark,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PLC Durumu',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: kPrimaryText,
              ),
            ),

            const SizedBox(height: 18),

            // Status cards
            Row(
              children: [
                Expanded(
                  child: _StatusCard(
                    title: 'Bağlantı',
                    value: _getConnectionStatus(),
                    color: connColor,
                    icon: isConnected ? Icons.check_circle : Icons.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(
                    title: 'Health Check',
                    value: _getHealthStatus(),
                    color: healthColor,
                    icon: _lastHealthCheck == true
                        ? Icons.favorite
                        : _lastHealthCheck == false
                            ? Icons.heart_broken
                            : Icons.help,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Statistics
            Card(
              color: kCardBg,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow(
                      label: 'Durum',
                      value: state.toString().split('.').last.toUpperCase(),
                    ),
                    const Divider(color: Color(0x33B9C0D4), thickness: 1.5),
                    _StatRow(
                      label: 'Uptime',
                      value: _formatDuration(_uptime),
                    ),
                    const Divider(color: Color(0x33B9C0D4), thickness: 1.5),
                    _StatRow(
                      label: 'Başarılı Kontrol',
                      value: _successfulChecks.toString(),
                    ),
                    const Divider(color: Color(0x33B9C0D4), thickness: 1.5),
                    _StatRow(
                      label: 'Başarısız Kontrol',
                      value: _failedChecks.toString(),
                    ),
                    const Divider(color: Color(0x33B9C0D4), thickness: 1.5),
                    _StatRow(
                      label: 'Son Kontrol',
                      value: _lastCheckTime != null
                          ? _formatTime(_lastCheckTime!)
                          : '--',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? null : () => _reconnect(),
                    icon: const Icon(Icons.refresh, size: 46),
                    label: const Text(
                      'Yeniden Bağlan',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: kSecondaryText.withOpacity(0.25),
                      foregroundColor: kPrimaryText,
                      disabledBackgroundColor: kSecondaryText.withOpacity(0.12),
                      disabledForegroundColor: kSecondaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _performHealthCheck(),
                    icon: const Icon(Icons.health_and_safety, size: 46),
                    label: const Text(
                      'Test Et',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: kAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: kAccent.withOpacity(0.35),
                      disabledForegroundColor: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getConnectionStatus() {
    return widget.plcService.isConnected ? 'BAĞLI' : 'BAĞLI DEĞİL';
  }

  String _getHealthStatus() {
    if (_lastHealthCheck == null) return 'BEKLENİYOR';
    return _lastHealthCheck! ? 'SAĞLIKLI' : 'SORUNLU';
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '--';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    } else if (minutes > 0) {
      return '${minutes}dk ${seconds}sn';
    } else {
      return '${seconds}sn';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  Future<void> _reconnect() async {
    await widget.plcService.reconnect();
    if (widget.plcService.isConnected) {
      setState(() {
        _connectedSince = DateTime.now();
        _uptime = Duration.zero;
      });
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCardBg,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: color, size: 64),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: kSecondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: kPrimaryText,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
