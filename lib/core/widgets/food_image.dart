import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../theme/app_theme.dart';

class FoodImage extends StatelessWidget {
  const FoodImage({
    super.key,
    this.menu,
    this.imageUrl,
    this.emoji,
    this.category,
    this.fit = BoxFit.cover,
    this.emojiSize = 40,
  });

  final MenuItem? menu;
  final String? imageUrl;
  final String? emoji;
  final String? category;
  final BoxFit fit;
  final double emojiSize;

  String get _imageUrl => imageUrl ?? menu?.imageUrl ?? '';
  String get _emoji => emoji ?? menu?.emoji ?? '🍽️';
  String get _category => category ?? menu?.category ?? 'Lainnya';

  @override
  Widget build(BuildContext context) {
    if (_imageUrl.trim().isEmpty) {
      return _fallback();
    }
    return Image.network(
      _imageUrl,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _fallback(showLoader: true);
      },
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback({bool showLoader = false}) {
    final bg = switch (_category.toLowerCase()) {
      'minuman' => AppColors.primaryContainer,
      'snack' => AppColors.accentSoft,
      _ => const Color(0xFFF1F5F9),
    };

    return Container(
      color: bg,
      alignment: Alignment.center,
      child: showLoader
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
            )
          : Text(_emoji, style: TextStyle(fontSize: emojiSize)),
    );
  }
}
