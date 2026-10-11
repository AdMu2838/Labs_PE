import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';

abstract final class DocumentService {
  static Future<void> certificate(String student, String cui, List<List<String>> rows) async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (_) => [
      pw.Text('UNSA | Ingeniería de Sistemas', style: pw.TextStyle(fontSize: 21, color: PdfColor.fromHex('#7B1835'), fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 18), pw.Text('CONSTANCIA DE MATRÍCULA DE LABORATORIOS', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 18), pw.Text('Estudiante: $student\nCUI: $cui\nEmitida: ${DateTime.now().toIso8601String().substring(0, 10)}'), pw.SizedBox(height: 20),
      pw.TableHelper.fromTextArray(headers: ['Periodo', 'Curso', 'Grupo', 'Horario'], data: rows, headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200), cellStyle: const pw.TextStyle(fontSize: 9)),
      pw.SizedBox(height: 24), pw.Text('Documento de consulta generado por la plataforma de laboratorios. No reemplaza la constancia oficial del sistema académico UNSA.', style: const pw.TextStyle(fontSize: 9)),
    ]));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'matricula-laboratorios.pdf');
  }
  static Future<void> csv(String filename, List<List<dynamic>> rows) async {
    final text = const ListToCsvConverter().convert(rows);
    await FilePicker.platform.saveFile(fileName: filename, type: FileType.custom, allowedExtensions: ['csv'], bytes: Uint8List.fromList(utf8.encode('\uFEFF$text')));
  }
}
