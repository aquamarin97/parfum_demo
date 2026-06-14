import 'package:flutter/material.dart';
import 'package:parfume_app/core/strings/app_strings.dart';
import 'package:parfume_app/ui/theme/app_admin_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';
import 'package:parfume_app/viewmodel/app_view_model.dart';

import 'price_settings.dart';

/// Admin paneli — kullanıcıya gösterilecek destek iletişim bilgileri.
///
/// Girilen isim ve telefon numarası, kullanıcı yardım butonuna bastığında
/// gösterilen dialogda görünür. Her iki alan da boş bırakılırsa yardım
/// butonu hiç gösterilmez.
class SupportSettings extends StatefulWidget {
  const SupportSettings({
    super.key,
    required this.viewModel,
    required this.adminStrings,
  });

  final AppViewModel viewModel;
  final AppStrings adminStrings;

  @override
  State<SupportSettings> createState() => _SupportSettingsState();
}

class _SupportSettingsState extends State<SupportSettings> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  AppStrings get _s => widget.adminStrings;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.viewModel.supportName);
    _phoneCtrl = TextEditingController(text: widget.viewModel.supportPhone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.viewModel.setSupportName(_nameCtrl.text.trim());
    await widget.viewModel.setSupportPhone(_phoneCtrl.text.trim());
    setState(() => _saving = false);
    _snack(_s.t('admin_saved'));
  }

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
          _s.t('admin_support_title'),
          style: TextStyle(
            fontSize: AppSizes.adminAppBarTitleSize,
            fontWeight: FontWeight.w800,
            color: AdminColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _s.t('admin_support_subtitle'),
          style: TextStyle(
            fontSize: AppSizes.adminDialogBodySize - 2,
            color: AdminColors.secondaryText,
          ),
        ),
        const SizedBox(height: 28),
        AdminField(
          label: _s.t('admin_support_name_label'),
          controller: _nameCtrl,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 20),
        AdminField(
          label: _s.t('admin_support_phone_label'),
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        Text(
          _s.t('admin_support_hint'),
          style: TextStyle(
            fontSize: AppSizes.adminDialogBodySize - 4,
            color: AdminColors.secondaryText.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
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
