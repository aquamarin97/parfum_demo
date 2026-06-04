import 'package:flutter/widgets.dart';

import '../data/models/language.dart';

/// Utility for resolving text direction from a [Language].
///
/// Used at the root of the widget tree ([AppRoot]) to set the
/// [Directionality] for the entire kiosk UI.
class RtlSupport {
  /// Returns [TextDirection.rtl] for right-to-left languages such as
  /// Arabic, [TextDirection.ltr] for all others.
  static TextDirection textDirection(Language language) =>
      language.isRtl ? TextDirection.rtl : TextDirection.ltr;
}