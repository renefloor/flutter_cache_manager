import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as util;
import 'dart:typed_data';

import 'package:file/file.dart';

import 'cache_file.dart' as def;

class CacheFile implements def.CacheFile, IOSink {
  js.JsObject _cache;
  String _name;

  static final js.JsObject nameOptions = js.JsObject.jsify(<String, dynamic>{
    'ignoreSearch': true,
    'ignoreMethod': true,
    'ignoreVary': true,
  });

  CacheFile(js.JsObject cache, String name) {
    print('CacheFile $name');
    _cache = cache;
    _name = name;
  }

  @override
  Future<bool> exists() async {
    print('exists $_name');
    // JS: return await cache.match(name, {ignoreSearch: true, ignoreMethod: true, ignoreVary: true}) != undefined;
    final js.JsObject response = await util.promiseToFuture<js.JsObject>(_cache.callMethod('match', <dynamic>[_name, nameOptions]));
    return response != null;
  }

  @override
  Future<void> delete() async {
    print('delete $_name');
    // JS: return await cache.delete(name, {ignoreSearch: true, ignoreMethod: true, ignoreVary: true});
    final result = await util.promiseToFuture<bool>(_cache.callMethod('delete', <dynamic>[_name, nameOptions]));
  }

  @override
  Future<void> createParent() {
    print('createParent $_name');
  }

  @override
  IOSink openWrite() {
    print('openWrite $_name');
    return this;
  }

  @override
  Future writeAsBytes(Uint8List bytes) async {
    print('writeAsBytes $_name ${bytes.length}');
    // JS: var blob = new Blob([bytes], {type : mime});
    final js.JsArray array = js.JsArray.from(bytes);
    final js.JsObject options1 = js.JsObject.jsify(<String, dynamic>{
      'mime': 'application/octet-stream',
    });
    final js.JsObject blob = js.JsObject(js.context['Blob'], <dynamic>[array, options1]);
    // JS: var options = {headers: {'Content-Type': mime, 'Content-Length': bytes.length}};
    final js.JsObject options2 = js.JsObject.jsify(<String, dynamic>{
      'headers': <String, dynamic>{
        'Content-Type': 'application/octet-stream',
        'Content-Length': bytes.length,
      },
    });
    // JS: await cache.put(path, new Response(blob, options));
    final js.JsObject response = js.JsObject(js.context['Response'], <dynamic>[blob, options2]);
    await util.promiseToFuture<js.JsObject>(_cache.callMethod('put', <dynamic>[_name, response]));
    return null;
  }

  @override
  Future<Uint8List> readAsBytes() async {
    print('readAsBytes $_name');
    // JS: var data = await cache.match(name, {ignoreSearch: true, ignoreMethod: true, ignoreVary: true});
    final js.JsObject response = await util.promiseToFuture<js.JsObject>(_cache.callMethod('match', <dynamic>[_name, nameOptions]));
    // JS: return data.arrayBuffer();
    final data = await util.promiseToFuture<ByteBuffer>(response.callMethod('arrayBuffer'));
    return data.asUint8List();
  }

  //*** IOSink

  @override
  Encoding encoding;

  @override
  void add(List<int> data) {
    print('sink.add');
    writeAsBytes(Uint8List.fromList(data));
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    print('sink.addError $error');
  }

  @override
  Future addStream(Stream<List<int>> stream) async {
    print('sink.addStream');
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
