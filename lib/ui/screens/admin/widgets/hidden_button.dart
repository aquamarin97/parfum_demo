// lib/plc/debug/hidden_button.dart
import 'package:flutter/material.dart';
import 'dart:async';

/// Gizli admin panel giriş butonu
/// 
/// Kullanım:
/// - Sol alt köşede görünmez alan
/// - 4 kez tıkla (2 saniye içinde)
/// - Şifre ekranı açılır
class HiddenAdminButton extends StatefulWidget {
  const HiddenAdminButton({
    super.key,
    required this.onAccessGranted,
    this.requiredTaps = 4,
    this.tapWindowSeconds = 2,
    this.password = '1234',
  });

  final VoidCallback onAccessGranted;
  final int requiredTaps;
  final int tapWindowSeconds;
  final String password;

  @override
  State<HiddenAdminButton> createState() => _HiddenAdminButtonState();
}

class _HiddenAdminButtonState extends State<HiddenAdminButton> {
  int _tapCount = 0;
  Timer? _resetTimer;

  void _handleTap() {
    setState(() {
      _tapCount++;
    });

    // Reset timer'ı yeniden başlat
    _resetTimer?.cancel();
    _resetTimer = Timer(
      Duration(seconds: widget.tapWindowSeconds),
      () {
        setState(() {
          _tapCount = 0;
        });
      },
    );

    // Yeterli sayıda tıklama yapıldıysa şifre ekranını aç
    if (_tapCount >= widget.requiredTaps) {
      _resetTimer?.cancel();
      setState(() {
        _tapCount = 0;
      });
      _showPasswordDialog();
    }
  }

  void _showPasswordDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text(
          'Admin Erişimi',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Lütfen şifreyi girin:',
              style: TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(fontSize: 40),
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '****',
                counterText: '',
              ),
              onSubmitted: (value) {
                _checkPassword(context, value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(fontSize: 36),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _checkPassword(context, controller.text);
            },
            child: const Text(
              'Giriş',
              style: TextStyle(fontSize: 36),
            ),
          ),
        ],
      ),
    );
  }

  void _checkPassword(BuildContext context, String password) {
    if (password == widget.password) {
      Navigator.pop(context);
      widget.onAccessGranted();
    } else {
      // Hatalı şifre
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hatalı şifre!',
            style: TextStyle(fontSize: 32),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          width: 80,
          height: 80,
          color: const Color.fromARGB(0, 133, 21, 21),
          // Debug için görmek istersen:
          // color: Colors.red.withOpacity(0.1),
          child: _tapCount > 0
              ? Center(
                  child: Text(
                    '$_tapCount',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 24,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}