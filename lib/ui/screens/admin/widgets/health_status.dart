import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parfume_app/infrastructure/plc/plc_service_manager.dart';
import 'package:parfume_app/ui/theme/app_admin_colors.dart';

/// Displays live PLC health metrics and provides manual health check
/// and reconnect actions.
///
/// Runs an automatic health check every 5 seconds while mounted.
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

    final connColor = isConnected ? AdminColors.success : AdminColors.danger;
    final healthColor = _lastHealthCheck == true
        ? AdminColors.success
        : _lastHealthCheck == false
            ? AdminColors.danger
            : AdminColors.secondaryText;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PLC Status',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: AdminColors.primaryText,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  title: 'Connection',
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

          Card(
            color: AdminColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow(
                    label: 'State',
                    value: state.toString().split('.').last.toUpperCase(),
                  ),
                  const Divider(color: AdminColors.divider, thickness: 1.5),
                  _StatRow(
                    label: 'Uptime',
                    value: _formatDuration(_uptime),
                  ),
                  const Divider(color: AdminColors.divider, thickness: 1.5),
                  _StatRow(
                    label: 'Successful Checks',
                    value: _successfulChecks.toString(),
                  ),
                  const Divider(color: AdminColors.divider, thickness: 1.5),
                  _StatRow(
                    label: 'Failed Checks',
                    value: _failedChecks.toString(),
                  ),
                  const Divider(color: AdminColors.divider, thickness: 1.5),
                  _StatRow(
                    label: 'Last Check',
                    value: _lastCheckTime != null
                        ? _formatTime(_lastCheckTime!)
                        : '--',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isConnected ? null : () => _reconnect(),
                  icon: const Icon(Icons.refresh, size: 46),
                  label: const Text(
                    'Reconnect',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor:
                        AdminColors.secondaryText.withValues(alpha: 0.25),
                    foregroundColor: AdminColors.primaryText,
                    disabledBackgroundColor:
                        AdminColors.secondaryText.withValues(alpha: 0.12),
                    disabledForegroundColor: AdminColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _performHealthCheck(),
                  icon: const Icon(Icons.health_and_safety, size: 46),
                  label: const Text(
                    'Run Health Check',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: AdminColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AdminColors.accent.withValues(alpha: 0.35),
                    disabledForegroundColor: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getConnectionStatus() {
    return widget.plcService.isConnected ? 'CONNECTED' : 'DISCONNECTED';
  }

  String _getHealthStatus() {
    if (_lastHealthCheck == null) return 'PENDING';
    return _lastHealthCheck! ? 'HEALTHY' : 'UNHEALTHY';
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '--';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
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

/// A compact status card showing an icon, label, and coloured value.
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
      color: AdminColors.cardBackground,
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
                color: AdminColors.secondaryText,
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

/// A labelled key–value row used inside the statistics card.
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
                color: AdminColors.secondaryText,
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
              color: AdminColors.primaryText,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
