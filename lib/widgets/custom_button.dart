import 'package:flutter/material.dart';
import 'package:s_live_document_system/constants/app_colors.dart';

/// 앱 전체에서 사용되는, 일관된 디자인의 버튼 위젯
class CustomButton extends StatelessWidget {
  /// 기본 생성자
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
    this.textStyle,
  });

  /// 메인 버튼 생성 헬퍼 (기본 색상)
  factory CustomButton.primary({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    IconData? icon,
    EdgeInsets? padding,
    double? width,
    double? height,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isPrimary: true,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
      padding: padding,
      width: width,
      height: height,
    );
  }

  /// 보조 버튼 생성 헬퍼 (아웃라인)
  factory CustomButton.secondary({
    Key? key,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    IconData? icon,
    EdgeInsets? padding,
    double? width,
    double? height,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isPrimary: false,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      backgroundColor: Colors.transparent,
      textColor: AppColors.primary,
      borderColor: AppColors.primary,
      padding: padding,
      width: width,
      height: height,
    );
  }

  /// 버튼 텍스트
  final String text;

  /// 버튼 클릭 이벤트
  final VoidCallback onPressed;

  /// 기본 스타일 적용 여부 (true: 채워진 스타일, false: 외곽선 스타일)
  final bool isPrimary;

  /// 로딩 상태 표시 여부
  final bool isLoading;

  /// 전체 너비 사용 여부
  final bool isFullWidth;

  /// 버튼 아이콘 (선택)
  final IconData? icon;

  /// 배경 색상 (선택, isPrimary가 true면 기본값으로 AppColors.primary 사용)
  final Color? backgroundColor;

  /// 텍스트 색상 (선택, isPrimary가 true면 기본값으로 흰색 사용)
  final Color? textColor;

  /// 테두리 색상 (선택, isPrimary가 false면 기본값으로 AppColors.primary 사용)
  final Color? borderColor;

  /// 패딩 (선택, 기본값으로 내부에서 설정)
  final EdgeInsets? padding;

  /// 테두리 둥글기 (선택, 기본값은 8.0)
  final double? borderRadius;

  /// 버튼 너비 (선택, isFullWidth가 true면 사용되지 않음)
  final double? width;

  /// 버튼 높이 (선택, 기본값은 패딩으로 조절됨)
  final double? height;

  /// 텍스트 스타일 (선택, 기본값으로 내부에서 설정)
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0);
    final effectiveBorderRadius = borderRadius ?? 8.0;

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor:
          backgroundColor ??
          (isPrimary ? AppColors.primary : Colors.transparent),
      foregroundColor:
          textColor ?? (isPrimary ? Colors.white : AppColors.primary),
      padding: effectivePadding,
      elevation: isPrimary ? 0 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        side: BorderSide(
          color:
              borderColor ??
              (isPrimary ? Colors.transparent : AppColors.primary),
          width: 1.5,
        ),
      ),
      fixedSize:
          (width != null || height != null)
              ? Size(width ?? double.infinity, height ?? 48.0)
              : null,
      textStyle:
          textStyle ??
          const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
    );

    final buttonContent =
        isLoading
            ? const SizedBox(
              width: 20.0,
              height: 20.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
            : (icon != null
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18.0),
                    const SizedBox(width: 8.0),
                    Text(text),
                  ],
                )
                : Text(text));

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: buttonContent,
    );

    return isFullWidth ? button : SizedBox(width: width, child: button);
  }
}
