import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DocumentViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const DocumentViewerPage({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  bool? isPdf;
  bool error = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _checkPdf();
  }

  Future<void> _checkPdf() async {
    setState(() { loading = true; });
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200 && response.bodyBytes.length > 4) {
        // PDF files start with %PDF
        final header = String.fromCharCodes(response.bodyBytes.take(4).toList());
        if (header == '%PDF') {
          setState(() { isPdf = true; error = false; });
        } else {
          setState(() { isPdf = false; error = false; });
        }
      } else {
        setState(() { error = true; });
      }
    } catch (_) {
      setState(() { error = true; });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = widget.url.split('.').last.toLowerCase();
    Widget content;
    if (loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (error) {
      content = _errorWidget('No se pudo cargar el archivo.');
    } else if (isPdf == true) {
      content = SfPdfViewer.network(widget.url,
        onDocumentLoadFailed: (details) {
          setState(() { error = true; });
        },
      );
    } else if (["jpg", "jpeg", "png", "gif", "bmp", "webp"].contains(ext)) {
      content = Center(
        child: InteractiveViewer(
          child: Image.network(widget.url, fit: BoxFit.contain, errorBuilder: (c, e, s) => _errorWidget('No se pudo cargar la imagen')),
        ),
      );
    } else {
      content = _errorWidget('Vista previa no soportada para este tipo de archivo.');
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: content,
    );
  }

  Widget _errorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SelectableText(widget.url, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir en otra app'),
              onPressed: () async {
                final uri = Uri.parse(widget.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}