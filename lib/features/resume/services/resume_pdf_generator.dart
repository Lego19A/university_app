// ============================================================
// RESUME PDF GENERATOR - Pure service that builds a PDF
// document from ResumeData and a PdfColor theme.
//
// This is the single source of truth for resume layout.
// The same function is called by:
//   1. PdfPreview (for the live on-screen preview)
//   2. The download/share action (exact same output)
//
// This guarantees 1:1 parity between preview and export.
//
// The layout replicates the structure from the existing
// resume_screen.dart Figma placeholder:
//   - Centered name header with letter spacing
//   - Contact info
//   - Divider
//   - EDUCATION section
//   - SKILLS section
//   - EXPERIENCE section
// ============================================================

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/resume_data_model.dart';

// ============================================================
// generateResumePdf - Builds and returns the PDF as bytes.
// Takes the resume data and theme color as input.
// ============================================================
Future<Uint8List> generateResumePdf(
  ResumeData data,
  PdfColor primaryColor,
) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ---- NAME HEADER ----
            pw.Center(
              child: pw.Text(
                data.name,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 2,
                ),
              ),
            ),
            pw.SizedBox(height: 4),

            // ---- CONTACT INFO ----
            pw.Center(
              child: pw.Text(
                '${data.email} | ${data.phone}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            if (data.address.isNotEmpty)
              pw.Center(
                child: pw.Text(
                  data.address,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ),

            pw.SizedBox(height: 12),
            pw.Divider(color: primaryColor, thickness: 1.5),
            pw.SizedBox(height: 12),

            // ---- EDUCATION SECTION ----
            _buildSectionHeader('EDUCATION', primaryColor),
            pw.SizedBox(height: 6),
            ...data.education.map((edu) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        edu.degree,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            edu.institution,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            edu.years,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      if (edu.gpa != null)
                        pw.Text(
                          'GPA: ${edu.gpa}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: primaryColor,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                )),

            pw.SizedBox(height: 8),

            // ---- SKILLS SECTION ----
            _buildSectionHeader('SKILLS', primaryColor),
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 8,
              runSpacing: 4,
              children: data.skills.map((skill) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: primaryColor.shade(0.9),
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: primaryColor, width: 0.5),
                  ),
                  child: pw.Text(
                    skill,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),

            pw.SizedBox(height: 16),

            // ---- EXPERIENCE SECTION ----
            _buildSectionHeader('EXPERIENCE', primaryColor),
            pw.SizedBox(height: 6),
            ...data.experience.map((exp) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            exp.title,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            exp.dates,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                    
                      ),
                      pw.Text(
                        exp.company,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: primaryColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        exp.description,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                )),

            // ---- EXTRACURRICULAR SECTION ----
            if (data.extracurriculars.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              _buildSectionHeader('EXTRACURRICULAR', primaryColor),
              pw.SizedBox(height: 6),
              ...data.extracurriculars.map((activity) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            )),
                        pw.Expanded(
                          child: pw.Text(
                            activity,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        );
      },
    ),
  );

  return pdf.save();
}

// ============================================================
// _buildSectionHeader - Reusable section title with underline.
// ============================================================
pw.Widget _buildSectionHeader(String title, PdfColor color) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Container(
        width: 40,
        height: 2,
        color: color,
      ),
    ],
  );
}
