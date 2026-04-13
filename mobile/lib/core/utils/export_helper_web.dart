import 'dart:convert';
import 'dart:html' as html;

Future<String> saveCsvExportImpl({
  required String csvContent,
  required String fileName,
}) async {
  final bytes = utf8.encode(csvContent);
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor =
      html.AnchorElement(href: url)..setAttribute('download', fileName);

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  return fileName;
}
