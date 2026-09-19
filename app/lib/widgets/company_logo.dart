import 'package:flutter/material.dart';

/// Renders a simple colored badge standing in for a company logo.
///
/// This MVP is front-end only and has no real image assets bundled, so
/// instead of broken `Image.asset` calls we render a lightweight,
/// branded-looking badge per company key. Swap this out for
/// `Image.asset('assets/logos/$logoAsset.png')` once real logo files are
/// added to `assets/logos/` and declared in `pubspec.yaml`.
class CompanyLogo extends StatelessWidget {
  final String logoAsset;
  final double size;

  const CompanyLogo({super.key, required this.logoAsset, this.size = 48});

  static const Map<String, _LogoStyle> _styles = {
    'rockstar': _LogoStyle(Color(0xFFFFC107), Icons.star, Colors.black),
    'playstation': _LogoStyle(
        Color(0xFF003791), Icons.sports_esports, Colors.white),
    'ubisoft': _LogoStyle(Colors.white, Icons.language, Colors.black),
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[logoAsset] ??
        const _LogoStyle(Colors.black12, Icons.business, Colors.black);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Colors.black12),
      ),
      child: Icon(style.icon, color: style.foreground, size: size * 0.5),
    );
  }
}

class _LogoStyle {
  final Color background;
  final IconData icon;
  final Color foreground;
  const _LogoStyle(this.background, this.icon, this.foreground);
}
