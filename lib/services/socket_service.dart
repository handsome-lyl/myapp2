import 'socket_service_base.dart';
import 'socket_service_io.dart'
    if (dart.library.js_interop) 'socket_service_web.dart'
    as impl;

export 'socket_service_base.dart';

SocketService createSocketService() => impl.createSocketService();
