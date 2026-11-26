import 'download_service_base.dart';
import 'download_service_io.dart'
    if (dart.library.js_interop) 'download_service_web.dart'
    as impl;

export 'download_service_base.dart';

DownloadService createDownloadService() => impl.createDownloadService();
