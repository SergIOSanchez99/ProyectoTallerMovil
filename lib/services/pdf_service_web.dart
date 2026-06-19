// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Guarda el PDF en la web disparando una descarga en el navegador.
Future<void> savePdf(List<int> bytes, String fileName) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Crear un enlace <a> temporal y hacer clic para descargar
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();

  // Liberar la URL del objeto
  html.Url.revokeObjectUrl(url);

  print('🌐 PDF descargado en el navegador: $fileName');
}
