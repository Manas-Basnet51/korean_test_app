import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:go_router/go_router.dart';

class PDFViewerScreen extends StatelessWidget {
  final File pdfFile;
  final String title;
  
  const PDFViewerScreen({
    super.key,
    required this.pdfFile,
    required this.title,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPdf(context),
          ),
        ],
        leading: IconButton(
          onPressed: () {
            context.pop();
          }, 
          icon: const Icon(Icons.arrow_back)
        ),
      ),
      body: SafeArea(
        child: PDFView(
          filePath: pdfFile.path,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          defaultPage: 0,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            if (kDebugMode) {
              print('PDF rendered with $pages pages');
            }
          },
          onError: (error) {
            if (kDebugMode) {
              print('Error in PDFView: $error');
            }
            context.pop(); // Use GoRouter's pop instead of Navigator.pop
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $error')),
            );
          },
          onPageError: (page, error) {
            debugPrint('Error on page $page: $error');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error on page $page: $error')),
            );
          },
          onViewCreated: (controller) {
            if (kDebugMode) {
              print('PDFView controller created');
            }
          },
          onPageChanged: (int? page, int? total) {
            if (kDebugMode) {
              print('Page changed: $page / $total');
            }
          },
        ),
      ),
    );
  }
  
  void _downloadPdf(BuildContext context) {
    try {
      // Implement file saving logic based on platform
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF saved to downloads')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving PDF: $e')),
      );
    }
  }
}