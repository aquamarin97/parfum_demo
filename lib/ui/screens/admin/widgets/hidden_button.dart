import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parfume_app/core/constants/app_constants.dart';
import 'package:parfume_app/ui/theme/app_admin_colors.dart';
import 'package:parfume_app/ui/theme/app_sizes.dart';

/// An invisible tap target in the bottom-left corner that opens the admin
/// panel after [requiredTaps] taps within [tapWindowSeconds] seconds.
///
/// A password dialog is shown before granting access. The default password
/// is defined in [AppConstants.adminPassword].
class HiddenAdminButton extends StatefulWidget {
  const HiddenAdminButton({
    super.key,
    required this.onAccessGranted,
    this.requiredTaps = 4,
    this.tapWindowSeconds = 2,
    this.password = AppConstants.adminPassword,
  });

  /// Called when the correct password is entered.
  final VoidCallback onAccessGranted;

  /// Number of taps required within [tapWindowSeconds] to trigger the dialog.
  final int requiredTaps;

  /// Time window in seconds within which [requiredTaps] must occur.
  final int tapWindowSeconds;

  /// Password required to access the admin panel.
  final String password;

  @override
  State<HiddenAdminButton> createState() => _HiddenAdminButtonState();
}

class _HiddenAdminButtonState extends State<HiddenAdminButton> {
  int _tapCount = 0;
  Timer? _resetTimer;

  void _handleTap() {
    setState(() => _tapCount++);

    _resetTimer?.cancel();
    _resetTimer = Timer(
      Duration(seconds: widget.tapWindowSeconds),
      () => setState(() => _tapCount = 0),
    );

    if (_tapCount >= widget.requiredTaps) {
      _resetTimer?.cancel();
      setState(() => _tapCount = 0);
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
          'Admin Access',
          style: TextStyle(
            fontSize: AppSizes.adminDialogTitleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter password:',
              style: TextStyle(fontSize: AppSizes.adminDialogBodySize),
            ),
            const SizedBox(height: AppSizes.spacingS),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(
                fontSize: AppSizes.adminDialogTitleSize,
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '****',
                counterText: '',
              ),
              onSubmitted: (value) => _checkPassword(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: AppSizes.adminDialogActionSize),
            ),
          ),
          ElevatedButton(
            onPressed: () => _checkPassword(context, controller.text),
            child: const Text(
              'Enter',
              style: TextStyle(fontSize: AppSizes.adminDialogActionSize),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Incorrect password.',
            style: TextStyle(fontSize: AppSizes.adminDialogBodySize),
          ),
          backgroundColor: AdminColors.danger,
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
          width: AppSizes.hiddenButtonSize,
          height: AppSizes.hiddenButtonSize,
          color: Colors.transparent,
          child: _tapCount > 0
              ? Center(
                  child: Text(
                    '$_tapCount',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: AppSizes.adminTapCounterSize,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}