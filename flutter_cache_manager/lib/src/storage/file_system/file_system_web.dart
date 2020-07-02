import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as util;

import 'package:flutter_cache_manager/src/storage/file_system/cache_file_web.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';

class WebFileSystem implements FileSystem {
  Future<js.JsObject> _cache;

  WebFileSystem(String key) : _cache = createCache(key);

  static Future<js.JsObject> createCache(String key) async {
    return html.window.caches.open(key);
  }

  @override
  Future<CacheFile> createFile(String name) async {
    assert(name != null);
    final js.JsObject cache = await _cache;
    return CacheFile(await _cache, name);
  }
}
