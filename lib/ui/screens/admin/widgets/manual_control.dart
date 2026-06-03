import 'package:flutter/material.dart';
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
  });

  final PLCServiceManager plcService;

  @override
  State<ManualControl> createState() => _ManualControlState();
}

class _ManualControlState extends State<ManualControl> {
  final _registerController = TextEditingController();
  final _valueController = TextEditingController();
  String? _lastResult;
  bool _isLoading = false;

  Future<void> _readRegister() async {
    if (!widget.plcService.isConnected) {
      _showError('PLC not connected');
      return;
    }

    final registerStr = _registerController.text.trim();
    if (registerStr.isEmpty) {
      _showError('Enter register address');
      return;
    }

    final register = int.tryParse(registerStr);
    if (register == null || register < 0 || register > 65535) {
      _showError('Invalid register address (0–65535)');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      // TODO: call direct read method
      // mock for now
      await Future.delayed(const Duration(milliseconds: 500));
      const value = 42;

      setState(() {
        _lastResult = 'Register R$register = $value';
      });

      PLCEventLogger.instance.logRead(register, value);
    } catch (e) {
      _showError('Read error: $e');
      PLCEventLogger.instance
          .logError('Register $register read error', error: e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _writeRegister() async {
    if (!widget.plcService.isConnected) {
      _showError('PLC not connected');
      return;
    }

    final registerStr = _registerController.text.trim();
    final valueStr = _valueController.text.trim();

    if (registerStr.isEmpty || valueStr.isEmpty) {
      _showError('Enter register and value');
      return;
    }

    final register = int.tryParse(registerStr);
    final value = int.tryParse(valueStr);

    if (register == null || register < 0 || register > 65535) {
      _showError('Invalid register address (0–65535)');
      return;
    }

    if (value == null || value < 0 || value > 65535) {
      _showError('Invalid value (0–65535)');
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
        title: const Text('Write Confirmation'),
        content: Text(
          'Value $value will be written to register R$register.\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
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
            child: const Text('Write'),
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
      // TODO: call direct write method
      // mock for now
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _lastResult = 'Register R$register = $value (written)';
      });

      PLCEventLogger.instance.logWrite(register, value);
    } catch (e) {
      _showError('Write error: $e');
      PLCEventLogger.instance
          .logError('Register $register write error', error: e.toString());
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
          const Text(
            'Manual Control',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: AdminColors.primaryText,
            ),
          ),

          const SizedBox(height: 18),

          _BigField(
            controller: _registerController,
            labelText: 'Register Address (0–65535)',
            prefixText: 'R',
          ),

          const SizedBox(height: 18),

          _BigField(
            controller: _valueController,
            labelText: 'Value (0–65535)',
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _readRegister,
                  icon: const Icon(Icons.download, size: 48),
                  label: const Text(
                    'Read',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
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
                  onPressed: _isLoading ? null : _writeRegister,
                  icon: const Icon(Icons.upload, size: 48),
                  label: const Text(
                    'Write',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
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

          const Text(
            'Quick Actions:',
            style: TextStyle(
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
                label: 'R0 (Suggestion 1)',
                onTap: () => setState(() => _registerController.text = '0'),
              ),
              _QuickActionChip(
                label: 'R10 (Tester)',
                onTap: () => setState(() => _registerController.text = '10'),
              ),
              _QuickActionChip(
                label: 'R20 (Payment)',
                onTap: () => setState(() => _registerController.text = '20'),
              ),
              _QuickActionChip(
                label: 'R30 (Perfume)',
                onTap: () => setState(() => _registerController.text = '30'),
              ),
              _QuickActionChip(
                label: 'R100 (Heartbeat)',
                onTap: () => setState(() => _registerController.text = '100'),
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
