import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class DocumentService {
  // PDF 파일 생성
  Future<File> generatePdf({
    required String customerName,
    required String rentalDateTime,
    required String studioNumber,
    required String documentName,
    required String signatureImageBase64,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('문서: $documentName'),
              pw.Text('고객명: $customerName'),
              pw.Text('대여 일시: $rentalDateTime'),
              pw.Text('스튜디오 번호: $studioNumber'),
              pw.Text('작성일: ${DateTime.now().toString()}'),
              // TODO: 서명 이미지 추가
              pw.Text('서명: (준비 중)'),
            ],
          );
        },
      ),
    );

    // PDF를 파일로 저장
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$documentName.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // PDF 미리보기
  Future<void> previewPdf(File file) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return await Printing.convertHtml(
          format: format,
          html: await file.readAsString(), // 임시 코드, PDF 내용으로 대체 필요
        );
      },
    );
  }
}
