class FileSnapshot {
  const FileSnapshot({
    required this.path,
    required this.size,
    required this.modifiedAt,
    required this.content,
  });

  final String path;
  final int size;
  final DateTime? modifiedAt;
  final String content;
}

abstract class FileService {
  String get platformLabel;

  Future<FileSnapshot> load();

  Future<void> save(String content);

  Future<void> clear();

  Future<int> readCounter();

  Future<void> writeCounter(int value);
}
