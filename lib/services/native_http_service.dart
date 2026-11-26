import 'native_http_service_base.dart';
import 'native_http_service_io.dart'
    if (dart.library.js_interop) 'native_http_service_web.dart'
    as impl;

export 'native_http_service_base.dart';

NativeHttpService createNativeHttpService() => impl.createNativeHttpService();
