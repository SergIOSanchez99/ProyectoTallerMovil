import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Guarda el PDF en el sistema de archivos nativo y lo comparte.
Future<void> savePdf(List<int> bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';

  final file = File(filePath);
  await file.writeAsBytes(bytes);

  print('💾 PDF guardado en: $filePath');
  await Share.shareXFiles([XFile(filePath)], text: 'Reporte de Colonoscopia');
}
