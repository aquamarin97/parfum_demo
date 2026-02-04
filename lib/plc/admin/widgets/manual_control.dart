// lib/plc/admin/widgets/manual_control.dart
import 'package:flutter/material.dart';
import 'package:parfume_app/plc/plc_service_manager.dart';
import 'package:parfume_app/plc/modbus_plc_client.dart';
import 'package:parfume_app/plc/admin/models/plc_event.dart';

/// Manuel register okuma/yazma widget
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
      // ModbusPLCClient'tan direkt oku
      final client = widget.plcService;
      
      // TODO: Direct read metodunu çağır
      // Şimdilik mock
      await Future.delayed(const Duration(milliseconds: 500));
      final value = 42; // Mock value
      
      setState(() {
        _lastResult = 'Register $register = $value';
      });
      
      PLCEventLogger.instance.logRead(register, value);
    } catch (e) {
      _showError('Okuma hatası: $e');
      PLCEventLogger.instance.logError('Register $register okuma hatası', error: e.toString());
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

    // Onay dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Yazma Onayı',
          style: TextStyle(fontSize: 28),
        ),
        content: Text(
          'Register $register\'a değer $value yazılacak. Emin misiniz?',
          style: const TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(fontSize: 20)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yaz', style: TextStyle(fontSize: 20)),
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
      // ModbusPLCClient'tan direkt yaz
      final client = widget.plcService;
      
      // TODO: Direct write metodunu çağır
      // Şimdilik mock
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _lastResult = 'Register $register = $value (yazıldı)';
      });
      
      PLCEventLogger.instance.logWrite(register, value);
    } catch (e) {
      _showError('Yazma hatası: $e');
      PLCEventLogger.instance.logError('Register $register yazma hatası', error: e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 20)),
        backgroundColor: Colors.red,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manuel Kontrol',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),

        // Register input
        TextField(
          controller: _registerController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 24),
          decoration: const InputDecoration(
            labelText: 'Register Adresi (0-65535)',
            labelStyle: TextStyle(fontSize: 20),
            border: OutlineInputBorder(),
            prefixText: 'R',
          ),
        ),

        const SizedBox(height: 16),

        // Value input (for write)
        TextField(
          controller: _valueController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 24),
          decoration: const InputDecoration(
            labelText: 'Değer (0-65535)',
            labelStyle: TextStyle(fontSize: 20),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 24),

        // Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _readRegister,
                icon: const Icon(Icons.download, size: 28),
                label: const Text(
                  'Oku',
                  style: TextStyle(fontSize: 24),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _writeRegister,
                icon: const Icon(Icons.upload, size: 28),
                label: const Text(
                  'Yaz',
                  style: TextStyle(fontSize: 24),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Loading indicator
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),

        // Result
        if (_lastResult != null && !_isLoading)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _lastResult!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // Quick actions
        const Text(
          'Hızlı İşlemler:',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickActionChip(
              label: 'R0 (Öneri 1)',
              onTap: () => _registerController.text = '0',
            ),
            _QuickActionChip(
              label: 'R10 (Tester)',
              onTap: () => _registerController.text = '10',
            ),
            _QuickActionChip(
              label: 'R20 (Ödeme)',
              onTap: () => _registerController.text = '20',
            ),
            _QuickActionChip(
              label: 'R30 (Parfüm)',
              onTap: () => _registerController.text = '30',
            ),
            _QuickActionChip(
              label: 'R100 (Heartbeat)',
              onTap: () => _registerController.text = '100',
            ),
          ],
        ),
      ],
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
      label: Text(
        label,
        style: const TextStyle(fontSize: 18),
      ),
      onPressed: onTap,
    );
  }
}