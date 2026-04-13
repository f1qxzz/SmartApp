import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> saveCsvExportImpl({
  required String csvContent,
  required String fileName,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(csvContent);
  return file.path;
}
