import 'package:flutter/material.dart';

import '../data/app_storage.dart';
import '../models/app_data.dart';

class AppController extends ChangeNotifier {
  AppController(this._storage, this._data);

  final AppStorage _storage;
  AppData _data;

  AppData get data => _data;

  Future<void> update(AppData data) async {
    _data = data;
    notifyListeners();
    await _storage.save(_data);
  }
}
