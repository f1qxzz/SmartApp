import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String> saveCsvExportImpl({
  required String csvContent,
  required String fileName,
}) async {
  final bytes = utf8.encode(csvContent);
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'text/csv;charset=utf-8;'));
  final url = web.URL.createObjectURL(blob);
  
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..setAttribute('download', fileName);

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);

  return fileName;
}
