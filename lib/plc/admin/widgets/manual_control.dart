// lib/plc/admin/widgets/manual_control.dart
import 'package:flutter/material.dart';
import 'package:parfume_app/plc/plc_service_manager.dart';
import 'package:parfume_app/plc/modbus_plc_client.dart';
import 'package:parfume_app/plc/admin/models/plc_event.dart';

/// Kiosk/32" uyumlu sabit renk & boyut sistemi (RegisterMonitor ile aynı)
const Color kBgDark = Color(0xFF0B1020);
const Color kCardBg = Color(0xFF141A2E);
const Color kPrimaryText = Colors.white;
const Color kSecondaryText = Color(0xFFB9C0D4);
const Color kAccent = Color(0xFF4DA3FF);
const Color kLiveGreen = Color(0xFF4CAF50);
const Color kDangerRed = Color(0xFFE53935);
const Color kWarnOrange = Color(0xFFFB8C00);

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
      _showError('PLC bağlı değil');
      return;
    }

    final registerStr = _registerController.text.trim();
    if (registerStr.isEmpty) {
      _showError('Register adresi giriniz');
      return;
    }

    final register = int.tryParse(registerStr);
    if (register == null || register < 0 || register > 65535) {
      _showError('Geçersiz register adresi (0-65535)');
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final client = widget.plcService;

      // TODO: Direct read metodunu çağır
      // Şimdilik mock
      await Future.delayed(const Duration(milliseconds: 500));
      final value = 42;

      setState(() {
        _lastResult = 'Register R$register = $value';
      });

      PLCEventLogger.instance.logRead(register, value);
    } catch (e) {
      _showError('Okuma hatası: $e');
      PLCEventLogger.instance
          .logError('Register $register okuma hatası', error: e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _writeRegister() async {
    if (!widget.plcService.isConnected) {
      _showError('PLC bağlı değil');
      return;
    }

    final registerStr = _registerController.text.trim();
    final valueStr = _valueController.text.trim();

    if (registerStr.isEmpty || valueStr.isEmpty) {
      _showError('Register ve değer giriniz');
      return;
    }

    final register = int.tryParse(registerStr);
    final value = int.tryParse(valueStr);

    if (register == null || register < 0 || register > 65535) {
      _showError('Geçersiz register adresi (0-65535)');
      return;
    }

    if (value == null || value < 0 || value > 65535) {
      _showError('Geçersiz değer (0-65535)');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardBg,
        titleTextStyle: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: kPrimaryText,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: kSecondaryText,
        ),
        title: const Text('Yazma Onayı'),
        content: Text(
          'Register R$register\'a değer $value yazılacak.\nEmin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'İptal',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: kSecondaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kWarnOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              textStyle:
                  const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            child: const Text('Yaz'),
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
      final client = widget.plcService;

      // TODO: Direct write metodunu çağır
      // Şimdilik mock
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _lastResult = 'Register R$register = $value (yazıldı)';
      });

      PLCEventLogger.instance.logWrite(register, value);
    } catch (e) {
      _showError('Yazma hatası: $e');
      PLCEventLogger.instance
          .logError('Register $register yazma hatası', error: e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kDangerRed,
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
    return Container(
      color: kBgDark,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manuel Kontrol',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: kPrimaryText,
              ),
            ),

            const SizedBox(height: 18),

            // Register input
            _BigField(
              controller: _registerController,
              labelText: 'Register Adresi (0-65535)',
              prefixText: 'R',
            ),

            const SizedBox(height: 18),

            // Value input
            _BigField(
              controller: _valueController,
              labelText: 'Değer (0-65535)',
            ),

            const SizedBox(height: 22),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _readRegister,
                    icon: const Icon(Icons.download, size: 48),
                    label: const Text(
                      'Oku',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
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
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _writeRegister,
                    icon: const Icon(Icons.upload, size: 48),
                    label: const Text(
                      'Yaz',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: kWarnOrange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: kWarnOrange.withOpacity(0.35),
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
                  color: kLiveGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kLiveGreen, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: kLiveGreen, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _lastResult!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: kPrimaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 26),

            const Text(
              'Hızlı İşlemler:',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: kPrimaryText,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickActionChip(
                  label: 'R0 (Öneri 1)',
                  onTap: () => setState(() => _registerController.text = '0'),
                ),
                _QuickActionChip(
                  label: 'R10 (Tester)',
                  onTap: () => setState(() => _registerController.text = '10'),
                ),
                _QuickActionChip(
                  label: 'R20 (Ödeme)',
                  onTap: () => setState(() => _registerController.text = '20'),
                ),
                _QuickActionChip(
                  label: 'R30 (Parfüm)',
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
      ),
    );
  }
}

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
        color: kPrimaryText,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: kCardBg,
        labelText: labelText,
        labelStyle: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: kSecondaryText,
        ),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: kAccent,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kSecondaryText.withOpacity(0.35), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAccent, width: 3),
        ),
      ),
    );
  }
}

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
      backgroundColor: kCardBg,
      side: BorderSide(color: kSecondaryText.withOpacity(0.25), width: 2),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: kPrimaryText,
        ),
      ),
      onPressed: onTap,
      avatar: const Icon(Icons.flash_on, size: 34, color: kAccent),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
