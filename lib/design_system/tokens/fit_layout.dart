/// Dimensões estruturais provisórias preservadas da implementação atual.
///
/// O DS3 confirma os papéis, mas Grid e Spacing ainda precisam de medição.
/// Centralizar os candidatos evita novos números mágicos durante a validação.
abstract final class FitLayout {
  static const none = 0.0;

  static const minimumTouchTarget = 48.0;
  static const compactTouchTarget = 44.0;
  static const buttonHeightSmall = 40.0;
  static const buttonHeightMedium = minimumTouchTarget;
  static const buttonHeightLarge = 56.0;

  static const navigationBarHeight = 68.0;
  static const navigationContentHeight = 64.0;
  static const topBarHeight = 56.0;
  static const listTileMinHeight = 56.0;

  static const iconSizeSmall = 16.0;
  static const iconSizeCompact = 18.0;
  static const iconSizeButton = 20.0;
  static const iconSize = 22.0;
  static const iconSizeMedium = 24.0;
  static const selectedIconSize = iconSizeMedium;
  static const iconSizeLarge = 32.0;
  static const iconSizeState = 40.0;
  static const iconSizeBadge = 14.0;

  static const loadingSizeSmall = 18.0;
  static const loadingSizeInline = 28.0;
  static const loadingSizeScreen = 32.0;
  static const loadingStrokeThin = 2.0;
  static const loadingStroke = 2.5;

  static const progressThickness = 8.0;
  static const progressCompactThickness = 6.0;
  static const progressRingSize = 72.0;
  static const progressRingStroke = 7.0;
  static const sliderTrackHeight = 4.0;

  static const borderThin = 1.0;
  static const borderFocused = 1.5;

  static const bottomSheetHandleWidth = 40.0;
  static const bottomSheetHandleHeight = 4.0;
  static const dialogMaxWidth = 420.0;
  static const tagMaxWidth = 160.0;
  static const skeletonListItemHeight = 72.0;

  static const avatarSmall = 32.0;
  static const avatarMedium = minimumTouchTarget;
  static const avatarLarge = 64.0;

  static const navigationUnselectedScale = 0.94;
  static const navigationSelectedScale = 1.0;
  static const navigationLabelHeight = 16.0;
  static const navigationBadgeOffsetTop = 6.0;
  static const navigationBadgeOffsetEnd = 8.0;

  /// Dimensões provisórias para composições de domínio.
  static const domainThumbnailSmall = compactTouchTarget;
  static const domainThumbnail = avatarLarge;
  static const domainAvatarHero = 72.0;
  static const domainMetricMinWidth = 88.0;
  static const domainMetricMaxWidth = 160.0;
  static const domainChartHeight = 128.0;
  static const domainChartBarMinHeight = 4.0;
  static const domainMediaAspectRatio = 16 / 9;
  static const domainCompactMediaAspectRatio = 3 / 2;
  static const domainMapAspectRatio = 4 / 3;
  static const domainProgressRingLarge = 136.0;
  static const domainProgressRingStroke = 10.0;
  static const domainTimelineMarker = 12.0;
  static const domainProfileAvatar = 56.0;
  static const domainQuickActionMinHeight = 112.0;
  static const domainHomeMaxContentWidth = 470.0;
  static const domainPlansMaxContentWidth = 860.0;
  static const domainPlanPreviewWidth = 200.0;
  static const domainExplorePlanPreviewWidth = 168.0;
  static const domainPlanPreviewMediaHeight = 64.0;
  static const domainExplorePlanPreviewMediaHeight = 88.0;
  static const domainCoachInsightMaxLines = 4;
  static const domainExerciseTagLimit = 3;
  static const domainAuthMaxContentWidth = 440.0;
  static const domainLibraryMuscleTileWidth = 104.0;
  static const domainLibraryMuscleStripHeight = 124.0;
  static const domainLibraryFeaturedCardWidth = 248.0;
  static const domainLibraryFeaturedMediaHeight = 132.0;
}
