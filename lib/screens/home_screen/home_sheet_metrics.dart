import 'package:flutter/material.dart';

class HomeSheetMetrics {
  const HomeSheetMetrics._({
    required this.scale,
    required this.heightScale,
  });

  factory HomeSheetMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final widthScale = (size.width / 390).clamp(0.88, 1.12);
    final heightScale = (size.height / 844).clamp(0.88, 1.1);
    final scale = ((widthScale + heightScale) / 2).toDouble();
    return HomeSheetMetrics._(
      scale: scale,
      heightScale: heightScale.toDouble(),
    );
  }

  final double scale;
  final double heightScale;

  EdgeInsets get outerPadding =>
      EdgeInsets.fromLTRB(16 * scale, 12 * scale, 16 * scale, 24 * scale);
  double get sheetRadius => 28 * scale;
  double get handleWidth => 44 * scale;
  double get handleHeight => (4 * scale).clamp(3.0, 6.0);
  double get sectionGap => 20 * scale;
  double get itemGap => 10 * scale;
  double get contentGap => 14 * scale;
  double get textGap => 4 * scale;
  double get cardInset => 20 * scale;
  double get cardPadding => 16 * scale;
  double get headerPadding => 14 * scale;
  double get compactHeaderPadding => 12 * scale;
  double get tileVerticalPadding => 14 * scale;
  double get cardRadius => 20 * scale;
  double get headerRadius => 24 * scale;
  double get pillRadius => 999;
  double get leadingSize => 44 * scale;
  double get leadingRadius => 14 * scale;
  double get leadingIconSize => 22 * scale;
  double get trailingSize => 32 * scale;
  double get trailingIconSize => 18 * scale;
  double get artworkSize => 72 * scale;
  double get compactArtworkSize => 56 * scale;
  double get artworkRadius => 18 * scale;
  double get artworkIconSize => 28 * scale;
  double get buttonHorizontalPadding => 14 * scale;
  double get buttonVerticalPadding => 10 * scale;
  double get selectPillHorizontalPadding => 10 * scale;
  double get selectPillVerticalPadding => 6 * scale;
  double get shadowBlur => 18 * scale;
  double get shadowOffsetY => 8 * scale;
  double get headerStackBreakpoint => 360 * scale;
  double get actionsMinSize =>
      (0.34 + ((1.0 - heightScale) * 0.12)).clamp(0.32, 0.42);
  double get actionsMaxSize => 0.92;
  double get playlistMinSize =>
      (0.42 + ((1.0 - heightScale) * 0.12)).clamp(0.4, 0.5);
  double get playlistInitialSize =>
      (0.58 + ((1.0 - heightScale) * 0.18)).clamp(0.56, 0.72);
  double get playlistMaxSize => 0.94;

  double get _estimatedHeaderHeight {
    final textBlockHeight = (textGap + 2) + 28 * scale + textGap + 18 * scale;
    final contentHeight =
        artworkSize > textBlockHeight ? artworkSize : textBlockHeight;
    return (headerPadding * 2) + contentHeight;
  }

  double get _estimatedActionTileHeight {
    final textBlockHeight = 22 * scale + textGap + 16 * scale;
    final contentHeight =
        leadingSize > textBlockHeight ? leadingSize : textBlockHeight;
    return (tileVerticalPadding * 2) + contentHeight + itemGap;
  }

  double actionsInitialSizeFor({
    required double viewportHeight,
    double bottomInset = 0,
    required int actionCount,
  }) {
    final desiredHeight = outerPadding.vertical +
        handleHeight +
        sectionGap +
        _estimatedHeaderHeight +
        (sectionGap * 0.9) +
        (_estimatedActionTileHeight * actionCount) +
        bottomInset +
        (12 * scale);
    return (desiredHeight / viewportHeight)
        .clamp(actionsMinSize, actionsMaxSize)
        .toDouble();
  }
}
