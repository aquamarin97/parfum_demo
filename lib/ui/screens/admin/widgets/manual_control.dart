import 'package:flutter/material.dart';
import 'package:parfume_app/core/strings/app_strings.dart';
import 'package:parfume_app/infrastructure/plc/plc_service_manager.dart';
import 'package:parfume_app/data/models/plc/plc_event.dart';
import 'package:parfume_app/ui/theme/app_admin_colors.dart';

/// Manual register read/write controls for PLC diagnostics.
///
/// All write operations require confirmation. Read operations are
/// currently mocked pending direct client access.
class ManualControl extends StatefulWidget {
  const ManualControl({
    super.key,
    required this.plcService,
    required this.adminStrings,
    this.isReadOnly = false,
  });

  final PLCServiceManager plcService;
  final AppStrings adminStrings;
  final bool isReadOnly;

  @override
  State<ManualControl> createState() => _ManualControlState();
}

class _ManualControlState extends State<ManualControl> {
  final _registerController = TextEditingController();
  final _valueController = TextEditingController();
  String? _lastResult;
  bool _isLoading = false;

  AppStrings get _s => widget.adminStrings;

  Future<void> _readRegister() async {
    if (!widget.plcService.isConnected) {
      _showError(_s.t('admin_manual_not_connected'));
      return;
    }

    final registerStr = _registerController.text.trim();
    if (registerStr.isEmpty) {
      _showError(_s.t('admin_manual_enter_register'));
      return;
    }

    final register = int.tryParse(registerStr);
    if (register == null || register < 0 || register > 65535) {
      _showError(_s.t('admin_manual_invalid_register'));
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final value = await widget.plcService.readRegister(register);
      setState(() {
        _lastResult = 'R$register = $value';
      });
    } catch (e) {
      _showError('${_s.t('admin_manual_read_error_prefix')}$e');
      PLCEventLogger.instance
          .logError('R$register read error', error: e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _writeRegister() async {
    if (!widget.plcService.isConnected) {
      _showError(_s.t('admin_manual_not_connected'));
      return;
    }

    final registerStr = _registerController.text.trim();
    final valueStr = _valueController.text.trim();

    if (registerStr.isEmpty || valueStr.isEmpty) {
      _showError(_s.t('admin_manual_enter_reg_and_value'));
      return;
    }

    final register = int.tryParse(registerStr);
    final value = int.tryParse(valueStr);

    if (register == null || register < 0 || register > 65535) {
      _showError(_s.t('admin_manual_invalid_register'));
      return;
    }

    if (value == null || value < 0 || value > 65535) {
      _showError(_s.t('admin_manual_invalid_value'));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.cardBackground,
        titleTextStyle: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: AdminColors.primaryText,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AdminColors.secondaryText,
        ),
        title: Text(_s.t('admin_manual_write_confirm_title')),
        content: Text(
          _s.t('admin_manual_write_confirm_body')
              .replaceAll('{value}', '$value')
              .replaceAll('{register}', '$register'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _s.t('admin_cancel'),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AdminColors.secondaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              textStyle:
                  const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            child: Text(_s.t('admin_manual_write')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      await widget.plcService.writeRegister(register, value);
      setState(() {
        _lastResult = 'R$register = $value ${_s.t('admin_manual_written_suffix')}';
      });
    } catch (e) {
      _showError('${_s.t('admin_manual_write_error_prefix')}$e');
      PLCEventLogger.instance
          .logError('R$register write error', error: e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AdminColors.danger,
        content: Text(
          message,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _registerController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _s.t('admin_manual_title'),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: AdminColors.primaryText,
            ),
          ),

          const SizedBox(height: 18),

          _BigField(
            controller: _registerController,
            labelText: _s.t('admin_manual_register_label'),
            prefixText: 'R',
          ),

          const SizedBox(height: 18),

          _BigField(
            controller: _valueController,
            labelText: _s.t('admin_manual_value_label'),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _readRegister,
                  icon: const Icon(Icons.download, size: 48),
                  label: Text(
                    _s.t('admin_manual_read'),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
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
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || widget.isReadOnly) ? null : _writeRegister,
                  icon: const Icon(Icons.upload, size: 48),
                  label: Text(
                    _s.t('admin_manual_write'),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: AdminColors.warning,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AdminColors.warning.withValues(alpha: 0.35),
                    disabledForegroundColor: Colors.white70,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(strokeWidth: 6),
              ),
            ),

          if (_lastResult != null && !_isLoading) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AdminColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.success, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AdminColors.success, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _lastResult!,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 26),

          Text(
            _s.t('admin_manual_quick_actions'),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AdminColors.primaryText,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickActionChip(
                label: 'R100 CMD_ACTION',
                onTap: () => setState(() => _registerController.text = '100'),
              ),
              _QuickActionChip(
                label: 'R200 STATUS_SYSTEM',
                onTap: () => setState(() => _registerController.text = '200'),
              ),
              _QuickActionChip(
                label: 'R201 LAST_CMD_SEQ',
                onTap: () => setState(() => _registerController.text = '201'),
              ),
              _QuickActionChip(
                label: 'R300 PAYMENT_STATUS',
                onTap: () => setState(() => _registerController.text = '300'),
              ),
              _QuickActionChip(
                label: 'R303 SALE_COMPLETED',
                onTap: () => setState(() => _registerController.text = '303'),
              ),
              _QuickActionChip(
                label: 'R400 PRESENCE',
                onTap: () => setState(() => _registerController.text = '400'),
              ),
              _QuickActionChip(
                label: 'R500 ERROR_CODE',
                onTap: () => setState(() => _registerController.text = '500'),
              ),
              _QuickActionChip(
                label: 'R600 PLC_HB',
                onTap: () => setState(() => _registerController.text = '600'),
              ),
              _QuickActionChip(
                label: 'R601 FLUTTER_HB',
                onTap: () => setState(() => _registerController.text = '601'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A large numeric input field styled for the admin panel.
class _BigField extends StatelessWidget {
  const _BigField({
    required this.controller,
    required this.labelText,
    this.prefixText,
  });

  final TextEditingController controller;
  final String labelText;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AdminColors.primaryText,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AdminColors.cardBackground,
        labelText: labelText,
        labelStyle: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AdminColors.secondaryText,
        ),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: AdminColors.accent,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AdminColors.secondaryText.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.accent, width: 3),
        ),
      ),
    );
  }
}

/// A tappable chip that pre-fills the register address field.
class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: AdminColors.cardBackground,
      side: BorderSide(
        color: AdminColors.secondaryText.withValues(alpha: 0.25),
        width: 2,
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AdminColors.primaryText,
        ),
      ),
      onPressed: onTap,
      avatar: const Icon(Icons.flash_on, size: 34, color: AdminColors.accent),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
