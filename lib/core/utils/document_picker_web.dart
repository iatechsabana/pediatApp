import 'dart:typed_data';
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'document_picker_stub.dart';

Future<PickedDocument?> pickDocumentImpl() async {
  final completer = Completer<PickedDocument?>();
  html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
  uploadInput.accept = '.pdf,.jpg,.png';
  uploadInput.click();
  uploadInput.onChange.listen((e) {
    final file = uploadInput.files?.first;
    if (file != null) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        final data = reader.result as List<int>;
        completer.complete(PickedDocument(name: file.name, bytes: Uint8List.fromList(data)));
      });
    } else {
      completer.complete(null);
    }
  });
  return completer.future;
}
