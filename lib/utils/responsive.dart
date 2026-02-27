import 'package:flutter/material.dart';

/// Describes the current device form factor based on screen width
enum DeviceFormFactor {
  /// Phone-sized screens (< 600dp) — e.g., Samsung S24 Ultra in portrait
  phone,

  /// Tablet-sized screens (600–1199dp) — e.g., Samsung Tab S9 in portrait
  /// or a large phone in landscape
  tablet,

  /// Desktop-sized screens (≥ 1200dp) — e.g., macOS, or tablet in landscape
  desktop,
}

/// Utility class for responsive layout values
abstract final class Responsive {
  static const double _phoneMaxWidth = 600;
  static const double _tabletMaxWidth = 1200;

  /// Returns the [DeviceFormFactor] for the current screen width
  static DeviceFormFactor of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < _phoneMaxWidth) return DeviceFormFactor.phone;
    if (width < _tabletMaxWidth) return DeviceFormFactor.tablet;
    return DeviceFormFactor.desktop;
  }

  /// Whether the current screen is phone-sized
  static bool isPhone(BuildContext context) =>
      of(context) == DeviceFormFactor.phone;

  /// Whether the current screen is tablet or desktop (uses sidebar layout)
  static bool hasSidebar(BuildContext context) =>
      of(context) != DeviceFormFactor.phone;

  /// Number of grid columns to use for the image grid
  static int gridColumns(BuildContext context) {
    switch (of(context)) {
      case DeviceFormFactor.phone:
        return 2;
      case DeviceFormFactor.tablet:
        return 4;
      case DeviceFormFactor.desktop:
        return 5;
    }
  }

  /// Width of the sidebar panel (0 for phone — no sidebar)
  static double sidebarWidth(BuildContext context) {
    switch (of(context)) {
      case DeviceFormFactor.phone:
        return 0;
      case DeviceFormFactor.tablet:
        return 280;
      case DeviceFormFactor.desktop:
        return 300;
    }
  }

  /// Content padding appropriate for the current form factor
  static EdgeInsets contentPadding(BuildContext context) {
    switch (of(context)) {
      case DeviceFormFactor.phone:
        return const EdgeInsets.all(12);
      case DeviceFormFactor.tablet:
        return const EdgeInsets.all(20);
      case DeviceFormFactor.desktop:
        return const EdgeInsets.all(24);
    }
  }

  /// Recommended cache width for thumbnail images
  static int imageCacheWidth(BuildContext context) {
    switch (of(context)) {
      case DeviceFormFactor.phone:
        return 300;
      case DeviceFormFactor.tablet:
        return 200;
      case DeviceFormFactor.desktop:
        return 180;
    }
  }
}
