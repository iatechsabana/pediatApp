import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'document_picker_stub.dart';

Future<PickedDocument?> pickDocumentImpl() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
  if (result != null) {
    final file = result.files.single;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      // Leer los bytes desde la ruta en móvil
      final ioFile = await File(file.path!).readAsBytes();
      bytes = ioFile;
    }
    if (bytes != null) {
      return PickedDocument(name: file.name, bytes: bytes);
    }
  }
  return null;
}
