import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  static Future<void> generateAndShareAttendancePdf({
    required String courseName,
    required String roomName,
    required String teacherName,
    required String sessionId,
    required List<Map<String, dynamic>> students, // Liste de maps contenant 'name', 'email', 'scannedAt'
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.blue, width: 2),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DIGITAL LIST',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Rapport d\'émargement automatique',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        DateTime.now().toString().substring(0, 10),
                        style: const pw.TextStyle(color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Informations de la séance
                pw.Text(
                  'DÉTAILS DE LA SÉANCE',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      children: [
                        _pdfInfoCell('Matière :', true),
                        _pdfInfoCell(courseName, false),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _pdfInfoCell('Salle :', true),
                        _pdfInfoCell(roomName, false),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _pdfInfoCell('Enseignant :', true),
                        _pdfInfoCell(teacherName, false),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _pdfInfoCell('ID Séance :', true),
                        _pdfInfoCell(sessionId, false),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Titre Liste Présents
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'LISTE DES ÉTUDIANTS PRÉSENTS',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                  ),
                    ),
                    pw.Text(
                      'Total : ${students.length} étudiant(s)',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),

                // Tableau des émargements
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: const {
                    0: pw.FixedColumnWidth(30),
                    1: pw.FlexColumnWidth(3),
                    2: pw.FlexColumnWidth(3),
                    3: pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Ligne d'en-tête du tableau
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _pdfTableHeader('N°'),
                        _pdfTableHeader('Nom Complet'),
                        _pdfTableHeader('Adresse Email'),
                        _pdfTableHeader('Heure d\'émargement'),
                      ],
                    ),
                    // Lignes de données
                    if (students.isEmpty)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Text('-', textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Text('Aucun étudiant présent pour le moment', style: const pw.TextStyle(color: PdfColors.grey600)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Text(''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Text(''),
                          ),
                        ],
                      )
                    else
                      ...List.generate(students.length, (index) {
                        final student = students[index];
                        final scannedAt = student['scannedAt'] as Timestamp?;
                        final timeStr = scannedAt != null
                            ? '${scannedAt.toDate().hour.toString().padLeft(2, '0')}:${scannedAt.toDate().minute.toString().padLeft(2, '0')}'
                            : '--:--';
                        return pw.TableRow(
                          children: [
                            _pdfTableCell('${index + 1}'),
                            _pdfTableCell(student['name'] ?? ''),
                            _pdfTableCell(student['email'] ?? ''),
                            _pdfTableCell(timeStr),
                          ],
                        );
                      }),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // Ouvre la boîte de dialogue système pour visualiser, imprimer et partager le PDF
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Emargement_${courseName.replaceAll(' ', '_')}_${DateTime.now().toString().substring(0, 10)}.pdf',
    );
  }

  static pw.Widget _pdfInfoCell(String text, bool isLabel) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isLabel ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _pdfTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  static pw.Widget _pdfTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }
}
