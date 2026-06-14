import 'package:flutter/material.dart';
import 'package:parfume_app/core/strings/admin_strings.dart';
import 'package:parfume_app/core/strings/app_strings.dart';
import 'package:parfume_app/infrastructure/plc/plc_service_manager.dart';
import 'package:parfume_app/ui/theme/app_admin_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/viewmodel/app_view_model.dart';

import 'widgets/event_log.dart';
import 'widgets/health_status.dart';
import 'widgets/manual_control.dart';
import 'widgets/price_settings.dart';
import 'widgets/register_monitor.dart';
import 'widgets/slot_price_settings.dart';
import 'widgets/support_settings.dart';
import 'widgets/timeout_settings.dart';

/// PLC administration panel.
///
/// Tabs: Monitor · Manual · Status · Log · Settings · Pricing
///
/// Accessed via the hidden admin button in the kiosk shell.
/// Requires an active [PLCServiceManager] instance.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({
    super.key,
    required this.plcService,
    required this.viewModel,
    this.isReadOnly = false,
  });

  final PLCServiceManager plcService;
  final AppViewModel viewModel;
  final bool isReadOnly;

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppStrings? _s;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadStrings();
  }

  Future<void> _loadStrings() async {
    final s = await loadAdminStrings(widget.viewModel.strings.localeCode);
    if (mounted) setState(() => _s = s);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    if (s == null) {
      return const Scaffold(
        backgroundColor: AdminColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppSizes.adminAppBarHeight,
        iconTheme: const IconThemeData(
          size: AppSizes.adminAppBarIconSize,
          color: Colors.white,
        ),
        backgroundColor: AdminColors.appBarBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          s.t('admin_panel_title'),
          style: const TextStyle(
            fontSize: AppSizes.adminAppBarTitleSize,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(AppSizes.adminTabBarHeight),
          child: Container(
            color: AdminColors.tabBarBackground,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorColor: Colors.white,
              indicatorWeight: AppSizes.adminIndicatorWeight,
              labelColor: Colors.white,
              unselectedLabelColor: AdminColors.secondaryText,
              labelStyle: const TextStyle(
                fontSize: AppSizes.adminTabSelectedFontSize,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: AppSizes.adminTabUnselectedFontSize,
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                _AdminTab(icon: Icons.monitor,           text: s.t('admin_tab_monitor')),
                _AdminTab(icon: Icons.edit,               text: s.t('admin_tab_manual')),
                _AdminTab(icon: Icons.health_and_safety,  text: s.t('admin_tab_status')),
                _AdminTab(icon: Icons.event_note,         text: s.t('admin_tab_log')),
                _AdminTab(icon: Icons.tune,               text: s.t('admin_tab_settings')),
                _AdminTab(icon: Icons.sell,               text: s.t('admin_tab_pricing')),
                _AdminTab(icon: Icons.support_agent,      text: s.t('admin_tab_support')),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: AdminColors.background,
        child: TabBarView(
          controller: _tabController,
          children: [
            // 1 — Monitor
            Padding(
              padding: const EdgeInsets.all(AppSizes.adminContentPadding),
              child: RegisterMonitor(
                plcService: widget.plcService,
                adminStrings: s,
              ),
            ),
            // 2 — Manual
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.adminContentPadding),
              child: ManualControl(
                plcService: widget.plcService,
                isReadOnly: widget.isReadOnly,
                adminStrings: s,
              ),
            ),
            // 3 — Status
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.adminContentPadding),
              child: HealthStatus(
                plcService: widget.plcService,
                adminStrings: s,
              ),
            ),
            // 4 — Log
            Padding(
              padding: const EdgeInsets.all(AppSizes.adminContentPadding),
              child: EventLog(adminStrings: s),
            ),
            // 5 — Settings (genel fiyat / para birimi + PLC timeout)
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.adminContentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PriceSettings(
                    viewModel: widget.viewModel,
                    adminStrings: s,
                  ),
                  const SizedBox(height: 48),
                  Divider(color: Colors.white12),
                  const SizedBox(height: 32),
                  TimeoutSettings(
                    viewModel: widget.viewModel,
                    adminStrings: s,
                  ),
                ],
              ),
            ),
            // 6 — Pricing (slot bazlı fiyat override)
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.adminContentPadding),
              child: SlotPriceSettings(
                viewModel: widget.viewModel,
                adminStrings: s,
              ),
            ),
            // 7 — Support (destek iletişim bilgileri)
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.adminContentPadding),
              child: SupportSettings(
                viewModel: widget.viewModel,
                adminStrings: s,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single tab in the [AdminPanelScreen] tab bar.
class _AdminTab extends StatelessWidget {
  const _AdminTab({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.adminTabWidth,
      height: AppSizes.adminTabHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSizes.adminTabIconSize),
          const SizedBox(height: AppSizes.adminTabSpacing),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, maxLines: 1, softWrap: false),
          ),
        ],
      ),
    );
  }
}
