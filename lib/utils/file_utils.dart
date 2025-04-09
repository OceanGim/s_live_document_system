import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:s_live_document_system/utils/logger.dart';

/// 파일 처리를 위한 유틸리티 클래스
class FileUtils {
  /// 애셋 파일을 로컬 파일로 복사
  static Future<File> copyAssetToLocal(
    String assetPath,
    String localFileName,
  ) async {
    try {
      // 애셋 파일 데이터 로드
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List();

      // 로컬 디렉토리 경로 얻기
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;

      // 로컬 파일 생성
      final File localFile = File('$tempPath/$localFileName');

      // 애셋 파일 데이터를 로컬 파일에 쓰기
      await localFile.writeAsBytes(bytes);

      Logger.debug('애셋 파일이 로컬에 복사됨: $assetPath -> ${localFile.path}');
      return localFile;
    } catch (e, stack) {
      Logger.error('애셋 파일 복사 실패', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// PDF 파일 이름 생성 (서류명_고객명_날짜.pdf)
  static String generateDocumentFileName(
    String documentType,
    String userName,
    DateTime date,
  ) {
    final String formattedDate =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final String fileName =
        '${_getDocumentTypeName(documentType)}_${userName}_$formattedDate.pdf';
    return fileName;
  }

  /// 서류 유형명 반환
  static String _getDocumentTypeName(String documentType) {
    switch (documentType) {
      case 'personal_info':
        return '개인정보동의서';
      case 'portrait_rights':
        return '초상권동의서';
      case 'equipment_rental':
        return '장비대여신청서';
      case 'facility_guidelines':
        return '이용자준수사항';
      case 'satisfaction_survey':
        return '만족도조사';
      default:
        return documentType;
    }
  }

  /// 이미지 파일 이름 생성 (대관사진_날짜_시간_스튜디오번호_고객명.jpg)
  static String generatePhotoFileName(
    DateTime date,
    String startTime,
    String studioNumber,
    String companyName,
  ) {
    final String formattedDate =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    // 시간에서 콜론(:) 제거 (ex: 14:30 -> 1430)
    final String formattedTime = startTime.replaceAll(':', '');

    final String fileName =
        '${formattedDate}_${formattedTime}_$studioNumber${companyName.isEmpty ? '' : '_$companyName'}.jpg';
    return fileName;
  }

  /// 사진 저장 경로 생성 (photo/yyyyMMdd/파일명)
  static String generatePhotoStoragePath(DateTime date, String fileName) {
    final String formattedDate =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return 'photo/$formattedDate/$fileName';
  }

  /// 문서 저장 경로 생성 (documents/유형/yyyyMMdd/파일명)
  static String generateDocumentStoragePath(
    String documentType,
    DateTime date,
    String fileName,
  ) {
    final String formattedDate =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return 'documents/$documentType/$formattedDate/$fileName';
  }

  /// 임시 파일 생성
  static Future<File> createTempFile(String fileName, List<int> bytes) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;
      final File tempFile = File('$tempPath/$fileName');

      // 파일에 데이터 쓰기
      await tempFile.writeAsBytes(bytes);

      Logger.debug('임시 파일 생성됨: ${tempFile.path}');
      return tempFile;
    } catch (e, stack) {
      Logger.error('임시 파일 생성 실패', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 로컬 파일 삭제
  static Future<void> deleteLocalFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        Logger.debug('파일 삭제됨: $filePath');
      } else {
        Logger.warning('삭제할 파일이 존재하지 않음: $filePath');
      }
    } catch (e, stack) {
      Logger.error('파일 삭제 실패', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 파일 크기 포맷팅 (KB, MB 등)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb MB';
    } else {
      final gb = (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
      return '$gb GB';
    }
  }

  /// 파일 확장자 확인
  static String getFileExtension(String fileName) {
    return fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  }

  /// 이미지 파일인지 확인
  static bool isImageFile(String fileName) {
    final ext = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  /// PDF 파일인지 확인
  static bool isPdfFile(String fileName) {
    final ext = getFileExtension(fileName);
    return ext == 'pdf';
  }
}
