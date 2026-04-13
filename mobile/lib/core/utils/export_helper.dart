import 'export_helper_io.dart' if (dart.library.html) 'export_helper_web.dart';

Future<String> saveCsvExport({
  required String csvContent,
  required String fileName,
}) {
  return saveCsvExportImpl(
    csvContent: csvContent,
    fileName: fileName,
  );
}
