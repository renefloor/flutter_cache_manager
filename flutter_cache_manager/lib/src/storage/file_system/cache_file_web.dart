import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:synchronized/synchronized.dart';

import 'cache_file.dart' as def;

class CacheFile implements def.CacheFile, IOSink {
  static final Lock lock = Lock();
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
    await lock.synchronized(() async {
      // JS: var blob = new Blob([bytes], {type : mime});
      final blob = js.JsObject(js.context['Blob'], [
        js.JsObject.jsify([bytes]),
        js.JsObject.jsify({'mime': 'image/*'}),
      ]);
  
      // JS: var options = {headers: {'Content-Type': mime, 'Content-Length': bytes.length}};
      final options = js.JsObject.jsify({
        'headers': {
          'Content-Type': 'image/*',
          'Content-Length': bytes.length,
        },
      });
  
      // JS: await cache.put(path, new Response(blob, options));
      final response = js.JsObject(js.context['Response'], [blob, options]);
      final promise = _cache.callMethod('put', [_name, response]);
      await _toFuture(promise);
    });
  }

  @override
  Future<Uint8List> readAsBytes() async {
    return await lock.synchronized(() async {
      // JS: var data = await cache.match(name, {ignoreSearch: true, ignoreMethod: true, ignoreVary: true});
      final promise1 = _cache.callMethod('match', [_name, nameOptions]);
      final response = await _toFuture<js.JsObject>(promise1);
  
      // JS: return await data.arrayBuffer();
      // arrayBuffer() would be simpler but doesn't work?
      // final promise2 = response.callMethod('arrayBuffer', []);
      // final data = await _toFuture<ByteBuffer>(promise2);
      // return data.asUint8List();
      final promise2 = response.callMethod('blob', []);
      final data = await _toFuture<html.Blob>(promise2);
      return await _getBlobData(data);
    });
  }

  Future<Uint8List> _getBlobData(html.Blob blob) {
    final completer = Completer<Uint8List>();
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    reader.onLoad.listen((_) => completer.complete(reader.result));
    return completer.future;
  }

  Future<T> _toFuture<T>(js.JsObject promise) {
    final completer = Completer<T>();
    promise.callMethod('then', [
      (result) => completer.complete(result)
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
