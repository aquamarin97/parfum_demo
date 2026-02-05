// lib/plc/admin/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:parfume_app/plc/plc_service_manager.dart';
import 'widgets/register_monitor.dart';
import 'widgets/manual_control.dart';
import 'widgets/health_status.dart';
import 'widgets/event_log.dart';

/// PLC Admin Panel Ana Ekran
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key, required this.plcService});

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
        toolbarHeight: 120,
        iconTheme: const IconThemeData(size: 50, color: Colors.white),

        backgroundColor: const Color(0xFF0B1020),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'PLC Admin Panel',
          style: TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: TabBar(
            controller: _tabController,
            isScrollable: true, // büyük fontta şart
            tabAlignment: TabAlignment.center,
            indicatorColor: Colors.white,
            indicatorWeight: 16,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFB9C0D4),
            labelStyle: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              _BigTab(icon: Icons.monitor, text: 'Monitor'),
              _BigTab(icon: Icons.edit, text: 'Manuel'),
              _BigTab(icon: Icons.health_and_safety, text: 'Durum'),
              _BigTab(icon: Icons.event_note, text: 'Log'),
            ],
          ),
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
          Padding(padding: const EdgeInsets.all(16), child: const EventLog()),
        ],
      ),
    );
  }
}

class _BigTab extends StatelessWidget {
  const _BigTab({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260, // statik: her tab geniş
      height: 140, // TabBar yüksekliği ile uyumlu
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52),
          const SizedBox(height: 6),
          // Taşma olursa bile küçültüp sığdırır (ama font büyük kalır)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, maxLines: 1, softWrap: false),
          ),
        ],
      ),
    );
  }
}
