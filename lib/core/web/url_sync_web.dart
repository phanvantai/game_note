import 'dart:js_interop';

@JS('window.history.pushState')
external void _historyPushState(JSAny? state, String title, String url);

@JS('window.location')
external _Location get _location;

extension type _Location._(JSObject _) implements JSObject {
  external String get pathname;
  external String get search;
  external String get hash;
}

class UrlSync {
  static void pushIfDifferent(Uri uri) {
    final target = uri.toString();
    final current = '${_location.pathname}${_location.search}${_location.hash}';
    if (target == current) return;
    _historyPushState(null, '', target);
  }
}
