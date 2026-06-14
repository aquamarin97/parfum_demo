import 'package:flutter/material.dart';
import 'package:parfume_app/core/strings/app_strings.dart';
import 'package:parfume_app/ui/theme/app_admin_colors.dart';

/// Sol alt köşede görünen yardım / destek butonu.
///
/// Yalnızca [supportName] ve [supportPhone] doluysa render edilir.
/// Dokunulduğunda isim ve telefon numarasını içeren bir dialog açar.
class HelpButton extends StatelessWidget {
  const HelpButton({
    super.key,
    required this.supportName,
    required this.supportPhone,
    required this.strings,
  });

  final String supportName;
  final String supportPhone;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    if (supportName.isEmpty || supportPhone.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 272,
      bottom: 16,
      child: GestureDetector(
        onTap: () => _showDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_in_talk_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(
                strings.t('help_button_label'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.support_agent_rounded,
                color: AdminColors.accent, size: 44),
            const SizedBox(width: 14),
            Text(
              strings.t('help_dialog_title'),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AdminColors.primaryText,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.t('help_dialog_body'),
              style: const TextStyle(
                fontSize: 28,
                color: AdminColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _ContactRow(
              icon: Icons.person_rounded,
              text: supportName,
            ),
            const SizedBox(height: 16),
            _ContactRow(
              icon: Icons.phone_rounded,
              text: supportPhone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              strings.t('help_dialog_close'),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AdminColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AdminColors.accent, size: 36),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AdminColors.primaryText,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
