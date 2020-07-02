import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:typed_data';

import 'package:file/file.dart';

import 'cache_file.dart' as def;

class CacheFile implements def.CacheFile, IOSink {
  js.JsObject _cache;
  String _name;

  static final js.JsObject nameOptions = js.JsObject.jsify({
    'ignoreSearch': true,
    'ignoreMethod': true,
    'ignoreVary': true,
  });

  CacheFile(js.JsObject cache, String name) {
    _cache = cache;
    _name = name;
  }

  @override
  Future<bool> exists() async {
    // JS: return await cache.match(name, {ignoreSearch: true, ignoreMethod: true, ignoreVary: true}) != undefined;
    final promise = _cache.callMethod('match', [_name, nameOptions]);
    final response = await _toFuture<js.JsObject>(promise);
    return response != null;
  }

  @override
  Future<void> delete() async {
    // JS: return await cache.delete(name, {ignoreSearch: true, ignoreMethod: true, ignoreVary: true});
    final promise = _cache.callMethod('delete', [_name, nameOptions]);
    final result = await _toFuture<bool>(promise);
  }

  @override
  Future<void> createParent() {
  }

  @override
  IOSink openWrite() {
    return this;
  }

  @override
  Future writeAsBytes(Uint8List bytes) async {
print('writeAsBytes start');
    // JS: var blob = new Blob([bytes], {type : mime});
    final array = js.JsObject.jsify([bytes]);
    final options1 = js.JsObject.jsify({
      'mime': 'application/octet-stream',
    });
    final blob = js.JsObject(js.context['Blob'], [array, options1]);

    // JS: var options = {headers: {'Content-Type': mime, 'Content-Length': bytes.length}};
    final options2 = js.JsObject.jsify({
      'headers': {
        'Content-Type': 'application/octet-stream',
        'Content-Length': bytes.length,
      },
    });

    // JS: await cache.put(path, new Response(blob, options));
    final response = js.JsObject(js.context['Response'], [blob, options2]);
    final promise = _cache.callMethod('put', [_name, response]);
    await _toFuture(promise);
print('writeAsBytes end');
  }

  @override
  Future<Uint8List> readAsBytes() async {
print('readAsBytes start');
    try {
      // JS: var data = await cache.match(name, {ignoreSearch: true, ignoreMethod: true, ignoreVary: true});
      final promise1 = _cache.callMethod('match', [_name, nameOptions]);
      final response = await _toFuture<js.JsObject>(promise1);
print(response);
  
      // JS: return data.arrayBuffer();
      final promise2 = response.callMethod('arrayBuffer');
      final data = await _toFuture<ByteBuffer>(promise2);
print('data ${data.lengthInBytes}');
      return data.asUint8List();
    }
    catch (e) {
      print(e);
    }
    finally {
print('readAsBytes end');
    }
  }

  Future<T> _toFuture<T>(js.JsObject promise) {
    final completer = Completer<T>();
    promise.callMethod('then', [
      (result) => completer.complete(result),
    ]);
    return completer.future;
  }

  //*** IOSink

  @override
  Encoding encoding;

  @override
  void add(List<int> data) {
    writeAsBytes(Uint8List.fromList(data));
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    print('addError $error');
  }

  @override
  Future addStream(Stream<List<int>> stream) async {
    stream.listen(add);
  }

  @override
  Future close() {
  }

  @override
  Future get done => throw UnimplementedError();

  @override
  Future flush() {
  }

  @override
  void write(Object obj) {
    throw UnimplementedError();
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    throw UnimplementedError();
  }

  @override
  void writeCharCode(int charCode) {
    throw UnimplementedError();
  }

  @override
  void writeln([Object obj = ""]) {
    throw UnimplementedError();
  }
}
