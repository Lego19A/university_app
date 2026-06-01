// ============================================================
// APP CONSTANTS - Reusable spacing, sizing, and string values.
// Centralizing these avoids magic numbers scattered in code.
// If the Figma design uses different padding/margins, update here.
// ============================================================

class AppConstants {
  // -- PADDING: Standard padding from screen edges (matches Figma margins) --
  static const double pagePadding = 20.0;

  // -- CARD BORDER RADIUS: Unified corner radius for all cards --
  static const double cardRadius = 16.0;

  // -- BUTTON BORDER RADIUS: Unified corner radius for all buttons --
  static const double buttonRadius = 12.0;

  // -- SPACING: Vertical spacing between sections --
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;

  // -- ICON SIZE: Standard icon sizes used in the app --
  static const double iconSizeSM = 20.0;
  static const double iconSizeMD = 24.0;
  static const double iconSizeLG = 32.0;

  // -- AVATAR SIZE: Profile avatar diameter --
  static const double avatarRadius = 50.0;

  // -- BOTTOM NAV HEIGHT: Height of the bottom navigation bar --
  static const double bottomNavHeight = 70.0;
}
