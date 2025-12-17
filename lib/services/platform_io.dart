import 'dart:io' show Platform;

bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
bool get isMobile => Platform.isAndroid || Platform.isIOS;
