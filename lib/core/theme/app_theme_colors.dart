import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnPrimary,
    required this.primary,
    required this.primarySoft,
    required this.secondary,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.divider,
    required this.navBackground,
    required this.navActive,
    required this.navInactive,
    required this.headerOverlayTop,
    required this.headerOverlayMid,
    required this.headerOverlayBottom,
    required this.headerActionSurface,
    required this.modalBarrier,
    required this.modalShadow,
    required this.sheetHandle,
    required this.methodGet,
    required this.methodPost,
    required this.methodPut,
    required this.methodDelete,
    required this.methodPatch,
    required this.methodHead,
    required this.methodOptions,
    required this.methodConnect,
    required this.chipNeutral,
    required this.codeLiteral,
    required this.codeKey,
    required this.codeString,
    required this.codeNumber,
  });

  const AppThemeColors.light()
    : background = AppColors.background,
      surface = AppColors.surface,
      surfaceMuted = AppColors.surfaceMuted,
      card = AppColors.card,
      border = AppColors.border,
      textPrimary = AppColors.textPrimary,
      textSecondary = AppColors.textSecondary,
      textOnPrimary = AppColors.textOnPrimary,
      primary = AppColors.primary,
      primarySoft = AppColors.primarySoft,
      secondary = AppColors.secondary,
      iconPrimary = AppColors.textPrimary,
      iconSecondary = AppColors.textSecondary,
      divider = AppColors.border,
      navBackground = AppColors.textOnPrimary,
      navActive = AppColors.methodGet,
      navInactive = AppColors.textPrimary,
      headerOverlayTop = const Color(0xE6FFFFFF),
      headerOverlayMid = const Color(0xA6FFFFFF),
      headerOverlayBottom = const Color(0x00FFFFFF),
      headerActionSurface = const Color(0xB8FFFFFF),
      modalBarrier = const Color(0x2E16212E),
      modalShadow = const Color(0x1416212E),
      sheetHandle = AppColors.surfaceMuted,
      methodGet = AppColors.methodGet,
      methodPost = AppColors.methodPost,
      methodPut = AppColors.methodPut,
      methodDelete = AppColors.methodDelete,
      methodPatch = AppColors.methodPatch,
      methodHead = AppColors.methodHead,
      methodOptions = AppColors.methodOptions,
      methodConnect = AppColors.methodConnect,
      chipNeutral = AppColors.chipNeutral,
      codeLiteral = AppColors.methodPut,
      codeKey = AppColors.secondary,
      codeString = AppColors.primary,
      codeNumber = AppColors.methodGet;

  const AppThemeColors.dark()
    : background = AppColors.darkBackground,
      surface = AppColors.darkSurface,
      surfaceMuted = AppColors.darkSurfaceMuted,
      card = AppColors.darkCard,
      border = AppColors.darkBorder,
      textPrimary = AppColors.darkTextPrimary,
      textSecondary = AppColors.darkTextSecondary,
      textOnPrimary = AppColors.darkTextOnPrimary,
      primary = AppColors.darkPrimary,
      primarySoft = AppColors.darkPrimarySoft,
      secondary = AppColors.darkSecondary,
      iconPrimary = AppColors.darkTextPrimary,
      iconSecondary = AppColors.darkTextSecondary,
      divider = AppColors.darkBorder,
      navBackground = AppColors.darkSurface,
      navActive = AppColors.darkPrimary,
      navInactive = AppColors.darkTextSecondary,
      headerOverlayTop = const Color(0xF2151B24),
      headerOverlayMid = const Color(0xB3151B24),
      headerOverlayBottom = const Color(0x00151B24),
      headerActionSurface = const Color(0xB3273140),
      modalBarrier = const Color(0x8010131A),
      modalShadow = const Color(0x40000000),
      sheetHandle = AppColors.darkBorder,
      methodGet = AppColors.darkMethodGet,
      methodPost = AppColors.darkMethodPost,
      methodPut = AppColors.darkMethodPut,
      methodDelete = AppColors.darkMethodDelete,
      methodPatch = AppColors.darkMethodPatch,
      methodHead = AppColors.darkMethodHead,
      methodOptions = AppColors.darkMethodOptions,
      methodConnect = AppColors.darkMethodConnect,
      chipNeutral = AppColors.darkChipNeutral,
      codeLiteral = AppColors.darkMethodPut,
      codeKey = AppColors.darkSecondary,
      codeString = AppColors.darkPrimary,
      codeNumber = AppColors.darkMethodGet;

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textOnPrimary;
  final Color primary;
  final Color primarySoft;
  final Color secondary;
  final Color iconPrimary;
  final Color iconSecondary;
  final Color divider;
  final Color navBackground;
  final Color navActive;
  final Color navInactive;
  final Color headerOverlayTop;
  final Color headerOverlayMid;
  final Color headerOverlayBottom;
  final Color headerActionSurface;
  final Color modalBarrier;
  final Color modalShadow;
  final Color sheetHandle;
  final Color methodGet;
  final Color methodPost;
  final Color methodPut;
  final Color methodDelete;
  final Color methodPatch;
  final Color methodHead;
  final Color methodOptions;
  final Color methodConnect;
  final Color chipNeutral;
  final Color codeLiteral;
  final Color codeKey;
  final Color codeString;
  final Color codeNumber;

  Color methodColor(String method) => switch (method.toUpperCase()) {
    'GET' => methodGet,
    'POST' => methodPost,
    'PUT' => methodPut,
    'DEL' => methodDelete,
    'PAT' => methodPatch,
    'HEAD' || 'TRACE' => methodHead,
    'OPT' || 'OPTI' => methodOptions,
    'CON' => methodConnect,
    _ => chipNeutral,
  };

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? card,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textOnPrimary,
    Color? primary,
    Color? primarySoft,
    Color? secondary,
    Color? iconPrimary,
    Color? iconSecondary,
    Color? divider,
    Color? navBackground,
    Color? navActive,
    Color? navInactive,
    Color? headerOverlayTop,
    Color? headerOverlayMid,
    Color? headerOverlayBottom,
    Color? headerActionSurface,
    Color? modalBarrier,
    Color? modalShadow,
    Color? sheetHandle,
    Color? methodGet,
    Color? methodPost,
    Color? methodPut,
    Color? methodDelete,
    Color? methodPatch,
    Color? methodHead,
    Color? methodOptions,
    Color? methodConnect,
    Color? chipNeutral,
    Color? codeLiteral,
    Color? codeKey,
    Color? codeString,
    Color? codeNumber,
  }) => AppThemeColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    card: card ?? this.card,
    border: border ?? this.border,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textOnPrimary: textOnPrimary ?? this.textOnPrimary,
    primary: primary ?? this.primary,
    primarySoft: primarySoft ?? this.primarySoft,
    secondary: secondary ?? this.secondary,
    iconPrimary: iconPrimary ?? this.iconPrimary,
    iconSecondary: iconSecondary ?? this.iconSecondary,
    divider: divider ?? this.divider,
    navBackground: navBackground ?? this.navBackground,
    navActive: navActive ?? this.navActive,
    navInactive: navInactive ?? this.navInactive,
    headerOverlayTop: headerOverlayTop ?? this.headerOverlayTop,
    headerOverlayMid: headerOverlayMid ?? this.headerOverlayMid,
    headerOverlayBottom: headerOverlayBottom ?? this.headerOverlayBottom,
    headerActionSurface: headerActionSurface ?? this.headerActionSurface,
    modalBarrier: modalBarrier ?? this.modalBarrier,
    modalShadow: modalShadow ?? this.modalShadow,
    sheetHandle: sheetHandle ?? this.sheetHandle,
    methodGet: methodGet ?? this.methodGet,
    methodPost: methodPost ?? this.methodPost,
    methodPut: methodPut ?? this.methodPut,
    methodDelete: methodDelete ?? this.methodDelete,
    methodPatch: methodPatch ?? this.methodPatch,
    methodHead: methodHead ?? this.methodHead,
    methodOptions: methodOptions ?? this.methodOptions,
    methodConnect: methodConnect ?? this.methodConnect,
    chipNeutral: chipNeutral ?? this.chipNeutral,
    codeLiteral: codeLiteral ?? this.codeLiteral,
    codeKey: codeKey ?? this.codeKey,
    codeString: codeString ?? this.codeString,
    codeNumber: codeNumber ?? this.codeNumber,
  );

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }

    return AppThemeColors(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceMuted:
          Color.lerp(surfaceMuted, other.surfaceMuted, t) ?? surfaceMuted,
      card: Color.lerp(card, other.card, t) ?? card,
      border: Color.lerp(border, other.border, t) ?? border,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textOnPrimary:
          Color.lerp(textOnPrimary, other.textOnPrimary, t) ?? textOnPrimary,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t) ?? primarySoft,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t) ?? iconPrimary,
      iconSecondary:
          Color.lerp(iconSecondary, other.iconSecondary, t) ?? iconSecondary,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      navBackground:
          Color.lerp(navBackground, other.navBackground, t) ?? navBackground,
      navActive: Color.lerp(navActive, other.navActive, t) ?? navActive,
      navInactive: Color.lerp(navInactive, other.navInactive, t) ?? navInactive,
      headerOverlayTop:
          Color.lerp(headerOverlayTop, other.headerOverlayTop, t) ??
          headerOverlayTop,
      headerOverlayMid:
          Color.lerp(headerOverlayMid, other.headerOverlayMid, t) ??
          headerOverlayMid,
      headerOverlayBottom:
          Color.lerp(headerOverlayBottom, other.headerOverlayBottom, t) ??
          headerOverlayBottom,
      headerActionSurface:
          Color.lerp(headerActionSurface, other.headerActionSurface, t) ??
          headerActionSurface,
      modalBarrier:
          Color.lerp(modalBarrier, other.modalBarrier, t) ?? modalBarrier,
      modalShadow: Color.lerp(modalShadow, other.modalShadow, t) ?? modalShadow,
      sheetHandle: Color.lerp(sheetHandle, other.sheetHandle, t) ?? sheetHandle,
      methodGet: Color.lerp(methodGet, other.methodGet, t) ?? methodGet,
      methodPost: Color.lerp(methodPost, other.methodPost, t) ?? methodPost,
      methodPut: Color.lerp(methodPut, other.methodPut, t) ?? methodPut,
      methodDelete:
          Color.lerp(methodDelete, other.methodDelete, t) ?? methodDelete,
      methodPatch: Color.lerp(methodPatch, other.methodPatch, t) ?? methodPatch,
      methodHead: Color.lerp(methodHead, other.methodHead, t) ?? methodHead,
      methodOptions:
          Color.lerp(methodOptions, other.methodOptions, t) ?? methodOptions,
      methodConnect:
          Color.lerp(methodConnect, other.methodConnect, t) ?? methodConnect,
      chipNeutral: Color.lerp(chipNeutral, other.chipNeutral, t) ?? chipNeutral,
      codeLiteral: Color.lerp(codeLiteral, other.codeLiteral, t) ?? codeLiteral,
      codeKey: Color.lerp(codeKey, other.codeKey, t) ?? codeKey,
      codeString: Color.lerp(codeString, other.codeString, t) ?? codeString,
      codeNumber: Color.lerp(codeNumber, other.codeNumber, t) ?? codeNumber,
    );
  }
}
