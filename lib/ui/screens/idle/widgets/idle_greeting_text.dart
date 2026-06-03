import 'package:flutter/material.dart';
import 'package:parfume_app/common/widgets/app_ventuse_text.dart';
import 'package:parfume_app/ui/theme/app_text_styles.dart';

/// Localised greeting text overlay for the idle screen.
///
/// Renders two headline lines: a plain [title1] and a [title2] + [brandName]
/// combination where [brandName] uses the custom [VentuseText] styling.
///
/// Positioned in the upper-left (LTR) or upper-right (RTL) area of its
/// parent [Stack], with a fade-and-slide entry animation.
///
/// A [ValueKey] keyed on [languageCode] is applied to the inner [Column] so
/// that Flutter replaces the subtree — rather than updating it in place —
/// when the language changes, ensuring [CrossAxisAlignment] is applied fresh.
class IdleGreetingText extends StatelessWidget {
  const IdleGreetingText({
    super.key,
    required this.animation,
    required this.languageCode,
    required this.isRtl,
    required this.title1,
    required this.title2,
    required this.brandName,
  });

  /// Drives the fade and slide entry transitions (0.0 → 1.0).
  final Animation<double> animation;

  /// BCP 47 code of the active language; used as the [ValueKey] for the
  /// inner [Column] so a language change triggers a full subtree rebuild.
  final String languageCode;

  /// Whether the active locale uses right-to-left text direction.
  final bool isRtl;

  /// First greeting line (e.g. `'Merhaba,'`).
  final String title1;

  /// Second greeting line prefix (e.g. `'Ben '`), displayed before [brandName].
  final String title2;

  /// Brand name rendered with [VentuseText] styling.
  final String brandName;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isRtl ? null : 130,
      right: isRtl ? 130 : null,
      top: 140,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(animation),
          child: Column(
            key: ValueKey(languageCode),
            crossAxisAlignment:
                isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                title1,
                style: AppTextStyles.headline.copyWith(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: title2,
                      style: AppTextStyles.headline.copyWith(
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: AppVentuseText(text: brandName),
                    ),
                  ],
                ),
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }
}