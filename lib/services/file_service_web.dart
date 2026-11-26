import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'file_service_base.dart';

const String _noteKey = 'chapter11_note';
const String _noteUpdatedKey = 'chapter11_note_updated';
const String _counterKey = 'chapter11_counter';

class WebFileService implements FileService {
  @override
  String get platformLabel => 'localStorage（shared_preferences）';

  @override
  Future<FileSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final content = prefs.getString(_noteKey) ?? '';
    final updated = prefs.getInt(_noteUpdatedKey);
    return FileSnapshot(
      path: 'localStorage://$_noteKey',
      size: utf8.encode(content).length,
      modifiedAt: updated == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updated),
      content: content,
    );
  }

  @override
  Future<void> save(String content) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_noteKey, content);
    await prefs.setInt(_noteUpdatedKey, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_noteKey);
    await prefs.remove(_noteUpdatedKey);
  }

  @override
  Future<int> readCounter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_counterKey) ?? 0;
  }

  @override
  Future<void> writeCounter(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_counterKey, value);
  }
}

FileService createFileService() => WebFileService();
