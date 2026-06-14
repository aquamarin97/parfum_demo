import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parfume_app/core/strings/app_strings.dart';
import 'package:parfume_app/domain/plc/plc_timings.dart';
import 'package:parfume_app/ui/theme/app_admin_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/viewmodel/app_view_model.dart';

import 'price_settings.dart';

/// Admin paneli — PLC iletişim süre parametreleri.
///
/// Her alan için minimum değer zorunludur; değişiklikler [AppViewModel.setTimings]
/// üzerinden hem PLC service'e hem de [PreferencesStore]'a kaydedilir.
class TimeoutSettings extends StatefulWidget {
  const TimeoutSettings({
    super.key,
    required this.viewModel,
    required this.adminStrings,
  });

  final AppViewModel viewModel;
  final AppStrings adminStrings;

  @override
  State<TimeoutSettings> createState() => _TimeoutSettingsState();
}

class _TimeoutSettingsState extends State<TimeoutSettings> {
  late final TextEditingController _ackCtrl;
  late final TextEditingController _idleCtrl;
  late final TextEditingController _payCtrl;
  late final TextEditingController _saleCtrl;
  bool _saving = false;

  AppStrings get _s => widget.adminStrings;

  @override
  void initState() {
    super.initState();
    final t = widget.viewModel.timings;
    _ackCtrl  = TextEditingController(text: t.commandAckTimeoutSec.toString());
    _idleCtrl = TextEditingController(text: t.systemIdlePollMs.toString());
    _payCtrl  = TextEditingController(text: t.paymentStatusPollMs.toString());
    _saleCtrl = TextEditingController(text: t.saleCompletedPollMs.toString());
  }

  @override
  void dispose() {
    _ackCtrl.dispose();
    _idleCtrl.dispose();
    _payCtrl.dispose();
    _saleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ack  = int.tryParse(_ackCtrl.text.trim());
    final idle = int.tryParse(_idleCtrl.text.trim());
    final pay  = int.tryParse(_payCtrl.text.trim());
    final sale = int.tryParse(_saleCtrl.text.trim());

    if (ack == null || ack < 5)    { _err(_s.t('admin_timeout_ack_error')); return; }
    if (idle == null || idle < 100) { _err(_s.t('admin_timeout_idle_error')); return; }
    if (pay == null || pay < 200)   { _err(_s.t('admin_timeout_payment_error')); return; }
    if (sale == null || sale < 100) { _err(_s.t('admin_timeout_sale_error')); return; }

    setState(() => _saving = true);
    await widget.viewModel.setTimings(PLCTimings(
      commandAckTimeoutSec: ack,
      systemIdlePollMs:     idle,
      paymentStatusPollMs:  pay,
      saleCompletedPollMs:  sale,
    ));
    setState(() => _saving = false);
    _snack(_s.t('admin_saved'));
  }

  void _err(String msg) => _snack(msg, isError: true);

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontSize: AppSizes.adminDialogBodySize)),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _s.t('admin_timeout_title'),
          style: TextStyle(
            fontSize: AppSizes.adminAppBarTitleSize,
            fontWeight: FontWeight.w800,
            color: AdminColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _s.t('admin_timeout_subtitle'),
          style: TextStyle(
            fontSize: AppSizes.adminDialogBodySize - 2,
            color: AdminColors.secondaryText,
          ),
        ),
        const SizedBox(height: 28),
        AdminField(
          label: _s.t('admin_timeout_ack_label'),
          controller: _ackCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 20),
        AdminField(
          label: _s.t('admin_timeout_idle_label'),
          controller: _idleCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 20),
        AdminField(
          label: _s.t('admin_timeout_payment_label'),
          controller: _payCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 20),
        AdminField(
          label: _s.t('admin_timeout_sale_label'),
          controller: _saleCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: 80,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: Colors.white),
                  )
                : Text(
                    _s.t('admin_save'),
                    style: const TextStyle(
                      fontSize: AppSizes.adminDialogActionSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
