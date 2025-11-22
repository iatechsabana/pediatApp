import 'dart:typed_data';

// Import condicional para multiplataforma
import 'document_picker_mobile.dart'
  if (dart.library.html) 'document_picker_web.dart';

class PickedDocument {
  final String name;
  final Uint8List bytes;
  PickedDocument({required this.name, required this.bytes});
}

Future<PickedDocument?> pickDocument() => pickDocumentImpl();
