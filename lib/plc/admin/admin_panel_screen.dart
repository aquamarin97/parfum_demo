// lib/plc/admin/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:parfume_app/plc/plc_service_manager.dart';
import 'widgets/register_monitor.dart';
import 'widgets/manual_control.dart';
import 'widgets/health_status.dart';
import 'widgets/event_log.dart';

/// PLC Admin Panel Ana Ekran
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({
    super.key,
    required this.plcService,
  });

  final PLCServiceManager plcService;

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PLC Admin Panel',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontSize: 20),
          tabs: const [
            Tab(icon: Icon(Icons.monitor), text: 'Monitor'),
            Tab(icon: Icon(Icons.edit), text: 'Manuel'),
            Tab(icon: Icon(Icons.health_and_safety), text: 'Durum'),
            Tab(icon: Icon(Icons.event_note), text: 'Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Register Monitor
          Padding(
            padding: const EdgeInsets.all(16),
            child: RegisterMonitor(plcService: widget.plcService),
          ),

          // Manuel Control
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ManualControl(plcService: widget.plcService),
          ),

          // Health Status
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: HealthStatus(plcService: widget.plcService),
          ),

          // Event Log
          Padding(
            padding: const EdgeInsets.all(16),
            child: const EventLog(),
          ),
        ],
      ),
    );
  }
}
