import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentViewerPage extends StatelessWidget {
  final String url;
  final String title;

  const DocumentViewerPage({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ext = url.split('.').last.toLowerCase();
    Widget content;
    if (["pdf"].contains(ext)) {
      content = SfPdfViewer.network(url);
    } else if (["jpg", "jpeg", "png", "gif", "bmp", "webp"].contains(ext)) {
      content = Center(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Text('No se pudo cargar la imagen')),
        ),
      );
    } else {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.insert_drive_file, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Vista previa no soportada para este tipo de archivo.'),
              const SizedBox(height: 16),
              SelectableText(url, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: content,
    );
  }
}