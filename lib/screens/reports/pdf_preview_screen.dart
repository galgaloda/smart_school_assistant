// =============================================================
// FILE: lib/screens/reports/pdf_preview_screen.dart (NEW FILE)
// =============================================================
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfFile;

  const PdfPreviewScreen({super.key, required this.pdfFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
      ),
      body: PdfPreview(
        build: (format) => pdfFile,
      ),
    );
  }
}
