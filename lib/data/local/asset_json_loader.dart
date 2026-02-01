// asset_json_loader.dart file
import 'dart:convert';

import 'package:flutter/services.dart';

class AssetJsonLoader {
  const AssetJsonLoader();

  Future<Map<String, dynamic>> loadJson(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw FormatException('Invalid JSON at $path');
  }
}