import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'file_service_base.dart';

class IoFileService implements FileService {
  Future<File> _noteFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/chapter11_note.txt');
  }

  Future<File> _counterFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/chapter11_counter.txt');
  }

  @override
  String get platformLabel => 'dart:io + path_provider（应用文档目录）';

  @override
  Future<FileSnapshot> load() async {
    final file = await _noteFile();
    if (!await file.exists()) {
      return FileSnapshot(
        path: file.path,
        size: 0,
        modifiedAt: null,
        content: '',
      );
    }
    final content = await file.readAsString();
    final stat = await file.stat();
    return FileSnapshot(
      path: file.path,
      size: stat.size,
      modifiedAt: stat.modified,
      content: content,
    );
  }

  @override
  Future<void> save(String content) async {
    final file = await _noteFile();
    await file.writeAsString(content, flush: true);
  }

  @override
  Future<void> clear() async {
    final file = await _noteFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<int> readCounter() async {
    final file = await _counterFile();
    if (!await file.exists()) {
      return 0;
    }
    return int.tryParse(await file.readAsString()) ?? 0;
  }

  @override
  Future<void> writeCounter(int value) async {
    final file = await _counterFile();
    await file.writeAsString('$value', flush: true);
  }
}

FileService createFileService() => IoFileService();
