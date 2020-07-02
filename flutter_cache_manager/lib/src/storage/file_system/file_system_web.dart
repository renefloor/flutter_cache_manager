import 'dart:async';
import 'dart:js' as js;

import 'package:flutter_cache_manager/src/storage/file_system/cache_file_web.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';

class WebFileSystem implements FileSystem {
  Future<js.JsObject> _cache;

  WebFileSystem(String key) : _cache = createCache(key);

  static Future<js.JsObject> createCache(String key) async {
    final completer = Completer<js.JsObject>();
    // DON'T use html.window.caches.open(key), it converts to Dart object and we need to keep the original JS one
    final storage = js.context['caches'];
    //TODO Cache API not supported if null
    final promise = storage.callMethod('open', [key]);
    promise.callMethod('then', [
      (js.JsObject cache) => completer.complete(cache),
    ]);
    return completer.future;
  }

  @override
  Future<CacheFile> createFile(String name) async {
    assert(name != null);
    return CacheFile(await _cache, name);
  }
}
