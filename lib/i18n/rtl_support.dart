// rtl_support.dart file
import 'package:flutter/widgets.dart';

import '../data/models/language.dart';

class RtlSupport {
  static TextDirection textDirection(Language language) {
    return language.isRtl ? TextDirection.rtl : TextDirection.ltr;
  }
}