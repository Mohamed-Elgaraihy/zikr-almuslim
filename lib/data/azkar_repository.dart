import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/azkar.dart';

class AzkarRepository {
  const AzkarRepository();

  Future<AzkarLibrary> load() async {
    final raw = await rootBundle.loadString('assets/data/azkar.json');
    return AzkarLibrary.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
