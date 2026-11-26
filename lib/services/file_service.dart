import 'file_service_base.dart';
import 'file_service_io.dart'
    if (dart.library.js_interop) 'file_service_web.dart'
    as impl;

export 'file_service_base.dart';

FileService createFileService() => impl.createFileService();
