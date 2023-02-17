import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewPage extends StatefulWidget {
  final String appBarTitle;
  final String pdfUrl;

  const PdfViewPage({Key key, this.appBarTitle, this.pdfUrl}) : super(key: key);

  @override
  _PdfViewPageState createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        title: Text(
          widget.appBarTitle,
          style: GoogleFonts.aBeeZee(color: Colors.black),
        ),
      ),
      body: Container(
        decoration:
            BoxDecoration(color: const Color.fromRGBO(220, 220, 220, 1.0), borderRadius: BorderRadius.circular(8)),
        child: SfPdfViewer.network(widget.pdfUrl),
      ),
    );
  }
}
