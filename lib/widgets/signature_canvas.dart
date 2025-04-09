import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:s_live_document_system/constants/app_colors.dart';
import 'package:signature/signature.dart';

/// 서명을 받기 위한 캔버스 위젯
/// signature 패키지를 사용하여 구현
class SignatureCanvas extends StatefulWidget {
  /// 기본 생성자
  const SignatureCanvas({
    super.key,
    required this.onSignatureChanged,
    this.initialSignature,
    this.width = double.infinity,
    this.height = 200,
    this.strokeColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.grey,
    this.borderWidth = 1.0,
    this.borderRadius = 8.0,
    this.penWidth = 3.0,
  });

  /// 서명이 변경될 때 호출되는 콜백
  final Function(Uint8List?) onSignatureChanged;

  /// 초기 서명 이미지 (선택적)
  final Uint8List? initialSignature;

  /// 캔버스 너비
  final double width;

  /// 캔버스 높이
  final double height;

  /// 펜 색상
  final Color strokeColor;

  /// 배경 색상
  final Color backgroundColor;

  /// 테두리 색상
  final Color borderColor;

  /// 테두리 두께
  final double borderWidth;

  /// 테두리 둥글기
  final double borderRadius;

  /// 펜 두께
  final double penWidth;

  @override
  State<SignatureCanvas> createState() => _SignatureCanvasState();
}

class _SignatureCanvasState extends State<SignatureCanvas> {
  late SignatureController _controller;
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: widget.penWidth,
      penColor: widget.strokeColor,
      exportBackgroundColor: widget.backgroundColor,
    );

    // 초기 서명이 있으면 로드
    if (widget.initialSignature != null) {
      _loadFromBytes(widget.initialSignature!);
    }

    // 서명 변경 리스너 추가
    _controller.onDrawEnd = _onDrawEnd;
  }

  Future<void> _loadFromBytes(Uint8List bytes) async {
    final ui.Image image = await _decodeImageFromList(bytes);
    setState(() {
      // 이미지를 직접 설정하는 대신 서명으로 간주하도록 설정
      _controller.clear();
      _hasSignature = true;
    });
  }

  Future<ui.Image> _decodeImageFromList(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  void _onDrawEnd() async {
    if (_controller.isEmpty) {
      setState(() {
        _hasSignature = false;
      });
      widget.onSignatureChanged(null);
      return;
    }

    setState(() {
      _hasSignature = true;
    });

    final data = await _controller.toPngBytes();
    if (data != null) {
      widget.onSignatureChanged(data);
    }
  }

  void _clearSignature() {
    _controller.clear();
    setState(() {
      _hasSignature = false;
    });
    widget.onSignatureChanged(null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.borderColor,
              width: widget.borderWidth,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius - 1),
            child: Signature(
              controller: _controller,
              width: widget.width,
              height: widget.height,
              backgroundColor: widget.backgroundColor,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 상태 텍스트
            Text(
              _hasSignature ? '서명이 완료되었습니다' : '위 영역에 서명해주세요',
              style: TextStyle(
                color:
                    _hasSignature ? AppColors.success : AppColors.textSecondary,
                fontSize: 14.0,
                fontWeight: _hasSignature ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            // 서명 지우기 버튼
            if (_hasSignature)
              TextButton.icon(
                onPressed: _clearSignature,
                icon: const Icon(Icons.delete_outline, size: 18.0),
                label: const Text('지우기'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 12.0,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
