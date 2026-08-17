import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme.dart';

class AppIcon {
  /// Returns a widget for the given [iconData]. If a matching SVG asset
  /// exists in `assets/images/` it will be used, otherwise fall back to
  /// the regular `Icon` widget.
  static Widget fromIconData(IconData iconData, {double? size, Color? color}) {
    final c = color ?? SirexeTheme.textPrimary;
    final s = size ?? 16.0;

    // Map common IconData to our SVG assets
    if (iconData == Icons.person || iconData == Icons.person_outline || iconData == Icons.person_pin_circle) {
      return SvgPicture.asset('assets/images/icon_user_dark.svg', width: s, height: s, color: c);
    }

    if (iconData == Icons.location_on || iconData == Icons.gps_fixed || iconData == Icons.my_location) {
      return SvgPicture.asset('assets/images/icon_pin_dark.svg', width: s, height: s, color: c);
    }

    if (iconData == Icons.warning || iconData == Icons.warning_amber_rounded || iconData == Icons.error_outline) {
      return SvgPicture.asset('assets/images/icon_alert_dark.svg', width: s, height: s, color: c);
    }

    if (iconData == Icons.map || iconData == Icons.map_outlined || iconData == Icons.layers) {
      return SvgPicture.asset('assets/images/icon_layer_dark.svg', width: s, height: s, color: c);
    }

    // Default fallback
    return Icon(iconData, size: s, color: c);
  }
}
