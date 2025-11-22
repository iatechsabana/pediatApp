
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'document_picker_stub.dart';

Future<PickedDocument?> pickDocumentImpl() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
  if (result != null && result.files.single.bytes != null) {
    final file = result.files.single;
    return PickedDocument(name: file.name, bytes: file.bytes!);
  }
  return null;
}
